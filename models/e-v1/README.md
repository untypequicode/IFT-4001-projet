# Modèle de Planification de Maintenance (e-v1)

Ce répertoire contient l'implémentation **e-v1** du modèle de programmation par contraintes (CP) en MiniZinc. Cette variante se distingue par une gestion fine et flexible des horaires des techniciens (gestion des pauses et blocs de travail) et une planification détaillée des opérations de maintenance.

## 📂 Structure du Code

Le modèle est modulaire pour séparer la logique de contraintes des données et des pré-calculs :

| Fichier              | Description                                                                                                     |
| :------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **`main.mzn`**       | Point d'entrée principal. Définit l'objectif d'optimisation (`TotalRetard`) et gère les sorties (Gantt ASCII).  |
| **`constant.mzn`**   | Définition des paramètres d'entrée (schéma de données : Jours, Gares, Trains, etc.).                            |
| **`computed.mzn`**   | Moteur de pré-calculs. Transforme les intervalles bruts en données indexées et filtre les fenêtres infaisables. |
| **`generic.mzn`**    | Contient les énumérations (`GSens`) et paramètres globaux (ex: règles de pauses min/max).                       |
| **`format_mzn.sh`**  | Script Bash utilitaire pour aligner automatiquement les commentaires du code.                                   |
| **`constraints/`**   | Dossier contenant les modules de logique métier.                                                                |
| ↳ `maintenances.mzn` | Contraintes sur les trains : activation, fenêtres de temps, voies et dépendances d'opérations.                  |
| ↳ `techniciens.mzn`  | Contraintes sur les ressources humaines : shifts flexibles, blocs de travail et pauses dynamiques.              |

## 🧠 Fonctionnalités et Logique

### 1\. Planification des Maintenances (`maintenances.mzn`)

Le modèle détermine pour chaque instance de maintenance requise :

- **Statut :** Active ou reportée (avec pénalité).
- **Horaires :** Début et fin précis respectant la disponibilité du train au centre de maintenance.
- **Infrastructure :** Choix d'une voie compatible avec le type d'opération.
- **Précédence :** Respect de l'ordre des opérations (ex: Opération A avant B).

### 2\. Gestion Avancée des Techniciens (`techniciens.mzn`)

Contrairement à une approche simplifiée, ce module gère la journée de travail comme une séquence de blocs :

- **Blocs & Pauses :** La journée est divisée en blocs de travail séparés par des pauses. Le nombre de pauses est contraint dynamiquement (`MinPauses` / `MaxPauses`).
- **Compétences :** Un technicien ne peut effectuer une tâche que s'il possède la qualification requise (Type de shift).
- **Continuité :** Une opération doit être entièrement incluse dans un bloc de travail continu.

### 3\. Objectif d'Optimisation (`main.mzn`)

Le solveur minimise la variable `TotalRetard`, calculée comme suit :

- **Retard :** Différence entre la fin réelle et la deadline théorique.
- **Pénalité Report :** Coût fixe élevé (10 000) pour toute maintenance non planifiée.
- **Priorité :** Les maintenances de périodicité critique (type 0) ont un poids multiplié par 100.

## 📊 Entrées et Sorties

### Entrées

Le modèle consomme des fichiers `.dzn` situés dans le dossier `../../instances/`. Il utilise les paramètres définis dans `constant.mzn` (Horizons, Gares, Voies, Équipements, etc.).

### Sorties (Output)

L'exécution produit une sortie textuelle riche comprenant :

1.  **Listing :** Liste des maintenances actives, horaires et retards.
2.  **Gantt Trains (ASCII) :** Visualisation de la présence des trains (`[]`), des maintenances (`Chiffre`) et des opérations.
3.  **Gantt Techniciens (ASCII) :** Visualisation des périodes travaillées (`#`) et des tâches (`Chiffre`).

Exemple de visualisation générée par `main.mzn` :

```text
TRAIN 1 (Type 1)
  Dispo : [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
  Maint : ............................111111111111........................................
  Op 01 : ............................1111................................................
```

## 🚀 Utilisation

Pour exécuter ce modèle depuis la racine du projet (nécessite MiniZinc installé) :

```bash
# Exemple avec le solveur Chuffed
minizinc --solver chuffed models/e-v1/main.mzn instances/small_01_e-v1.dzn
```

### Formatage du code

Un script est fourni pour maintenir la lisibilité du code (alignement des séparateurs) :

```bash
cd models/e-v1
./format_mzn.sh .
```
