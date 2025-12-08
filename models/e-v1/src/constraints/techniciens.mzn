include "../constant.mzn";
% ==========================================================================================
% Contraintes et variables liées aux techniciens (shifts)
% Ce fichier calcule le temps de travail de chaque employés afin qu'ils respectent
% leurs horaires de travail
% ==========================================================================================

array[1..SNb, 1..SDTemps] of var bool: STravail;                                           % Planning binaire : STravail[i, u] = true si le technicien i travaille à l'unité de temps u

array[1..SNb, 1..SDivision] of var 0..SDTemps: STemps;                                     % Temps total travaillé par technicien i sur chaque division d (en unités de SDTemps)

constraint                                                                                 % Calcul du temps travaillé par technicien pour sa division d
  forall(d in 1..SDivision, t in SType, c in 1..SCapacite[d, t]) (                         % (conversion binaire -> somme des périodes)
    let {
      int: i = calculer_index_lineaire(SOffsets, d, t, c)
    } in
      STemps[i, d] =
        sum(u in 1..SDTemps)(
          if STravail[i, u] then P else 0 endif
        )
  );

constraint                                                                                 % Respect des minima / maxima de temps de travail par division/type pour chaque technicien
  forall(d in 1..SDivision, t in SType, c in 1..SCapacite[d, t]) (
    let {
      int: i = calculer_index_lineaire(SOffsets, d, t, c)
    } in
      STempsMin[d, t] <= STemps[i, d] /\
      STemps[i, d] <= STempsMax[d, t]
  );

% ==========================================================================================
% Extension possible
% ==========================================================================================
% - Contraintes d'exclusion mutuelle (un technicien ne peut être à deux endroits en même temps)
% - Contraintes de transition (temps de préparation / transfert entre périodes)
% - Contraintes de regroupement si besoin (fenêtres, pauses, qualifications)