# v1-basic

Modèle MiniZinc de base centralisé.

Structure des données:
- `models/v1-basic/data/test/data_small.dzn` : jeu de données petit (3 trains) pour tests rapides
- `models/v1-basic/data/test/data_medium.dzn` : jeu de données moyen (6 trains)
- `models/v1-basic/data/test/data_large.dzn` (alias de `data_full.dzn`) : jeu de données complet
- `models/v1-basic/data/prod/data_production.dzn` : copie du jeu complet pour usage production

Exécution :

minizinc models/v1-basic/src/main.mzn models/v1-basic/data/test/data_small.dzn

(minizinc doit être installé localement)

