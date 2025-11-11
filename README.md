# IFT-4001 / IFT-7020 Projet

Ce projet modélise et résout un problème de planification de maintenance ferroviaire. L'objectif est d'automatiser la génération de plannings optimisés pour réduire le temps et les erreurs liés aux processus manuels (Excel).

Le problème combine l'ordonnancement, l'affectation de ressources et des contraintes temporelles et opérationnelles (fenêtres temporelles, compétences des équipes, capacité d'atelier, priorités, replanification rapide).

---

## Prérequis

### Gestionnaire de paquets Nix (recommandé)

Le projet supporte Nix pour la reproductibilité des environnements. Voir https://nixos.org/ pour l'installation.

### Dépendances sans Nix

- `just` (exécuteur de recettes)
- `texlive-full` (distribution LaTeX)
- `texlab` (serveur LSP LaTeX)

Voir les sections plus bas pour les commandes d'installation sur Windows / macOS / Debian.

---

## Installation rapide

1. Cloner le dépôt :

   ```
   git clone git@github.com:untypequicode/IFT-4001-projet.git
   cd IFT-4001-projet
   ```

2. Entrer dans l'environnement (Nix) :
   ```
   nix-shell
   ```

---

## Structure du projet (résumé)

La hiérarchie principale a été centralisée et normalisée. Les changements importants :

- le modèle existant `e-v1` a été renommé en `v1-basic` (historique préservé via `git mv`).
- les sources MiniZinc sont centralisées dans `models/v1-basic/src/`.
- les résultats précédents `output/e-v1` ont été renommés `output/v1-basic`.

Arborescence principale (extrait) :

- `default.nix` — Configuration Nix
- `README.md` — Documentation principale (ce fichier)
- `requirements.txt` — Dépendances Python (si utilisées)
- `solve.sh` — Script de résolution (si présent)
- `.gitignore`
- `docs/`
  - `proposition/` — Proposition initiale (LaTeX)
  - `rapport-final/` — Rapport court (LaTeX)
  - `modeles/` — Documentation technique (nouveau)
- `models/`
  - `v1-basic/` — Modèle de base (MiniZinc)
    - `config.json`
    - `src/` (contient `main.mzn`, `constant.mzn`, `generic.mzn`, et sous-dossiers `core/`, `constraints/` si présents)
    - `data/` (schema, `test/`, `prod/`, `generators/`)
    - `docs/` (explications du modèle)
  - `v2-optimized/` — Modèle optimisé (squelette)
  - `v3-decomposition/` — Approche par décomposition (squelette)
- `output/`
  - `v1-basic/` — Solutions et exports pour v1
  - `v2-optimized/` — (même structure prévue)
  - `comparisons/` — Comparaisons inter-modèles, benchmarks
- `scripts/` — Scripts utilitaires (export, validation, analyse, latex, utils)
  - `export/` (exporters, templates)
  - `validation/`
  - `analysis/`
  - `latex/`
  - `utils/`
- `tests/` — Tests unitaires / fixtures

Remarque : les renommages/centralisations ont été effectués en conservant l'historique Git (opérations `git mv`). Les sources MiniZinc précédemment dans la racine `src/` ont été déplacées dans `models/v1-basic/src/`.

---

## Utilisation (rappels)

- Construire les documents LaTeX :

  ```
  just build
  ```

- Nettoyer :

  ```
  just clean
  ```

- Lister les recettes `just` :

  ```
  just --list
  ```

- Compiler manuellement LaTeX :
  ```
  pdflatex main.tex
  ```

---

## Notes pour les développeurs

- Si tu ajoutes de nouveaux modèles, place-les sous `models/` avec la même convention (`vX-name`) et un `README.md` explicite.
- Place les données de test dans `models/<model>/data/test/` et les scénarios de production dans `models/<model>/data/prod/`.
- Les exportateurs et scripts d'analyse doivent écrire dans `output/<model>/` pour garder une structure propre.
- Mettre à jour `docs/modeles/` pour documenter les changements d'architecture entre versions de modèles.

---

Si tu veux, je peux :

- ajouter des stubs pour les scripts listés (`scripts/`) et les tests (`tests/`),
- générer une arborescence README plus détaillée automatiquement,
- ou commiter les `git mv` et nouveaux fichiers dans une branche spécifique.

Indique ce que tu préfères faire ensuite.
