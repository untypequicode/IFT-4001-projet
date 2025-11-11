% ==========================================================================================
% operations.mzn
% Contraintes et variables liées aux opérations élémentaires (squelette)
% ==========================================================================================
%
% Ce fichier contient un squelette pour modéliser les opérations atomiques qui composent
% une maintenance. Il s'appuie sur les conventions et les paramètres définis dans
% `models/v1-basic/src/constant.mzn` et les fonctions utilitaires de `core/utils.mzn`.
%
% Hypothèses / entrées attendues :
% - OType        : ensemble des types d'opérations
% - OTemps[o,p]  : durée (minutes) de l'opération o pour une plexité p (défini en constant.mzn)
% - ODependance[a,b] : bool (si b dépend de a)
% - OEquipement[o,e] : bool (si l'opération o nécessite l'équipement e)
% - OVType[o]    : type de voie requis pour l'opération o (VType)
% - OShift[o]    : shift nécessaire (SType)
% - P, PNb, H, JOUR etc. (définis dans constant.mzn)
% - TId, MType, TTypeOf, TDuplex, EType, EQuantite, VId, VNb, VOffsets, ModVoies(...) sont disponibles
%
% Notation recommandée dans les données :
% - On suppose la présence d'un mapping `TTypeOf` : array[TId] of TType
% - `TDuplex[TTypeOf[t]]` donne la plexité du train t
%
% ==========================================================================================

% -------------------------------------------------------------------------------
% Variables de décision pour les opérations (par train et maintenance)
% -------------------------------------------------------------------------------
%
% OScheduled[t,m,o] = true si l'opération o de la maintenance m pour le train t est planifiée/exécutée
array[TId, MType, OType] of var bool: OScheduled;

% Heure de début (en minutes depuis le début de l'horizon) de l'opération o pour (t,m)
array[TId, MType, OType] of var 0..H: OStart;

% Heure de fin de l'opération
array[TId, MType, OType] of var 0..H: OEnd;

% Durée effective (en minutes). On peut contraindre ODuration = OTemps[...] si planifié.
array[TId, MType, OType] of var 0..H: ODuration;

% Optionnel : assignation d'une voie (index parmi les VId existantes)
% Si OVType[o] est défini, on peut contraindre OVoie à être un VId du type OVType[o].
% Pour simplifier, on laisse ici la variable facultative :
array[TId, MType, OType] of var VId: OVoie; % nécessite gestion des domaines si utilisé

% -------------------------------------------------------------------------------
% Contraintes de base
% -------------------------------------------------------------------------------

% 1) Si une opération est planifiée, sa durée correspond à OTemps[o, plexité du train]
constraint
  forall(t in TId, m in MType, o in OType) (
    OScheduled[t,m,o] ->
      ( ODuration[t,m,o] = OTemps[o, TDuplex[TTypeOf[t]]] /\
        OEnd[t,m,o] = OStart[t,m,o] + ODuration[t,m,o] )
  );

% 2) Si l'opération n'est pas planifiée, on force les valeurs à 0 (ou autres valeurs neutres)
constraint
  forall(t in TId, m in MType, o in OType) (
    (not OScheduled[t,m,o]) -> (ODuration[t,m,o] = 0 /\ OStart[t,m,o] = 0 /\ OEnd[t,m,o] = 0)
  );

% 3) Cohérence avec la maintenance parent :
%    si la maintenance MScheduled[t,m] est fausse, aucune opération ne doit être planifiée
constraint
  forall(t in TId, m in MType, o in OType) (
    MScheduled[t,m] -> (OScheduled[t,m,o] = MOperation[m,o]) /\
    (not MScheduled[t,m]) -> (not OScheduled[t,m,o])
  );

% 4) Dépendances entre opérations (si ODependance[a,b] = true -> b commence après a fini)
constraint
  forall(t in TId, m in MType, a, b in OType where ODependance[a,b]) (
    OScheduled[t,m,a] /\ OScheduled[t,m,b] -> (OStart[t,m,b] >= OEnd[t,m,a])
  );

% 5) Option : éviter chevauchement interne pour les opérations d'une même maintenance si nécessaire
%    (par défaut, dépendances et ordonnancement peuvent gérer l'enchaînement)
%    On peut activer une contrainte stricte si on veut séquentialiser toutes les opérations :
% constraint
%   forall(t in TId, m in MType) (
%     forall(a,b in OType where a < b) (
%       OScheduled[t,m,a] /\ OScheduled[t,m,b] -> (OEnd[t,m,a] <= OStart[t,m,b] \/ OEnd[t,m,b] <= OStart[t,m,a])
%     )
%   );

% -------------------------------------------------------------------------------
% Capacités d'équipement (squelette)
% -------------------------------------------------------------------------------
% Approche par désagrégation temporelle (PNb périodes) :
% - On introduit OpActive[t,m,o,u] = 1 si l'opération o est active pendant la période u (1..PNb)
% - Puis on contraint la capacité : pour tout équipement e et période u, nombre d'opérations
%   qui utilisent e activement ≤ EQuantite[e].
%
% Cette désagrégation augmente considérablement la taille du modèle mais permet de
% modéliser précisément les capacités temporelles.
%
% Variables binaires d'activité (création conditionnelle)
array[TId, MType, OType, 1..PNb] of var bool: OpActive;

% Lier OpActive avec OStart/OEnd (approximation : si l'opération chevauche la période u alors OpActive=1)
% On doit convertir périodes P en intervalles temps : pér. u correspond à [ (u-1)*P , u*P )
constraint
  forall(t in TId, m in MType, o in OType, u in 1..PNb) (
    OpActive[t,m,o,u] ->
      ( OScheduled[t,m,o] /\
        OStart[t,m,o] < u * P /\
        OEnd[t,m,o] > (u-1) * P
      )
  );

% Réciproque (si l'opération chevauche la période, alors OpActive peut être 1)
% (On garde la relation unidirectionnelle ci-dessus pour réduire la rigidité du modèle)
%
% Capacité par équipement e pour chaque période u :
constraint
  forall(e in EType, u in 1..PNb) (
    sum(t in TId, m in MType, o in OType where OEquipement[o,e]) ( OpActive[t,m,o,u] ) <= EQuantite[e]
  );

% -------------------------------------------------------------------------------
% Gestion des voies (squelette)
% -------------------------------------------------------------------------------
% Si une opération nécessite une voie du type OVType[o], il faut s'assurer qu'une même voie
% n'est pas utilisée par deux opérations chevauchantes.
%
% Implémentation possible :
% - Déclarer OVoie[t,m,o] ∈ ModVoies(OVType[o]) (un VId valide)
% - Pour chaque voie v et chaque période u, n'opérations assignées à v et actives <= 1
%
% Traduction via OpActive (périodes discrètes) :
constraint
  forall(v in VId, u in 1..PNb) (
    sum(t in TId, m in MType, o in OType where OVType[o] != undefined) (
      bool2int(OpActive[t,m,o,u] /\ (OVoie[t,m,o] == v))
    ) <= 1
  );

% Note : la condition `OVType[o] != undefined` est conceptuelle. En MiniZinc, il faut
% s'assurer que OVType[o] a une valeur et que OVoie domaine est contraint à la liste des
% VId correspondant au type OVType[o]. La construction exacte dépend de la représentation
% des identifiants VId et des fonctions utilitaires ModVoies/VOffsets.

% -------------------------------------------------------------------------------
% Contraintes liées aux shifts / personnels (liaison avec OShift)
% -------------------------------------------------------------------------------
% Exemple : si une opération demande un certain shift SType, on peut contraindre
% le nombre d'opérations actives nécessitant ce shift pour chaque période u
% à être ≤ nombre de techniciens disponibles (SCapacite pour une division/type).
%
% Exemple (approche squelettique) :
% - On doit avoir OpRequiresShift[o, s] (bool) indiquant si l'op. o requiert shift s.
% - Puis : forall(u,s) sum_{t,m,o where OpRequiresShift[o,s]} OpActive[t,m,o,u] <= TotalShiftAvailable[s,u]
%
% Left as TODO: implémentation précise selon données de SCapacite et mapping shift->technicien.

% -------------------------------------------------------------------------------
% Objectifs et pénalités (exemples)
% -------------------------------------------------------------------------------
% Exemples d'objectifs utilisant opérations :
% - Minimiser la somme des délais pour opérations critiques
% - Minimiser le makespan (max OEnd)
% - Minimiser l'utilisation des ressources en heures
%
% Définition d'un makespan (exemple) :
var 0..H: makespan = max([ OEnd[t,m,o] | t in TId, m in MType, o in OType where OScheduled[t,m,o] ]);
% solve minimize makespan;  % décommenter selon problème

% -------------------------------------------------------------------------------
% Output d'exemple (affichage des opérations planifiées)
% -------------------------------------------------------------------------------
% output [
%   \"OPERATIONS PLANIFIEES:\\n\",
%   concat([ if OScheduled[t,m,o] then
%              \"Train \" ++ show(t) ++ \" M=\" ++ show(m) ++ \" O=\" ++ show(o) ++ \" start=\" ++ show(OStart[t,m,o]) ++ \" end=\" ++ show(OEnd[t,m,o]) ++ \"\\n\"
%            else \"\" endif
%            | t in TId, m in MType, o in OType ])
% ];

% ==========================================================================================
% Fin du fichier operations.mzn (squelette)
% - Remplir / spécialiser les parties OpActive/OVoie/shift selon les structures de données
% - Adapter l'approximation temporelle (périodes P) en fonction de la granularité souhaitée
% ==========================================================================================
