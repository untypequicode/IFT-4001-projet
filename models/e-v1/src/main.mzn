include "constant.mzn";
include "constraints/maintenances.mzn";
include "constraints/techniciens.mzn";

% ===============================================================
% OBJECTIF : RETARD MINIMUM + ÉQUILIBRAGE
% ===============================================================

% 1. Minimiser le Retard (Priorité Absolue)
var int: total_retard = sum(i in 1..MInstanceNb)(
    let {
        int: p_type = MTPeriode[TTRef[MInstanceRefT[i]], MInstanceRefType[i]];
        int: weight = if p_type == 0 then 100 else 1 endif;
    } in
    if varMActive[i] then
        weight * max(0, varMEnd[i] - varDeadline[i])
    else
        % Pénalité énorme si on saute la maintenance
        weight * (10000 + max(0, P - varDeadline[i]))
    endif
);

% 2. Makespan (Tasser le planning)
var int: makespan = max([0] ++ [varMEnd[i] | i in 1..MInstanceNb]);

% 3. Équilibrage de la charge (NOUVEAU)
% On calcule la somme des carrés des heures travaillées.
% Mathématiquement, pour une somme fixe d'heures, minimiser la somme des carrés force la moyenne.
% Ex: 100h + 0h -> 10000.  50h + 50h -> 2500 + 2500 = 5000 (Mieux !)
var int: equity_penalty = sum(s in 1..SNb)(
    let { var int: h = sum(p in 1..P)(bool2int(varSTravail[s, p])); } in
    h * h
);

% Coût technique (éviter les trous "attente payée" inutiles)
var int: cout_tech_inactivite = sum(s in 1..SNb, p in 1..P)(
    bool2int(varSTravail[s, p]) - bool2int(varSTache[s, p])
);

solve minimize 
    total_retard * 100000 
    + makespan * 100 
    + equity_penalty * 10  % On donne du poids à l'équité
    + cout_tech_inactivite;

% ===============================================================
% AFFICHAGE GANTT (MIS À JOUR AVEC TYPES RÉELS)
% ===============================================================

output [
  "\n==============================================================================\n",
  "                            GANTT TRAINS\n",
  "==============================================================================\n",
  "Légende Maint : Type de maintenance réel (MTNb)\n",
  "Légende Op    : Type d'opération réel (OTNb)\n"
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
       % On récupère le type de maintenance associé à l'instance active à cet instant
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
         % On affiche 'o' (le type d'opération) si l'opération 'o' est en cours
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

output [
  "\n==============================================================================\n",
  "                            GANTT TECHNICIENS\n",
  "==============================================================================\n",
  "Légende: [0-9] = Type d'Opération réel, # = Attente payée, . = Repos\n"
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
            % On cherche quel TYPE d'opération (o) le technicien s effectue
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
  "  [Periodes/Jour: " ++
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

output [
  "\nDIAGNOSTIC:\n",
  "Retard Total : " ++ show(total_retard) ++ "\n",
  "Score Équité : " ++ show(equity_penalty) ++ "\n",
  "Nb Maintenances : " ++ show(sum(i in 1..MInstanceNb)(bool2int(fix(varMActive[i])))) ++ " / " ++ show(MInstanceNb) ++ "\n"
];