include "generic.mzn";
include "constant.mzn";

% ====================================================================
% Calculs Préliminaires
% ====================================================================
1..: P = J * PJ;

% ====================================================================
% Mapping des Entités
% ====================================================================
1..: VNb = sum(VNbT);
array[1..VNb] of 1..VTNb: VRef = [v | v in 1..VTNb, _ in 1..VNbT[v]];

1..: SNb = sum(SNbT);
array[1..SNb] of 1..STNb: STRef = [s | s in 1..STNb, _ in 1..SNbT[s]];

1..: TNb = sum(TNbT);
array[1..TNb] of 1..TTNb: TTRef = [t | t in 1..TTNb, _ in 1..TNbT[t]];

% ====================================================================
% Reconstruction des Intervalles
% ====================================================================
int: NbIntervalsInput = sum(InputNbIntervallesParTrain);

array[1..NbIntervalsInput] of 1..TNb: InputIntervallesTrain = [
  t | t in 1..TNb, k in 1..InputNbIntervallesParTrain[t]
];

0..: TIntervallesNbTotal = NbIntervalsInput;
array[1..TIntervallesNbTotal] of 1..TNb: TIntervallesTRef = InputIntervallesTrain;

array[1..TIntervallesNbTotal] of 1..P: TIntervallesPDebut = array1d(1..TIntervallesNbTotal, InputIntervallesDebut);
array[1..TIntervallesNbTotal] of 1..P: TIntervallesPFin = array1d(1..TIntervallesNbTotal, InputIntervallesFin);
array[1..TIntervallesNbTotal] of 0..GNb: TIntervallesGDebut = array1d(1..TIntervallesNbTotal, InputIntervallesGareDebut);
array[1..TIntervallesNbTotal] of 0..GNb: TIntervallesGFin = array1d(1..TIntervallesNbTotal, InputIntervallesGareFin);

array[1..TNb] of 0..: TIntervallesNb = InputNbIntervallesParTrain;
array[1..TNb] of 1..max(1, TIntervallesNbTotal+1): TIntervallesDecalageT = [
    min([TIntervallesNbTotal+1] ++ [k | k in 1..TIntervallesNbTotal where TIntervallesTRef[k] == n])
    | n in 1..TNb
];

% ====================================================================
% Suite Standard (Maintenances et Opérations)
% ====================================================================

array[1..MTNb] of 0..: MONb = [
  sum(o in 1..OTNb)(if MOperation[m, o] then 1 else 0 endif) | m in 1..MTNb
];

array[1..MTNb, 1..EtageMax] of 0..: MTempsMin = array2d(1..MTNb, 1..EtageMax, [
  PSetup * max(0, MONb[m] - 1) + sum(o in 1..OTNb)(OTemps[o, e])
  | m in 1..MTNb, e in 1..EtageMax
]);

% Ici on filtre 'infinity' nativement pour ne prendre que les durées réelles
array[1..TTNb] of 0..: TTMTempsMin = [
  min(m in 1..MTNb where MTPeriode[t, m] != infinity)(MTempsMin[m, TEtage[t]])
  | t in 1..TTNb
];

% ====================================================================
% Faisabilité d'Intervalles
% ====================================================================

array[1..TIntervallesNbTotal] of bool: TIntervallesPossible = [
  (TIntervallesPFin[i] - (if TIntervallesGFin[i] > 0 then GTemps[TIntervallesGFin[i]] else 0 endif)) -
  (TIntervallesPDebut[i] + (if TIntervallesGDebut[i] > 0 then GTemps[TIntervallesGDebut[i]] else 0 endif)) -
  TTMTempsMin[TTRef[TIntervallesTRef[i]]] > 0
  | i in 1..TIntervallesNbTotal
];

0..TIntervallesNbTotal: TIntervallesPossibleNb = sum(i in 1..TIntervallesNbTotal)(if TIntervallesPossible[i] then 1 else 0 endif);

array[1..TIntervallesPossibleNb] of 1..TNb: TIntervallesTRefPossible = [
  TIntervallesTRef[i] | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];
array[1..TIntervallesPossibleNb] of int: TIntervallesPDebutPossible = [
  TIntervallesPDebut[i] + (if TIntervallesGDebut[i] > 0 then GTemps[TIntervallesGDebut[i]] else 0 endif)
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];
array[1..TIntervallesPossibleNb] of int: TIntervallesPFinPossible = [
  TIntervallesPFin[i] - (if TIntervallesGFin[i] > 0 then GTemps[TIntervallesGFin[i]] else 0 endif)
  | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];
array[1..TIntervallesPossibleNb] of 0..GNb: TIntervallesGDebutPossible = [
  TIntervallesGDebut[i] | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];
array[1..TIntervallesPossibleNb] of 0..GNb: TIntervallesGFinPossible = [
  TIntervallesGFin[i] | i in 1..TIntervallesNbTotal where TIntervallesPossible[i]
];

% ====================================================================
% Instances de Maintenances
% ====================================================================

% On vérifie par rapport à 'infinity'
array[1..TTNb] of 1..: MTNbT = [
  sum(m in 1..MTNb)(if MTPeriode[t, m] == infinity then 0 else 1 endif) | t in 1..TTNb
];

array[1..TNb] of 1..: MNbT = [ MTNbT[TTRef[t]] | t in 1..TNb ];
1..: MNb = sum(MNbT);

array[1..MNb] of 1..TNb: MRefT = [ t | t in 1..TNb, _ in 1..MNbT[t] ];
array[1..MNb] of 1..MTNb: MRefM = [
  m | t in 1..TNb, m in 1..MTNb where MTPeriode[TTRef[t], m] != infinity, _ in 1..1
];

0..: TIntervallesNbMax = max(TIntervallesNb);
int: MInstanceNb = MNb * TIntervallesNbMax;

array[1..MInstanceNb] of 1..MNb: MInstanceRefMNb = [ ceil(i / TIntervallesNbMax) | i in 1..MInstanceNb ];
array[1..MInstanceNb] of 1..TIntervallesNbMax: MInstanceRepetition = [ (i - 1) mod TIntervallesNbMax + 1 | i in 1..MInstanceNb ];
array[1..MInstanceNb] of 1..TNb: MInstanceRefT = [ MRefT[MInstanceRefMNb[i]] | i in 1..MInstanceNb ];
array[1..MInstanceNb] of 1..MTNb: MInstanceRefType = [ MRefM[MInstanceRefMNb[i]] | i in 1..MInstanceNb ];

% ====================================================================
% Horizons
% ====================================================================
int: MaxDureePossible = max([P] ++ [OTemps[o, e] | o in 1..OTNb, e in 1..EtageMax] ++ STTempsMax);
int: MaxPeriodicitePossible = max([0] ++ [MTPeriode[t, m] | t in 1..TTNb, m in 1..MTNb where MTPeriode[t, m] != infinity]);
int: MaxHorizonFutur = P + MaxPeriodicitePossible + MaxDureePossible;
int: MinHorizonPasse = min([0] ++ [MDerniereFois[t, m] | t in 1..TNb, m in 1..MTNb]);
