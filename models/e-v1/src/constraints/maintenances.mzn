include "../constant.mzn";

% ==============================================================================
% 1. VARIABLES
% ==============================================================================
array[1..MInstanceNb] of var bool: varMActive;
array[1..MInstanceNb] of var 0..MaxHorizonFutur: varMStart;
array[1..MInstanceNb] of var 0..MaxHorizonFutur: varMEnd;
array[1..MInstanceNb] of var 0..VNb: varMVoieChoisie;

array[1..MInstanceNb, 1..OTNb] of var 0..MaxHorizonFutur: varOStart;
array[1..MInstanceNb, 1..OTNb] of var 0..MaxDureePossible: varODuree;
array[1..MInstanceNb, 1..OTNb] of var 0..SNb: varOAffectation;

int: SAFE_INFINITY = MaxHorizonFutur * 100;
array[1..MInstanceNb] of var -SAFE_INFINITY..SAFE_INFINITY: varDerniereFois;
array[1..MInstanceNb] of var -SAFE_INFINITY..SAFE_INFINITY: varDeadline;

% ==============================================================================
% 2. LOGIQUE D'ACTIVATION
% ==============================================================================
constraint forall(i in 1..MInstanceNb) (
    let {
        int: t = MInstanceRefT[i];
        int: m_type = MInstanceRefType[i];
        int: rep = MInstanceRepetition[i];
        int: max_rep = TIntervallesNb[t];
        int: idx = if rep <= max_rep then TIntervallesDecaladeT[t] + (rep - 1) else 1 endif;
    } in
    % Force P0 si possible
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

% ==============================================================================
% 3. PROPAGATION DEADLINE
% ==============================================================================
constraint forall(i in 1..MInstanceNb) (
    let { int: t = MInstanceRefT[i]; int: m_type = MInstanceRefType[i]; } in
    (if MInstanceRepetition[i] == 1 then 
        varDerniereFois[i] = MDerniereFois[t, m_type]
     else 
        let { int: prev = i - 1; } in
        varDerniereFois[i] = if varMActive[prev] then varMEnd[prev] else varDerniereFois[prev] endif
     endif)
     /\
     (let { int: p = MTPeriode[TTRef[t], m_type]; } in
      if p == infinity then varDeadline[i] = SAFE_INFINITY
      elseif p == 0 then varDeadline[i] = 0
      else varDeadline[i] = varDerniereFois[i] + p endif
     )
);

% ==============================================================================
% 4. OPÉRATIONS (Bornes Strictes)
% ==============================================================================
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
        % ALIGNEMENT STRICT : La maintenance commence et finit exactement avec ses opérations
        varMStart[i] == min([ varOStart[i, o] | o in RequiredOps ]) /\
        varMEnd[i] == max([ varOStart[i, o] + varODuree[i, o] | o in RequiredOps ])
    else 
        forall(o in 1..OTNb)(
             varODuree[i, o] == 0 /\ varOStart[i, o] == 0 /\ varOAffectation[i, o] == 0
        )
    endif
);

% ==============================================================================
% 5. VOIES (SÉCURITÉ)
% ==============================================================================
% A. Compatibilité
constraint forall(i in 1..MInstanceNb) (
    if varMActive[i] then
        forall(o in 1..OTNb where MOperation[MInstanceRefType[i], o]) (
            OVoie[o, VRef[varMVoieChoisie[i]]] == true
        )
    else true endif
);

% B. Un seul train par voie (Disjonction Voies)
constraint forall(i, j in 1..MInstanceNb where i < j) (
    if varMActive[i] /\ varMActive[j] /\ varMVoieChoisie[i] == varMVoieChoisie[j] then
        varMEnd[i] <= varMStart[j] \/ varMEnd[j] <= varMStart[i]
    else true endif
);

% C. Un seul train à la fois (Disjonction Trains)
% C'est cette contrainte qui empêche d'avoir deux maintenances superposées sur le même train
% et donc garantit qu'on ne change pas de voie "en même temps".
constraint forall(i, j in 1..MInstanceNb where i < j) (
    if MInstanceRefT[i] == MInstanceRefT[j] then
        if varMActive[i] /\ varMActive[j] then
             varMEnd[i] + PSetup <= varMStart[j] \/ varMEnd[j] + PSetup <= varMStart[i]
        else true endif
    else true endif
);