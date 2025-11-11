IFT-4001-projet/models/v1-basic/src/core/README.md#L1-200

# core/ — Types et utilitaires (documentation détaillée)

Ce répertoire contient la « bibliothèque » bas-niveau réutilisable du modèle `e-v1` :
les définitions de types (énums) et les fonctions utilitaires partagées. L'objectif est
d'offrir un point de vérité unique pour les types et des helpers robustes pour éviter
les duplications et faciliter la maintenance.

Table des matières

- But et philosophie
- Fichiers importants
- Fonctions exposées (signatures et exemples)
- Ordre d'inclusion recommandé
- Exemples d'usage pratiques
- Tests et validation
- Bonnes pratiques
- Contact / maintenance

But et philosophie

- Séparer clairement : types, utilitaires, constantes et contraintes.
- Garder `core/` léger, générique et indépendant des détails métier ; mettre le code spécifique
  aux contraintes dans `constraints/`.

Fichiers importants

- `core/types.mzn` — enums et alias de types (TType, TId, VType, VId, EType, SType, MType, OType, GSens, Plexite, ...). C'est la source de vérité des types.
- `core/utils.mzn` — fonctions utilitaires réutilisables :
  - calc_offsets, get_subarray, calc_offsets_2d, get_var_subarray_2d, get_linear_index, safe_sum_bool.
- `core/README.md` (ce fichier) — documentation et exemples d'utilisation.

Fonctions exposées (dans `core/utils.mzn`) — signatures et bref usage

- calc_offsets
  - Signature :
    `function array[$$E] of int: calc_offsets(array[$$E] of int: counts)`
  - Description :
    Calcule l'offset (index 1-based) de départ de chaque groupe dans un tableau linéarisé.
  - Exemple :
    ```
    % counts = [5,3,4] -> offsets = [1,6,9]
    array[int] of int: offsets = calc_offsets(counts);
    ```

- get_subarray
  - Signature :
    `function array[int] of $$T: get_subarray(array[int] of $$T: data, array[$$E] of int: offsets, array[$$E] of int: counts, $$E: m)`
  - Description :
    Retourne la portion de `data` correspondant au groupe `m`.
  - Exemple :
    ```
    array[int] of TId: trains_of_type = get_subarray(T, TOffsets, TNb, some_type);
    ```

- calc_offsets_2d
  - Signature :
    `function array[$$E1, $$E2] of int: calc_offsets_2d(array[$$E1, $$E2] of int: counts)`
  - Description :
    Même logique que `calc_offsets`, mais pour une matrice 2D de tailles.

- get_var_subarray_2d
  - Signature :
    `function array[int] of var $$T: get_var_subarray_2d(array[int] of var $$T: data, array[$$E1,$$E2] of int: offsets, array[$$E1,$$E2] of int: counts, $$E1: r, $$E2: c)`
  - Description :
    Extrait une slice de variables depuis un vecteur linéarisé, utile pour manipuler des variables d'un groupe.

- get_linear_index
  - Signature :
    `function int: get_linear_index(array[$$E1,$$E2] of int: offsets, $$E1: r, $$E2: c, int: item_in_group)`
  - Description :
    Convertit des coordonnées (r, c, item) en indice linéaire 1D.

- safe_sum_bool
  - Signature :
    `function int: safe_sum_bool(array[int] of bool: b, int: w)`
  - Description :
    Somme pondérée d'un tableau booléen : true -> w, false -> 0. Utile pour compter avec poids.

Ordre d'inclusion recommandé

- Pour éviter erreurs de dépendances, utiliser cet ordre dans `main.mzn` :
  ```
  include "core/types.mzn";    % enums
  include "core/utils.mzn";    % helpers génériques
  include "generic.mzn";       % constantes simples (HEURE, JOUR)
  include "constant.mzn";      % paramètres/données dépendants des types
  include "constraints/....mzn";
  ```

Exemples d'usage pratiques

- Construction d'un array linéarisé par type (dans `constant.mzn`) :

  ```
  array[TType] of int: TOffsets = calc_offsets(TNb);
  function array[int] of TId: ModTrains(TType: t) =
      get_subarray(T, TOffsets, TNb, t);
  ```

- Utilisation dans contraintes (techniciens) :
  ```
  let { int: idx_tech = get_linear_index(SOffsets, d, t, i) } in
    STemps[idx_tech, d] = sum(u in 1..SDTemps)( if STravail[idx_tech, u] then P else 0 endif );
  ```

Tests et validation

- À chaque modification de `core/utils.mzn`, exécuter un run rapide sur `models/e-v1/data/test/data_small.dzn` pour détecter les erreurs de syntaxe.
- Ajouter des petits exemples (mini-datasets) pour chaque nouvelle fonction afin d'avoir des tests manuels rapides.
- Optionnel : créer un script `scripts/validation/check_core.py` qui vérifie la présence des signatures attendues dans `core/utils.mzn`.

Bonnes pratiques pour les contributeurs

- Les nouveaux enums vont dans `core/types.mzn`.
- Les fonctions réutilisables vont dans `core/utils.mzn` uniquement si elles sont génériques ; sinon, elles restent dans le fichier `constraints` concerné.
- Documente toute fonction nouvellement ajoutée avec : signature, comportement, complexité (si pertinent) et un mini-exemple.
- Évite les includes circulaires. `core` doit être indépendant et inclusif (les autres fichiers incluent `core`, pas l'inverse).

Maintenance / évolution

- Si la bibliothèque grossit trop, scinder `core/utils.mzn` en modules (p.ex. `core/offsets.mzn`, `core/array_helpers.mzn`) et mettre à jour les includes.
- Garde `core/types.mzn` comme unique source de vérité des types.

Contact / auteur

- Complète `models/e-v1/config.json` (champ `maintainer`) pour indiquer le responsable du modèle.
- Pour toute question sur une fonction particulière, indique le nom de la fonction et le fichier ; je fournis un exemple d'utilisation ou un test minimal.
