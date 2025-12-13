include "../constant.mzn";

% ================================================
% Variables de Décision - Techniciens
% ================================================

array[1..SNb, 1..P] of var bool: varSTache;       % Technicien en tâche.
array[1..SNb, 1..P] of var bool: varSTravail;     % Technicien en travail.

% ================================================
% Contrainte 1 : Ubiquité des Techniciens
% ================================================

constraint forall(s in 1..SNb, p in 1..P) (
    sum(i in 1..MInstanceNb, o in 1..OTNb)(
        bool2int(
            varMActive[i] /\
            varOAffectation[i, o] == s /\
            varODuree[i, o] > 0 /\
            p > varOStart[i, o] /\
            p <= varOStart[i, o] + varODuree[i, o]
        )
    ) <= 1                                        % Un seul travail par technicien.
);

% ================================================
% Contrainte 2 : Activation des Statuts
% ================================================

constraint forall(s in 1..SNb, p in 1..P) (
    varSTache[s, p] <-> exists(i in 1..MInstanceNb, o in 1..OTNb)(
        varMActive[i] /\
        varOAffectation[i, o] == s /\
        varODuree[i, o] > 0 /\
        p > varOStart[i, o] /\
        p <= varOStart[i, o] + varODuree[i, o]
    )                                             % Tâche active si opération cours.
);

constraint forall(s in 1..SNb, p in 1..P) (
    varSTache[s, p] -> varSTravail[s, p]          % Tâche implique travail.
);

constraint forall(i in 1..MInstanceNb, o in 1..OTNb) (
    if varMActive[i] /\ varOAffectation[i, o] > 0 then
        STRef[varOAffectation[i, o]] == OShift[o] % Type shift coïncide.
    else true endif
);

% ================================================
% Contrainte 3 : Gestion Journalière
% ================================================

int: NbJours = ceil(P / PJ);                      % Nombre de jours.

constraint forall(s in 1..SNb, j in 1..NbJours) (
    let {
        int: debut_jour = (j-1)*PJ + 1;
        int: fin_jour = min(P, j*PJ);

        var int: heures_jour = sum(p in debut_jour..fin_jour)(bool2int(varSTravail[s, p]));

        % Détection sécurisée des débuts de blocs.
        array[debut_jour..fin_jour] of var bool: est_debut_bloc = array1d(debut_jour..fin_jour, [
            varSTravail[s, p] /\ (p == debut_jour \/ (p > debut_jour /\ not varSTravail[s, p-1]))
            | p in debut_jour..fin_jour
        ]);

        var int: nb_blocs = sum(p in debut_jour..fin_jour)(bool2int(est_debut_bloc[p]));
        var int: nb_pauses = max(0, nb_blocs - 1);
    } in

    % Plage horaire valide.
    (
        (nb_blocs == 0 /\ heures_jour == 0)
        \/
        (nb_blocs > 0 /\ heures_jour >= STTempsMin[STRef[s]] /\ heures_jour <= STTempsMax[STRef[s]])
    )
    /\
    % Pauses dans les limites.
    (
        if nb_blocs > 0 then
            nb_pauses >= MinPauses /\ nb_pauses <= MaxPauses
        else
            true
        endif
    )
    /\
    % Chaque bloc contient au moins une tâche.
    forall(p in debut_jour..fin_jour) (
        if est_debut_bloc[p] then
            exists(k in p..fin_jour) (
                varSTache[s, k] /\
                forall(m in p..k) (varSTravail[s, m])
            )
        else
            true
        endif
    )
);
