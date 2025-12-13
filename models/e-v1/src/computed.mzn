include "generic.mzn";
include "constant.mzn";

% Calcule automatiquement les constantes dérivées des paramètres utilisateur

% Périodes et unités
1..: P = J * PJ;

% Voies
1..: VNb = sum(VNbT);
array[1..VNb] of 1..VTNb: VRef;
VRef = [
  v
  | v in 1..VTNb, _ in 1..VNbT[v]
];

% Techniciens (shifts)
1..: SNb = sum(SNbT);
array[1..SNb] of 1..STNb: STRef;
STRef = [
  s
  | s in 1..STNb, _ in 1..SNbT[s]
];

% Trains & Trajets & Gares
1..: TNb = sum(TNbT);
array[1..TNb] of 1..TTNb: TTRef;
TTRef = [
  t
  | t in 1..TTNb, _ in 1..TNbT[t]
];

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
]);

array[1..TNb] of 0..: TIntervallesNb;
TIntervallesNb = [
  sum(p in 1..P)(TPresent[n, p] /\ (p == 1 \/ not TPresent[n, p-1]))
  | n in 1..TNb
];

0..: TIntervallesNbTotal;
TIntervallesNbTotal = sum(TIntervallesNb);

array[1..TIntervallesNbTotal] of 1..TNb: TIntervallesTRef;
TIntervallesTRef = [
  n
  | n in 1..TNb, p in 1..P
    where TPresent[n, p] /\ (p == 1 \/ not TPresent[n, p-1])
];

array[1..TNb] of 1..max(1, TIntervallesNbTotal): TIntervallesDecaladeT;
TIntervallesDecaladeT = [
  1 + sum(
    [
      TIntervallesNb[j]
      | j in index_set(TIntervallesNb) where j < k
    ]
  )
  | k in index_set(TIntervallesNb)
];

array[1..TIntervallesNbTotal] of 1..P: TIntervallesPDebut;
TIntervallesPDebut = [
  p
  | n in 1..TNb, p in 1..P
    where TPresent[n, p] /\ (p == 1 \/ not TPresent[n, p-1])
];

array[1..TIntervallesNbTotal] of 1..P: TIntervallesPFin;
TIntervallesPFin = [
  p
  | n in 1..TNb, p in 1..P
    where TPresent[n, p] /\ (p == P \/ not TPresent[n, p+1])
];

% --- CORRECTION TYPE ERROR ICI ---
% Utilisation de max/min sur des listes pour garantir le typage 'int' (constant)

array[1..TIntervallesNbTotal] of 0..GNb: TIntervallesGDebut;
TIntervallesGDebut = [
  let {
      int: n = TIntervallesTRef[i];
      int: p_debut = TIntervallesPDebut[i];
      % On cherche le max index k <= p_debut où la gare est connue.
      % [0] est ajouté pour éviter un crash si la liste est vide (max renverra 0)
      int: best_k = max([0] ++ [ k | k in 1..p_debut where TTrajetGare[n, k] > 0 ]);
  } in
  if best_k > 0 then TTrajetGare[n, best_k] else 0 endif
  | i in 1..TIntervallesNbTotal
];

array[1..TIntervallesNbTotal] of 0..GNb: TIntervallesGFin;
TIntervallesGFin = [
  let {
      int: n = TIntervallesTRef[i];
      int: p_fin = TIntervallesPFin[i];
      % On cherche le min index k >= p_fin où la gare est connue.
      % [P+1] est ajouté comme sentinelle (infini) si la liste est vide
      int: best_k = min([P+1] ++ [ k | k in p_fin..P where TTrajetGare[n, k] > 0 ]);
  } in
  if best_k <= P then TTrajetGare[n, best_k] else 0 endif
  | i in 1..TIntervallesNbTotal
];

% --- FIN CORRECTION ---

% Maintenances & Opérations
array[1..MTNb] of 0..: MONb;
MONb = [
  sum(o in 1..OTNb)(
    if MOperation[m, o] then 1 else 0 endif
  )
  | m in 1..MTNb
];

array[1..MTNb, 1..EtageMax] of 0..: MTempsMin;
MTempsMin = array2d(1..MTNb, 1..EtageMax, [
  PSetup * max(0, MONb[m] - 1) +
  sum(o in 1..OTNb)(
    OTemps[o, e]
  )
  | m in 1..MTNb, e in 1..EtageMax
]);

array[1..TTNb] of 0..: TTMTempsMin;
TTMTempsMin = [
  min(m in 1..MTNb where MTPeriode[t, m] != infinity)(
    MTempsMin[m, TEtage[t]]
  )
  | t in 1..TTNb
];

array[1..TIntervallesNbTotal] of bool: TIntervallesPossible;
TIntervallesPossible = [
  (TIntervallesPFin[i] - (if TIntervallesGFin[i] > 0 then GTemps[TIntervallesGFin[i]] else 0 endif)) - 
  (TIntervallesPDebut[i] + (if TIntervallesGDebut[i] > 0 then GTemps[TIntervallesGDebut[i]] else 0 endif)) - 
  TTMTempsMin[TTRef[TIntervallesTRef[i]]] > 0
  | i in 1..TIntervallesNbTotal
];

0..TIntervallesNbTotal: TIntervallesPossibleNb;
TIntervallesPossibleNb = sum(i in 1..TIntervallesNbTotal)(
  if TIntervallesPossible[i] then 1 else 0 endif
);

array[1..TIntervallesPossibleNb] of 1..TNb: TIntervallesTRefPossible;
TIntervallesTRefPossible = [
  TIntervallesTRef[i]
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];

array[1..TIntervallesPossibleNb] of int: TIntervallesPDebutPossible;
TIntervallesPDebutPossible = [
  TIntervallesPDebut[i] + (if TIntervallesGDebut[i] > 0 then GTemps[TIntervallesGDebut[i]] else 0 endif)
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];

array[1..TIntervallesPossibleNb] of int: TIntervallesPFinPossible;
TIntervallesPFinPossible = [
  TIntervallesPFin[i] - (if TIntervallesGFin[i] > 0 then GTemps[TIntervallesGFin[i]] else 0 endif)
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];

array[1..TIntervallesPossibleNb] of 0..GNb: TIntervallesGDebutPossible;
TIntervallesGDebutPossible = [
  TIntervallesGDebut[i]
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];

array[1..TIntervallesPossibleNb] of 0..GNb: TIntervallesGFinPossible;
TIntervallesGFinPossible = [
  TIntervallesGFin[i]
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];


array[1..TTNb] of 1..: MTNbT;
MTNbT = [
  sum(m in 1..MTNb)(
    if MTPeriode[t, m] == infinity then 0 else 1 endif
  )
  | t in 1..TTNb
];

array[1..TNb] of 1..: MNbT;
MNbT = [
  MTNbT[TTRef[t]]
  | t in 1..TNb
];

1..: MNb;
MNb = sum(MNbT);

array[1..MNb] of 1..TNb: MRefT;
MRefT = [
  t
  | t in 1..TNb, _ in 1..MNbT[t]
];

array[1..MNb] of 1..MTNb: MRefM;
MRefM = [
  m
  | t in 1..TNb, m in 1..MTNb
    where MTPeriode[TTRef[t], m] != infinity,
    _ in 1..1
];

% Instances
0..: TIntervallesNbMax;
TIntervallesNbMax = max(TIntervallesNb);

int: MInstanceNb;
MInstanceNb = MNb * TIntervallesNbMax;

array[1..MInstanceNb] of 1..MNb: MInstanceRefMNb;
MInstanceRefMNb = [
  ceil(i / TIntervallesNbMax) 
  | i in 1..MInstanceNb
];

array[1..MInstanceNb] of 1..TIntervallesNbMax: MInstanceRepetition;
MInstanceRepetition = [
  (i - 1) mod TIntervallesNbMax + 1 
  | i in 1..MInstanceNb
];

array[1..MInstanceNb] of 1..TNb: MInstanceRefT;
MInstanceRefT = [
  MRefT[MInstanceRefMNb[i]] 
  | i in 1..MInstanceNb
];

array[1..MInstanceNb] of 1..MTNb: MInstanceRefType;
MInstanceRefType = [
  MRefM[MInstanceRefMNb[i]] 
  | i in 1..MInstanceNb
];

int: MaxDureePossible = max(
  [P] ++ 
  [OTemps[o, e] | o in 1..OTNb, e in 1..EtageMax] ++
  STTempsMax
);

int: MaxPeriodicitePossible = max(
  [0] ++ 
  [MTPeriode[t, m] | t in 1..TTNb, m in 1..MTNb where MTPeriode[t, m] != infinity]
);

int: MaxHorizonFutur = P + MaxPeriodicitePossible + MaxDureePossible;

int: MinHorizonPasse = min(
  [0] ++ 
  [MDerniereFois[t, m] | t in 1..TNb, m in 1..MTNb]
);