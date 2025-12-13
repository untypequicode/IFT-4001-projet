include "constant.mzn";
include "constraints/maintenances.mzn";
include "constraints/techniciens.mzn";

% ==============================================================================
% Objectifs d'Optimisation
% ==============================================================================

% Minimiser retard maintenance (priorité absolue).
var int: TotalRetard = sum(i in 1..MInstanceNb)(
    let {
        int: p_type = MTPeriode[TTRef[MInstanceRefT[i]], MInstanceRefType[i]];
        int: weight = if p_type == 0 then 100 else 1 endif;
    } in
    if varMActive[i] then
        weight * max(0, varMEnd[i] - varDeadline[i])
    else
        % Pénalité énorme si maintenance omise.
        weight * (10000 + max(0, P - varDeadline[i]))
    endif
);

% Minimiser makespan (tasser planning).
var int: Makespan = max([0] ++ [varMEnd[i] | i in 1..MInstanceNb]);

% Équilibrer charge techniciens (minimiser variance).
var int: EquityPenalty = sum(s in 1..SNb)(
    let { var int: h = sum(p in 1..P)(bool2int(varSTravail[s, p])); } in
    h * h
);

% Minimiser inactivité payée (attente sans tâche).
var int: CoutInactivite = sum(s in 1..SNb, p in 1..P)(
    bool2int(varSTravail[s, p]) - bool2int(varSTache[s, p])
);

% --- Fonction Objectif Composée ---
solve minimize
    TotalRetard * 1000
    + Makespan * 100
    + EquityPenalty * 10
    + CoutInactivite;

% ==============================================================================
% Affichage GANTT - Trains
% ==============================================================================

output [
  "==============================================================================\n",
  "                       DÉTAILS DES MAINTENANCES ACTIVES\n",
  "==============================================================================\n",
  "ID | Train | Type | Voie | Début | Fin | Durée | Deadline | Retard | Ops (Type:Start-End-Tech)\n",
  "------------------------------------------------------------------------------\n"
];

output [
  if fix(varMActive[i]) then
    let {
      int: t = MInstanceRefT[i];
      int: m_type = MInstanceRefType[i];
      int: start = fix(varMStart[i]);
      int: end = fix(varMEnd[i]);
      int: deadline = fix(varDeadline[i]);
      int: retard = max(0, end - deadline);
    } in
    show_int(2, i) ++ " | " ++
    show_int(5, t) ++ " | " ++
    show_int(4, m_type) ++ " | " ++
    show_int(4, fix(varMVoieChoisie[i])) ++ " | " ++
    show_int(5, start) ++ " | " ++
    show_int(3, end) ++ " | " ++
    show_int(5, end - start) ++ " | " ++
    (if deadline >= SAFE_INFINITY then " INF  " else show_int(8, deadline) endif) ++ " | " ++
    show_int(6, retard) ++ " | " ++
    concat([
      if fix(varODuree[i, o]) > 0 then
        " (" ++ show(o) ++ ":" ++ show(fix(varOStart[i, o])) ++ "-" ++ show(fix(varOStart[i, o] + varODuree[i, o])) ++ "-T" ++ show(fix(varOAffectation[i, o])) ++ ")"
      else "" endif
      | o in 1..OTNb
    ]) ++ "\n"
  else "" endif
  | i in 1..MInstanceNb
];

output ["------------------------------------------------------------------------------\n"];

output [
  "\n==============================================================================\n",
  "                            GANTT TRAINS\n",
  "==============================================================================\n",
  "Légende Maint : Type de maintenance réel\n",
  "Légende Op    : Type d'opération réel\n"
];

output [
  let {
    array[int] of int: active_instances = [
       i | i in 1..MInstanceNb
       where MInstanceRefT[i] == t /\ fix(varMActive[i])
    ];
  } in
  "TRAIN " ++ show(t) ++ " (Type " ++ show(TTRef[t]) ++ ")\n" ++

  "  Sens  : " ++
  concat([
    (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
    let { GSens: s = TTrajetSens[t, p]; } in
    if s == aller then ">" elseif s == retour then "<" else "=" endif
    | p in 1..P
  ]) ++ "\n" ++

  "  Gare  : " ++
  concat([
    (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
    if TTrajetGare[t, p] > 0 then show(TTrajetGare[t, p]) else "." endif
    | p in 1..P
  ]) ++ "\n" ++

  "  Maint : " ++
  concat([
    (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
    let {
       int: m_type = sum(i in active_instances)(
         if p > fix(varMStart[i]) /\ p <= fix(varMEnd[i]) then MInstanceRefType[i] else 0 endif
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

% ==============================================================================
% Affichage GANTT - Techniciens
% ==============================================================================

output [
  "\n==============================================================================\n",
  "                            GANTT TECHNICIENS\n",
  "==============================================================================\n",
  "Légende: [0-9] = Opération, # = Attente, . = Repos\n"
];

output [
  let {
      int: nb_jours = ceil(P / PJ);
  } in
  "Tech " ++ show_int(2, s) ++ " (Type " ++ show(STRef[s]) ++ ") : " ++
  concat([
    (if p > 1 /\ (p-1) mod PJ == 0 then "|" else "" endif) ++
    if fix(varSTache[s, p]) then
        let {
            int: op_type = sum(i in 1..MInstanceNb, o in 1..OTNb)(
                if fix(varMActive[i]) /\
                   fix(varOAffectation[i, o]) == s /\
                   p > fix(varOStart[i, o]) /\ p <= fix(varOStart[i, o]) + fix(varODuree[i, o])
                then o else 0 endif
            );
        } in
        if op_type > 0 then show(op_type mod 10) else "?" endif
    elseif fix(varSTravail[s, p]) then "#" else "." endif
    | p in 1..P
  ]) ++
  "  [Périodes/Jour: " ++
  concat([
     let {
        int: h_jour = sum(p in ((j-1)*PJ + 1)..min(P, j*PJ))(bool2int(fix(varSTravail[s, p])));
     } in
     "J" ++ show(j) ++ ":" ++ show(h_jour) ++
     if j < nb_jours then ", " else "" endif
     | j in 1..nb_jours
  ]) ++ "]" ++ "\n"
  | s in 1..SNb
];

% ==============================================================================
% Diagnostic Final
% ==============================================================================

output [
  "\nDIAGNOSTIC:\n",
  "Retard Total       : " ++ show(TotalRetard) ++ "\n",
  "Score Équité       : " ++ show(EquityPenalty) ++ "\n",
  "Coût Inactivité    : " ++ show(CoutInactivite) ++ "\n",
  "Makespan           : " ++ show(Makespan) ++ "\n",
  "Maintenances       : " ++ show(sum(i in 1..MInstanceNb)(bool2int(fix(varMActive[i])))) ++ " / " ++ show(MInstanceNb) ++ "\n"
];
