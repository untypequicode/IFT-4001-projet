include "../constant.mzn";

% ===========================================================================
% Variables de Décision - Maintenances
% ===========================================================================

array[1..MInstanceNb] of var bool: varMActive;
array[1..MInstanceNb] of var 0..MaxHorizonFutur: varMStart;
array[1..MInstanceNb] of var 0..MaxHorizonFutur: varMEnd;
array[1..MInstanceNb] of var 0..VNb: varMVoieChoisie;

array[1..MInstanceNb, 1..OTNb] of var 0..MaxHorizonFutur: varOStart;
array[1..MInstanceNb, 1..OTNb] of var 0..MaxDureePossible: varODuree;
array[1..MInstanceNb, 1..OTNb] of var 0..SNb: varOAffectation;

% Définition d'un infini "sûr" pour le solveur (assez grand mais fini)
int: SAFE_INFINITY = MaxHorizonFutur * 2;

array[1..MInstanceNb] of var -SAFE_INFINITY..SAFE_INFINITY: varDerniereFois;
array[1..MInstanceNb] of var -SAFE_INFINITY..SAFE_INFINITY: varDeadline;

% ===========================================================================
% Contrainte 1 : Logique d'Activation et Fenêtres
% ===========================================================================

constraint forall(i in 1..MInstanceNb) (
    let {
        int: t = MInstanceRefT[i];
        int: m_type = MInstanceRefType[i];
        int: rep = MInstanceRepetition[i];
        int: max_rep = TIntervallesNb[t];
        int: idx = if rep <= max_rep then TIntervallesDecalageT[t] + (rep - 1) else 1 endif;
    } in
    if rep <= max_rep /\ MTPeriode[TTRef[t], m_type] == 0 /\ TIntervallesPossible[idx] then
        varMActive[i] == true
    else true endif
    /\
    if not varMActive[i] then
        varMStart[i] == 0 /\ varMEnd[i] == 0 /\ varMVoieChoisie[i] == 0 /\
        forall(o in 1..OTNb)(varOStart[i, o] == 0 /\ varODuree[i, o] == 0 /\ varOAffectation[i, o] == 0)
    else
        varMVoieChoisie[i] > 0 /\
        varMEnd[i] > varMStart[i] /\
        let {
            int: b_min = TIntervallesPDebut[idx] + (if TIntervallesGDebut[idx] > 0 then GTemps[TIntervallesGDebut[idx]] else 0 endif);
            int: b_max = TIntervallesPFin[idx] - (if TIntervallesGFin[idx] > 0 then GTemps[TIntervallesGFin[idx]] else 0 endif);
        } in
        varMStart[i] >= b_min /\ varMEnd[i] <= b_max
    endif
);

% ===========================================================================
% Contrainte 2 : Propagation des Deadlines (AVEC GESTION INFINITY)
% ===========================================================================

constraint forall(i in 1..MInstanceNb) (
    let { int: t = MInstanceRefT[i]; int: m_type = MInstanceRefType[i]; } in
    % Dernière fois
    (if MInstanceRepetition[i] == 1 then
        varDerniereFois[i] = MDerniereFois[t, m_type]
     else
        let { int: prev = i - 1; } in
        varDerniereFois[i] = if varMActive[prev] then varMEnd[prev] else varDerniereFois[prev] endif
    endif)
     /\
     % Deadline : Conversion de 'infinity' (entrée) vers SAFE_INFINITY (variable)
     (let { int: p = MTPeriode[TTRef[t], m_type]; } in
      if p == infinity then
          varDeadline[i] = SAFE_INFINITY
      elseif p == 0 then
          varDeadline[i] = 0
      else
          varDeadline[i] = varDerniereFois[i] + p
      endif
     )
);

% ===========================================================================
% Contrainte 3 : Opérations
% ===========================================================================

constraint forall(i in 1..MInstanceNb) (
    if varMActive[i] then
        let {
            set of int: RequiredOps = { o | o in 1..OTNb where MOperation[MInstanceRefType[i], o] };
        } in
        forall(o in 1..OTNb) (
            if o in RequiredOps then
                varODuree[i, o] == OTemps[o, TEtage[TTRef[MInstanceRefT[i]]]] /\
                varOAffectation[i, o] > 0
            else
                varODuree[i, o] == 0 /\ varOStart[i, o] == 0 /\ varOAffectation[i, o] == 0
            endif
        ) /\
        forall(o1, o2 in RequiredOps) (
            if ODependance[o2, o1] then
                varOStart[i, o2] >= varOStart[i, o1] + varODuree[i, o1] + PSetup
            else true endif
        ) /\
        varMStart[i] == min([ varOStart[i, o] | o in RequiredOps ]) /\
        varMEnd[i] == max([ varOStart[i, o] + varODuree[i, o] | o in RequiredOps ])
    else
        forall(o in 1..OTNb)(
             varODuree[i, o] == 0 /\ varOStart[i, o] == 0 /\ varOAffectation[i, o] == 0
        )
    endif
);

% ===========================================================================
% Contrainte 4 : Compatibilité Voies
% ===========================================================================

constraint forall(i in 1..MInstanceNb) (
    if varMActive[i] then
        forall(o in 1..OTNb where MOperation[MInstanceRefType[i], o]) (
            OVoie[o, VRef[varMVoieChoisie[i]]] == true
        )
    else true endif
);

% ===========================================================================
% Contrainte 5 : Disjonction Voies
% ===========================================================================

constraint forall(i, j in 1..MInstanceNb where i < j) (
    if varMActive[i] /\ varMActive[j] /\ varMVoieChoisie[i] == varMVoieChoisie[j] then
        varMEnd[i] <= varMStart[j] \/ varMEnd[j] <= varMStart[i]
    else true endif
);

% ===========================================================================
% Contrainte 6 : Disjonction Trains
% ===========================================================================

constraint forall(i, j in 1..MInstanceNb where i < j) (
    if MInstanceRefT[i] == MInstanceRefT[j] then
        if varMActive[i] /\ varMActive[j] then
             varMEnd[i] + PSetup <= varMStart[j] \/ varMEnd[j] + PSetup <= varMStart[i]
        else true endif
    else true endif
);
