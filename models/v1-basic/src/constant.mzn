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

array[TType] of int: TOffsets = calc_offsets(TNb);
function array[int] of TId: ModTrains(TType: t) =
    get_subarray(T, TOffsets, TNb, t);

array[TType] of Plexite: TDuplex;                                                          % Plexité d'un train

% ==========================================================================================
% Voies
% ==========================================================================================

array[VType] of int: VNb;                                                                  % Nombre de voie par type
array[1..sum(VNb)] of VId: V;                                                              % Liste des voies

array[VType] of int: VOffsets = calc_offsets(VNb);
function array[int] of VId: ModVoies(VType: v) =
    get_subarray(V, VOffsets, VNb, v);

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
array[1..SDivision, SType] of 1..SNb: SOffsets = calc_offsets_2d(SCapacite);

% ==========================================================================================
% Trajets & Gares
% ==========================================================================================
array[GType] of int: GTemps;                                                               % Temps de la distance entre la gare et le centre de maintenance (minutes)
1..H: GPeriode;                                                                            % Periodicité des trajets
int: GP = GPeriode div P;

array[1..sum(TNb), 1..GP] of GType: GTrajetGare;                                           % Gare du trajet
array[1..sum(TNb), 1..GP] of GSens: GTrajetSens;                                           % Sens du trajet

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
array[TType, MType] of ..0: MDerniereFois;                                                 % Derniere execution d'une maintenance par type de train
array[TId, MType] of 0..H: MUrgence;                                                       % Urgence d'une maintenance par train
