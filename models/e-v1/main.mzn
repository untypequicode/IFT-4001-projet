include "constant.mzn";
include "computed.mzn";
include "constraints/maintenances.mzn";
include "constraints/techniciens.mzn";

% ===============================================
% Objectifs d'Optimisation
% ===============================================

var int: TotalRetard = sum(i in 1..MInstanceNb)( % Retard total pondéré.
    let {
        int: p_type = MTPeriode[TTRef[MInstanceRefT[i]], MInstanceRefType[i]];
        int: weight = if p_type == 0 then 100 else 1 endif;
    } in
    if varMActive[i] then
        weight * max(0, varMEnd[i] - varDeadline[i])
    else
        weight * (10000 + max(0, P - varDeadline[i]))
    endif
);

solve minimize TotalRetard;

% ===============================================
% Affichage Texte
% ===============================================

output [
=================================================
  "--- Trains ---\n"
];

output [
  "Train " ++ show(TIntervallesTRef[k]) ++
  ": Arrivée=" ++ show(TIntervallesPDebut[k]) ++
  " périodes, Départ=" ++ show(TIntervallesPFin[k]) ++ " périodes\n"
  | k in 1..TIntervallesNbTotal
];

output ["\n--- Maintenances Planifiées (Actives) ---\n"];

output [
  if fix(varMActive[i]) then
    let {
        int: t = MInstanceRefT[i];
        int: weight = if MTPeriode[TTRef[t], MInstanceRefType[i]] == 0 then 100 else 1 endif;
        int: retard = max(0, fix(varMEnd[i]) - fix(varDeadline[i]));
    } in
    "Maintenance " ++ show(i) ++
    " (Train " ++ show(t) ++
    ", Priorité=" ++ show(weight) ++
    "): Début=" ++ show(fix(varMStart[i])) ++
    ", Fin=" ++ show(fix(varMEnd[i])) ++
    ", Retard=" ++ show(retard) ++ " périodes\n"
  else "" endif
  | i in 1..MInstanceNb
];

output [
  if not fix(varMActive[i]) then
     "Maintenance " ++ show(i) ++ " (Train " ++ show(MInstanceRefT[i]) ++ ") : NON PLANIFIÉE (Pénalité appliquée)\n"
  else "" endif
  | i in 1..MInstanceNb
];

output ["\n--- Opérations ---\n"];

output [
  if fix(varMActive[i]) then
    concat([
      if fix(varODuree[i, o]) > 0 then
        "Opération " ++ show(o) ++
        " (Maint " ++ show(i) ++
        ", Voie " ++ show(fix(varMVoieChoisie[i])) ++
        "): Début=" ++ show(fix(varOStart[i, o])) ++
        ", Fin=" ++ show(fix(varOStart[i, o] + varODuree[i, o])) ++
        ", Durée=" ++ show(fix(varODuree[i, o])) ++ " périodes\n"
      else "" endif
      | o in 1..OTNb
    ])
  else "" endif
  | i in 1..MInstanceNb
];

output ["\n--- Techniciens ---\n"];

output [
  let {
      int: max_blocs = MaxPauses + 1;

      int: start_shift = min([P+1] ++ [
          fix(varShiftStart[s, j, b])
          | j in 1..J, b in 1..max_blocs
          where fix(varShiftEnd[s, j, b]) > fix(varShiftStart[s, j, b])
      ]);

      int: end_shift = max([0] ++ [
          fix(varShiftEnd[s, j, b])
          | j in 1..J, b in 1..max_blocs
          where fix(varShiftEnd[s, j, b]) > fix(varShiftStart[s, j, b])
      ]);

      bool: a_travaille = (end_shift > 0);
  } in
  if a_travaille then
    "Technicien " ++ show(s) ++ " (Type " ++ show(STRef[s]) ++ "): " ++
    "Activité globale de " ++ show(start_shift) ++ " à " ++ show(end_shift) ++ " périodes\n" ++
    concat([
       if fix(varMActive[i]) /\ fix(varOAffectation[i,o]) == s then
          "   -> Exécute Op " ++ show(o) ++ " (Maint " ++ show(i) ++ "): " ++
          show(fix(varOStart[i,o])) ++ " à " ++ show(fix(varOStart[i,o] + varODuree[i,o])) ++ "\n"
       else "" endif
       | i in 1..MInstanceNb, o in 1..OTNb
    ])
  else "" endif
  | s in 1..SNb
];

output [
  "\n--- Objectif ---\n",
  "Retard pondéré total: " ++ show(TotalRetard) ++ "\n",
];

output ["------------------------------------------------------------------------------\n"];

% ===============================================
% Affichage GANTT Trains
% ===============================================

output [
=================================================
  "                            GANTT TRAINS\n",
=================================================
  "Légende Présence : [ ] = Au centre de maintenance, . = En circulation/Ailleurs\n",
  "Légende Maint    : Chiffre = Type de maintenance en cours\n",
  "Légende Op       : Chiffre = Type d'opération en cours\n"
];

output [
  let {
    array[int] of int: active_instances = [
       i | i in 1..MInstanceNb
       where MInstanceRefT[i] == t /\ fix(varMActive[i])
    ];
  } in
  "TRAIN " ++ show(t) ++ " (Type " ++ show(TTRef[t]) ++ ")\n" ++

  "  Dispo : " ++
  concat([
    (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
    let {
        bool: is_present = exists(k in 1..TIntervallesNbTotal)(
            TIntervallesTRef[k] == t /\
            p >= TIntervallesPDebut[k] /\
            p <= TIntervallesPFin[k]
        );
    } in
    if is_present then "[" else "." endif
    | p in 1..P
  ]) ++ "\n" ++

  "  Maint : " ++
  concat([
    (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
    let {
       int: m_type = sum(i in active_instances)(
          if p > fix(varMStart[i]) /\
             p <= fix(varMEnd[i]) then MInstanceRefType[i] else 0 endif
       );
    } in
    if m_type > 0 then show(m_type mod 10) else "." endif
    | p in 1..P
  ]) ++ "\n" ++

  concat([
    "  Op " ++ show_int(2, o) ++ " : " ++
    concat([
      (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
      let {
          bool: is_doing_o = exists(i in active_instances)(
            fix(varODuree[i, o]) > 0 /\
            p > fix(varOStart[i, o]) /\ p <= fix(varOStart[i, o]) + fix(varODuree[i, o])
         );
      } in
      if is_doing_o then show(o mod 10) else "." endif
      | p in 1..P
    ]) ++ "\n"
    | o in 1..OTNb
  ]) ++
  "------------------------------------------------------------------------------\n"
  | t in 1..TNb
];

% ===============================================
% Affichage GANTT Techniciens
% ===============================================

output [
=================================================
  "                            GANTT TECHNICIENS\n",
=================================================
  "Légende: [0-9] = Opération, # = Attente, . = Repos\n"
];

output [
  "Tech " ++ show_int(2, s) ++ " (Type " ++ show(STRef[s]) ++ ") : " ++
  concat([
    (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
    let {
       int: j_curr = (p-1) div PJ + 1;

       bool: is_working = exists(b in 1..(MaxPauses+1))(
           p >= fix(varShiftStart[s, j_curr, b]) /\
           p <  fix(varShiftEnd[s, j_curr, b])
       );

       int: op_type = sum(i in 1..MInstanceNb, o in 1..OTNb)(
            if fix(varMActive[i]) /\
               fix(varOAffectation[i, o]) == s /\
               p > fix(varOStart[i, o]) /\
               p <= fix(varOStart[i, o]) + fix(varODuree[i, o])
            then o else 0 endif
       );
    } in
    if op_type > 0 then show(op_type mod 10)
    elseif is_working then "#"
    else "." endif
    | p in 1..P
  ]) ++
  "  [Périodes/Jour: " ++
  concat([
     let {
        int: h_jour = sum(b in 1..(MaxPauses+1))(
           fix(varShiftEnd[s, j, b]) - fix(varShiftStart[s, j, b])
        );
     } in
     "J" ++ show(j) ++ ":" ++ show(h_jour) ++
     if j < ceil(P/PJ) then ", " else "" endif
     | j in 1..ceil(P/PJ)
  ])
  ++ "]" ++ "\n"
  | s in 1..SNb
];

output [
  "\nDIAGNOSTIC:\n",
  "Retard Total       : " ++ show(TotalRetard) ++ "\n",
  "Maintenances       : " ++ show(sum(i in 1..MInstanceNb)(bool2int(fix(varMActive[i])))) ++ " / " ++ show(MInstanceNb) ++ "\n"
];
