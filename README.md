# Planification de Maintenance Ferroviaire : Comparaison de Deux Modèles MiniZinc

![MiniZinc](https://img.shields.io/badge/MiniZinc-2.9.0-blue)
![Python](https://img.shields.io/badge/Python-3.x-green)
![LaTeX](https://img.shields.io/badge/LaTeX-Required-orange)
![Nix](https://img.shields.io/badge/Nix-Supported-lightblue)

## Résumé

Ce projet modélise et résout un problème de planification de maintenance ferroviaire en utilisant la programmation par contraintes (MiniZinc). Le problème est formulé comme un **Resource-Constrained Project Scheduling Problem (RCPSP)** avec des contraintes spécifiques au domaine ferroviaire : fenêtres temporelles strictes (possiblement multiples par train), temps de setup variables selon le contexte, et ressources multiples avec capacités simultanées.

Deux modèles MiniZinc distincts ont été développés et comparés sur trois solveurs (Chuffed, Gecode, OR-Tools) : **l-v1** avec vérification ponctuelle des ressources, et **e-v1** avec modélisation fine des techniciens par blocs de travail. Les expérimentations sur 8 instances de différentes tailles révèlent que OR-Tools est le solveur le plus robuste (15 instances sur 16 résolues), et que le modèle l-v1 présente des performances supérieures (temps 2 à 20 fois plus rapides) au prix d'une modélisation moins détaillée.

## Auteurs

- **Ethan Facca**
- **Léa Potin**

## Problématique

La planification de maintenance ferroviaire représente un défi opérationnel majeur pour les entreprises de transport. Avec des centaines de trains nécessitant des maintenances régulières, des fenêtres temporelles strictes, et des ressources limitées (voies, techniciens, équipements), ce problème présente toutes les caractéristiques d'un problème d'optimisation combinatoire complexe.

Le problème consiste à planifier les opérations de maintenance sur un horizon de plusieurs jours en respectant :

- Les fenêtres temporelles de présence des trains au centre de maintenance
- Les contraintes de précédence entre opérations avec temps de setup
- Les capacités limitées des ressources (voies exclusives, techniciens par type, équipements)
- Les contraintes de travail des techniciens (temps min/max, pauses)
- Les compatibilités entre voies et équipements
- La gestion dynamique des deadlines et des maintenances optionnelles

L'objectif est de minimiser le retard pondéré des maintenances par rapport à leurs dates butoirs, calculées en fonction de leur périodicité et de la dernière fois où elles ont été effectuées.

## Réalisations

Les réalisations principales de ce projet sont :

1. **Développement de deux modèles MiniZinc** avec des approches de modélisation différentes (modélisation fine des techniciens vs vérification ponctuelle)
2. **Évaluation expérimentale** sur 8 instances de différentes tailles (small, medium, large)
3. **Comparaison des performances** sur trois solveurs (Chuffed, Gecode, OR-Tools)
4. **Identification des facteurs de difficulté** et analyse de l'impact des choix de modélisation sur la performance

## Méthodologie

### Modèle l-v1 : Vérification ponctuelle

Architecture **monolithique** (1 fichier) utilisant les **minutes** comme unité temporelle. Chaque train a une **fenêtre unique** définie par son arrivée et son départ.

**Gestion des ressources par vérification ponctuelle :** Au lieu de créer une variable pour chaque technicien à chaque instant, le modèle vérifie simplement qu'à chaque début d'opération, la demande totale en techniciens ne dépasse pas la capacité disponible. Cette approche réduit le nombre de variables à seulement les temps et voies des opérations.

**Caractéristiques principales :**
- Horizon temporel : 1 jour (1440 minutes)
- Vérification ponctuelle des ressources (techniciens, équipements)
- Contraintes disjonctives explicites pour les non-chevauchements
- Toutes les maintenances doivent être planifiées (pas d'optionnalité)
- Objectif : minimiser le retard pondéré par priorité

Voir `models/l-v1/README.md` pour plus de détails.

### Modèle e-v1 : Modélisation fine et modulaire

Architecture **modulaire** (6 fichiers) utilisant les **périodes** comme unité temporelle (typiquement 15 minutes). L'horizon total est configurable sur plusieurs jours.

**Caractéristiques principales :**
- Horizon temporel : multi-jours (configurable)
- **Intervalles multiples** : un train peut avoir plusieurs fenêtres de présence durant l'horizon
- **Instances dynamiques de maintenances** : génération automatique avec possibilité de ne pas les planifier
- **Deadlines dynamiques** : propagation automatique des dates butoirs
- **Variables d'affectation** : assignation spécifique de techniciens aux opérations
- **Blocs de travail des techniciens** : planification explicite des horaires avec pauses obligatoires (1-3 par jour)
- **Objectif avec pénalités** : gestion des maintenances optionnelles avec pénalités fortes (10000) pour les non planifiées

Voir `models/e-v1/README.md` pour plus de détails.

### Comparaison des modèles

| Aspect | l-v1 | e-v1 |
|--------|------|------|
| Organisation | Monolithique | Modulaire |
| Unité temporelle | Minutes | Périodes |
| Fenêtres/train | 1 fixe | Multiples |
| Maintenances | Obligatoires | Optionnelles |
| Deadlines | Statiques | Dynamiques |
| Gestion techniciens | Vérif. ponctuelle | Blocs détaillés |
| Pauses | Non | Oui (1-3) |
| Affectation individuelle | Non | Oui |
| Complexité | Faible | Élevée |

## Résultats expérimentaux

Les expérimentations ont été réalisées avec un timeout de 10 minutes (600 secondes) sur 8 instances de différentes tailles :

- **Small** : small_01, small_02 (2 trains, 2-3 maintenances)
- **Medium** : medium_01, medium_02, medium_03 (3-4 trains, 4-5 maintenances)
- **Large** : large_01, large_02, large_03 (5-6 trains, 6-8 maintenances)

### Performance globale

**Modèle l-v1 :** Le modèle l-v1 montre des performances globalement meilleures sur les instances small et medium. Toutes les instances small sont résolues en moins de 6 secondes avec tous les solveurs. Les instances medium sont également bien gérées, avec des temps variant de 0.5s à 94s selon le solveur. Les instances large présentent plus de difficultés, avec 2 timeouts sur Gecode.

**Modèle e-v1 :** Le modèle e-v1 présente des temps de résolution systématiquement plus élevés que l-v1 (2 à 20 fois plus lents), reflétant sa complexité accrue due à la modélisation fine des blocs de travail des techniciens. Les instances medium et large présentent 4 timeouts.

**Impact de la modélisation :** La différence de performance s'explique par le nombre de variables : l-v1 utilise $O(|OP|)$ variables (temps et voies uniquement), tandis que e-v1 ajoute $O(|S| \times J \times B)$ variables pour les blocs de travail des techniciens, où $S$ est le nombre de techniciens, $J$ le nombre de jours, et $B$ le nombre de blocs par jour.

### Comparaison des solveurs

- **OR-Tools** : Le solveur le plus robuste sur les deux modèles (15 instances sur 16 résolues), avec une capacité à résoudre des instances que les autres abandonnent.
- **Gecode** : Excelle sur les petites instances de l-v1 mais peine sur e-v1 et les grandes instances.
- **Chuffed** : Montre des performances variables selon l'instance.

Pour une analyse détaillée des résultats, voir le rapport final (`docs/rapport-final/`).

## Prérequis

### Gestionnaire de paquets Nix (recommandé)

Le projet supporte Nix pour la reproductibilité des environnements. Voir https://nixos.org/ pour l'installation.

### Dépendances sans Nix

- **MiniZinc** (avec solveurs Chuffed, Gecode, OR-Tools)
- **Python 3** (pour les scripts de génération d'instances)
- **LaTeX** (pour la compilation des rapports)
- **`just`** (exécuteur de recettes, optionnel)

## Installation

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
│   ├── e-v1/                    # Modèle e-v1
│   │   ├── main.mzn             # Point d'entrée principal
│   │   ├── constant.mzn         # Paramètres d'entrée
│   │   ├── computed.mzn         # Pré-calculs
│   │   ├── generic.mzn          # Énumérations et constantes
│   │   ├── constraints/         # Modules de contraintes
│   │   │   ├── maintenances.mzn
│   │   │   └── techniciens.mzn
│   │   └── README.md
│   └── l-v1/                    # Modèle l-v1
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

## Solveurs supportés

Le projet a été testé avec les solveurs suivants :

- **Chuffed** : Solveur basé sur la propagation et la recherche locale
- **Gecode** : Solveur basé sur la propagation et le branchement
- **OR-Tools (CP-SAT)** : Solveur avec techniques avancées de propagation

Les performances varient selon le modèle et la complexité des instances. Voir le rapport final pour une analyse détaillée.

## Documentation

- **Rapport final** : `docs/rapport-final/main.pdf` (après compilation)
- **Proposition initiale** : `docs/proposition/main.pdf` (après compilation)
- **Documentation modèle l-v1** : `models/l-v1/README.md`
- **Documentation modèle e-v1** : `models/e-v1/README.md`

Les résultats des expérimentations sont stockés dans `results/`, organisés par modèle et solveur. Chaque fichier contient les métriques de résolution (temps, valeur objectif, statut) pour une combinaison instance-modèle-solveur.

## Perspectives futures

Les perspectives futures incluent :

- Générer plus d'instances pour une évaluation plus complète
- Développer des heuristiques personnalisées pour améliorer les performances
- Adapter les instances pour permettre une comparaison directe entre modèles
- Étendre la modélisation pour inclure d'autres contraintes réalistes
