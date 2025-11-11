% ==========================================================================================
% trajets.mzn
% Contraintes et variables liées aux trajets des trains (aller/retour/gare)
% ==========================================================================================
%
% Contexte :
% - Ce fichier propose un squelette pour modéliser les trajets entre gares et le centre de maintenance,
%   la planification des arrivées/départs et les contraintes temporelles associées.
% - Il s'appuie sur les données déclarées dans `constant.mzn` :
%     - GTrajetGare[TId, 1..GP] : gare associée à chaque période du trajet (GType)
%     - GTrajetSens[TId, 1..GP] : sens du trajet (GSens)
%     - GTemps[GType]           : temps de trajet (minutes) entre la gare et le centre
%     - GPeriode / GP           : périodicité et nombre de périodes
% - Le modèle doit relier les trajets aux maintenances (par ex. heure d'arrivée disponible pour MStart)
%
% Remarques :
% - On considère ici une granularité en périodes P (définie dans `constant.mzn`).
% - Certaines implémentations peuvent nécessiter une désagrégation temporelle plus fine.
%
% TODO :
% - Adapter les domaines et types exacts (TId, GP, PNb, etc.) en fonction des données d'entrée du projet.
% - Lier précisément avec la partie "maintenances" pour forcer disponibilité des trains.
% ==========================================================================================

% ------------------------------------------------------------------------------
% Variables de décision (squelette)
% ------------------------------------------------------------------------------
% Indique si le trajet j (période de la séquence GP) est utilisé pour le train t
array[TId, 1..GP] of var bool: GPlanned;        % true si train t a un trajet prévu sur la période j

% Heure d'arrivée au centre pour le train t lors de la période j (minutes depuis début horizon)
% Valeur significative seulement si GPlanned[t,j] = true
array[TId, 1..GP] of var 0..H: GArrivee;

% Heure de départ du centre pour le train t lors de la période j (minutes)
array[TId, 1..GP] of var 0..H: GDepart;

% Durée effective du trajet (aller ou retour) — peut être dérivée de GTemps et plexité si besoin
array[TId, 1..GP] of var 0..H: GDuree;

% Optionnel : indice de slot de quai / voie pour le déchargement / embarquement (si nécessaire)
% array[TId, 1..GP] of var VId: GVoie;

% ------------------------------------------------------------------------------
% Contraintes de base
% ------------------------------------------------------------------------------

% 1) Cohérence avec les données d'entrée GTrajetGare / GTrajetSens.
%    Si un trajet est planifié pour (t,j), alors la gare/sens associés doivent être valides.
%    (On ne redéclare pas les constantes ci-dessous, elles existent dans input.)
%
% Exemple d'utilisation (commentée): on pourrait forcer que si le sens est 'aller' alors GArrivee =
%   temps de trajet depuis la gare vers le centre (GTemps[GTrajetGare[t,j]]).
%
constraint
  forall(t in TId, j in 1..GP) (
    GPlanned[t,j] ->
      ( GDuree[t,j] = GTemps[GTrajetGare[t,j]] /\
        % Si sens = aller, arrivée = départ_gare + trajet => on simplifie en posant l'instant d'arrivée
        % Selon la modélisation des fenêtres, on peut contraindre GArrivee et GDepart comme ci-dessous :
        (GTrajetSens[t,j] = aller -> GArrivee[t,j] + 0 = GArrivee[t,j]) /\
        (GTrajetSens[t,j] = retour -> GDepart[t,j] + 0 = GDepart[t,j])
      )
  );

% Note : les deux conditions sur GArrivee/GDepart ci-dessus sont des placeholders neutres.
% Remplacer par des relations temporelles pertinentes selon le modèle : par exemple
%   - si le train arrive depuis une gare, GArrivee correspond à l'instant où il est au centre,
%   - si il repart en sens 'retour', GDepart correspond à l'instant de départ vers la gare.

% 2) Liens temporels simples : si trajet planifié, respecter la durée
constraint
  forall(t in TId, j in 1..GP) (
    GPlanned[t,j] -> (GDepart[t,j] = GArrivee[t,j] + GDuree[t,j])
  );

% 3) Un train ne peut être présent à deux trajets distincts au même instant :
%    pour toute paire de périodes j1 != j2, si les intervalles [GArrivee,GDepart) se chevauchent,
%    alors pas les deux planifiés. Ici on donne une contrainte simplifiée via disjonction temporelle.
constraint
  forall(t in TId, j1, j2 in 1..GP where j1 < j2) (
    GPlanned[t,j1] /\ GPlanned[t,j2] ->
      (GDepart[t,j1] <= GArrivee[t,j2] \/ GDepart[t,j2] <= GArrivee[t,j1])
  );

% 4) Liaison avec maintenances : si une maintenance MStart[t,m] est prévue, il faut que
%    pour la maintenance planifiée, le train soit présent (arrivé) au centre au bon moment.
%    Nous supposons que `MScheduled` et `MStart` existent dans le modèle de maintenances.
%
% Exemple (squelette) : Pour tout train t et maintenance m planifiée,
% on force l'existence d'au moins un j tel que le train est au centre pendant l'intervalle de la maintenance.
%
% (Attention : cette contrainte suppose l'existence des identifiants et variables MScheduled/MStart/MDuration)
constraint
  forall(t in TId, m in MType) (
    % Si la maintenance est programmée, il doit exister une période j couvrant la fenêtre MStart..MStart+MDuration
    MScheduled[t,m] ->
      exists(j in 1..GP) (
        GPlanned[t,j] /\
        GArrivee[t,j] <= MStart[t,m] /\
        GDepart[t,j] >= MStart[t,m] + MDuration[t,m]
      )
  );

% 5) Respect des périodicités et des fenêtres de trajets (exemple)
%    Si la donnée fournit des fenêtres de disponibilité par gare (ex: GWindowStart[GType, u], GWindowEnd[...] ),
%    on peut contraindre que GArrivee soit dans ces fenêtres.
%    Ici on explique le pattern (TODO: adapter si les fenêtres existent).
%
% Exemple commenté :
% % constraint forall(t in TId, j in 1..GP where GPlanned[t,j]) (
% %   GArrivee[t,j] >= GWindowStart[GTrajetGare[t,j]] /\
% %   GArrivee[t,j] <= GWindowEnd[GTrajetGare[t,j]]
% % );

% ------------------------------------------------------------------------------
% Contrainte de capacité de quai / flux (squelette)
% ------------------------------------------------------------------------------
% Si les quais / voies sont limités, on peut utiliser une désagrégation temporelle (périodes 1..PNb)
% et introduire une variable binaire GActive[t,j,u] = 1 si le train t est actif (au centre) dans la période u
% pour le trajet j. Ensuite contraindre la somme des GActive sur une période u ≤ capacité de quai.
%
% Variables (optionnelles) :
% array[TId, 1..GP, 1..PNb] of var bool: GActive;
%
% Liaison possible :
% constraint forall(t in TId, j in 1..GP, u in 1..PNb) (
%   GActive[t,j,u] -> (GPlanned[t,j] /\ GArrivee[t,j] < u*P /\ GDepart[t,j] > (u-1)*P)
% );
%
% Capacité (exemple) :
% constraint forall(u in 1..PNb) (
%   sum(t in TId, j in 1..GP) ( bool2int(GActive[t,j,u]) ) <= TotalQuaisAvailable
% );

% ------------------------------------------------------------------------------
% Priorités / urgences / contraintes petites fenêtres
% ------------------------------------------------------------------------------
% Si certaines périodes de trajet sont critiques (p.ex. train à haute priorité doit arriver avant X),
% la donnée MUrgence[...] ou d'autres paramètres peuvent être utilisés pour contraindre GArrivee.
%
% Exemple (commenté) :
% constraint forall(t in TId where HighPriority[t]) (
%   exists(j in 1..GP)( GPlanned[t,j] /\ GArrivee[t,j] <= PriorityDeadline[t] )
% );

% ------------------------------------------------------------------------------
% Output (suggestion)
% ------------------------------------------------------------------------------
% output [
%   \"TRAJETS PLANIFIES:\\n\",
%   concat([ if GPlanned[t,j] then
%              \"Train \" ++ show(t) ++ \" periode=\" ++ show(j) ++ \" gare=\" ++ show(GTrajetGare[t,j]) ++ \" sens=\" ++ show(GTrajetSens[t,j]) ++ \" arrivee=\" ++ show(GArrivee[t,j]) ++ \" depart=\" ++ show(GDepart[t,j]) ++ \"\\n\"
%            else \"\" endif
%            | t in TId, j in 1..GP ])
% ];

% ==========================================================================================
% Fin du squelette trajets.mzn
% ==========================================================================================
