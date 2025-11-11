% ==========================================================================================
% Contraintes et variables liées aux techniciens (shifts)
% Ce fichier contient la déclaration des variables de planning des techniciens ainsi que
% les contraintes de calcul du temps travaillé et de respect des min/max par division/type.
% Il est prévu pour être inclus depuis le `main.mzn`.
% ==========================================================================================

% Planning binaire : STravail[i, u] = true si le technicien i travaille à l'unité de temps u
array[1..SNb, 1..SDTemps] of var bool: STravail;

% Temps total travaillé par technicien i sur chaque division d (en unités de SDTemps)
array[1..SNb, 1..SDivision] of var 0..SDTemps: STemps;

% Calcul du temps travaillé par technicien pour sa division d (conversion binaire -> somme des périodes)
constraint
  forall(d in 1..SDivision, t in SType, i in 1..SCapacite[d, t]) (
    let {
      int: idx_tech = get_linear_index(SOffsets, d, t, i)
    } in
      STemps[idx_tech, d] =
        sum(u in 1..SDTemps)(
          if STravail[idx_tech, u] then P else 0 endif
        )
  );

% Respect des minima / maxima de temps de travail par division/type pour chaque technicien
constraint
  forall(d in 1..SDivision, t in SType, i in 1..SCapacite[d, t]) (
    let {
      int: idx_tech = get_linear_index(SOffsets, d, t, i)
    } in
      STempsMin[d, t] <= STemps[idx_tech, d] /\
      STemps[idx_tech, d] <= STempsMax[d, t]
  );

% (Extension possible)
% - Contraintes d'exclusion mutuelle (un technicien ne peut être à deux endroits en même temps)
% - Contraintes de transition (temps de préparation / transfert entre périodes)
% - Contraintes de regroupement si besoin (fenêtres, pauses, qualifications)
% Ces contraintes peuvent être ajoutées ici ou dans d'autres fichiers `constraints/*.mzn`.
