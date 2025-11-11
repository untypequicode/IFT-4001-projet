% Core types and enums for the v1-basic MiniZinc model
% This file centralises enumerations and simple type declarations used by the model.
% Keep this file focused on types (enums, simple aliases). Implementation / helpers are in core/utils.mzn.

% ------------------------------------------------------------------------------------------
% Train & identifiers
% ------------------------------------------------------------------------------------------
enum TType;       % Types de train (ex : TER, TGV, etc.)
enum TId;         % Identifiants des trains (une valeur par train)

% ------------------------------------------------------------------------------------------
% Voies (tracks)
% ------------------------------------------------------------------------------------------
enum VType;       % Type de voie (par ex. garage, voie-atelier, etc.)
enum VId;         % Identifiants des voies

% ------------------------------------------------------------------------------------------
% Equipements, maintenances, opérations
% ------------------------------------------------------------------------------------------
enum EType;       % Type d'équipement (ex : moteur, pantographe, ...)
enum MType;       % Type de maintenance (M1, M2, ...)
enum OType;       % Type d'opération (opérations atomiques d'une maintenance)

% ------------------------------------------------------------------------------------------
% Shifts / personnels
% ------------------------------------------------------------------------------------------
enum SType;       % Type de shift / catégorie de technicien (ex: électricien, mécano, ...)
% SType est utilisé dans les matrices de capacités et offsets

% ------------------------------------------------------------------------------------------
% Trajets & gares
% ------------------------------------------------------------------------------------------
enum GType;       % Nom/type de gare (pour les trajets trains <-> centre)
enum GSens = {aller, retour, gare};  % Sens du trajet

% ------------------------------------------------------------------------------------------
% Plexité / Duplexité
% ------------------------------------------------------------------------------------------
enum Plexite;     % Plexité (nombre d'étages/segments d'un train) — utilisé pour adapter temps et ressources

% ------------------------------------------------------------------------------------------
% Règles de compatibilité (alias/comment) — ex. mappings
% ------------------------------------------------------------------------------------------
% Les associations plus complexes (par ex. OEquipement: array[OType, EType] of bool)
% sont définies dans constant.mzn/les fichiers de configuration du modèle.

% ------------------------------------------------------------------------------------------
% Fin
% ------------------------------------------------------------------------------------------
