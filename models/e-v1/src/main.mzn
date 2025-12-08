include "constant.mzn";
include "core/types.mzn";
include "core/utils.mzn";
include "core/output_functions.mzn";
include "constraints/techniciens.mzn";
include "constraints/maintenances.mzn";
include "constraints/operations.mzn";
include "constraints/trajets.mzn";

% Fichier principal qui génère l'affichage formaté des résultats

% Section 1: Constantes calculées
output [
  "\n",
  "╔══════════════════════════════════════════════════════════════════════════════════════╗\n",
  "║                     CONSTANTES CALCULÉES AUTOMATIQUEMENT                             ║\n",
  "╚══════════════════════════════════════════════════════════════════════════════════════╝\n",
  "\n",
  "┌─ Périodes et horizon ─────────────────────────────────────────────────────────────┐\n",
  "│ PNb (Nombre de périodes)        : ", show_int(6, PNb), "                                      │\n",
  "│ PJour (Nombre de jours)         : ", show_int(6, PJour), "                                      │\n",
  "│ GP (Périodes par cycle trajet)  : ", show_int(6, GP), "                                      │\n",
  "└───────────────────────────────────────────────────────────────────────────────────┘\n",
  "\n",
  "┌─ Trains ──────────────────────────────────────────────────────────────────────────┐\n",
  "│ Total trains                    : ", show_int(6, sum(TNb)), "                                      │\n",
  "│ Par type                        : ", show(TNb), "\n",
  "│ Offsets                         : ", show(TOffsets), "\n",
  "└───────────────────────────────────────────────────────────────────────────────────┘\n",
  "\n",
  "┌─ Voies ───────────────────────────────────────────────────────────────────────────┐\n",
  "│ Total voies                     : ", show_int(6, sum(VNb)), "                                      │\n",
  "│ Par type                        : ", show(VNb), "\n",
  "│ Offsets                         : ", show(VOffsets), "\n",
  "└───────────────────────────────────────────────────────────────────────────────────┘\n",
  "\n",
  "┌─ Techniciens ─────────────────────────────────────────────────────────────────────┐\n",
  "│ Total techniciens               : ", show_int(6, SNb), "                                      │\n",
  "│ Nombre de divisions             : ", show_int(6, SDivision), "                                      │\n",
  "│ Temps par division              : ", show_int(6, SDTemps), " minutes                             │\n",
  "│ Techniciens par division        : ", show(SDNb), "\n",
  "└───────────────────────────────────────────────────────────────────────────────────┘\n",
  "\n",
  "┌─ Trajets & Gares ─────────────────────────────────────────────────────────────────┐\n",
  "│ Période de cycle                : ", show_int(6, GP), "                                      │\n",
  "│ Total intervalles présence      : ", show_int(6, GTotalIntervalles), "                                      │\n",
  "└───────────────────────────────────────────────────────────────────────────────────┘\n",
  "\n\n"
];

% Section 2: Gantt Techniciens
output [
  "╔══════════════════════════════════════════════════════════════════════════════════════╗\n",
  "║                          GANTT - PLANNING TECHNICIENS                                ║\n",
  "╚══════════════════════════════════════════════════════════════════════════════════════╝\n",
  "\n",
  "Légende : █ = Travail  │  ░ = Repos\n",
  "\n"
] ++ [
  let {
    int: d = min(dd in 1..SDivision, t in SType where
                 SOffsets[dd, t] <= i /\
                 i < SOffsets[dd, t] + SCapacite[dd, t])(dd);
    SType: type_tech = min(dd in 1..SDivision, t in SType where
                           SOffsets[dd, t] <= i /\
                           i < SOffsets[dd, t] + SCapacite[dd, t])(t);
    array[int] of bool: planning = [fix(STravail[i, u]) | u in 1..SDTemps];
  } in
  gantt_technicien_visuel(i, show(type_tech), d, planning, fix(STemps[i, d]), SDTemps)
  | i in 1..SNb
] ++ [
  "\n\n"
];

% Section 3: Gantt Trajets
output [
  "╔══════════════════════════════════════════════════════════════════════════════════════╗\n",
  "║                          GANTT - PLANNING TRAJETS                                    ║\n",
  "╚══════════════════════════════════════════════════════════════════════════════════════╝\n",
  "\n",
  "Légende : A = Aller  │  R = Retour  │  ■ = En gare (maintenance possible)  │  · = Autre\n",
  "\n"
] ++ [
  let {
    array[int] of GSens: sens = [GTrajetSens[n, p] | p in 1..GP];
    array[GSens] of string: symboles = [aller: "A", retour: "R", gare: "■"];
  } in
  " T" ++ show_int(3, n) ++ " |" ++
  concat([
    if sens[p] == gare then
      (if GPresent[n, p] then "■" else "·" endif)
    else
      enum_vers_symbole(sens[p], symboles)
    endif
    | p in 1..GP
  ]) ++ "|\n"
  | n in 1..sum(TNb)
] ++ [
  "\n"
];
