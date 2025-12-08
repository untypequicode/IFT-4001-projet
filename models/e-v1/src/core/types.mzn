% Définit les types énumérés utilisés dans le modèle

enum TType;                     % Types de train (TER, TGV, etc.)
enum TId;                       % Identifiants des trains

enum VType;                     % Types de voie (extérieure, atelier, etc.)
enum VId;                       % Identifiants des voies

enum EType;                     % Types d'équipement (moteur, pantographe, etc.)
enum MType;                     % Types de maintenance (M1, M2, etc.)
enum OType;                     % Types d'opération (opérations atomiques d'une maintenance)

enum SType;                     % Types de technicien (électricien, mécano, etc.)

enum GType;                     % Types de gare
enum GSens = {aller, retour, gare};  % Sens du trajet

enum Plexite;                   % Plexité (nombre d'étages)
