# Modèle MiniZinc pour la Planification de Maintenance Ferroviaire

Ce répertoire contient le modèle MiniZinc pour résoudre un problème de planification de maintenance ferroviaire modélisé comme un **RCPSP** (Resource-Constrained Project Scheduling Problem).

## 📁 Fichiers

- **`model.mzn`** : Modèle MiniZinc principal avec toutes les contraintes
- **`data_example.dzn`** : Fichier de données d'exemple pour tester le modèle


## 📊 Structure du Modèle

### Entités Principales

- **Trains** : Arrivent et partent avec des fenêtres temporelles
- **Maintenances** : Liées aux trains (1-N), ont des priorités et dates butoirs
- **Opérations** : Liées aux maintenances (1-N), nécessitent des ressources
- **Voies** : Ressources exclusives (une opération à la fois)
- **Techniciens** : Ressources multiples avec limites par type
- **Équipements** : Ressources multiples avec capacité simultanée

### Contraintes Implémentées

1. ✅ **Fenêtres temporelles** : Les opérations doivent être dans la fenêtre du train
2. ✅ **Hiérarchie** : Maintenance → Opérations
3. ✅ **Précédence** : Ordre des opérations avec setup
4. ✅ **Non-chevauchement** : Opérations du même train sur même voie
5. ✅ **Setup entre trains** : Temps de setup sur même voie
6. ✅ **Capacité des voies** : Ressource exclusive
7. ✅ **Ressources techniciens** : Contrainte de capacité
8. ✅ **Ressources équipements** : Contrainte de capacité avec limite simultanée
9. ✅ **Équipement sur voie** : Compatibilité voie-équipement
10. ✅ **Max temps techniciens** : Limites de charge de travail

### Objectif

Minimiser le **retard pondéré** :

```
∑(priority[m] × max(0, end_maint[m] - due_date[m]))
```

Où les maintenances urgentes (priority=1) ont plus de poids que les préventives (priority=2).

## 🔧 Personnalisation

### Créer vos propres données

Créez un nouveau fichier `.dzn` en suivant la structure de `data_example.dzn` :

1. Définissez les ensembles (TRAIN, MAINT, OP, etc.)
2. Spécifiez les paramètres des trains (arrival, departure)
3. Définissez les maintenances et leurs relations aux trains
4. Définissez les opérations et leurs relations aux maintenances
5. Spécifiez les ressources (techniciens, équipements, voies)
6. Définissez les matrices de relations N-N (tech_required, equip_required, equip_available_on_track)

**Important** : Pour les tableaux 2D, utilisez la fonction `array2d()` :

```minizinc
tech_required = array2d(OP, TECH, [
    2, 0, 0,
    1, 1, 0,
    ...
]);
```

### Modifier les contraintes

Le modèle est modulaire. Vous pouvez :

- Commenter/décommenter des contraintes dans `model.mzn`
- Ajouter de nouvelles contraintes
- Modifier l'objectif (par exemple, minimiser le makespan)

## 📝 Notes Techniques

- Les contraintes de ressources sont vérifiées aux instants de début de chaque opération pour garantir la cohérence
- Les contraintes de setup peuvent être ajustées selon vos besoins (`setup_time_between_trains`, `setup_time_between_ops`)
- La contrainte sur les types de voie peut être affinée si vous avez un mapping explicite voie-type

## 🐛 Dépannage

### Le solveur ne trouve pas de solution

1. Vérifiez que les fenêtres temporelles sont réalistes
2. Vérifiez que les ressources sont suffisantes
3. Augmentez le temps limite de résolution
4. Essayez un autre solveur (Chuffed est souvent meilleur pour ce type de problème)
5. Vérifiez que les contraintes de précédence ne créent pas de cycles impossibles

### Erreur de syntaxe

Vérifiez que :
- Tous les ensembles sont définis
- Tous les paramètres sont initialisés
- Les dimensions des tableaux correspondent
- Les tableaux 2D utilisent `array2d()` dans les fichiers `.dzn`

### Erreur "UNSATISFIABLE"

Si le modèle est insatisfiable :
1. Vérifiez que les fenêtres temporelles permettent d'exécuter toutes les opérations
2. Vérifiez que les ressources sont suffisantes (techniciens, équipements)
3. Vérifiez que les contraintes de précédence sont cohérentes
4. Essayez de relâcher temporairement certaines contraintes pour identifier le problème


