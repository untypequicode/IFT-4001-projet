include "generic.mzn";

% ============================================
% Paramètres d'Entrée - À Définir dans Fichier .dzn
% ============================================

% --- Périodes et Unités ---
1..: J;                                       % Nombre de jours.
1..1440: PJ;                                  % Périodes par jour.
1..: PSetup;                                  % Temps setup entre opérations.
1..: PVoie;                                   % Temps entre trains sur voie.
1..: EtageMax;                                % Étage maximum train.

% --- Voies ---
1..: VTNb;                                    % Nombre de types de voies.
array[1..VTNb] of 1..: VNbT;                  % Nombre voies par type.
array[1..VNb] of 1..EtageMax: VEtage;         % Étage autorisé par voie.

% --- Équipements ---
1..: ENb;                                     % Nombre d'équipements.
array[1..ENb] of 1..: ECapacite;              % Capacité équipement.
array[1..ENb] of 1..: EQuantite;              % Quantité équipement.
array[1..VNb, 1..ENb] of bool: VEDisponible;  % Équipement dispo par voie.

% --- Techniciens et Shifts ---
1..: STNb;                                    % Nombre de types shifts.
array[1..STNb] of 1..: SNbT;                  % Techniciens par type.
array[1..STNb] of 0..PJ: STTempsMin;          % Temps min travail type.
array[1..STNb] of 0..PJ: STTempsMax;          % Temps max travail type.

% --- Trains et Trajets ---
1..: TTNb;                                    % Nombre de types trains.
array[1..TTNb] of 1..: TNbT;                  % Trains par type.
array[1..TTNb] of 1..EtageMax: TEtage;        % Étage par type train.

1..: GNb;                                     % Nombre de gares.
array[1..GNb] of 1..P: GTemps;                % Temps gare vers maintenance.

array[1..TNb, 1..P] of 0..GNb: TTrajetGare;   % Gare actuelle par période.
array[1..TNb, 1..P] of GSens: TTrajetSens;    % Sens trajet par période.

% --- Maintenances et Opérations ---
1..: MTNb;                                    % Nombre de types maintenances.
1..: OTNb;                                    % Nombre de types opérations.

array[1..OTNb, 1..ENb] of bool: OEquipement;  % Équipement opération.
array[1..OTNb, 1..EtageMax] of 1..P: OTemps;  % Temps opération/étage.
array[1..OTNb, 1..OTNb] of bool: ODependance; % Dépendances opérations.
array[1..OTNb] of 1..STNb: OShift;            % Shift requis opération.
array[1..OTNb, 1..VTNb] of bool: OVoie;       % Voie requise opération.

array[1..MTNb, 1..OTNb] of bool: MOperation;  % Opérations maintenance.
array[1..TTNb, 1..MTNb] of 0..: MTPeriode;    % Périodicité maintenance.
array[1..TNb, 1..MTNb] of ..0: MDerniereFois; % Dernière exécution maint.

include "computed.mzn";
