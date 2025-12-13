include "generic.mzn";

% Paramètres à définir par l'utilisateur dans le fichier .dzn

% Périodes et unités
1..: J;                                        % Nombre de jours
1..1440: PJ;                                   % Période par jour
1..: PSetup;                                   % Temps de setup entre opérations (periodes)
1..: PVoie;                                    % Temps entre deux trains sur une même voie (periodes)
1..: EtageMax;                                 % Nombre maximum d'etage pour un train

% Voies
1..: VTNb;                                     % Nombre de type de voies
array[1..VTNb] of 1..: VNbT;                   % Nombre de voies par type
array[1..VNb] of 1..EtageMax: VEtage;          % Nombre d'étage autorisé par type de voie

% Equipements
1..: ENb;                                      % Nombre d'équipements
array[1..ENb] of 1..: ECapacite;               % Capacité d'un équipement
array[1..ENb] of 1..: EQuantite;               % Quantité d'un équipement
array[1..VNb, 1..ENb] of bool: VEDisponible;   % Equipement disponible par voie

% Techniciens (shifts)
1..: STNb;                                     % Nombre de type de techniciens
array[1..STNb] of 1..: SNbT;                   % Nombre de techniciens par type par division
array[1..STNb] of 0..PJ: STTempsMin;           % Temps minimal de travail par type de technicien (periodes)
array[1..STNb] of 0..PJ: STTempsMax;           % Temps maximal de travail par type de technicien (periodes)

% Trains & Trajets & Gares
1..: TTNb;                                     % Nombre de type de trains
array[1..TTNb] of 1..: TNbT;                   % Nombre de trains par type
array[1..TTNb] of 1..EtageMax: TEtage;         % Nombre d'étage par type de train

1..: GNb;                                      % Nombre de gares
array[1..GNb] of 1..P: GTemps;                 % Temps de la gare vers le centre de maintenance (periodes)

array[1..TNb, 1..P] of 0..GNb: TTrajetGare;    % Gare actuelle pour un train à une periode précise (0 => est à une gare mais peut se déplacer dans une autre gare ou le centre de maintenance, mais il peut aussi être dans une gare loin du centre de maintenance)
array[1..TNb, 1..P] of GSens: TTrajetSens;     % Sens du train par rapport au centre de maintenance par periode

% Maintenances & Opérations
1..: MTNb;                                     % Nombre de type de maintenances
1..: OTNb;                                     % Nombre de type d'opérations

array[1..OTNb, 1..ENb] of bool: OEquipement;   % Équipement nécessaire par opération
array[1..OTNb, 1..EtageMax] of 1..P: OTemps;   % Temps par opération et nombre d'étage
array[1..OTNb, 1..OTNb] of bool: ODependance;  % Dépendances entre opérations
array[1..OTNb] of 1..STNb: OShift;             % Shifts nécessaires par opération
array[1..OTNb, 1..VTNb] of bool: OVoie;        % Voie nécessaire par opération

array[1..MTNb, 1..OTNb] of bool: MOperation;   % Opérations nécessaires par maintenance
array[1..TTNb, 1..MTNb] of 0..: MTPeriode;     % Périodicité d'une maintenance par type de train (periodes) (0 => à chaque visite au centre de maintenance) (infinity => pas necessaire pour un type de train)
array[1..TNb, 1..MTNb] of ..0: MDerniereFois;  % Denière exécution d'une maintenance par train

include "computed.mzn";
