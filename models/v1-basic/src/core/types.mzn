% ==========================================================================================
% Trains
% ==========================================================================================
enum TType;                                                                                % Types de train (ex : TER, TGV, etc.)
enum TId;                                                                                  % Identifiants des trains (une valeur par train)

% ==========================================================================================
% Voies
% ==========================================================================================
enum VType;                                                                                % Type de voie (par ex. voie exterieur, voie-atelier, etc.)
enum VId;                                                                                  % Identifiants des voies

% ==========================================================================================
% Equipements, maintenances, opérations
% ==========================================================================================
enum EType;                                                                                % Type d'équipement (ex : moteur, pantographe, ...)
enum MType;                                                                                % Type de maintenance (M1, M2, ...)
enum OType;                                                                                % Type d'opération (opérations atomiques d'une maintenance)

% ==========================================================================================
% Shifts / personnels
% ==========================================================================================
enum SType;                                                                                % Type de shift / catégorie de technicien (ex: électricien, mécano, ...)

% ==========================================================================================
% Trajets & gares
% ==========================================================================================
enum GType;                                                                                % Nom/type de gare (pour les trajets trains <-> centre)
enum GSens = {aller, retour, gare};                                                        % Sens du trajet

% ==========================================================================================
% Plexité / Duplexité
% ==========================================================================================
enum Plexite;                                                                              % Plexité (nombre d'étages)