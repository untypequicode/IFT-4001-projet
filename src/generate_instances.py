#!/usr/bin/env python3
"""
Script pour générer des instances de test de différentes tailles
pour le problème de planification de maintenance ferroviaire.
"""

import random
import sys

def generate_instance(num_trains, num_maintenances_per_train, num_ops_per_maint, 
                     num_tracks, num_tech_types, num_equip_types,
                     horizon=1440, seed=None):
    """Génère une instance du problème."""
    
    if seed is not None:
        random.seed(seed)
    
    num_maintenances = num_trains * num_maintenances_per_train
    num_ops = num_maintenances * num_ops_per_maint
    
    # Génération des trains
    trains = []
    for t in range(1, num_trains + 1):
        # Fenêtres temporelles réparties sur l'horizon
        arrival = random.randint(0, horizon // 2)
        departure = random.randint(arrival + 240, min(arrival + 720, horizon))
        trains.append({
            'id': t,
            'arrival': arrival,
            'departure': departure,
            'complexity': random.randint(1, 3)
        })
    
    # Génération des maintenances
    maintenances = []
    maint_id = 1
    for train_id in range(1, num_trains + 1):
        for _ in range(num_maintenances_per_train):
            priority = random.choice([1, 2])  # 1=urgente, 2=préventive
            # Due date dans la fenêtre du train
            train = trains[train_id - 1]
            due_date = random.randint(train['arrival'], train['departure'])
            maintenances.append({
                'id': maint_id,
                'train': train_id,
                'priority': priority,
                'due_date': due_date,
                'periodicity': random.choice([30, 60, 90, 180]),
                'last_done': 0
            })
            maint_id += 1
    
    # Génération des opérations
    operations = []
    op_id = 1
    for maint in maintenances:
        # Générer un graphe de précédence simple (chaîne)
        prev_op = 0
        for _ in range(num_ops_per_maint):
            duration = random.randint(30, 120)
            required_track_type = random.choice([1, 2])
            operations.append({
                'id': op_id,
                'maint': maint['id'],
                'duration': duration,
                'required_track_type': required_track_type,
                'predecessor': prev_op
            })
            prev_op = op_id
            op_id += 1
    
    # Génération des ressources
    technicians = []
    for k in range(1, num_tech_types + 1):
        technicians.append({
            'id': k,
            'nb_total': random.randint(3, 8),
            'min_time': random.randint(180, 240),
            'max_time': random.randint(360, 480)
        })
    
    equipments = []
    for e in range(1, num_equip_types + 1):
        equipments.append({
            'id': e,
            'quantity': random.randint(5, 15),
            'simultaneous_capacity': random.randint(2, 5)
        })
    
    # Génération des matrices de relations
    tech_required = []
    equip_required = []
    for op in operations:
        tech_row = [random.randint(0, 3) for _ in range(num_tech_types)]
        equip_row = [random.randint(0, 2) for _ in range(num_equip_types)]
        tech_required.append(tech_row)
        equip_required.append(equip_row)
    
    # Équipement disponible sur voie
    equip_available_on_track = []
    for track in range(1, num_tracks + 1):
        # Voies paires ont plus d'équipements
        row = [True if track % 2 == 0 or e == 1 else random.choice([True, False]) 
               for e in range(1, num_equip_types + 1)]
        equip_available_on_track.append(row)
    
    return {
        'trains': trains,
        'maintenances': maintenances,
        'operations': operations,
        'tracks': list(range(1, num_tracks + 1)),
        'technicians': technicians,
        'equipments': equipments,
        'tech_required': tech_required,
        'equip_required': equip_required,
        'equip_available_on_track': equip_available_on_track,
        'setup_time_between_trains': 30,
        'setup_time_between_ops': 10,
        'horizon': horizon
    }

def write_dzn(instance, filename):
    """Écrit une instance au format .dzn"""
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"% Instance générée automatiquement\n")
        f.write(f"% {len(instance['trains'])} trains, {len(instance['maintenances'])} maintenances, {len(instance['operations'])} opérations\n\n")
        
        f.write(f"H = {instance['horizon']};\n\n")
        
        # Ensembles
        f.write(f"TRAIN = 1..{len(instance['trains'])};\n")
        f.write(f"MAINT = 1..{len(instance['maintenances'])};\n")
        f.write(f"OP = 1..{len(instance['operations'])};\n")
        f.write(f"TRACK = 1..{len(instance['tracks'])};\n")
        f.write(f"TECH = 1..{len(instance['technicians'])};\n")
        f.write(f"EQUIP = 1..{len(instance['equipments'])};\n\n")
        
        # Trains
        f.write("% Trains\n")
        arrivals = [t['arrival'] for t in instance['trains']]
        departures = [t['departure'] for t in instance['trains']]
        complexities = [t['complexity'] for t in instance['trains']]
        f.write(f"arrival = {arrivals};\n")
        f.write(f"departure = {departures};\n")
        f.write(f"train_complexity = {complexities};\n\n")
        
        # Maintenances
        f.write("% Maintenances\n")
        maint_trains = [m['train'] for m in instance['maintenances']]
        priorities = [m['priority'] for m in instance['maintenances']]
        due_dates = [m['due_date'] for m in instance['maintenances']]
        periodicities = [m['periodicity'] for m in instance['maintenances']]
        last_dones = [m['last_done'] for m in instance['maintenances']]
        f.write(f"maint_train = {maint_trains};\n")
        f.write(f"priority = {priorities};\n")
        f.write(f"due_date = {due_dates};\n")
        f.write(f"periodicity = {periodicities};\n")
        f.write(f"last_done = {last_dones};\n\n")
        
        # Opérations
        f.write("% Opérations\n")
        op_maints = [o['maint'] for o in instance['operations']]
        durations = [o['duration'] for o in instance['operations']]
        track_types = [o['required_track_type'] for o in instance['operations']]
        predecessors = [o['predecessor'] for o in instance['operations']]
        f.write(f"op_maint = {op_maints};\n")
        f.write(f"duration = {durations};\n")
        f.write(f"required_track_type = {track_types};\n")
        f.write(f"predecessor = {predecessors};\n\n")
        
        # Techniciens
        f.write("% Techniciens\n")
        nb_totals = [t['nb_total'] for t in instance['technicians']]
        min_times = [t['min_time'] for t in instance['technicians']]
        max_times = [t['max_time'] for t in instance['technicians']]
        f.write(f"nb_total = {nb_totals};\n")
        f.write(f"min_time = {min_times};\n")
        f.write(f"max_time = {max_times};\n\n")
        
        # Équipements
        f.write("% Équipements\n")
        quantities = [e['quantity'] for e in instance['equipments']]
        capacities = [e['simultaneous_capacity'] for e in instance['equipments']]
        f.write(f"quantity = {quantities};\n")
        f.write(f"simultaneous_capacity = {capacities};\n\n")
        
        # Relations opération-technicien
        f.write("% Relations opération-technicien\n")
        f.write("tech_required = array2d(OP, TECH, [\n")
        flat_list = []
        for row in instance['tech_required']:
            flat_list.extend(row)
        f.write("    " + ", ".join(map(str, flat_list)) + "\n")
        f.write("]);\n\n")
        
        # Relations opération-équipement
        f.write("% Relations opération-équipement\n")
        f.write("equip_required = array2d(OP, EQUIP, [\n")
        flat_list = []
        for row in instance['equip_required']:
            flat_list.extend(row)
        f.write("    " + ", ".join(map(str, flat_list)) + "\n")
        f.write("]);\n\n")
        
        # Équipement disponible sur voie
        f.write("% Équipement disponible sur voie\n")
        f.write("equip_available_on_track = array2d(TRACK, EQUIP, [\n")
        flat_list = []
        for row in instance['equip_available_on_track']:
            flat_list.extend([str(b).lower() for b in row])
        f.write("    " + ", ".join(flat_list) + "\n")
        f.write("]);\n\n")
        
        # Setup
        f.write("% Setup\n")
        f.write(f"setup_time_between_trains = {instance['setup_time_between_trains']};\n")
        f.write(f"setup_time_between_ops = {instance['setup_time_between_ops']};\n")

def main():
    """Génère un ensemble d'instances de test"""
    
    instances = [
        # Petites instances
        (2, 2, 2, 3, 2, 2, "small_01"),
        (3, 2, 2, 4, 3, 2, "small_02"),
        
        # Instances moyennes
        (5, 2, 3, 4, 3, 2, "medium_01"),
        (7, 2, 3, 5, 3, 2, "medium_02"),
        (5, 3, 3, 5, 3, 2, "medium_03"),
        
        # Grandes instances
        (10, 2, 3, 6, 3, 2, "large_01"),
        (10, 3, 3, 6, 3, 2, "large_02"),
        (15, 2, 3, 8, 3, 2, "large_03"),
    ]
    
    output_dir = "instances"
    import os
    os.makedirs(output_dir, exist_ok=True)
    
    for i, (trains, maints_per_train, ops_per_maint, tracks, tech, equip, name) in enumerate(instances):
        instance = generate_instance(trains, maints_per_train, ops_per_maint, 
                                    tracks, tech, equip, seed=i)
        filename = f"{output_dir}/{name}.dzn"
        write_dzn(instance, filename)
        print(f"Généré: {filename} ({trains} trains, {len(instance['maintenances'])} maintenances, {len(instance['operations'])} opérations)")

if __name__ == '__main__':
    main()

