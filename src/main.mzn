include "constant.mzn";

% ==========================================================================================
% Variables et contraintes des techniciens
% ==========================================================================================
array[1..SNb, 1..SDTemps] of var bool: STravail;                                           % STravail[i, t] = true si technicien i travaille à l'unité t de sa division
array[1..SNb, 1..SDivision] of var 0..SDTemps: STemps;                                     % STemps[i, d] = temps travaillé par technicien i en division d

constraint forall(d in 1..SDivision, t in SType, i in 1..SCapacite[d, t]) (                % Pour chaque technicien et sa division : calculer le temps travaillé dans cette division
    let {
        int: idx_tech = get_linear_index(SOffsets, d, t, i)
    } in
    STemps[idx_tech, d] = sum(u in 1..SDTemps)(
        if STravail[idx_tech, u] then P else 0 endif
    )
);

constraint forall(d in 1..SDivision, t in SType, i in 1..SCapacite[d, t]) (                % Vérifier que pour chaque technicien et sa division d'affectation, il respecte min/max
    let {
        int: idx_tech = get_linear_index(SOffsets, d, t, i)
    } in
    STempsMin[d, t] <= STemps[idx_tech, d] /\
    STemps[idx_tech, d] <= STempsMax[d, t]
);


% ==========================================================================================
% Variables et contraintes des maintenances
% ==========================================================================================
% TODO

% ==========================================================================================
% Variables et contraintes des operations
% ==========================================================================================
% TODO

% ==========================================================================================
% Variables et contraintes des trajets
% ==========================================================================================
% TODO
