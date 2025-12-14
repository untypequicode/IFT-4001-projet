# Modèle MiniZinc pour la Planification de Maintenance Ferroviaire

Ce répertoire contient le modèle MiniZinc pour résoudre un problème de planification de maintenance ferroviaire modélisé comme un **RCPSP** (Resource-Constrained Project Scheduling Problem).

## Fichiers

- **`model.mzn`** : Modèle MiniZinc principal contenant toutes les contraintes et la fonction objectif
- **`data_example.dzn`** : Fichier de données d'exemple pour tester le modèle

## Structure du Modèle

### Entités Principales

Le modèle gère les entités suivantes :

- **Trains** : Arrivent et partent avec des fenêtres temporelles définies
- **Maintenances** : Liées aux trains (relation 1-N), caractérisées par des priorités et des dates butoirs
- **Opérations** : Liées aux maintenances (relation 1-N), nécessitent des ressources spécifiques
- **Voies** : Ressources exclusives (une opération à la fois par voie)
- **Techniciens** : Ressources multiples avec limites par type (nombre total, temps min/max)
- **Équipements** : Ressources multiples avec capacité simultanée

### Contraintes Implémentées

Le modèle implémente les contraintes suivantes :

1. **Fenêtres temporelles** : Les opérations doivent être exécutées dans la fenêtre temporelle du train associé
2. **Hiérarchie maintenance-opérations** : Toutes les opérations d'une maintenance doivent être complétées pour que la maintenance soit terminée
3. **Précédence entre opérations** : Ordre d'exécution des opérations avec temps de setup entre opérations consécutives
4. **Non-chevauchement sur voie** : Les opérations du même train sur la même voie ne peuvent pas se chevaucher
5. **Setup entre trains** : Temps de setup requis sur une voie lorsqu'on passe d'un train à un autre
6. **Capacité des voies** : Chaque voie est une ressource exclusive (une opération à la fois)
7. **Ressources techniciens** : Contrainte de capacité par type de technicien (vérifiée à chaque instant)
8. **Ressources équipements** : Contrainte de capacité avec limite de capacité simultanée par équipement
9. **Équipement sur voie** : Compatibilité entre équipements et voies (matrice de disponibilité)
10. **Limites de temps techniciens** : Contraintes sur le temps minimum et maximum de travail par type de technicien

### Fonction Objectif

Le modèle minimise le **retard pondéré total** :

```
∑(priority[m] × max(0, end_maint[m] - due_date[m]))
```

Où :
- `priority[m]` est la priorité de la maintenance m (1 pour urgente, 2 pour préventive)
- `end_maint[m]` est le temps de fin de la maintenance m
- `due_date[m]` est la date butoir idéale de la maintenance m

Les maintenances urgentes (priority=1) ont un poids plus élevé dans la fonction objectif que les maintenances préventives (priority=2).

## Utilisation

### Créer vos propres données

Pour créer un nouveau fichier de données, suivez la structure de `data_example.dzn` :

1. Définissez les ensembles (TRAIN, MAINT, OP, TRACK, TECH, EQUIP)
2. Spécifiez les paramètres des trains (arrival, departure, train_complexity)
3. Définissez les maintenances et leurs relations aux trains (maint_train)
4. Spécifiez les priorités, périodicités, dates butoirs et dernières exécutions des maintenances
5. Définissez les opérations et leurs relations aux maintenances (op_maint)
6. Spécifiez les durées, types de voie requis et précédences des opérations
7. Définissez les ressources (techniciens avec limites, équipements avec capacités)
8. Définissez les matrices de relations N-N (tech_required, equip_required, equip_available_on_track)

**Important** : Pour les tableaux 2D dans les fichiers `.dzn`, utilisez la fonction `array2d()` :

```minizinc
tech_required = array2d(OP, TECH, [
    2, 0, 0,
    1, 1, 0,
    ...
]);
```

### Exécution du modèle

Pour exécuter le modèle avec un fichier de données :

```bash
minizinc model.mzn data_example.dzn
```

Pour spécifier un solveur et un timeout :

```bash
minizinc --solver chuffed --time-limit 600000 model.mzn data_example.dzn
```

## Personnalisation

### Modifier les contraintes

Le modèle est modulaire. Vous pouvez :

- Commenter ou décommenter des contraintes dans `model.mzn`
- Ajouter de nouvelles contraintes selon vos besoins
- Modifier la fonction objectif (par exemple, minimiser le makespan)

### Ajuster les paramètres de setup

Les contraintes de setup peuvent être ajustées selon vos besoins :
- `setup_time_between_trains` : Temps de setup entre trains différents
- `setup_time_between_ops` : Temps de setup entre opérations consécutives

## Notes Techniques

- **Horizon temporel** : Le modèle utilise un horizon d'une journée (1440 minutes)
- **Vérification des ressources** : Les contraintes de ressources sont vérifiées aux instants de début de chaque opération pour garantir la cohérence
- **Types de voie** : La contrainte sur les types de voie peut être affinée si vous avez un mapping explicite voie-type dans vos données

## Dépannage

### Le solveur ne trouve pas de solution

Si le solveur ne trouve pas de solution, vérifiez :

1. Les fenêtres temporelles sont réalistes et permettent d'exécuter toutes les opérations
2. Les ressources sont suffisantes (nombre de techniciens, équipements disponibles)
3. Le temps limite de résolution est suffisant (augmentez avec `--time-limit`)
4. Essayez un autre solveur (Chuffed, Gecode, OR-Tools)
5. Les contraintes de précédence ne créent pas de cycles impossibles

### Erreur de syntaxe

Vérifiez que :

- Tous les ensembles sont définis (TRAIN, MAINT, OP, etc.)
- Tous les paramètres sont initialisés avec des valeurs valides
- Les dimensions des tableaux correspondent aux ensembles définis
- Les tableaux 2D utilisent `array2d()` dans les fichiers `.dzn`

### Erreur "UNSATISFIABLE"

Si le modèle est insatisfiable :

1. Vérifiez que les fenêtres temporelles permettent d'exécuter toutes les opérations avec leurs durées
2. Vérifiez que les ressources sont suffisantes (techniciens, équipements, voies)
3. Vérifiez que les contraintes de précédence sont cohérentes (pas de cycles)
4. Vérifiez que les contraintes de setup ne rendent pas le problème impossible
5. Essayez de relâcher temporairement certaines contraintes pour identifier le problème

### Timeout

Si le solveur atteint le timeout :

1. Augmentez le temps limite avec `--time-limit`
2. Essayez un autre solveur (OR-Tools est souvent plus performant sur ce type de problème)
3. Simplifiez l'instance (réduisez le nombre d'opérations ou de trains)
4. Vérifiez que l'instance n'est pas trop contrainte (relâchez certaines contraintes si nécessaire)
