% ============================================================================
% Modèle MiniZinc pour la planification de maintenance ferroviaire (RCPSP)
% ============================================================================

% ----------------------------------------------------------------------------
% ENSEMBLES
% ----------------------------------------------------------------------------
set of int: TRAIN;
set of int: MAINT;                     % Maintenance
set of int: OP;                        % Opération
set of int: TRACK;                     % Voie
set of int: TECH;                      % Technicien
set of int: EQUIP;                     % Équipement

% ----------------------------------------------------------------------------
% PARAMÈTRES - TRAINS
% ----------------------------------------------------------------------------
array[TRAIN] of int: arrival;          % Temps d'arrivée (minutes)
array[TRAIN] of int: departure;        % Temps de départ (minutes)
array[TRAIN] of int: train_complexity;  % Complexité du train (pour setup)

% ----------------------------------------------------------------------------
% PARAMÈTRES - MAINTENANCES
% ----------------------------------------------------------------------------
array[MAINT] of TRAIN: maint_train;    % Relation 1-N : maintenance → train
array[MAINT] of int: periodicity;      % Périodicité de la maintenance
array[MAINT] of int: priority;         % 1 = urgente, 2 = préventive
array[MAINT] of int: last_done;        % Dernière fois effectuée
array[MAINT] of int: due_date;          % Date butoir idéale (minutes depuis début)

% ----------------------------------------------------------------------------
% PARAMÈTRES - OPÉRATIONS
% ----------------------------------------------------------------------------
array[OP] of MAINT: op_maint;          % Relation 1-N : opération → maintenance
array[OP] of int: duration;            % Durée de l'opération (minutes)
array[OP] of int: required_track_type; % Type de voie requise
array[OP] of int: predecessor;         % ID opération précédente (0 si aucune)

% ----------------------------------------------------------------------------
% PARAMÈTRES - TECHNICIENS
% ----------------------------------------------------------------------------
array[TECH] of int: nb_total;          % Nombre total de techniciens disponibles
array[TECH] of int: min_time;          % Temps minimum de travail (minutes)
array[TECH] of int: max_time;          % Temps maximum de travail (minutes)

% ----------------------------------------------------------------------------
% PARAMÈTRES - ÉQUIPEMENTS
% ----------------------------------------------------------------------------
array[EQUIP] of int: quantity;         % Quantité totale disponible
array[EQUIP] of int: simultaneous_capacity; % Capacité simultanée maximale

% ----------------------------------------------------------------------------
% PARAMÈTRES - RELATIONS N-N
% ----------------------------------------------------------------------------
array[OP, TECH] of int: tech_required;      % Nombre de techniciens requis par opération
array[OP, EQUIP] of int: equip_required;   % Quantité d'équipement requis par opération
array[TRACK, EQUIP] of bool: equip_available_on_track; % Équipement disponible sur voie

% ----------------------------------------------------------------------------
% PARAMÈTRES - SETUP
% ----------------------------------------------------------------------------
int: setup_time_between_trains;        % Temps de setup entre deux trains sur même voie
int: setup_time_between_ops;           % Temps de setup entre opérations

% ----------------------------------------------------------------------------
% PARAMÈTRE - HORIZON
% ----------------------------------------------------------------------------
int: H; % Horizon temporel en minutes (24h = 1440 minutes)

% ----------------------------------------------------------------------------
% VARIABLES DE DÉCISION
% ----------------------------------------------------------------------------
array[OP] of var 0..H: start_op;       % Temps de début de chaque opération
array[OP] of var 0..H: end_op;         % Temps de fin de chaque opération

array[MAINT] of var 0..H: start_maint; % Temps de début de chaque maintenance
array[MAINT] of var 0..H: end_maint;   % Temps de fin de chaque maintenance

array[OP] of var TRACK: assigned_track; % Voie assignée à chaque opération

% ----------------------------------------------------------------------------
% CONTRAINTES
% ----------------------------------------------------------------------------

% Contrainte 1: Relation entre start_op et end_op
constraint forall(o in OP) (
    end_op[o] = start_op[o] + duration[o]
);

% Contrainte 2: Fenêtres temporelles des trains
% Toutes les opérations d'une maintenance doivent être dans la fenêtre du train
constraint forall(m in MAINT) (
    let { TRAIN: t = maint_train[m] } in
    start_maint[m] >= arrival[t] /\
    end_maint[m] <= departure[t]
);

% Contrainte 3: Hiérarchie Maintenance → Opérations
% Les opérations d'une maintenance doivent être dans la fenêtre de la maintenance
constraint forall(o in OP) (
    let { MAINT: m = op_maint[o] } in
    start_op[o] >= start_maint[m] /\
    end_op[o] <= end_maint[m]
);

% Contrainte 4: Définition de start_maint et end_maint
% start_maint = min des start_op de ses opérations
% end_maint = max des end_op de ses opérations
constraint forall(m in MAINT) (
    start_maint[m] = min([start_op[o] | o in OP where op_maint[o] = m]) /\
    end_maint[m] = max([end_op[o] | o in OP where op_maint[o] = m])
);

% Contrainte 5: Précédence des opérations
% Si une opération a un prédécesseur, elle doit commencer après la fin du prédécesseur
constraint forall(o in OP where predecessor[o] != 0) (
    start_op[o] >= end_op[predecessor[o]] + setup_time_between_ops
);

% Contrainte 6: Non-chevauchement des opérations du même train sur la même voie
% Si deux opérations du même train utilisent la même voie, elles ne peuvent pas se chevaucher
% et nécessitent un setup entre elles
constraint forall(o1, o2 in OP where o1 < o2) (
    let { MAINT: m1 = op_maint[o1], 
          MAINT: m2 = op_maint[o2],
          TRAIN: t1 = maint_train[m1],
          TRAIN: t2 = maint_train[m2] } in
    (t1 = t2 /\ assigned_track[o1] = assigned_track[o2]) ->
    (end_op[o1] + setup_time_between_ops <= start_op[o2] \/
     end_op[o2] + setup_time_between_ops <= start_op[o1])
);

% Contrainte 7: Setup entre deux trains sur la même voie
% Si deux opérations de trains différents utilisent la même voie, il faut un setup plus long
constraint forall(o1, o2 in OP where o1 < o2) (
    let { MAINT: m1 = op_maint[o1], 
          MAINT: m2 = op_maint[o2],
          TRAIN: t1 = maint_train[m1],
          TRAIN: t2 = maint_train[m2] } in
    (t1 != t2 /\ assigned_track[o1] = assigned_track[o2]) ->
    (end_op[o1] + setup_time_between_trains <= start_op[o2] \/
     end_op[o2] + setup_time_between_trains <= start_op[o1])
);

% Contrainte 8: Respect des types de voie
% Chaque opération doit être assignée à une voie compatible avec son type requis
% On suppose qu'il existe un paramètre array[TRACK] of int: track_type
% Pour simplifier, on suppose que les voies sont numérotées et que les types sont compatibles
% si track_type[track] >= required_track_type[op]
% Note: Si vous avez un mapping explicite voie-type, ajoutez-le dans les données
% Pour l'instant, on suppose que toutes les voies de type >= required_track_type sont compatibles
% Cette contrainte peut être désactivée si tous les types sont compatibles

% Contrainte 9: Capacité des techniciens (ressource multiple)
% Pour chaque type de technicien, on vérifie que la capacité n'est jamais dépassée
% Approche: vérification aux instants de début de chaque opération
% (cela garantit que la capacité n'est jamais dépassée car on vérifie à chaque changement)
constraint forall(t in TECH, o in OP) (
    % À l'instant de début de chaque opération, vérifier la capacité totale utilisée
    sum(o2 in OP) (
        if start_op[o2] <= start_op[o] /\ start_op[o] < end_op[o2] then
            tech_required[o2, t]
        else 0
        endif
    ) <= nb_total[t]
);

% Contrainte 10: Capacité des équipements (ressource multiple avec capacité simultanée)
% Même approche pour les équipements
constraint forall(e in EQUIP, o in OP) (
    sum(o2 in OP) (
        if start_op[o2] <= start_op[o] /\ start_op[o] < end_op[o2] then
            equip_required[o2, e]
        else 0
        endif
    ) <= simultaneous_capacity[e]
);

% Contrainte 11: Équipement disponible sur voie
% Si une opération nécessite un équipement, elle doit être sur une voie où cet équipement est disponible
constraint forall(o in OP, e in EQUIP where equip_required[o, e] > 0) (
    equip_available_on_track[assigned_track[o], e]
);

% Contrainte 12: Respect max_time technicien
% On vérifie que la charge totale de travail par type de technicien ne dépasse pas le maximum
% Note: La contrainte min_time est omise car elle peut être trop restrictive.
% Si vous voulez garantir un minimum d'utilisation, ajustez les données ou modélisez
% chaque technicien individuellement (plus complexe)
constraint forall(t in TECH) (
    let { var int: total_work = sum(o in OP) (
        tech_required[o, t] * duration[o]
    ) } in
    total_work <= max_time[t] * nb_total[t]
);

% Note: La capacité exclusive des voies est déjà gérée par les contraintes 6 et 7
% qui incluent les temps de setup. Ces contraintes assurent qu'une voie ne peut
% accueillir qu'une seule opération à la fois (avec setup entre opérations).

% ----------------------------------------------------------------------------
% OBJECTIF
% ----------------------------------------------------------------------------
% Minimiser le retard pondéré par priorité
var int: total_weighted_delay = 
    sum(m in MAINT) (
        priority[m] * max(0, end_maint[m] - due_date[m])
    );

solve minimize total_weighted_delay;

% ----------------------------------------------------------------------------
% OUTPUT
% ----------------------------------------------------------------------------
output [
    "=== PLANIFICATION DE MAINTENANCE FERROVIAIRE ===\n",
    "\n--- Trains ---\n"
] ++ [
    "Train \(t): Arrivée=\(arrival[t])min, Départ=\(departure[t])min\n"
    | t in TRAIN
] ++ [
    "\n--- Maintenances ---\n"
] ++ [
    "Maintenance \(m) (Train \(maint_train[m]), Priorité=\(priority[m])): " ++
    "Début=\(start_maint[m])min, Fin=\(end_maint[m])min, " ++
    "Retard=\(max(0, end_maint[m] - due_date[m]))min\n"
    | m in MAINT
] ++ [
    "\n--- Opérations ---\n"
] ++ [
    "Opération \(o) (Maint \(op_maint[o]), Voie \(assigned_track[o])): " ++
    "Début=\(start_op[o])min, Fin=\(end_op[o])min, Durée=\(duration[o])min\n"
    | o in OP
] ++ [
    "\n--- Objectif ---\n",
    "Retard pondéré total: \(total_weighted_delay)\n"
];

