% ==========================================================================================
% core/utils.mzn
% Fonctions utilitaires réutilisables pour les modèles MiniZinc (v1-basic)
%
% Contient :
%  - calculer_decalages : calcul des indices de départ pour tableaux groupés 1D
%  - extraire_sous_tableau  : extraction d'un sous-tableau 1D
%  - calculer_decalages_2d: calcul des indices de départ pour tableaux groupés 2D
%  - extraire_sous_tableau_var_2d: extraction d'un sous-tableau 2D (variables)
%  - calculer_index_lineaire: conversion (r,c,item) vers index 1D
%  - Fonctions de logique temporelle (a_retour_avant, a_aller_apres, etc.)
%
% Notes :
% - Ces fonctions opèrent sur des tableaux 1-indexés.
% - Les fonctions 2D supposent une structure rectangulaire.
% ==========================================================================================

% ==========================================================================================
% calculer_decalages : Indices de départ pour tableau 1D groupé
% Entrée :
%   comptes : array[$$E] of int  (nombre d'éléments dans chaque groupe)
% Sortie :
%   array[$$E] of int contenant l'indice (1-indexé) du début de chaque groupe
% Exemple :
%  comptes = [5,3,4] -> decalages = [1,6,9]
% ==========================================================================================
function array[$$E] of int: calculer_decalages(array[$$E] of int: comptes) =
    [ 1 + sum([ comptes[m2] | m2 in index_set(comptes) where m2 < m ])
      | m in index_set(comptes) ];

% ==========================================================================================
% extraire_sous_tableau : Extraction depuis une représentation linéaire 1D
% Entrée :
%   donnees   : array[int] of $$T     (tableau linéaire complet)
%   decalages : array[$$E] of int     (résultat de calculer_decalages)
%   comptes   : array[$$E] of int     (nombre d'éléments par groupe)
%   m         : $$E                   (groupe à extraire)
% Sortie :
%   array[int] of $$T contenant les éléments du groupe m
% ==========================================================================================
function array[int] of $$T: extraire_sous_tableau(
    array[int] of $$T: donnees,
    array[$$E] of int: decalages,
    array[$$E] of int: comptes,
    $$E: m
) =
    [ donnees[decalages[m] + i - 1] | i in 1..comptes[m] ];

% ==========================================================================================
% calculer_decalages_2d : Indices de départ pour tableau 2D groupé
% Entrée :
%   comptes : array[$$E1, $$E2] of int  (nombre d'éléments par groupe (r,c))
% Sortie :
%   array[$$E1, $$E2] of int avec l'indice linéaire du début de chaque groupe
% ==========================================================================================
function array[$$E1, $$E2] of int: calculer_decalages_2d(
    array[$$E1, $$E2] of int: comptes
) =
    array2d(index_set_1of2(comptes), index_set_2of2(comptes),
           [ let {
               int: lignes_avant = sum([ sum([ comptes[r2, c2] | c2 in index_set_2of2(comptes) ])
                                        | r2 in index_set_1of2(comptes) where r2 < r ]),
               int: cols_avant   = sum([ comptes[r, c2] | c2 in index_set_2of2(comptes) where c2 < c ])
             } in
             1 + lignes_avant + cols_avant
             | r in index_set_1of2(comptes), c in index_set_2of2(comptes)
           ] );

% ==========================================================================================
% extraire_sous_tableau_var_2d : Extraction sous-ensemble de variables (2D → 1D)
% Entrée :
%   donnees   : array[int] of var $$T     (tableau linéaire de variables)
%   decalages : array[$$E1, $$E2] of int  (résultat de calculer_decalages_2d)
%   comptes   : array[$$E1, $$E2] of int  (nombre d'éléments par groupe)
%   r, c      : $$E1, $$E2                (coordonnées du groupe)
% Sortie :
%   array[int] of var $$T contenant les variables du groupe (r,c)
% ==========================================================================================
function array[int] of var $$T: extraire_sous_tableau_var_2d(
    array[int] of var $$T: donnees,
    array[$$E1, $$E2] of int: decalages,
    array[$$E1, $$E2] of int: comptes,
    $$E1: r,
    $$E2: c
) =
    [ donnees[decalages[r, c] + i - 1] | i in 1..comptes[r, c] ];

% ==========================================================================================
% calculer_index_lineaire : Conversion (r, c, item) -> Index 1D
% Entrée :
%   decalages : array[$$E1, $$E2] of int  (résultat de calculer_decalages_2d)
%   r, c      : $$E1, $$E2                (coordonnées du groupe)
%   item_pos  : int                       (position 1-indexée dans le groupe)
% Sortie :
%   int : indice linéaire correspondant
% ==========================================================================================
function int: calculer_index_lineaire(
    array[$$E1, $$E2] of int: decalages,
    $$E1: r,
    $$E2: c,
    int: item_pos
) = decalages[r, c] + (item_pos - 1);

% ==========================================================================================
% somme_ponderee_bool: Somme d'un tableau booléen (Vrai = poids w, Faux = 0)
% ==========================================================================================
function int: somme_ponderee_bool(array[int] of bool: b, int: w) =
    sum(i in index_set(b))( if b[i] then w else 0 endif );

% ==========================================================================================
% LOGIQUE SÉQUENTIELLE GÉNÉRIQUE (Compatible int, bool, enum)
% ==========================================================================================

% ------------------------------------------------------------------------------------------
% verifier_sequence_gauche : Regarde l'élément actuel et le passé (gauche)
%
% Entrées :
%   - val_neutre      : La valeur "courante" (ex: gare, 1)
%   - val_cible       : La valeur qui déclenche/arrête la séquence (ex: retour, 2)
%   - accepter_bord   : True si le début du tableau est valide
%   - verifier_actuel : True pour forcer grille[ligne, t] == val_neutre
%
% Logique :
%   1. (Optionnel) Vérifie si la case actuelle est 'val_neutre'.
%   2. Vérifie si à gauche on a une chaîne de 'val_neutre' qui vient d'un 'val_cible' 
%      ou du bord.
% ------------------------------------------------------------------------------------------
function bool: verifier_sequence_gauche(
    array[int, int] of $$T: grille,
    int: ligne,
    int: t,
    $$T: val_neutre,
    $$T: val_cible,
    bool: accepter_bord,
    bool: verifier_actuel
) =
    let {
        % 1. Validation de la case courante (si demandé)
        bool: actuel_ok = if verifier_actuel then grille[ligne, t] == val_neutre else true endif;

        % 2. Recherche cible (ex: retour) vers la gauche
        bool: trouve_cible = exists(k in index_set_2of2(grille) where k < t)(
            grille[ligne, k] == val_cible /\ 
            forall(j in k+1..t-1)(grille[ligne, j] == val_neutre)
        );
        
        % 3. Vérification bord (Début)
        bool: atteint_bord = accepter_bord /\ 
            forall(k in index_set_2of2(grille) where k < t)(grille[ligne, k] == val_neutre);
            
    } in (actuel_ok /\ (trouve_cible \/ atteint_bord));

% ------------------------------------------------------------------------------------------
% verifier_sequence_droite : Regarde l'élément actuel et le futur (droite)
% ------------------------------------------------------------------------------------------
function bool: verifier_sequence_droite(
    array[int, int] of $$T: grille,
    int: ligne,
    int: t,
    $$T: val_neutre,
    $$T: val_cible,
    bool: accepter_bord,
    bool: verifier_actuel
) =
    let {
        % 1. Validation de la case courante (si demandé)
        bool: actuel_ok = if verifier_actuel then grille[ligne, t] == val_neutre else true endif;

        % 2. Recherche cible (ex: aller) vers la droite
        bool: trouve_cible = exists(k in index_set_2of2(grille) where k > t)(
            grille[ligne, k] == val_cible /\ 
            forall(j in t+1..k-1)(grille[ligne, j] == val_neutre)
        );
        
        % 3. Vérification bord (Fin)
        bool: atteint_bord = accepter_bord /\ 
            forall(k in index_set_2of2(grille) where k > t)(grille[ligne, k] == val_neutre);
            
    } in (actuel_ok /\ (trouve_cible \/ atteint_bord));

% ==========================================================================================
% Fin de core/utils.mzn
% ==========================================================================================