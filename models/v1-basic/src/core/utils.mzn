% ==========================================================================================
% core/utils.mzn
% Fonctions utilitaires réutilisables pour les modèles MiniZinc (v1-basic)
% Contient :
%  - calc_offsets : calcul des offsets pour tableaux groupés 1D
%  - get_subarray  : extraction d'un sous-tableau 1D
%  - calc_offsets_2d: calcul des offsets pour tableaux groupés 2D
%  - get_var_subarray_2d: extraction d'un sous-tableau 2D (variables linéarisées)
%  - get_linear_index: conversion d'un indice (r,c,item) vers index linéaire 1D
%
% Chaque fonction est écrite de manière générique (utilise les placeholders $$E, $$T, $$E1, $$E2)
% pour être réutilisable dans plusieurs contextes du modèle.
%
% Notes :
% - Ces fonctions opèrent sur des tableaux 1-indexés (convention MiniZinc).
% - Les fonctions 2D supposent que la structure de `counts` est rectangulaire.
% ==========================================================================================

% ==========================================================================================
% calc_offsets : offsets pour tableau 1D groupé
% Entrée :
%   counts : array[$$E] of int  (nombre d'éléments dans chaque groupe)
% Sortie :
%   array[$$E] of int contenant l'indice (1-indexé) du début de chaque groupe
% Exemple :
%  counts = [5,3,4] -> offsets = [1,6,9]
% ==========================================================================================
function array[$$E] of int: calc_offsets(array[$$E] of int: counts) =
    [ 1 + sum([ counts[m2] | m2 in index_set(counts) where m2 < m ])
      | m in index_set(counts) ];

% ==========================================================================================
% get_subarray : extraction d'un sous-tableau depuis une représentation linéaire 1D
% Entrée :
%   data    : array[int] of $$T     (tableau linéaire contenant les éléments de tous les groupes)
%   offsets : array[$$E] of int     (résultat de calc_offsets)
%   counts  : array[$$E] of int     (nombre d'éléments par groupe)
%   m       : $$E                   (groupe à extraire)
% Sortie :
%   array[int] of $$T contenant les éléments du groupe m
% ==========================================================================================
function array[int] of $$T: get_subarray(
    array[int] of $$T: data,
    array[$$E] of int: offsets,
    array[$$E] of int: counts,
    $$E: m
) =
    [ data[offsets[m] + i - 1] | i in 1..counts[m] ];

% ==========================================================================================
% calc_offsets_2d : offsets pour tableau 2D groupé
% Entrée :
%   counts : array[$$E1, $$E2] of int  (nombre d'éléments par groupe (r,c))
% Sortie :
%   array[$$E1, $$E2] of int avec l'indice linéaire (1-indexé) du début de chaque groupe
%
% Logique :
%  - parcours par lignes (r croissant), puis colonnes (c croissant)
%  - offset(r,c) = 1 + total des éléments des groupes précédents (lignes + colonnes antérieures)
% ==========================================================================================
function array[$$E1, $$E2] of int: calc_offsets_2d(
    array[$$E1, $$E2] of int: counts
) =
    array2d(index_set_1of2(counts), index_set_2of2(counts),
           [ let {
               int: before_rows = sum([ sum([ counts[r2, c2] | c2 in index_set_2of2(counts) ])
                                        | r2 in index_set_1of2(counts) where r2 < r ]),
               int: before_cols = sum([ counts[r, c2] | c2 in index_set_2of2(counts) where c2 < c ])
             } in
             1 + before_rows + before_cols
             | r in index_set_1of2(counts), c in index_set_2of2(counts)
           ] );

% ==========================================================================================
% get_var_subarray_2d : extraction d'un sous-ensemble linéarisé de variables (2D → 1D)
% Entrée :
%   data    : array[int] of var $$T         (tableau linéaire de variables)
%   offsets : array[$$E1, $$E2] of int      (résultat de calc_offsets_2d)
%   counts  : array[$$E1, $$E2] of int      (nombre d'éléments par groupe)
%   r, c    : $$E1, $$E2                    (coordonnées du groupe)
% Sortie :
%   array[int] of var $$T contenant les variables correspondant au groupe (r,c)
% ==========================================================================================
function array[int] of var $$T: get_var_subarray_2d(
    array[int] of var $$T: data,
    array[$$E1, $$E2] of int: offsets,
    array[$$E1, $$E2] of int: counts,
    $$E1: r,
    $$E2: c
) =
    [ data[offsets[r, c] + i - 1] | i in 1..counts[r, c] ];

% ==========================================================================================
% get_linear_index : conversion coordonnée (r, c, item_in_group) -> index linéaire 1D
% Entrée :
%   offsets : array[$$E1, $$E2] of int  (résultat de calc_offsets_2d)
%   r, c    : $$E1, $$E2                (coordonnées du groupe)
%   item_in_group : int                 (position (1-indexed) dans le groupe)
% Sortie :
%   int : indice linéaire correspondant dans le tableau 1D
% ==========================================================================================
function int: get_linear_index(
    array[$$E1, $$E2] of int: offsets,
    $$E1: r,
    $$E2: c,
    int: item_in_group
) = offsets[r, c] + (item_in_group - 1);

% ==========================================================================================
% Small helpers (optionnels)
% - safe_sum_bool: somme pondérée d'un tableau booléen en remplaçant false par 0 et true par w
% ==========================================================================================
function int: safe_sum_bool(array[int] of bool: b, int: w) =
    sum(i in index_set(b))( if b[i] then w else 0 endif );

% ==========================================================================================
% Fin de core/utils.mzn
% ==========================================================================================
