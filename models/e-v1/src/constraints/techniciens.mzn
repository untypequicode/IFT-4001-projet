include "../constant.mzn";

% ==============================================================================
% VARIABLES TECHNICIENS
% ==============================================================================
array[1..SNb, 1..P] of var bool: varSTache;   
array[1..SNb, 1..P] of var bool: varSTravail; 

% ==============================================================================
% 1. CONTRAINTE D'UBIQUITÉ
% ==============================================================================
constraint forall(s in 1..SNb, p in 1..P) (
    sum(i in 1..MInstanceNb, o in 1..OTNb)(
        bool2int(
            varMActive[i] /\
            varOAffectation[i, o] == s /\
            varODuree[i, o] > 0 /\
            p > varOStart[i, o] /\
            p <= varOStart[i, o] + varODuree[i, o]
        )
    ) <= 1
);

% ==============================================================================
% 2. DÉFINITION DE L'ACTIVITÉ
% ==============================================================================
constraint forall(s in 1..SNb, p in 1..P) (
    varSTache[s, p] <-> exists(i in 1..MInstanceNb, o in 1..OTNb)(
        varMActive[i] /\
        varOAffectation[i, o] == s /\
        varODuree[i, o] > 0 /\
        p > varOStart[i, o] /\
        p <= varOStart[i, o] + varODuree[i, o]
    )
);

constraint forall(s in 1..SNb, p in 1..P) (
    varSTache[s, p] -> varSTravail[s, p]
);

constraint forall(i in 1..MInstanceNb, o in 1..OTNb) (
    if varMActive[i] /\ varOAffectation[i, o] > 0 then
        STRef[varOAffectation[i, o]] == OShift[o]
    else true endif
);

% ==============================================================================
% 3. GESTION JOURNALIÈRE (PAUSES & BLOCS UTILES)
% ==============================================================================
int: NbJours = ceil(P / PJ);

constraint forall(s in 1..SNb, j in 1..NbJours) (
    let {
        int: debut_jour = (j-1)*PJ + 1;
        int: fin_jour = min(P, j*PJ);
        
        var int: heures_jour = sum(p in debut_jour..fin_jour)(bool2int(varSTravail[s, p]));
        
        % Calcul sécurisé des débuts de blocs (p-1 n'est accédé que si p > debut_jour)
        array[debut_jour..fin_jour] of var bool: is_start_block = array1d(debut_jour..fin_jour, [
            varSTravail[s, p] /\ (p == debut_jour \/ (p > debut_jour /\ not varSTravail[s, p-1]))
            | p in debut_jour..fin_jour
        ]);
        
        var int: nb_blocs = sum(p in debut_jour..fin_jour)(bool2int(is_start_block[p]));
        var int: nb_pauses = max(0, nb_blocs - 1);
    } in
    
    % REGLE A : Heures Min/Max
    (
        (nb_blocs == 0 /\ heures_jour == 0) 
        \/ 
        (nb_blocs > 0 /\ heures_jour >= STTempsMin[STRef[s]] /\ heures_jour <= STTempsMax[STRef[s]])
    )
    /\
    % REGLE B : Pauses Min/Max
    (
        if nb_blocs > 0 then
            nb_pauses >= MinPauses /\ nb_pauses <= MaxPauses
        else 
            true 
        endif
    )
    /\
    % REGLE C : Pas de "Bloc Fantôme" (chaque bloc doit contenir au moins une tâche)
    forall(p in debut_jour..fin_jour) (
        if is_start_block[p] then
            exists(k in p..fin_jour) (
                varSTache[s, k] /\
                forall(m in p..k) (varSTravail[s, m])
            )
        else
            true
        endif
    )
);