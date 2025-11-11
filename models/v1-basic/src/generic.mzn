int: HEURE = 60;
int: JOUR = HEURE * 24;

% ==========================================================================================
% Calcul des offsets pour tableaux 1D
% ==========================================================================================
% Convertit un tableau 1D avec groupes en offsets (indices de début de chaque groupe)
% Dimension: array[E] → array[E]
% Exemple: Si counts = [5, 3, 4], offsets = [1, 6, 9]
%   - Groupe 1 commence à index 1 (5 éléments)
%   - Groupe 2 commence à index 6 (3 éléments)
%   - Groupe 3 commence à index 9 (4 éléments)
function array[$$E] of int: calc_offsets(array[$$E] of int: counts) =
    [m: 1 + sum([counts[m2] | m2 in index_set(counts) where m2 < m])
     | m in index_set(counts)];

% ==========================================================================================
% Extraction d'un sous-tableau 1D
% ==========================================================================================
% Récupère les éléments d'un groupe spécifique dans un tableau 1D linéaire
% Dimension: array[int] × array[E] × array[E] × E → array[int]
% Paramètres:
%   - data: tableau linéaire 1D contenant tous les éléments
%   - offsets: indices de début de chaque groupe (résultat de calc_offsets)
%   - counts: nombre d'éléments par groupe
%   - m: groupe à extraire
% Exemple: Si data = [a,b,c,d,e,f,g,h,i], offsets = [1,6,9], counts = [5,3,4]
%   - get_subarray(..., groupe_2) retourne [f,g,h]
function array[int] of $$T: get_subarray(
    array[int] of $$T: data,
    array[$$E] of int: offsets,
    array[$$E] of int: counts,
    $$E: m
) = [data[offsets[m] + i - 1] | i in 1..counts[m]];

% ==========================================================================================
% Extraction d'un sous-tableau 2D (variables)
% ==========================================================================================
% Récupère les variables d'un groupe spécifique dans un tableau 1D linéaire
% Dimension: array[int] de var T × array[E1,E2] × array[E1,E2] × E1 × E2 → array[int] de var T
% Paramètres:
%   - data: tableau linéaire 1D de variables
%   - offsets: indices de début pour chaque groupe (résultat de calc_offsets_2d)
%   - counts: nombre d'éléments par groupe (tableau 2D)
%   - r, c: groupe à extraire (ligne et colonne)
% Exemple: Récupérer le planning de tous les techniciens d'une division/type
function array[int] of var $$T: get_var_subarray_2d(
    array[int] of var $$T: data,
    array[$$E1, $$E2] of int: offsets,
    array[$$E1, $$E2] of int: counts,
    $$E1: r,
    $$E2: c
) = [data[offsets[r, c] + i - 1] | i in 1..counts[r, c]];

% ==========================================================================================
% Calcul des offsets pour tableaux 2D
% ==========================================================================================
% Convertit un tableau 2D avec groupes en offsets pour accès linéaire 1D
% Dimension: array[E1, E2] → array[E1, E2]
% Paramètres:
%   - counts: tableau 2D où counts[r,c] = nombre d'éléments du groupe (r,c)
% Retour: tableau 2D où offsets[r,c] = indice linéaire du début du groupe (r,c)
% Exemple: Si counts = [[5,3], [4,2]], offsets = [[1,6], [9,13]]
%   - Groupe (1,1) commence à index 1 (5 éléments)
%   - Groupe (1,2) commence à index 6 (3 éléments)
%   - Groupe (2,1) commence à index 9 (4 éléments)
%   - Groupe (2,2) commence à index 13 (2 éléments)
function array[$$E1, $$E2] of int: calc_offsets_2d(
    array[$$E1, $$E2] of int: counts
) = array2d(index_set_1of2(counts), index_set_2of2(counts), [
    let {
        % Somme de tous les éléments avant cette ligne
        int: before_rows = sum([sum([counts[r2, c2] | c2 in index_set_2of2(counts)])
                               | r2 in index_set_1of2(counts) where r2 < r]),
        % Somme dans cette ligne avant cette colonne
        int: before_cols = sum([counts[r, c2] | c2 in index_set_2of2(counts) where c2 < c])
    } in
    1 + before_rows + before_cols
    | r in index_set_1of2(counts), c in index_set_2of2(counts)
]);

% ==========================================================================================
% Conversion indice 2D vers 1D linéaire
% ==========================================================================================
% Convertit des coordonnées 2D (groupe, élément) en indice linéaire 1D
% Dimension: array[E1, E2] × E1 × E2 × int → int
% Paramètres:
%   - offsets: offsets 2D (résultat de calc_offsets_2d)
%   - r, c: groupe (ligne, colonne)
%   - item_in_group: numéro de l'élément dans le groupe (1-indexed)
% Retour: indice linéaire dans le tableau 1D
% Exemple: Pour accéder au 3ème technicien du groupe (division=1, type=2)
%   - get_linear_index(SOffsets, 1, 2, 3) retourne l'indice dans STravail[1..SNb]
function int: get_linear_index(
    array[$$E1, $$E2] of int: offsets,
    $$E1: r,
    $$E2: c,
    int: item_in_group
) = offsets[r, c] + (item_in_group - 1);
