include "generic.mzn";
include "constant.mzn";

% ====================================================================
% Constantes Dérivées Automatiques
% ====================================================================

% --- Périodes et Unités ---
1..: P = J * PJ;                                                      % Nombre total de périodes.

% ====================================================================
% Voies
% ====================================================================

1..: VNb = sum(VNbT);                                                 % Nombre total de voies.
array[1..VNb] of 1..VTNb: VRef;
VRef = [
  v
  | v in 1..VTNb, _ in 1..VNbT[v]
];                                                                    % Références des voies.

% ====================================================================
% Techniciens (shifts)
% ====================================================================

1..: SNb = sum(SNbT);                                                 % Nombre total de techniciens.
array[1..SNb] of 1..STNb: STRef;
STRef = [
  s
  | s in 1..STNb, _ in 1..SNbT[s]
];                                                                    % Références des types shift.

% ====================================================================
% Trains, Trajets et Gares
% ====================================================================

1..: TNb = sum(TNbT);                                                 % Nombre total de trains.
array[1..TNb] of 1..TTNb: TTRef;
TTRef = [
  t
  | t in 1..TTNb, _ in 1..TNbT[t]
];                                                                    % Références types de train.

array[1..TNb, 1..P] of bool: TPresent;
TPresent = array2d(1..TNb, 1..P, [
  TTrajetSens[n, p] == gare /\
  (
    exists(k in 1..p-1)(
      TTrajetSens[n, k] == retour /\
      forall(j in k+1..p-1)(TTrajetSens[n, j] == gare)
    ) \/
    forall(k in 1..p-1)(
      TTrajetSens[n, k] == gare
    )
  ) /\
  (
    exists(k in p+1..P)(
      TTrajetSens[n, k] == aller /\
      forall(j in p+1..k-1)(TTrajetSens[n, j] == gare)
    ) \/
    forall(k in p+1..P)(
      TTrajetSens[n, k] == gare
    )
  )
  | n in 1..TNb, p in 1..P
]);                                                                   % Train en gare période.

% ====================================================================
% Intervalles d'Activité
% ====================================================================

array[1..TNb] of 0..: TIntervallesNb;
TIntervallesNb = [
  sum(p in 1..P)(TPresent[n, p] /\ (p == 1 \/ not TPresent[n, p-1]))
  | n in 1..TNb
];                                                                    % Intervalles par train.

0..: TIntervallesNbTotal;
TIntervallesNbTotal = sum(TIntervallesNb);                            % Total intervalles.

array[1..TIntervallesNbTotal] of 1..TNb: TIntervallesTRef;
TIntervallesTRef = [
  n
  | n in 1..TNb, p in 1..P
    where TPresent[n, p] /\ (p == 1 \/ not TPresent[n, p-1])
];                                                                    % Trains par intervalle.

array[1..TNb] of 1..max(1, TIntervallesNbTotal): TIntervallesDecalageT;
TIntervallesDecalageT = [
  1 + sum(
    [
      TIntervallesNb[j]
      | j in index_set(TIntervallesNb) where j < k
    ]
  )
  | k in index_set(TIntervallesNb)
];                                                                    % Décalage index train.

array[1..TIntervallesNbTotal] of 1..P: TIntervallesPDebut;
TIntervallesPDebut = [
  p
  | n in 1..TNb, p in 1..P
    where TPresent[n, p] /\ (p == 1 \/ not TPresent[n, p-1])
];                                                                    % Début intervalle.

array[1..TIntervallesNbTotal] of 1..P: TIntervallesPFin;
TIntervallesPFin = [
  p
  | n in 1..TNb, p in 1..P
    where TPresent[n, p] /\ (p == P \/ not TPresent[n, p+1])
];                                                                    % Fin intervalle.

% ====================================================================
% Gares aux Débuts/Fins d'Intervalles
% ====================================================================

% Utilisation de max/min sur listes pour garantir typage int (constant).

array[1..TIntervallesNbTotal] of 0..GNb: TIntervallesGDebut;
TIntervallesGDebut = [
  let {
      int: n = TIntervallesTRef[i];
      int: p_debut = TIntervallesPDebut[i];
      % Gare max connue avant ou à début.
      int: best_k = max([0] ++ [ k | k in 1..p_debut where TTrajetGare[n, k] > 0 ]);
  } in
  if best_k > 0 then TTrajetGare[n, best_k] else 0 endif
  | i in 1..TIntervallesNbTotal
];                                                                    % Gare début intervalle.

array[1..TIntervallesNbTotal] of 0..GNb: TIntervallesGFin;
TIntervallesGFin = [
  let {
      int: n = TIntervallesTRef[i];
      int: p_fin = TIntervallesPFin[i];
      % Gare min connue après ou à fin.
      int: best_k = min([P+1] ++ [ k | k in p_fin..P where TTrajetGare[n, k] > 0 ]);
  } in
  if best_k <= P then TTrajetGare[n, best_k] else 0 endif
  | i in 1..TIntervallesNbTotal
];                                                                    % Gare fin intervalle.

% ====================================================================
% Maintenances et Opérations
% ====================================================================

array[1..MTNb] of 0..: MONb;
MONb = [
  sum(o in 1..OTNb)(
    if MOperation[m, o] then 1 else 0 endif
  )
  | m in 1..MTNb
];                                                                    % Opérations par maintenance.

array[1..MTNb, 1..EtageMax] of 0..: MTempsMin;
MTempsMin = array2d(1..MTNb, 1..EtageMax, [
  PSetup * max(0, MONb[m] - 1) +
  sum(o in 1..OTNb)(
    OTemps[o, e]
  )
  | m in 1..MTNb, e in 1..EtageMax
]);                                                                   % Temps min maint/étage.

array[1..TTNb] of 0..: TTMTempsMin;
TTMTempsMin = [
  min(m in 1..MTNb where MTPeriode[t, m] != infinity)(
    MTempsMin[m, TEtage[t]]
  )
  | t in 1..TTNb
];                                                                    % Temps min type train.

% ====================================================================
% Faisabilité d'Intervalles pour Maintenance
% ====================================================================

array[1..TIntervallesNbTotal] of bool: TIntervallesPossible;
TIntervallesPossible = [
  (TIntervallesPFin[i] - (if TIntervallesGFin[i] > 0 then GTemps[TIntervallesGFin[i]] else 0 endif)) -
  (TIntervallesPDebut[i] + (if TIntervallesGDebut[i] > 0 then GTemps[TIntervallesGDebut[i]] else 0 endif)) -
  TTMTempsMin[TTRef[TIntervallesTRef[i]]] > 0
  | i in 1..TIntervallesNbTotal
];                                                                    % Intervalle assez long.

0..TIntervallesNbTotal: TIntervallesPossibleNb;
TIntervallesPossibleNb = sum(i in 1..TIntervallesNbTotal)(
  if TIntervallesPossible[i] then 1 else 0 endif
);                                                                    % Nombre intervalles OK.

% --- Extraction des Intervalles Possibles ---

array[1..TIntervallesPossibleNb] of 1..TNb: TIntervallesTRefPossible;
TIntervallesTRefPossible = [
  TIntervallesTRef[i]
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];                                                                    % Trains avec intervalles OK.

array[1..TIntervallesPossibleNb] of int: TIntervallesPDebutPossible;
TIntervallesPDebutPossible = [
  TIntervallesPDebut[i] + (if TIntervallesGDebut[i] > 0 then GTemps[TIntervallesGDebut[i]] else 0 endif)
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];                                                                    % Début ajusté gare.

array[1..TIntervallesPossibleNb] of int: TIntervallesPFinPossible;
TIntervallesPFinPossible = [
  TIntervallesPFin[i] - (if TIntervallesGFin[i] > 0 then GTemps[TIntervallesGFin[i]] else 0 endif)
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];                                                                    % Fin ajustée gare.

array[1..TIntervallesPossibleNb] of 0..GNb: TIntervallesGDebutPossible;
TIntervallesGDebutPossible = [
  TIntervallesGDebut[i]
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];                                                                    % Gare début OK.

array[1..TIntervallesPossibleNb] of 0..GNb: TIntervallesGFinPossible;
TIntervallesGFinPossible = [
  TIntervallesGFin[i]
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];                                                                    % Gare fin OK.

% ====================================================================
% Instances de Maintenances
% ====================================================================

array[1..TTNb] of 1..: MTNbT;
MTNbT = [
  sum(m in 1..MTNb)(
    if MTPeriode[t, m] == infinity then 0 else 1 endif
  )
  | t in 1..TTNb
];                                                                    % Maintenances type train.

array[1..TNb] of 1..: MNbT;
MNbT = [
  MTNbT[TTRef[t]]
  | t in 1..TNb
];                                                                    % Maintenances par train.

1..: MNb;
MNb = sum(MNbT);                                                      % Total maintenance types.

array[1..MNb] of 1..TNb: MRefT;
MRefT = [
  t
  | t in 1..TNb, _ in 1..MNbT[t]
];                                                                    % Références trains maint.

array[1..MNb] of 1..MTNb: MRefM;
MRefM = [
  m
  | t in 1..TNb, m in 1..MTNb
    where MTPeriode[TTRef[t], m] != infinity,
    _ in 1..1
];                                                                    % Références types maint.

% --- Instances Maintenances (Détail) ---

0..: TIntervallesNbMax;
TIntervallesNbMax = max(TIntervallesNb);                              % Max intervalles par train.

int: MInstanceNb;
MInstanceNb = MNb * TIntervallesNbMax;                                % Total instances.

array[1..MInstanceNb] of 1..MNb: MInstanceRefMNb;
MInstanceRefMNb = [
  ceil(i / TIntervallesNbMax)
  | i in 1..MInstanceNb
];                                                                    % Index maintenance instance.

array[1..MInstanceNb] of 1..TIntervallesNbMax: MInstanceRepetition;
MInstanceRepetition = [
  (i - 1) mod TIntervallesNbMax + 1
  | i in 1..MInstanceNb
];                                                                    % Numéro intervalle instance.

array[1..MInstanceNb] of 1..TNb: MInstanceRefT;
MInstanceRefT = [
  MRefT[MInstanceRefMNb[i]]
  | i in 1..MInstanceNb
];                                                                    % Références trains instance.

array[1..MInstanceNb] of 1..MTNb: MInstanceRefType;
MInstanceRefType = [
  MRefM[MInstanceRefMNb[i]]
  | i in 1..MInstanceNb
];                                                                    % Types maintenances instance.

% ====================================================================
% Horizons de Temps
% ====================================================================

int: MaxDureePossible = max(
  [P] ++
  [OTemps[o, e] | o in 1..OTNb, e in 1..EtageMax] ++
  STTempsMax
);                                                                    % Durée max possible.

int: MaxPeriodicitePossible = max(
  [0] ++
  [MTPeriode[t, m] | t in 1..TTNb, m in 1..MTNb where MTPeriode[t, m] != infinity]
);                                                                    % Périodicité max.

int: MaxHorizonFutur = P + MaxPeriodicitePossible + MaxDureePossible; % Horizon futur.

int: MinHorizonPasse = min(
  [0] ++
  [MDerniereFois[t, m] | t in 1..TNb, m in 1..MTNb]
);                                                                    % Horizon passé.
