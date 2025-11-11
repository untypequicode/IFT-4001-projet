# e-v1 (v1-basic)

Modèle MiniZinc de base centralisé pour la planification de maintenance ferroviaire.
Ce répertoire représente la version canonique du modèle (nommé `e-v1`). Le code est organisé
pour séparer clairement les définitions de types, les utilitaires, les constantes et les
fichiers de contraintes. Conservez les sources et les jeux de données sous ce dossier pour
l'exécution locale, les tests et la reproductibilité.

But

- Fournir un modèle de référence (v1-basic) regroupant les sources MiniZinc, les utilitaires et les jeux de données.
- Garder le code utilisateur original dans les bons fichiers et laisser des placeholders vides pour les parties non implémentées.

Structure du dossier

- `models/v1-basic/`
  - `config.json` : métadonnées du modèle (chemins, versions, run example).
  - `README.md` (ce fichier).
  - `src/` : code MiniZinc
    - `main.mzn` : fichier principal (inclut les fichiers `constant`, `core`, `constraints/*`)
    - `constant.mzn`, `generic.mzn` : constantes et helpers restaurés
    - `core/`
      - `types.mzn` : enums / types
      - `utils.mzn` : fonctions utilitaires (offsets, get_linear_index, ...)
    - `constraints/`
      - `techniciens.mzn` : ton code d'origine gérant les techniciens (restauré)
      - `maintenances.mzn` : placeholder (fichier minimal / TODO)
      - `operations.mzn` : placeholder (fichier minimal / TODO)
      - `trajets.mzn` : placeholder (fichier minimal / TODO)
  - `data/`
    - `test/`
      - `data_small.dzn` : petit jeu (3 trains) — tests rapides
      - `data_medium.dzn` : jeu moyen (6 trains)
      - `data_large.dzn` : jeu complet (alias de `data_full.dzn`)
      - `data_full.dzn` : jeu complet restauré depuis l'historique
      - `sample_data.dzn` : fixture minimale
    - `prod/`
      - `data_production.dzn` : copie du jeu complet pour usage production

Remarques sur le code

- J'ai conservé et placé ton code original (celui que tu avais écrit) dans :
  - `models/v1-basic/src/constraints/techniciens.mzn`
  - `models/v1-basic/src/constant.mzn`
  - `models/v1-basic/src/generic.mzn`
- Les fichiers `maintenances.mzn`, `operations.mzn`, `trajets.mzn` sont volontairement laissés comme placeholders (contenu minimal / TODO). Ils ne contiennent pas de contraintes opérationnelles actives tant que tu ne les remplis pas. Cela garantit que seul ton code existant est effectif.
- `core/utils.mzn` contient des utilitaires (offsets, extractions, get_linear_index) nécessaires au fonctionnement de ton code ; je les ai conservés car ils facilitent la lecture et la maintenance.

Configuration et métadonnées

- `models/v1-basic/config.json` contient les métadonnées du modèle : nom, version, chemin du `main`, jeux de données de test et prod, run example et outils recommandés.
- Exemple d'extrait :
  - `"main": "src/main.mzn"`
  - `"test_data": ["data/test/data_small.dzn", "data/test/data_medium.dzn", "data/test/data_large.dzn"]`
  - `"prod_data": "data/prod/data_production.dzn"`

Exécution locale (exemples)

- Exécution rapide (petit jeu) :
  ```
  minizinc models/v1-basic/src/main.mzn models/v1-basic/data/test/data_small.dzn
  ```
- Exécution avec solver recommandé :
  ```
  minizinc --solver Gecode models/v1-basic/src/main.mzn models/v1-basic/data/test/data_small.dzn
  ```
- Pour tester le jeu complet :
  ```
  minizinc models/v1-basic/src/main.mzn models/v1-basic/data/test/data_large.dzn
  ```

Bonnes pratiques

- Ne pousse pas ces changements tant que tu n'as pas validé localement (je n'ai rien poussé).
- Si tu veux réactiver/compléter les contraintes pour `maintenances`, `operations` ou `trajets`, je peux :
  - réinjecter des fragments historiques si tu as des commits précis à cibler, ou
  - t'aider à implémenter progressivement ces fichiers à partir des TODOs.
- Si tu veux que je découpe `data_full.dzn` différemment ou que j'ajoute des scénarios (data_small/medium ajustés), je peux le faire sans pousser.

Contact / auteur

- Mets à jour `models/v1-basic/config.json` (champ `maintainer`) avec ton nom et email si tu veux.
