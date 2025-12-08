include "../constant.mzn";
% Gère le planning et le temps de travail des techniciens

array[1..SNb, 1..SDTemps] of var bool: STravail;  % Planning binaire des techniciens (true = travail)
array[1..SNb, 1..SDivision] of var 0..SDTemps: STemps;  % Temps total travaillé par technicien et par division

% Calcule le temps travaillé par chaque technicien sur sa division
constraint
  forall(d in 1..SDivision, t in SType, c in 1..SCapacite[d, t]) (
    let {
      int: i = calculer_index_lineaire(SOffsets, d, t, c)
    } in
      STemps[i, d] =
        sum(u in 1..SDTemps)(
          if STravail[i, u] then P else 0 endif
        )
  );

% Respecte les limites min/max de temps de travail
constraint
  forall(d in 1..SDivision, t in SType, c in 1..SCapacite[d, t]) (
    let {
      int: i = calculer_index_lineaire(SOffsets, d, t, c)
    } in
      STempsMin[d, t] <= STemps[i, d] /\
      STemps[i, d] <= STempsMax[d, t]
  );
