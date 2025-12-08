include "core/utils.mzn";
include "generic.mzn";
include "constant.mzn";

% ==========================================================================================
% CONSTANTES CALCULÉES AUTOMATIQUEMENT
% Ce fichier contient toutes les constantes qui sont dérivées des paramètres utilisateur
% définis dans constant.mzn
% NE PAS DÉFINIR CES VALEURS DANS LE FICHIER .dzn - ELLES SONT CALCULÉES AUTOMATIQUEMENT
% ==========================================================================================

% ------------------------------------------------------------------------------------------
% Périodes et horizon
% ------------------------------------------------------------------------------------------
int: PNb = H div P;                                                                        % Nombre de périodes
int: PJour = H div JOUR;                                                                   % Nombre de jours dans l'horizon
int: GP = GPeriode div P;                                                                  % Nombre de périodes dans un cycle de trajet

% ------------------------------------------------------------------------------------------
% Trains (offsets et fonctions d'accès)
% ------------------------------------------------------------------------------------------
int: NbTrains = card(TId);                                                                 % Nombre total de trains
array[TType] of int: TOffsets = calculer_decalages(TNb);                                   % Offsets pour accéder aux trains par type

function array[int] of TId: ModTrains(TType: t) =                                          % Extraction des trains d'un type donné
    extraire_sous_tableau(T, TOffsets, TNb, t);

% ------------------------------------------------------------------------------------------
% Voies (offsets et fonctions d'accès)
% ------------------------------------------------------------------------------------------
int: NbVoies = card(VId);                                                                  % Nombre total de voies
array[VType] of int: VOffsets = calculer_decalages(VNb);                                   % Offsets pour accéder aux voies par type

function array[int] of VId: ModVoies(VType: v) =                                           % Extraction des voies d'un type donné
    extraire_sous_tableau(V, VOffsets, VNb, v);

% ------------------------------------------------------------------------------------------
% Shifts (calculs basés sur les divisions)
% ------------------------------------------------------------------------------------------
int: SDTemps = JOUR div SDivision;                                                         % Temps de la division des équipes de techniciens
array[1..SDivision] of int: SDNb = [sum(t in SType)(SCapacite[d, t]) | d in 1..SDivision]; % Nombre de techniciens par division
int: SNb = sum(SDNb);                                                                      % Nombre total de techniciens
array[1..SDivision, SType] of 1..SNb: SOffsets = calculer_decalages_2d(SCapacite);         % Offsets pour accéder aux techniciens par division et type

% ------------------------------------------------------------------------------------------
% Trajets & Gares (calculs de présence et intervalles)
% ------------------------------------------------------------------------------------------
array[1..NbTrains, 1..GP] of bool: GPresent = array2d(1..NbTrains, 1..GP, [               % Matrice de présence d'un train en gare de proximité
    if GTrajetSens[n, p] != gare then false else
      verifier_sequence_gauche(GTrajetSens, n, p, gare, retour, true, true) /\
      verifier_sequence_droite(GTrajetSens, n, p, gare, aller,  true, true)
    endif
    | n in 1..NbTrains, p in 1..GP
]);

array[1..NbTrains] of int: GNbIntervalles = [                                              % Nombre d'intervalles (Comptage basé sur les DÉBUTS de créneaux)
    sum(p in 1..GP)(GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1]))
    | n in 1..NbTrains
];

array[1..NbTrains] of int: GOffsetsIntervalles = calculer_decalages(GNbIntervalles);       % Offsets pour accéder aux intervalles
int: GTotalIntervalles = sum(GNbIntervalles);                                              % Nombre total d'intervalles pour dimensionner les tableaux

array[1..GTotalIntervalles] of 1..GP: GIntervallesDebut = [                                % Heure de début en gare
    p
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

array[1..GTotalIntervalles] of 1..GP: GIntervallesFin = [                                  % Heure de fin en gare
    min(k in p..GP where (k == GP \/ not GPresent[n, k+1]))(k)
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

array[1..GTotalIntervalles] of GType: GIntervallesTypeDebut = [                            % Type de gare au début
    GTrajetGare[n, p]
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

array[1..GTotalIntervalles] of GType: GIntervallesTypeFin = [                              % Type de gare à la fin
    let {
        int: fin = min(k in p..GP where (k == GP \/ not GPresent[n, k+1]))(k)
    } in GTrajetGare[n, fin]
    | n in 1..NbTrains, p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];

% ------------------------------------------------------------------------------------------
% Maintenances (calcul des urgences)
% ------------------------------------------------------------------------------------------
array[TId, MType] of int: MUrgence = array2d(TId, MType, [                                 % Urgence d'une maintenance par train (date butoir)
    let {
        TType: type_train = min(tt in TType where exists(tr in ModTrains(tt))(tr == t))(tt);
        int: date_butoir = MDerniereFois[t, m] + MPeriode[type_train, m];
    } in
    if MPeriode[type_train, m] == 0 then H 
    else date_butoir 
    endif
    | t in TId, m in MType
]);