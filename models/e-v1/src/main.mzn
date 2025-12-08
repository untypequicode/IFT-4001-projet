include "constant.mzn";
include "core/types.mzn";
include "core/utils.mzn";
include "constraints/techniciens.mzn";
include "constraints/maintenances.mzn";
include "constraints/operations.mzn";
include "constraints/trajets.mzn";

% Minimal output (customize as needed)
% output ["Model executed. Check constraints files for details.\n"];

output [
  "==================================================================================================\n",
  "=== PLANNING COMPACT & INTERVALLES DÉTECTÉS ===\n",
  "Légende : A=Aller, R=Retour, #=Maintenance(OK), .=Gare(Attente)\n",
  "==================================================================================================\n",
  "Train | Planning (H01 -> H" ++ show(GP) ++ ")       | Créneaux (Début -> Fin : Gare_Deb -> Gare_Fin)\n",
  "------+-" ++ concat(["-" | p in 1..GP]) ++ "-+----------------------------------------------\n"
] ++
[
  % 1. Nom du train
  " T" ++ show_int(2, n) ++ "  | " ++
  
  % 2. La ligne de temps compacte
  concat([
    if GTrajetSens[n, p] == aller then "A"
    elseif GTrajetSens[n, p] == retour then "R"
    elseif GPresent[n, p] then "#"
    else "."
    endif
    | p in 1..GP
  ]) ++ 
  
  " | " ++

  % 3. Les infos complètes (Début -> Fin : Gare_Deb -> Gare_Fin)
  let {
      int: nb_creneaux = GNbIntervalles[n];
      int: offset      = GOffsetsIntervalles[n];
  } in
  if nb_creneaux == 0 then 
      "" 
  else 
      concat([
          let {
             int: idx   = offset + k - 1;
             int: d     = GIntervallesDebut[idx];
             int: f     = GIntervallesFin[idx];
             GType: t_d = GIntervallesTypeDebut[idx]; % Gare Début
             GType: t_f = GIntervallesTypeFin[idx];   % Gare Fin
          } in
          "[" ++ show_int(2, d) ++ "->" ++ show_int(2, f) ++ " : " ++ show(t_d) ++ "->" ++ show(t_f) ++ "] "
          | k in 1..nb_creneaux
      ])
  endif ++ "\n"
  
  % FILTRE D'AFFICHAGE (Change 20 par sum(TNb) pour tout voir)
  | n in 1..min(20, sum(TNb)) 
];