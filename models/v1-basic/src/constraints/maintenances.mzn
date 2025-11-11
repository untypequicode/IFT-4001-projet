% ==========================================================================================
% maintenances.mzn
% Contraintes et variables liées aux maintenances et opérations (squelette)
% ==========================================================================================
%
% Objectif :
% - Fournir un squelette clair pour modéliser la planification des maintenances par train,
%   en découpant une maintenance en opérations atomiques.
% - Prévoir les variables de décision (planning, heures de début) et contraintes
%   minimales (durée, non-débordement, urgence, dépendances).
%
% Remarques / Pré-requis (à fournir dans les données d'entrée) :
% - Il est attendu que la donnée fournisse un mapping `TTypeOf` :
%     array[TId] of TType: TTypeOf;
%   (permet de récupérer la plexité via TDuplex[TTypeOf[t]] pour calculer les temps OTemps)
% - Les tableaux suivants sont utilisés (définis dans constant.mzn ou config):
%   - MOperation[MType, OType] : bool (opération O nécessaire pour maintenance M)
%   - OTemps[OType, Plexite] : int (durée d'une opération selon la plexité du train)
%   - ODependance[OType, OType] : bool (dépendances entre opérations)
%   - OShift[OType] : int (shift requis)
%   - OEquipement[OType, EType] : bool
%   - OVType[OType] : VType (type de voie nécessaire)
%   - MUrgence[TId, MType] : 0..H (date maximale / degré d'urgence) — convention : 0 = non critique
%   - MDerniereFois[TType, MType] et MPeriode[TType, MType] peuvent être utilisés pour périodicité
%
% Note : ce fichier contient des contraintes génériques / exemples. Certains aspects
% (assignation des voies VId, gestion fine des équipements, fenêtrage temporel, etc.)
% demandent des variables additionnelles spécifiques au problème et aux données.
% ==========================================================================================

% -------------------------------------------------------------------------------
% Variables de décision (planning des maintenances)
% -------------------------------------------------------------------------------

% Est-ce que la maintenance m est effectuée pour le train t ?
array[TId, MType] of var bool: MScheduled;

% Heure de début de la maintenance (en minutes ; valide si MScheduled[t,m] = true)
array[TId, MType] of var 0..H: MStart;

% Durée totale estimée de la maintenance (somme des opérations requises)
array[TId, MType] of var 0..H: MDuration;

% Heures de début et fin par opération (seulement consistant si opération requise)
array[TId, MType, OType] of var 0..H: OStart;
array[TId, MType, OType] of var 0..H: OEnd;

% Optionnel : assignation d'une voie (VId) et d'équipement (indices) par opération
% (Décommenter si vous fournissez VId et gestion des voies)
% array[TId, MType, OType] of var VId: OVoie;
% array[TId, MType, OType, EType] of var bool: OUsesEquipment;

% -------------------------------------------------------------------------------
% Contraintes de cohérence et calcul des durées
% -------------------------------------------------------------------------------

% 1) Calculer la durée d'une opération selon la plexité du train.
%    Nécessite : array[TId] of TType: TTypeOf (fourni par l'input).
%    OTemps[O, plex] -> durée en minutes.
%
%    On calcule MDuration comme la somme des durées des opérations requises.
constraint
  forall(t in TId, m in MType) (
    MDuration[t,m] =
      sum(o in OType where MOperation[m,o]) (
        OTemps[o, TDuplex[TTypeOf[t]]]
      )
  );

% 2) Si une maintenance est programmée, toutes ses opérations requises doivent
%    avoir un start/end et être incluses dans la fenêtre [MStart, MStart + MDuration).
constraint
  forall(t in TId, m in MType) (
    % Pour toutes opérations o requises par m
    forall(o in OType where MOperation[m,o]) (
      % OStart et OEnd définis en relation avec MStart
      (MScheduled[t,m] -> (OStart[t,m,o] >= MStart[t,m])) /\
      (MScheduled[t,m] -> (OEnd[t,m,o] <= MStart[t,m] + MDuration[t,m])) /\
      % Définition de la durée d'une opération
      (MScheduled[t,m] -> (OEnd[t,m,o] = OStart[t,m,o] + OTemps[o, TDuplex[TTypeOf[t]]]))
    )
  );

% 3) Si la maintenance n'est pas programmée, on contraint start = 0 pour éviter ambiguïté
constraint
  forall(t in TId, m in MType) (
    (not MScheduled[t,m]) -> (MStart[t,m] = 0 /\ MDuration[t,m] = 0)
  );

% 4) Respect des urgences : si MUrgence>0, la maintenance doit commencer avant l'instant d'urgence
%    (Interprétation : MUrgence[t,m] est un horizon maximal pour le début)
constraint
  forall(t in TId, m in MType where MUrgence[t,m] > 0) (
    MScheduled[t,m] -> (MStart[t,m] <= MUrgence[t,m])
  );

% 5) Dépendances entre opérations : si ODependance[a,b] = true, b ne peut commencer avant a est fini
constraint
  forall(t in TId, m in MType, a,b in OType where ODependance[a,b]) (
    MScheduled[t,m] -> (OStart[t,m,b] >= OEnd[t,m,a])
  );

% 6) Optionnel : ne pas dépasser l'horizon H
constraint
  forall(t in TId, m in MType) (
    MScheduled[t,m] -> (MStart[t,m] + MDuration[t,m] <= H)
  );

% -------------------------------------------------------------------------------
% Contrainte d'utilisation d'équipements (squelette)
% -------------------------------------------------------------------------------
% Ici on indique la manière générale de contraindre la capacité des équipements :
% pour chaque instant discret u (ou pour chaque intervalle selon une
% découpe temporelle), la somme des opérations utilisant l'équipement e ne doit
% pas dépasser EQuantite[e].
%
% Implémentation possible (approche par découpage temporel) :
%  - Définir des unités de temps discrètes (périodes) PNb (défini en constant.mzn)
%  - Introduire variables binaires OpActive[t,m,o,u] indiquant si l'opération o de (t,m)
%    est active durant la période u.
%  - Contraindre : forall(e in EType, u) sum((t,m,o) uses e) OpActive[t,m,o,u] <= EQuantite[e]
%
% Pour l'instant on laisse un TODO : implémenter la désagrégation temporelle si nécessaire.
%
% TODO: ajouter la modélisation OpActive et la contrainte d'équipement si on veut
% des vérifications fines sur la disponibilité des équipements.
%
% Exemple (commentaire) :
% % array[TId, MType, OType, 1..PNb] of var bool: OpActive;
% % constraint forall(e in EType, u in 1..PNb) (
% %   sum(t in TId, m in MType, o in OType where OEquipement[o,e]) ( OpActive[t,m,o,u] ) <= EQuantite[e]
% % );

% -------------------------------------------------------------------------------
% Contrainte d'exclusivité de ressources (voies) - squelette
% -------------------------------------------------------------------------------
% Si une opération nécessite une voie OVType[o], il faut assigner une voie spécifique
% VId parmi celles du type OVType[o] et s'assurer qu'il n'y a pas de chevauchement
% temporel sur la même voie.
%
% Variables proposées :
%   array[TId, MType, OType] of var VId: OVoie;
%
% Contrainte d'exclusion:
%   forall(v in VId) sum((t,m,o) assigned to v at time u) <= 1  (sur chaque période)
%
% TODO: si nécessaire, ajouter la variable OVoie et la logique d'exclusion temporelle.

% -------------------------------------------------------------------------------
% Contraintes de périodicité / respect des dernières exécutions (squelette)
% -------------------------------------------------------------------------------
% Si on dispose de MDerniereFois[TType,MType] (heure de dernière exécution) et de
% MPeriode[TType,MType] (périodicité recommandée), on peut contraindre:
%   MScheduled[t,m] -> (MStart[t,m] >= MDerniereFois[TTypeOf[t], m] + MPeriode[TTypeOf[t], m])
%
% (ou la forme inverse suivant la sémantique des données).
%
% TODO: activer cette contrainte si les paramètres MDerniereFois et MPeriode sont fournis.

% -------------------------------------------------------------------------------
% Objectif (exemple)
% -------------------------------------------------------------------------------
% Pour un modèle d'optimisation, on peut proposer différents objectifs :
%  - Minimiser le total des retards par rapport aux urgences
%  - Minimiser la somme des temps non-utilisés / makespan
%  - Minimiser l'utilisation d'équipements coûteux
%
% Exemple d'objectif (commenté) : minimiser le dépassement des urgences
% var int: total_urgency_penalty = sum(t,m where MUrgence[t,m] > 0) (
%    let { var int: delay = max(0, MStart[t,m] - MUrgence[t,m]) } in delay
% );
% solve minimize total_urgency_penalty;
%
% L'objectif exact dépendra de la formulation choisie.

% -------------------------------------------------------------------------------
% Affichage (suggestion)
% -------------------------------------------------------------------------------
% On peut ajouter un output pour lister les maintenances planifiées et les plages.
% Exemple minimal :
% output [
%   \"MAINTENANCES PLANIFIEES:\\n\",
%   concat([ if MScheduled[t,m] then
%              \"Train \" ++ show(t) ++ \" - Maintenance \" ++ show(m) ++ \" starts=\" ++ show(MStart[t,m]) ++ \" dur=\" ++ show(MDuration[t,m]) ++ \"\\n\"
%            else \"\" endif
%            | t in TId, m in MType ])
% ];

% ==========================================================================================
% Fin du squelette maintenances.mzn
% ==========================================================================================
