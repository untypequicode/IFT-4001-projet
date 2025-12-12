#!/usr/bin/env python3
"""
Corrige toutes les instances pour avoir des fenêtres temporelles réalistes.
"""

import re
import os

def fix_instance(filename):
    """Corrige une instance."""
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extraire les valeurs
    arrival_match = re.search(r'arrival = \[(.*?)\]', content)
    departure_match = re.search(r'departure = \[(.*?)\]', content)
    
    if not arrival_match or not departure_match:
        print(f"  Erreur: impossible de parser {filename}")
        return False
    
    arrivals = [int(x.strip()) for x in arrival_match.group(1).split(',')]
    departures = [int(x.strip()) for x in departure_match.group(1).split(',')]
    
    # Corriger les fenêtres : minimum 480 minutes (8h) par train
    fixed = False
    for i in range(len(arrivals)):
        window = departures[i] - arrivals[i]
        if window < 480:
            # Étendre à 480 minutes minimum
            new_departure = arrivals[i] + 480
            if new_departure > 1440:
                # Si ça dépasse, commencer plus tôt
                new_arrival = max(0, 1440 - 480)
                arrivals[i] = new_arrival
                departures[i] = 1440
            else:
                departures[i] = new_departure
            fixed = True
    
    if fixed:
        # Remplacer dans le contenu
        new_arrivals = '[' + ', '.join(map(str, arrivals)) + ']'
        new_departures = '[' + ', '.join(map(str, departures)) + ']'
        
        content = re.sub(r'arrival = \[.*?\]', f'arrival = {new_arrivals}', content)
        content = re.sub(r'departure = \[.*?\]', f'departure = {new_departures}', content)
        
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

# Corriger toutes les instances
instances_dir = 'instances'
fixed_count = 0

print("Correction des fenêtres temporelles...")
print()

for filename in os.listdir(instances_dir):
    if filename.endswith('.dzn'):
        filepath = os.path.join(instances_dir, filename)
        if fix_instance(filepath):
            print(f"✓ {filename} corrigé")
            fixed_count += 1
        else:
            print(f"  {filename} OK")

print()
print(f"Total: {fixed_count} instance(s) corrigée(s)")

