include "core/types.mzn";

% Paramètres à définir par l'utilisateur dans le fichier .dzn

% Horizon et unités
int: H;                 % Horizon de planification (minutes)
int: P;                 % Période de temps (minutes)
int: Setup;             % Temps de setup entre opérations (minutes)
int: Deplacement;       % Temps de déplacement entre voies (minutes)
int: Nettoyage;         % Temps de nettoyage avant départ (minutes)
int: Preparation;       % Temps de préparation avant service (minutes)
int: Transfert;         % Temps de transfert train de remplacement (minutes)

% Trains
array[TType] of int: TNb;           % Nombre de trains par type
array[1..sum(TNb)] of TId: T;       % Liste des trains
array[TType] of Plexite: TDuplex;   % Plexité par type de train

% Voies
array[VType] of int: VNb;           % Nombre de voies par type
array[1..sum(VNb)] of VId: V;       % Liste des voies
array[VType] of Plexite: VDuplex;   % Plexité par type de voie

% Equipements
array[EType] of int: ECapacite;     % Capacité d'un équipement
array[EType] of int: EQuantite;     % Quantité d'un équipement

% Techniciens (shifts)
int: SDivision;                                     % Nombre de divisions par jour
int: SDCalibration;                                 % Début de la première division
array[1..SDivision, SType] of int: SCapacite;       % Capacité par division et type
array[1..SDivision, SType] of 1..SDTemps: STempsMin;  % Temps minimal de travail
array[1..SDivision, SType] of 1..SDTemps: STempsMax;  % Temps maximal de travail

% Trajets & Gares
array[GType] of int: GTemps;        % Temps depuis gare vers centre (minutes)
1..H: GPeriode;                     % Périodicité des trajets (minutes)

array[1..sum(TNb), 1..GP] of GType: GTrajetGare;  % Gare par train et période
array[1..sum(TNb), 1..GP] of GSens: GTrajetSens;  % Sens par train et période

% Maintenances & Opérations
array[OType, EType] of bool: OEquipement;      % Équipement nécessaire par opération
array[OType, Plexite] of int: OTemps;          % Temps par opération et plexité
array[OType, OType] of bool: ODependance;      % Dépendances entre opérations
array[OType] of int: OShift;                   % Shifts nécessaires par opération
array[OType] of VType: OVType;                 % Type de voie par opération

array[MType, OType] of bool: MOperation;       % Opérations par maintenance
array[TType, MType] of int: MPeriode;          % Périodicité par type de train (minutes)
array[TId, MType] of ..0: MDerniereFois;       % Dernière exécution (timestamp négatif ou 0)

% Inclut les constantes calculées automatiquement
include "computed.mzn";
