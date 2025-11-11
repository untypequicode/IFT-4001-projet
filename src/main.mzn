include "generic.mzn";

% =====================================================================
% Horizon et unités
% =====================================================================
int: H;                                                               % Horizon de planification (minutes)
int: P;                                                               % Période de temps (minutes)
int: PNb = H div P;                                                   % Nombre de périodes
int: Setup;                                                           % Temps de setup entre opérations (minutes)
int: Deplacement;                                                     % Temps de déplacement entre voies (minutes)
int: Nettoyage;                                                       % Temps de nettoyage obligatoire avant départ (minutes)
int: Preparation;                                                     % Temps minimal de préparation avant service (minutes)
int: Transfert;                                                       % Temps de transfert train de remplacement (minutes)
enum Plexite;                                                         % PLexite (nombre d'etages)

% =====================================================================
% Trains
% =====================================================================
enum TType;                                                           % Types de train
enum TId;                                                             % Identifiants des trains

array[TType] of int: TNb;                                             % Nombre de trains par type
array[1..sum(TNb)] of TId: T;                                         % Liste des trains

array[TType] of int: TOffsets = calc_offsets(TNb);
function array[int] of TId: ModTrains(TType: t) =
    get_subarray(T, TOffsets, TNb, t);

array[TType] of Plexite: TDuplex;                                     % Plexité d'un train

% =====================================================================
% Voies
% =====================================================================
enum VType;                                                           % Type de voie
enum VId;                                                             % Identifiants des voies

array[VType] of int: VNb;                                             % Nombre de voie par type
array[1..sum(VNb)] of VId: V;                                         % Liste des voies

array[VType] of int: VOffsets = calc_offsets(VNb);
function array[int] of VId: ModVoies(VType: v) =
    get_subarray(V, VOffsets, VNb, v);

array[VType] of Plexite: VDuplex;                                     % Plexité d'une voie

% ------------------------------------------------------------------- % Implémentation d'un double train

% =====================================================================
% Equipements
% =====================================================================
enum EType;                                                           % Type d'équipement
array[EType] of int: ECapacite;                                       % Capacité d'un équipement
array[EType] of int: EQuantite;                                       % Quantité d'un équipement

% =====================================================================
% Shifts
% =====================================================================

enum SType;                                                           % Type de shift/technicien
int: SDivision;                                                       % Nombre de division des équipes de techniciens au sein d'une même journée
int: SDTemps = ((JOUR) div SDivision);                                % Temps de la division des équipes de techniciens
int: SDCalibration;                                                   % Début de la premiere division pour calibrer le temps
array[1..SDivision] of array[SType] of int: SCapacite;                % Capacité du personnel de technicien pour une division
array[1..SDivision] of array[SType] of 1..SDTemps: STempsMin;         % Nombre d'heure minimale pour une équipe de techniciens sur une division
array[1..SDivision] of array[SType] of 1..SDTemps: STempsMax;         % Nombre d'heure maximale pour une équipe de techniciens sur une division

% =====================================================================
% Trajets & Gares
% =====================================================================
enum GType;                                                           % Type/Nom de gare
enum GSens = {aller, retour};                                         % Sens du trajet
array[GType] of int: GTemps;                                          % Temps de la distance entre la gare et le centre de maintenance (minutes)
1..H: GPeriode;                                                       % Periodicité des trajets

array[1..sum(TNb)] of array [1..GPeriode] of GType: GTrajetGare;      % Gare du trajet
array[1..sum(TNb)] of array [1..GPeriode] of GSens: GTrajetSens;      % Sens du trajet

% =====================================================================
% Maintenances & Opérations
% =====================================================================
enum MType;                                                           % Type de maintenance
enum OType;                                                           % Type d'opération

array[OType] of array[EType] of bool: OEquipement;                    % Equipement nécessaire par opération
array[OType] of array[Plexite] of int: OTemps;                        % Temps nécessaire par opération en fonction de la plexité du train
array[OType] of array[OType] of bool: ODependance;                    % Opérations nécessaire par opération
array[OType] of array[MType] of bool: OMaintenance;                   % Opérations nécessaire par opération
array[OType] of int: OShift;                                          % Shifts nécessaire par opération
array[OType] of VType: OVType;                                        % Type de voie nécessaire par opération



% ------------------------------------------------------------------- % Liste des maintenaces planifiées sur une voie (variable)
% ------------------------------------------------------------------- % Liste des opérations planifiées (variable)
% ------------------------------------------------------------------- % Liste des trajets planifiées (variable)
% ------------------------------------------------------------------- % Liste des techniciens planifiées (variable)
