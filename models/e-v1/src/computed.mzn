include "core/utils.mzn";
include "generic.mzn";
include "constant.mzn";

% Calcule automatiquement les constantes dérivées des paramètres utilisateur

% Périodes et horizon
int: PNb = H div P;                         % Nombre de périodes
int: PJour = H div JOUR;                    % Nombre de jours
int: GP = GPeriode div P;                   % Périodes par cycle de trajet

% Trains
int: NbTrains = card(TId);                  % Nombre total de trains
array[TType] of int: TOffsets = calculer_decalages(TNb);  % Offsets par type

function array[int] of TId: ModTrains(TType: t) =  % Trains d'un type donné
    extraire_sous_tableau(T, TOffsets, TNb, t);

% Voies
int: NbVoies = card(VId);                   % Nombre total de voies
array[VType] of int: VOffsets = calculer_decalages(VNb);  % Offsets par type

function array[int] of VId: ModVoies(VType: v) =  % Voies d'un type donné
    extraire_sous_tableau(V, VOffsets, VNb, v);

% Techniciens (shifts)
int: SDTemps = JOUR div SDivision;          % Temps par division
array[1..SDivision] of int: SDNb = [sum(t in SType)(SCapacite[d, t]) | d in 1..SDivision];  % Techniciens par division
int: SNb = sum(SDNb);                       % Nombre total de techniciens
array[1..SDivision, SType] of 1..SNb: SOffsets = calculer_decalages_2d(SCapacite);  % Offsets par division et type

% Trajets & Gares (présence et intervalles)
array[1..NbTrains, 1..GP] of bool: GPresent = array2d(1..NbTrains, 1..GP, [  % Matrice de présence en gare
    if GTrajetSens[n, p] != gare then false else
      verifier_sequence_gauche(GTrajetSens, n, p, gare, retour, true, true) /\
      verifier_sequence_droite(GTrajetSens, n, p, gare, aller,  true, true)
    endif
    | n in 1..NbTrains, p in 1..GP
]);

array[1..NbTrains] of int: GNbIntervalles = [  % Nombre d'intervalles par train
    sum(p in 1..GP)(GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1]))
    | n in 1..NbTrains
];

array[1..NbTrains] of int: GOffsetsIntervalles = calculer_decalages(GNbIntervalles);  % Offsets des intervalles
int: GTotalIntervalles = sum(GNbIntervalles);  % Total d'intervalles

array[1..GTotalIntervalles] of 1..GP: GIntervallesDebut = [  % Début de chaque intervalle
    p
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

array[1..GTotalIntervalles] of 1..GP: GIntervallesFin = [  % Fin de chaque intervalle
    min(k in p..GP where (k == GP \/ not GPresent[n, k+1]))(k)
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

array[1..GTotalIntervalles] of GType: GIntervallesTypeDebut = [  % Type de gare au début
    GTrajetGare[n, p]
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

array[1..GTotalIntervalles] of GType: GIntervallesTypeFin = [  % Type de gare à la fin
    let {
        int: fin = min(k in p..GP where (k == GP \/ not GPresent[n, k+1]))(k)
    } in GTrajetGare[n, fin]
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

% Maintenances (urgences)
array[TId, MType] of int: MUrgence = array2d(TId, MType, [  % Date butoir par maintenance
    let {
        TType: type_train = min(tt in TType where exists(tr in ModTrains(tt))(tr == t))(tt);
        int: date_butoir = MDerniereFois[t, m] + MPeriode[type_train, m];
    } in
    if MPeriode[type_train, m] == 0 then H
    else date_butoir
    endif
    | t in TId, m in MType
]);
