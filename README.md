# IFT-4001 / IFT-7020 Projet

Ce projet modélise et résout un problème de planification de maintenance ferroviaire en utilisant la programmation par contraintes (MiniZinc). L'objectif est d'automatiser la génération de plannings optimisés pour réduire le temps et les erreurs liés aux processus manuels.

Le problème est modélisé comme un **RCPSP** (Resource-Constrained Project Scheduling Problem) et combine l'ordonnancement, l'affectation de ressources et des contraintes temporelles et opérationnelles (fenêtres temporelles, compétences des équipes, capacité d'atelier, priorités, replanification rapide).

## Auteurs

- Léa Potin
- Ethan Facca

## Prérequis

### Gestionnaire de paquets Nix (recommandé)

Le projet supporte Nix pour la reproductibilité des environnements. Voir https://nixos.org/ pour l'installation.

### Dépendances sans Nix

- MiniZinc (avec solveurs Chuffed, Gecode, OR-Tools)
- Python 3 (pour les scripts de génération d'instances)
- LaTeX (pour la compilation des rapports)
- `just` (exécuteur de recettes, optionnel)

## Installation rapide

1. Cloner le dépôt :

   ```bash
   git clone git@github.com:untypequicode/IFT-4001-projet.git
   cd IFT-4001-projet
   ```

2. Entrer dans l'environnement (Nix) :

   ```bash
   nix-shell
   ```

## Structure du projet

```
IFT-4001-projet/
├── README.md                    # Documentation principale
├── default.nix                  # Configuration Nix
├── docs/                        # Documentation et rapports
│   ├── proposition/             # Proposition initiale (LaTeX)
│   └── rapport-final/           # Rapport final (LaTeX)
│       ├── main.tex
│       ├── content/             # Sections du rapport
│       └── img/                 # Images et logos
├── models/                      # Modèles MiniZinc
│   ├── e-v1/                    # Modèle e-v1 (Ethan)
│   │   ├── main.mzn             # Point d'entrée principal
│   │   ├── constant.mzn         # Paramètres d'entrée
│   │   ├── computed.mzn         # Pré-calculs
│   │   ├── generic.mzn          # Énumérations et constantes
│   │   ├── constraints/         # Modules de contraintes
│   │   │   ├── maintenances.mzn
│   │   │   └── techniciens.mzn
│   │   └── README.md
│   └── l-v1/                    # Modèle l-v1 (Léa)
│       ├── model.mzn            # Modèle monolithique
│       ├── data_example.dzn     # Exemple de données
│       └── README.md
├── instances/                    # Instances de test
│   ├── configs/                 # Configurations JSON
│   │   ├── small_*.json
│   │   ├── medium_*.json
│   │   ├── large_*.json
│   │   └── multiday/            # Configurations multi-jours
│   ├── generator/               # Scripts de génération
│   │   ├── creer_config.py
│   │   └── generer_data.py
│   ├── small_*_l-v1.dzn         # Instances small pour l-v1
│   ├── small_*_e-v1.dzn         # Instances small pour e-v1
│   ├── medium_*_l-v1.dzn       # Instances medium pour l-v1
│   ├── medium_*_e-v1.dzn       # Instances medium pour e-v1
│   ├── large_*_l-v1.dzn        # Instances large pour l-v1
│   ├── large_*_e-v1.dzn        # Instances large pour e-v1
│   └── multiday/                # Instances multi-jours (e-v1)
├── results/                      # Résultats des expérimentations
│   ├── e-v1/                    # Résultats du modèle e-v1
│   │   ├── chuffed/
│   │   ├── gecode/
│   │   └── or-tools/
│   └── l-v1/                    # Résultats du modèle l-v1
│       ├── chuffed/
│       ├── gecode/
│       └── or-tools/
└── src/                          # Scripts utilitaires
```

## Modèles

Le projet contient deux modèles MiniZinc distincts avec des approches de modélisation différentes :

### Modèle l-v1 (Léa)

Architecture monolithique avec vérification ponctuelle des contraintes de ressources. Le modèle minimise le retard pondéré total des maintenances. Voir `models/l-v1/README.md` pour plus de détails.

**Caractéristiques principales :**
- Horizon temporel : 1 jour (1440 minutes)
- Vérification ponctuelle des ressources (techniciens, équipements)
- Contraintes disjonctives explicites pour les non-chevauchements

### Modèle e-v1 (Ethan)

Architecture modulaire avec modélisation fine des techniciens (blocs de travail, pauses, limites quotidiennes). Le modèle minimise une fonction objectif composée (retard pondéré, makespan, équité, inactivité). Voir `models/e-v1/README.md` pour plus de détails.

**Caractéristiques principales :**
- Horizon temporel : multi-jours (configurable)
- Modélisation fine des techniciens avec variables booléennes par période
- Gestion des blocs de travail journaliers et des pauses

## Instances de test

Huit instances de test ont été générées automatiquement, couvrant différentes tailles et complexités :

- **Small** : small_01, small_02 (2 trains, 2-3 maintenances)
- **Medium** : medium_01, medium_02, medium_03 (3-4 trains, 4-5 maintenances)
- **Large** : large_01, large_02, large_03 (5-6 trains, 6-8 maintenances)

Chaque instance existe en deux versions :
- `*_l-v1.dzn` : format pour le modèle l-v1
- `*_e-v1.dzn` : format pour le modèle e-v1

Les configurations JSON utilisées pour générer ces instances sont disponibles dans `instances/configs/`.

Des instances supplémentaires exploitant les capacités multi-jours du modèle e-v1 sont disponibles dans `instances/multiday/`.

## Utilisation

### Générer des instances

Pour générer de nouvelles instances, utilisez les scripts dans `instances/generator/` :

```bash
cd instances/generator
python creer_config.py  # Créer une configuration JSON
python generer_data.py  # Générer les fichiers .dzn à partir des configs
```

### Exécuter un modèle

Pour exécuter un modèle avec une instance :

```bash
# Modèle l-v1
minizinc models/l-v1/model.mzn instances/small_01_l-v1.dzn

# Modèle e-v1
minizinc models/e-v1/main.mzn instances/small_01_e-v1.dzn
```

Pour spécifier un solveur et un timeout :

```bash
minizinc --solver chuffed --time-limit 600000 models/l-v1/model.mzn instances/small_01_l-v1.dzn
```

### Compiler les documents LaTeX

Pour compiler le rapport final :

```bash
cd docs/rapport-final
just build
```

Ou manuellement :

```bash
cd docs/rapport-final
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

Pour nettoyer les fichiers temporaires :

```bash
just clean
```

## Résultats

Les résultats des expérimentations sont stockés dans `results/`, organisés par modèle et solveur. Chaque fichier contient les métriques de résolution (temps, valeur objectif, statut) pour une combinaison instance-modèle-solveur.

Les résultats sont analysés et présentés dans le rapport final (`docs/rapport-final/`).

## Documentation

- **Rapport final** : `docs/rapport-final/main.pdf` (après compilation)
- **Proposition initiale** : `docs/proposition/main.pdf` (après compilation)
- **Documentation modèle l-v1** : `models/l-v1/README.md`
- **Documentation modèle e-v1** : `models/e-v1/README.md`

## Notes pour les développeurs

- Les modèles sont indépendants et peuvent être modifiés séparément
- Les instances sont générées à partir de configurations JSON pour assurer la cohérence
- Les résultats doivent être organisés par modèle et solveur dans `results/`
- La documentation doit être mise à jour lors de modifications importantes des modèles

## Solveurs supportés

Le projet a été testé avec les solveurs suivants :

- **Chuffed** : Solveur basé sur la propagation et la recherche locale
- **Gecode** : Solveur basé sur la propagation et le branchement
- **OR-Tools (CP-SAT)** : Solveur avec techniques avancées de propagation

Les performances varient selon le modèle et la complexité des instances. Voir le rapport final pour une analyse détaillée.
