include "core/types.mzn";
include "core/utils.mzn";
include "generic.mzn";

% ==========================================================================================
% Horizon et unités
% ==========================================================================================
int: H;                                                                                    % Horizon de planification (minutes)
int: P;                                                                                    % Période de temps (minutes)
int: PNb = H div P;                                                                        % Nombre de périodes
int: PJour = H div JOUR;                                                                   % Nombre de jour dans l'horizon
int: Setup;                                                                                % Temps de setup entre opérations (minutes)
int: Deplacement;                                                                          % Temps de déplacement entre voies (minutes)
int: Nettoyage;                                                                            % Temps de nettoyage obligatoire avant départ (minutes)
int: Preparation;                                                                          % Temps minimal de préparation avant service (minutes)
int: Transfert;                                                                            % Temps de transfert train de remplacement (minutes)

% ==========================================================================================
% Trains
% ==========================================================================================

array[TType] of int: TNb;                                                                  % Nombre de trains par type
array[1..sum(TNb)] of TId: T;                                                              % Liste des trains

array[TType] of int: TOffsets = calculer_decalages(TNb);
function array[int] of TId: ModTrains(TType: t) =
    extraire_sous_tableau(T, TOffsets, TNb, t);

array[TType] of Plexite: TDuplex;                                                          % Plexité d'un train

% ==========================================================================================
% Voies
% ==========================================================================================

array[VType] of int: VNb;                                                                  % Nombre de voie par type
array[1..sum(VNb)] of VId: V;                                                              % Liste des voies

array[VType] of int: VOffsets = calculer_decalages(VNb);
function array[int] of VId: ModVoies(VType: v) =
    extraire_sous_tableau(V, VOffsets, VNb, v);

array[VType] of Plexite: VDuplex;                                                          % Plexité d'une voie

% ---------------------------------------------------------------------------------------- % Implémentation d'un double train

% ==========================================================================================
% Equipements
% ==========================================================================================
array[EType] of int: ECapacite;                                                            % Capacité d'un équipement
array[EType] of int: EQuantite;                                                            % Quantité d'un équipement

% ==========================================================================================
% Shifts
% ==========================================================================================
int: SDivision;                                                                            % Nombre de division des équipes de techniciens au sein d'une même journée
int: SDTemps = ((JOUR) div SDivision);                                                     % Temps de la division des équipes de techniciens
int: SDCalibration;                                                                        % Début de la premiere division pour calibrer le temps
array[1..SDivision, SType] of int: SCapacite;                                              % Capacité du personnel de technicien pour une division
array[1..SDivision] of int: SDNb = [sum(t in SType)(SCapacite[d, t]) | d in 1..SDivision]; % Nombre de techniciens par division
int: SNb = sum(SDNb);                                                                      % Nombre de techniciens par division
array[1..SDivision, SType] of 1..SDTemps: STempsMin;                                       % Nombre d'heure minimale pour une équipe de techniciens sur une division
array[1..SDivision, SType] of 1..SDTemps: STempsMax;                                       % Nombre d'heure maximale pour une équipe de techniciens sur une division
array[1..SDivision, SType] of 1..SNb: SOffsets = calculer_decalages_2d(SCapacite);

% ==========================================================================================
% Trajets & Gares
% ==========================================================================================
array[GType] of int: GTemps;                                                               % Temps de la distance entre la gare et le centre de maintenance (minutes)
1..H: GPeriode;                                                                            % Periodicité des trajets
int: GP = GPeriode div P;

array[1..sum(TNb), 1..GP] of GType: GTrajetGare;                                           % Gare du trajet
array[1..sum(TNb), 1..GP] of GSens: GTrajetSens;                                           % Sens du trajet
array[1..sum(TNb), 1..GP] of bool: GPresent = array2d(1..sum(TNb), 1..GP, [                % Matrice de présence d'un train en gare de proximité (Vérifie la séquence Gauche/Droite + Présence actuelle)
    if GTrajetSens[n, p] != gare then false else
      verifier_sequence_gauche(GTrajetSens, n, p, gare, retour, true, true) /\
      verifier_sequence_droite(GTrajetSens, n, p, gare, aller,  true, true)
    endif
    | n in 1..sum(TNb), p in 1..GP 
]);
array[1..sum(TNb)] of int: GNbIntervalles = [                                              % Nombre d'intervalles (Comptage basé sur les DÉBUTS de créneaux)
    sum(p in 1..GP)(GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1]))
    | n in 1..sum(TNb)
];

array[1..sum(TNb)] of int: GOffsetsIntervalles = calculer_decalages(GNbIntervalles);       % Offsets pour accéder aux intervalles (Via utils.mzn)
int: GTotalIntervalles = sum(GNbIntervalles);                                              % Nombre total d'intervalles pour dimensionner les tableaux

array[1..GTotalIntervalles] of 1..GP: GIntervallesDebut = [                                % Heure de début en gare
    p
    | n in 1..sum(TNb), p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];
array[1..GTotalIntervalles] of 1..GP: GIntervallesFin = [                                  % Heure de fin en gare
    min(k in p..GP where (k == GP \/ not GPresent[n, k+1]))(k)
    | n in 1..sum(TNb), p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];
array[1..GTotalIntervalles] of GType: GIntervallesTypeDebut = [                            % Type de gare au début
    GTrajetGare[n, p]
    | n in 1..sum(TNb), p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];
array[1..GTotalIntervalles] of GType: GIntervallesTypeFin = [                              % Type de gare à la fin
    let { 
        int: fin = min(k in p..GP where (k == GP \/ not GPresent[n, k+1]))(k) 
    } in GTrajetGare[n, fin]
    | n in 1..sum(TNb), p in 1..GP
    where GPresent[n, p] /\ (p == 1 \/ not GPresent[n, p-1])
];


% ==========================================================================================
% Maintenances & Opérations
% ==========================================================================================

array[OType, EType] of bool: OEquipement;                                                  % Equipement nécessaire par opération
array[OType, Plexite] of int: OTemps;                                                      % Temps nécessaire par opération en fonction de la plexité du train
array[OType, OType] of bool: ODependance;                                                  % Opérations nécessaire par opération
array[OType] of int: OShift;                                                               % Shifts nécessaire par opération
array[OType] of VType: OVType;                                                             % Type de voie nécessaire par opération

array[MType, OType] of bool: MOperation;                                                   % Operations nécessaire par maintenance
array[TType, MType] of int: MPeriode;                                                      % Periodicite d'une maintenance par type de train
array[TId, MType] of ..0: MDerniereFois;                                                   % Derniere execution d'une maintenance par type de train
array[TId, MType] of int: MUrgence = array2d(TId, MType, [                                 % Urgence d'une maintenance par train
    let {
        TType: type_train = min(tt in TType where exists(tr in ModTrains(tt))(tr == t))(tt);
        int: date_butoir = MDerniereFois[t, m] + MPeriode[type_train, m];
    } in
    if MPeriode[type_train, m] == 0 then H 
    else date_butoir 
    endif
    | t in TId, m in MType
]);
