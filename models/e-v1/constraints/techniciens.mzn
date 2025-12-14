include "../constant.mzn";

% ===========================================================================
% Variables de Décision - Techniciens (Approche Intervalles / Blocs)
% ===========================================================================

int: MaxBlocs = MaxPauses + 1;

% Début et Fin de chaque bloc 'b' pour le jour 'j' et le technicien 's'.
array[1..SNb, 1..J, 1..MaxBlocs] of var 0..P: varShiftStart;
array[1..SNb, 1..J, 1..MaxBlocs] of var 0..P: varShiftEnd;

% Variable auxiliaire pour la durée
array[1..SNb, 1..J, 1..MaxBlocs] of var 0..PJ: varBlockDuration;

% ===========================================================================
% Contrainte 1 : Structure Temporelle des Blocs (Intra-Jour)
% ===========================================================================

constraint forall(s in 1..SNb, j in 1..J) (
    let {
        int: day_start = (j-1) * PJ; 
        int: day_end   = j * PJ;
    } in
    forall(b in 1..MaxBlocs) (
        varShiftStart[s, j, b] >= day_start /\
        varShiftEnd[s, j, b]   <= day_end /\
        varShiftEnd[s, j, b]   >= varShiftStart[s, j, b] /\
        varBlockDuration[s, j, b] == varShiftEnd[s, j, b] - varShiftStart[s, j, b]
    ) /\
    forall(b in 1..MaxBlocs-1) (
        varShiftEnd[s, j, b] <= varShiftStart[s, j, b+1]
    )
);

% ===========================================================================
% Contrainte 2 : Respect des Horaires de Travail et Pauses
% ===========================================================================

constraint forall(s in 1..SNb, j in 1..J) (
    let {
        var int: heures_jour = sum(b in 1..MaxBlocs)(varBlockDuration[s, j, b]);
        var int: nb_blocs_actifs = sum(b in 1..MaxBlocs)(bool2int(varBlockDuration[s, j, b] > 0));
        var int: nb_pauses = max(0, nb_blocs_actifs - 1);
    } in
    (heures_jour == 0 \/ 
    (heures_jour >= STTempsMin[STRef[s]] /\ heures_jour <= STTempsMax[STRef[s]]))
    /\
    (if heures_jour > 0 then 
        nb_pauses >= MinPauses /\ nb_pauses <= MaxPauses 
     else true endif)
);

% ===========================================================================
% Contrainte 3 : Inclusion des Tâches
% ===========================================================================

constraint forall(i in 1..MInstanceNb, o in 1..OTNb) (
    if varMActive[i] /\ varOAffectation[i, o] > 0 then
        let {
            var int: s = varOAffectation[i, o];
            var int: t_start = varOStart[i, o];
            var int: t_end   = varOStart[i, o] + varODuree[i, o];
        } in
        exists(j in 1..J, b in 1..MaxBlocs) (
             varShiftStart[s, j, b] <= t_start /\
             varShiftEnd[s, j, b]   >= t_end
        )
    else true endif
);

% ===========================================================================
% Contrainte 4 : Non-Chevauchement (Disjonction)
% ===========================================================================

constraint forall(i1 in 1..MInstanceNb, o1 in 1..OTNb, i2 in 1..MInstanceNb, o2 in 1..OTNb where i1 < i2 \/ (i1 == i2 /\ o1 < o2)) (
    if varMActive[i1] /\ varMActive[i2] /\ 
       varOAffectation[i1, o1] > 0 /\ 
       varOAffectation[i1, o1] == varOAffectation[i2, o2] then
        varOStart[i1, o1] + varODuree[i1, o1] <= varOStart[i2, o2] 
        \/
        varOStart[i2, o2] + varODuree[i2, o2] <= varOStart[i1, o1]
    else true endif
);

% ===========================================================================
% Contrainte 5 : Type de Shift
% ===========================================================================

constraint forall(i in 1..MInstanceNb, o in 1..OTNb) (
    if varMActive[i] /\ varOAffectation[i, o] > 0 then
        STRef[varOAffectation[i, o]] == OShift[o]
    else true endif
);

% ===========================================================================
% Contrainte 6 : Activité Journalière Stricte (SI ET SEULEMENT SI)
% ===========================================================================
% "Un technicien travaille le jour J SI ET SEULEMENT S'IL a une opération ce jour-là"

constraint forall(s in 1..SNb, j in 1..J) (
    let {
       int: day_start = (j-1) * PJ;
       int: day_end   = j * PJ;
       
       % Vérifie si le technicien 's' a une tâche 'active' qui chevauche le jour 'j'
       var bool: has_task_this_day = exists(i in 1..MInstanceNb, o in 1..OTNb)(
           varMActive[i] /\ 
           varOAffectation[i, o] == s /\
           % Chevauchement: Le début de la tâche est avant la fin du jour 
           % ET la fin de la tâche est après le début du jour
           varOStart[i, o] < day_end /\ 
           (varOStart[i, o] + varODuree[i, o]) > day_start
       );
       
       var int: total_duration = sum(b in 1..MaxBlocs)(varBlockDuration[s, j, b]);
    } in
    % Implication stricte : Pas de tâche => Pas de travail (Durée 0)
    (not has_task_this_day) -> (total_duration == 0)
    
    % Note : La réciproque (Tâche => Travail) est déjà garantie par la Contrainte 3
    % (Inclusion), car une tâche a une durée > 0 et doit être dans un shift.
);