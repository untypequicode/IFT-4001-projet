% ======================================================
% Paramètres Temporels
% ======================================================

int: J;                                                 % Nombre de jours.
int: PJ;                                                % Périodes par jour.

% ======================================================
% Paramètres Gares et Voies
% ======================================================

int: GNb;                                               % Nombre de gares.
array[1..GNb] of int: GTemps;                           % Temps par gare.

int: VTNb;                                              % Nombre de types de voies.
array[1..VTNb] of int: VNbT;                            % Nombre de voies par type.
array[int] of int: VEtage;                              % Étage (caténaire) par voie.

% ======================================================
% Paramètres Équipements
% ======================================================

int: ENb;                                               % Nombre d'équipements.
array[1..ENb] of int: ECapacite;                        % Capacité par équipement.
array[1..ENb] of int: EQuantite;                        % Quantité disponible.
array[int, 1..ENb] of bool: VEDisponible;               % Disponibilité par voie.

% ======================================================
% Paramètres Techniciens
% ======================================================

int: STNb;                                              % Nombre de types de techniciens.
array[1..STNb] of int: SNbT;                            % Nombre de techniciens par type.
array[1..STNb] of int: STTempsMin;                      % Temps minimum de travail.
array[1..STNb] of int: STTempsMax;                      % Temps maximum de travail.

% ======================================================
% Paramètres Trains
% ======================================================

int: TTNb;                                              % Nombre de types de trains.
array[1..TTNb] of int: TNbT;                            % Nombre de trains par type.
array[1..TTNb] of int: TEtage;                          % Étage (caténaire) par train.

% ======================================================
% Configuration des Intervalles
% ======================================================

array[1..sum(TNbT)] of int: InputNbIntervallesParTrain; % Nombre d'intervalles par train.

array[int] of int: InputIntervallesDebut;               % Début d'intervalle.
array[int] of int: InputIntervallesFin;                 % Fin d'intervalle.
array[int] of int: InputIntervallesGareDebut;           % Gare de début.
array[int] of int: InputIntervallesGareFin;             % Gare de fin.

% ======================================================
% Paramètres Maintenances
% ======================================================

int: MTNb;                                              % Nombre de types de maintenances.
array[1..TTNb, 1..MTNb] of int: MTPeriode;              % Périodicité par type de train et maintenance.
array[1..sum(TNbT), 1..MTNb] of int: MDerniereFois;     % Dernière exécution.

int: OTNb;                                              % Nombre de types d'opérations.
array[1..MTNb, 1..OTNb] of bool: MOperation;            % Opérations requises.
array[1..OTNb, 1..EtageMax] of int: OTemps;             % Durée par opération et étage.
array[1..OTNb] of int: OShift;                          % Type de shift requis.
array[1..OTNb, 1..VTNb] of bool: OVoie;                 % Compatibilité voie.
array[1..OTNb, 1..OTNb] of bool: ODependance;           % Dépendances entre opérations.
array[1..OTNb, 1..ENb] of bool: OEquipement;            % Équipements requis.

int: PSetup;                                            % Durée de changement de voie.
int: PVoie;                                             % Durée de passage voie.
int: EtageMax;                                          % Nombre d'étages maximum.
