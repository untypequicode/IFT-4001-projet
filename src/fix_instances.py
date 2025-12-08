#!/usr/bin/env python3
"""
Script pour corriger les instances qui sont UNSATISFIABLE.
Ajuste les fenêtres temporelles et les ressources pour rendre les instances satisfaisables.
"""

import re

def fix_instance(filename):
    """Corrige une instance pour la rendre satisfaisable."""
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Lire les valeurs actuelles
    arrival_match = re.search(r'arrival = \[(.*?)\]', content)
    departure_match = re.search(r'departure = \[(.*?)\]', content)
    max_time_match = re.search(r'max_time = \[(.*?)\]', content)
    
    if not all([arrival_match, departure_match, max_time_match]):
        print(f"Impossible de parser {filename}")
        return
    
    arrivals = [int(x.strip()) for x in arrival_match.group(1).split(',')]
    departures = [int(x.strip()) for x in departure_match.group(1).split(',')]
    max_times = [int(x.strip()) for x in max_time_match.group(1).split(',')]
    
    # Ajuster les fenêtres temporelles pour qu'elles soient plus larges
    # Au moins 8 heures (480 minutes) par train
    for i in range(len(arrivals)):
        window = departures[i] - arrivals[i]
        if window < 480:
            # Étendre la fenêtre à au moins 480 minutes
            departures[i] = arrivals[i] + 480
            if departures[i] > 1440:
                # Si ça dépasse l'horizon, ajuster l'arrivée
                departures[i] = 1440
                arrivals[i] = departures[i] - 480
    
    # Augmenter max_time de 20% pour plus de flexibilité
    max_times = [int(t * 1.2) for t in max_times]
    
    # Remplacer dans le contenu
    new_arrivals = '[' + ', '.join(map(str, arrivals)) + ']'
    new_departures = '[' + ', '.join(map(str, departures)) + ']'
    new_max_times = '[' + ', '.join(map(str, max_times)) + ']'
    
    content = re.sub(r'arrival = \[.*?\]', f'arrival = {new_arrivals}', content)
    content = re.sub(r'departure = \[.*?\]', f'departure = {new_departures}', content)
    content = re.sub(r'max_time = \[.*?\]', f'max_time = {new_max_times}', content)
    
    # Sauvegarder
    backup_filename = filename.replace('.dzn', '_backup.dzn')
    with open(backup_filename, 'w', encoding='utf-8') as f:
        with open(filename, 'r', encoding='utf-8') as orig:
            f.write(orig.read())
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ {filename} corrigé (backup: {backup_filename})")

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        fix_instance(sys.argv[1])
    else:
        print("Usage: python fix_instances.py <instance.dzn>")
        print("Exemple: python fix_instances.py instances/small_01.dzn")

