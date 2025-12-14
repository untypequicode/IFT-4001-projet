% ====================================================================
% Paramètres Temporels
% ====================================================================

int: J;                                         % Nombre de jours.
int: PJ;                                        % Périodes par jour.

% ====================================================================
% Paramètres Gares et Voies
% ====================================================================

int: GNb;
array[1..GNb] of int: GTemps;

int: VTNb;
array[1..VTNb] of int: VNbT;
array[int] of int: VEtage;                      % Étage (caténaire) par voie.

% ====================================================================
% Paramètres Équipements
% ====================================================================

int: ENb;
array[1..ENb] of int: ECapacite;
array[1..ENb] of int: EQuantite;
array[int, 1..ENb] of bool: VEDisponible;

% ====================================================================
% Paramètres Techniciens
% ====================================================================

int: STNb;
array[1..STNb] of int: SNbT;
array[1..STNb] of int: STTempsMin;
array[1..STNb] of int: STTempsMax;

% ====================================================================
% Paramètres Trains
% ====================================================================

int: TTNb;
array[1..TTNb] of int: TNbT;
array[1..TTNb] of int: TEtage;

% ====================================================================
% Configuration des Intervalles
% ====================================================================

array[1..sum(TNbT)] of int: InputNbIntervallesParTrain;

array[int] of int: InputIntervallesDebut;
array[int] of int: InputIntervallesFin;
array[int] of int: InputIntervallesGareDebut;
array[int] of int: InputIntervallesGareFin;

% ====================================================================
% Paramètres Maintenances
% ====================================================================

int: MTNb;
% Ici on utilise 'int' simple pour autoriser 'infinity'
array[1..TTNb, 1..MTNb] of int: MTPeriode;
array[1..sum(TNbT), 1..MTNb] of int: MDerniereFois;

int: OTNb;
array[1..MTNb, 1..OTNb] of bool: MOperation;
array[1..OTNb, 1..EtageMax] of int: OTemps;
array[1..OTNb] of int: OShift;
array[1..OTNb, 1..VTNb] of bool: OVoie;
array[1..OTNb, 1..OTNb] of bool: ODependance;
array[1..OTNb, 1..ENb] of bool: OEquipement;

int: PSetup;
int: PVoie;
int: EtageMax;
% Plus besoin de définir 'Infini', on utilisera le mot-clé natif