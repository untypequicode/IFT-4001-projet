% include "../constant.mzn";

% % ==============================================================================
% % 1. VARIABLES
% % ==============================================================================

% % --- Décision d'activation ---
% array[1..MInstanceNb] of var bool: varMActive;

% % --- Planification Temporelle ---
% array[1..MInstanceNb] of var 0..MaxHorizonFutur: varMStart;
% array[1..MInstanceNb] of var 0..MaxHorizonFutur: varMEnd;
% array[1..MInstanceNb] of var 0..MaxDureePossible: varMDureeGlobale;

% % --- Choix de la Voie ---
% array[1..MInstanceNb] of var 0..VNb: varMVoieChoisie;

% % --- Détail des Opérations ---
% array[1..MInstanceNb, 1..OTNb] of var 0..MaxHorizonFutur: varOStart;
% array[1..MInstanceNb, 1..OTNb] of var 0..MaxDureePossible: varODuree;

% % --- Variables Internes (CORRECTION ICI : DOMAINES ÉLARGIS) ---
% int: SAFE_INFINITY = MaxHorizonFutur * 10;

% % On autorise le négatif car MDerniereFois peut être < 0
% array[1..MInstanceNb] of var -SAFE_INFINITY..MaxHorizonFutur: varDerniereFois;
% % Une deadline peut être négative (retard dès le début)
% array[1..MInstanceNb] of var -SAFE_INFINITY..SAFE_INFINITY: varDeadline;


% % ==============================================================================
% % 2. LOGIQUE CŒUR : ACTIVATION
% % ==============================================================================

% constraint forall(i in 1..MInstanceNb) (
%     let {
%         int: t = MInstanceRefT[i];
%         int: rep = MInstanceRepetition[i];
%         int: max_rep = TIntervallesNb[t];
%     } in
%     % Désactive les instances fantômes
%     if rep > max_rep then
%         varMActive[i] == false
%     else
%         true
%     endif
% );

% % Si INACTIF, forcage à 0
% constraint forall(i in 1..MInstanceNb) (
%     if varMActive[i] == false then
%         varMStart[i] == 0 /\
%         varMEnd[i] == 0 /\
%         varMDureeGlobale[i] == 0 /\
%         varMVoieChoisie[i] == 0 /\
%         forall(o in 1..OTNb)(varOStart[i, o] == 0 /\ varODuree[i, o] == 0)
%     else
%         varMDureeGlobale[i] > 0 /\
%         varMVoieChoisie[i] > 0 /\
%         varMEnd[i] = varMStart[i] + varMDureeGlobale[i] /\
%         varMEnd[i] <= P + 1
%     endif
% );

% % ==============================================================================
% % 3. PROJECTION SUR LA GRILLE (varMV)
% % ==============================================================================

% constraint forall(i in 1..MInstanceNb, p in 1..P) (
%     if varMActive[i] then
%         if p >= varMStart[i] /\ p < varMEnd[i] then
%             varMV[i, p] = varMVoieChoisie[i]
%         else
%             varMV[i, p] = 0
%         endif
%     else
%         varMV[i, p] = 0
%     endif
% );

% % ==============================================================================
% % 4. GESTION DES OPÉRATIONS
% % ==============================================================================

% % A. Durées
% constraint forall(i in 1..MInstanceNb, o in 1..OTNb) (
%     if varMActive[i] /\ MOperation[ MInstanceRefType[i], o ] then
%         varODuree[i, o] = OTemps[o, TEtage[ TTRef[ MInstanceRefT[i] ] ]]
%     else
%         varODuree[i, o] = 0
%     endif
% );

% % B. Dépendances
% constraint forall(i in 1..MInstanceNb, o1, o2 in 1..OTNb) (
%     if varMActive[i] /\ ODependance[o2, o1] /\ varODuree[i, o1] > 0 /\ varODuree[i, o2] > 0 then
%         varOStart[i, o2] >= varOStart[i, o1] + varODuree[i, o1] + PSetup
%     else true endif
% );

% % C. Inclusion
% constraint forall(i in 1..MInstanceNb, o in 1..OTNb) (
%     if varMActive[i] /\ varODuree[i, o] > 0 then
%         varOStart[i, o] >= varMStart[i] /\
%         varOStart[i, o] + varODuree[i, o] <= varMEnd[i]
%     else true endif
% );

% % D. Compatibilité Voie/Equipement
% constraint forall(i in 1..MInstanceNb, o in 1..OTNb) (
%     if varMActive[i] /\ varODuree[i, o] > 0 then
%         OVoie[o, VRef[ varMVoieChoisie[i] ]] == true
%         /\
%         forall(e in 1..ENb where OEquipement[o, e]) (
%             VEDisponible[ varMVoieChoisie[i], e ] == true
%         )
%     else true endif
% );

% % ==============================================================================
% % 5. CONTRAINTES DE TEMPS (TRAJETS)
% % ==============================================================================

% constraint forall(i in 1..MInstanceNb) (
%     let {
%         int: t = MInstanceRefT[i];
%         int: rep = MInstanceRepetition[i];
%         int: max_rep = TIntervallesNb[t];
%     } in
%     % Garde pour éviter Array Out of Bounds
%     if rep <= max_rep then
%         let {
%             int: idx = TIntervallesDecaladeT[t] + (rep - 1);
%             int: start_min = TIntervallesPDebut[idx] + (if TIntervallesGDebut[idx] > 0 then GTemps[TIntervallesGDebut[idx]] else 0 endif);
%             int: end_max = TIntervallesPFin[idx] - (if TIntervallesGFin[idx] > 0 then GTemps[TIntervallesGFin[idx]] else 0 endif) + 1;
%         } in
%         if varMActive[i] then
%             varMStart[i] >= start_min /\
%             varMEnd[i] <= end_max
%         else true endif
%     else true endif
% );

% % ==============================================================================
% % 6. CALCUL DEADLINE
% % ==============================================================================

% constraint forall(i in 1..MInstanceNb) (
%     let {
%         int: t = MInstanceRefT[i];
%         int: m_type = MInstanceRefType[i];
%         int: periodicite = MTPeriode[TTRef[t], m_type];
%     } in
%     % 1. Dernière Fois (Peut être négatif)
%     (if MInstanceRepetition[i] == 1 then 
%         varDerniereFois[i] = MDerniereFois[t, m_type]
%      else 
%         let { int: prev_i = i - 1; } in
%         if varMActive[prev_i] then
%             varDerniereFois[i] = varMEnd[prev_i]
%         else
%             varDerniereFois[i] = varDerniereFois[prev_i]
%         endif
%      endif) 
%      /\
%      % 2. Deadline (Peut être négative)
%      (if periodicite == infinity then varDeadline[i] = SAFE_INFINITY
%       elseif periodicite == 0 then varDeadline[i] = 0 
%       else varDeadline[i] = varDerniereFois[i] + periodicite endif)
% );

% % ==============================================================================
% % 7. RESSOURCES GLOBALES
% % ==============================================================================

% constraint forall(p in 1..P) (
%     % Techniciens
%     forall(type_s in 1..STNb) (
%         sum(i in 1..MInstanceNb, o in 1..OTNb) (
%             bool2int(varMActive[i] /\ varODuree[i, o] > 0 /\ varOStart[i, o] <= p /\ p < varOStart[i, o] + varODuree[i, o] /\ OShift[o] == type_s)
%         ) <= sum(tech in 1..SNb where STRef[tech] == type_s) (bool2int(varSTravail[tech, p]))
%     ) 
%     /\
%     % Equipements
%     forall(e in 1..ENb) (
%         sum(i in 1..MInstanceNb, o in 1..OTNb) (
%             bool2int(varMActive[i] /\ varODuree[i, o] > 0 /\ varOStart[i, o] <= p /\ p < varOStart[i, o] + varODuree[i, o] /\ OEquipement[o, e])
%         ) <= EQuantite[e]
%     )
% );

% % ==============================================================================
% % 8. SÉQUENCEMENT
% % ==============================================================================

% constraint forall(i in 1..MInstanceNb, j in 1..MInstanceNb where i < j) (
%     if MInstanceRefT[i] == MInstanceRefT[j] then
%         if varMActive[i] /\ varMActive[j] then
%             (varMEnd[i] + PSetup <= varMStart[j]) \/ (varMEnd[j] + PSetup <= varMStart[i])
%         else true endif
%     else true endif
% );

% constraint forall(i_zero in 1..MInstanceNb, i_other in 1..MInstanceNb) (
%     if i_zero != i_other /\ 
%        MInstanceRefT[i_zero] == MInstanceRefT[i_other] /\ 
%        MTPeriode[TTRef[MInstanceRefT[i_zero]], MInstanceRefType[i_zero]] == 0 /\
%        MTPeriode[TTRef[MInstanceRefT[i_other]], MInstanceRefType[i_other]] != 0
%     then
%        if varMActive[i_zero] /\ varMActive[i_other] then
%            varMStart[i_zero] >= varMEnd[i_other]
%        else true endif
%     else true endif
% );