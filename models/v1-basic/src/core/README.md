IFT-4001-projet/models/v1-basic/src/core/README.md#L1-200
# core/ — Types et utils

Ce répertoire contient les définitions partagées et les utilitaires réutilisables pour le modèle `v1-basic`.
Il vise à centraliser les types (énums) et les fonctions utilitaires afin d'éviter les duplications et de faciliter la maintenance.

Objectifs
- Centraliser les définitions de types (énums) dans `core/types.mzn`.
- Regrouper les fonctions utilitaires réutilisables dans `core/utils.mzn`.
- Forcer un seul point de vérité pour les types et les helpers, afin d'éviter les répétitions entre `generic.mzn`, `constant.mzn`, etc.
- Donner des conventions claires pour l'ajout de nouveaux éléments.

Fichiers principaux
- `core/types.mzn` : déclarations `enum` et alias de types.
- `core/utils.mzn` : fonctions utilitaires (offsets, extraction de sous-tableaux, conversion d'indices, helpers).

Conventions générales
- Ne déclare pas d'`enum` dans `constant.mzn` ni dans `generic.mzn`. Toutes les `enum` doivent vivre exclusivement dans `core/types.mzn`.
- `constant.mzn` importe `core/types.mzn` (via `include "core/types.mzn";`) et ne contient que des paramètres / tableaux / constantes dépendants des types.
- `generic.mzn` conserve uniquement des constantes globales simples (p.ex. HEURE, JOUR) et de la documentation : les fonctions utilitaires doivent être dans `core/utils.mzn`.
- Nomme les fonctions utilitaires de façon descriptive et sans préfixes ambigus. Exemple : `calc_offsets`, `get_subarray`, `get_linear_index`.

Ordre d'inclusion recommandé
Dans `main.mzn`, respecter cet ordre d'inclusion pour que les dépendances soient satisfaites :
```models/v1-basic/src/main.mzn#L1-8
include "core/types.mzn";
include "core/utils.mzn";
include "generic.mzn";
include "constant.mzn";
include "constraints/techniciens.mzn";
include "constraints/maintenances.mzn";
```

Fonctions exposées (dans `core/utils.mzn`)
- `function array[$$E] of int: calc_offsets(array[$$E] of int: counts)`
  Calcule la position de départ (offset) de chaque groupe dans un tableau linéarisé.
- `function array[int] of $$T: get_subarray(array[int] of $$T: data, array[$$E] of int: offsets, array[$$E] of int: counts, $$E: m)`
  Extrait le sous-tableau correspondant au groupe `m`.
- `function array[$$E1, $$E2] of int: calc_offsets_2d(array[$$E1, $$E2] of int: counts)`
  Version 2D de `calc_offsets`.
- `function array[int] of var $$T: get_var_subarray_2d(array[int] of var $$T: data, array[$$E1,$$E2] of int: offsets, array[$$E1,$$E2] of int: counts, $$E1: r, $$E2: c)`
  Extrait des variables linéarisées pour un couple (r,c).
- `function int: get_linear_index(array[$$E1,$$E2] of int: offsets, $$E1: r, $$E2: c, int: item_in_group)`
  Convertit (r,c,item) → indice linéaire 1D.
- `function int: safe_sum_bool(array[int] of bool: b, int: w)`
  Somme pondérée d'un tableau booléen (utile pour convertir des booléens en poids).

Pourquoi cette séparation ?
- Lisibilité : les types sont visibles d'un coup d'œil et ne sont pas disséminés.
- Réutilisabilité : plusieurs fichiers peuvent inclure `core/utils.mzn` sans duplication.
- Maintenance : changer un enum ou une fonction se fait en un seul endroit, réduit le risque d'incohérence.

Bonnes pratiques pour ajouter du code
- Si tu ajoutes un nouvel enum : place-le dans `core/types.mzn`.
- Si tu écris une fonction utilitaire générique : ajoute-la dans `core/utils.mzn` si elle est utile à plusieurs fichiers. Documente la signature et le comportement (exemples d'entrée/sortie).
- Si la fonction est spécifique à un constraint file, place-la dans ce fichier plutôt que dans `core/`.
- Évite d'ajouter des dépendances circulaires (fichiers qui s'incluent mutuellement). Préfère que `constant.mzn` inclue `core/types.mzn` et `core/utils.mzn`, jamais l'inverse.

Exemples d'utilisation
- Exemple d'extraction d'un sous-tableau (dans `constant.mzn` ou un constraint) :
```models/v1-basic/src/constant.mzn#L20-28
array[TType] of int: TOffsets = calc_offsets(TNb);
function array[int] of TId: ModTrains(TType: t) =
    get_subarray(T, TOffsets, TNb, t);
```

- Exemple simple d'appel à `get_linear_index` (dans un fichier de contraintes) :
```models/v1-basic/src/constraints/techniciens.mzn#L1-12
let {
  int: idx_tech = get_linear_index(SOffsets, d, t, i)
} in
  STemps[idx_tech, d] = sum(u in 1..SDTemps)( if STravail[idx_tech, u] then P else 0 endif );
```

Tests et validation
- Quand tu modifies `core/utils.mzn`, exécute rapidement un run sur `data_small.dzn` pour détecter les erreurs de syntaxe ou d'include.
- Documente toute nouvelle fonction et ajoute un exemple de mini-usage dans le commentaire du fichier (ou dans `core/README.md`).

Notes finales
- Ce répertoire est la "bibliothèque standard" du modèle v1-basic : garde-le propre et évite d'y mettre du code spécifique non réutilisable.
- Si tu veux renommer `utils.mzn` en `helpers.mzn` ou scinder les fonctions en plusieurs fichiers (p.ex. `core/offsets.mzn`, `core/array_helpers.mzn`), on peut le faire mais il faut alors mettre à jour tous les `include` de façon cohérente.

Auteur / contact
- Si tu as des questions sur une fonction ou une inclusion, dis-moi quel fichier/ligne et je t'explique/commenterai l'usage.
