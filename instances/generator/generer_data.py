#!/usr/bin/env python3
"""
Générateur de jeux de données pour les modèles MiniZinc de maintenance ferroviaire.
Lit un fichier de configuration JSON et génère DEUX fichiers .dzn :
1. {nom}_e-v1.dzn : Modèle détaillé (Périodes, e-v1) avec INPUT INTERVALLES.
2. {nom}_l-v1.dzn : Modèle RCPSP (Minutes, l-v1).
"""

import argparse
import json
import random
import sys
from pathlib import Path
from typing import Any, Dict, List


def charger_config(json_path: Path) -> dict:
    """Charge la configuration depuis un fichier JSON"""
    try:
        with open(json_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        return config
    except FileNotFoundError:
        print(f"❌ Erreur : Le fichier {json_path} n'existe pas")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Erreur de syntaxe JSON dans {json_path} : {e}")
        sys.exit(1)


class DatasetGenerator:
    """Générateur de jeux de données MiniZinc (Double Sortie)"""

    def __init__(self, config: dict, seed: int = None):
        self.config = config
        if seed is not None:
            random.seed(seed)

        # === INITIALISATION DES CONSTANTES GLOBALES ===
        self.J = config["jours"]
        self.PJ = config["periodes_par_jour"]
        self.P = self.J * self.PJ

        # Conversion Périodes -> Minutes pour le modèle l-v1
        self.minutes_par_periode = 1440 // self.PJ
        self.H_minutes = self.P * self.minutes_par_periode

        # === GÉNÉRATION / COMPLÉTION DES LISTES (AUTO-FILL) ===
        if config.get("voies_par_type") is None:
            config["voies_par_type"] = [
                random.randint(2, 5) for _ in range(config["types_voies"])
            ]
        if config.get("techniciens_par_type") is None:
            config["techniciens_par_type"] = [
                random.randint(3, 8) for _ in range(config["types_techniciens"])
            ]
        if config.get("trains_par_type") is None:
            config["trains_par_type"] = [
                random.randint(5, 15) for _ in range(config["types_trains"])
            ]

        # === STOCKAGE DES DONNÉES EN MÉMOIRE ===
        self.VNbT = config["voies_par_type"]
        self.VNb = sum(self.VNbT)

        self.SNbT = config["techniciens_par_type"]
        self.SNb = sum(self.SNbT)

        self.TNbT = config["trains_par_type"]
        self.TNb = sum(self.TNbT)

        self._generate_voies_data()
        self._generate_equipements_data()
        self._generate_techniciens_data()
        self._generate_trains_data()
        self._generate_gares_data()
        self._generate_trajets_data()  # Logique corrigée ici
        self._generate_operations_data()
        self._generate_maintenances_data()

    # =========================================================================
    # GÉNÉRATION DES DONNÉES INTERNES
    # =========================================================================

    def _generate_voies_data(self):
        self.VEtages = []
        for i, nb_voies in enumerate(self.VNbT):
            etage = (
                self.config["etage_max"]
                if i == 0
                else random.randint(1, self.config["etage_max"])
            )
            self.VEtages.extend([etage] * nb_voies)

    def _generate_equipements_data(self):
        self.ECapacite = [
            random.randint(1, 4) for _ in range(self.config["nb_equipements"])
        ]
        self.EQuantite = [
            min(random.randint(2, 10), self.VNb)
            for _ in range(self.config["nb_equipements"])
        ]

        self.VEDisponible = [
            [False for _ in range(self.config["nb_equipements"])]
            for _ in range(self.VNb)
        ]
        for j in range(self.config["nb_equipements"]):
            k = self.EQuantite[j]
            chosen = (
                random.sample(range(self.VNb), k)
                if k < self.VNb
                else list(range(self.VNb))
            )
            for i in chosen:
                self.VEDisponible[i][j] = True

    def _generate_techniciens_data(self):
        self.STTempsMin = []
        self.STTempsMax = []
        for _ in range(self.config["types_techniciens"]):
            min_h = random.randint(6, 7)
            max_h = random.randint(8, 10)
            self.STTempsMin.append(min_h * 4)
            self.STTempsMax.append(max_h * 4)

    def _generate_trains_data(self):
        self.TEtage = [
            random.randint(1, self.config["etage_max"])
            for _ in range(self.config["types_trains"])
        ]

    def _generate_gares_data(self):
        max_periods = max(1, (self.PJ + 23) // 24)
        self.GTemps = [
            random.randint(1, max_periods) for _ in range(self.config["nb_gares"])
        ]

    def _generate_trajets_data(self):
        """
        Génère les intervalles UNIQUEMENT quand le train est au centre.
        Corrigé pour garantir des intervalles même sur des horizons courts (1 jour).
        """
        self.InputNbIntervallesParTrain = []
        self.InputIntervallesDebut = []
        self.InputIntervallesFin = []
        self.InputIntervallesGareDebut = []
        self.InputIntervallesGareFin = []

        self.TArrivalMinutes = []
        self.TDepartureMinutes = []

        for train_idx in range(self.TNb):
            current_intervals = 0
            periode_courante = 1

            first_center_arrival = -1
            last_center_departure = -1

            # --- CORRECTION : Offset proportionnel à l'horizon ---
            # Si P est petit (48), l'offset max doit être petit (ex: 12)
            max_offset = max(1, self.P // 6)
            offset_initial = random.randint(0, max_offset)
            periode_courante += offset_initial

            while periode_courante <= self.P:
                # --- PHASE 1 : Circulation ---
                # Si l'horizon est court, on réduit le temps "dehors"
                if self.P < 100:
                    temps_exterieur = random.randint(4, 12)  # Court
                else:
                    temps_exterieur = random.randint(10, 40)  # Long

                periode_courante += temps_exterieur

                if periode_courante > self.P:
                    break

                # --- PHASE 2 : Au Centre ---
                debut_dispo = periode_courante

                # Durée au centre adaptée
                if self.P < 100:
                    duree_dispo = random.randint(12, 24)
                else:
                    duree_dispo = random.randint(12, 48)

                fin_dispo = min(debut_dispo + duree_dispo - 1, self.P)

                if debut_dispo <= self.P:
                    self.InputIntervallesDebut.append(debut_dispo)
                    self.InputIntervallesFin.append(fin_dispo)
                    self.InputIntervallesGareDebut.append(0)
                    self.InputIntervallesGareFin.append(0)

                    current_intervals += 1

                    if first_center_arrival == -1:
                        first_center_arrival = debut_dispo
                    last_center_departure = fin_dispo

                periode_courante = fin_dispo + 1

            # --- CORRECTION : FAILSAFE (Sécurité) ---
            # Si aucun intervalle n'a été généré (car horizon trop court ou aléatoire malchanceux),
            # on en force un manuellement.
            if current_intervals == 0:
                debut_force = random.randint(1, max(1, self.P // 3))
                fin_force = min(self.P, debut_force + random.randint(12, 24))

                self.InputIntervallesDebut.append(debut_force)
                self.InputIntervallesFin.append(fin_force)
                self.InputIntervallesGareDebut.append(0)
                self.InputIntervallesGareFin.append(0)

                current_intervals = 1

                if first_center_arrival == -1:
                    first_center_arrival = debut_force
                last_center_departure = fin_force

            self.InputNbIntervallesParTrain.append(current_intervals)

            # Données l-v1
            if first_center_arrival != -1:
                arr = (first_center_arrival - 1) * self.minutes_par_periode
                dep = (last_center_departure) * self.minutes_par_periode
            else:
                arr = 0
                dep = self.H_minutes

            self.TArrivalMinutes.append(arr)
            self.TDepartureMinutes.append(dep)

    def _generate_operations_data(self):
        self.OEquipement = []
        for i in range(self.config["types_operations"]):
            self.OEquipement.append(
                [
                    random.choice([True, False])
                    for _ in range(self.config["nb_equipements"])
                ]
            )

        self.OTemps = []
        for i in range(self.config["types_operations"]):
            self.OTemps.append(
                [random.randint(1, 4) for _ in range(self.config["etage_max"])]
            )

        self.ODependance = []
        for i in range(self.config["types_operations"]):
            row = []
            for j in range(self.config["types_operations"]):
                if j < i and random.random() < 0.25:
                    row.append(True)
                else:
                    row.append(False)
            self.ODependance.append(row)

        self.OShift = [
            random.randint(1, self.config["types_techniciens"])
            for _ in range(self.config["types_operations"])
        ]

        self.OVoie = []
        for i in range(self.config["types_operations"]):
            self.OVoie.append(
                [
                    random.choice([True, False])
                    for _ in range(self.config["types_voies"])
                ]
            )

    def _generate_maintenances_data(self):
        self.MOperation = []
        for i in range(self.config["types_maintenances"]):
            ops = [
                random.choice([True, False])
                for _ in range(self.config["types_operations"])
            ]
            if not any(ops):
                ops[random.randint(0, len(ops) - 1)] = True
            self.MOperation.append(ops)

        self.MTPeriode = []
        for i in range(self.config["types_trains"]):
            row = []
            for j in range(self.config["types_maintenances"]):
                r = random.random()
                if r < 0.15:
                    val = "infinity"
                elif r < 0.25:
                    val = 0
                else:
                    val = random.choice([7, 14, 30, 90]) * self.PJ
                row.append(val)
            self.MTPeriode.append(row)

        self.MDerniereFois = []
        for i in range(self.TNb):
            self.MDerniereFois.append(
                [
                    -random.randint(0, 30 * self.PJ)
                    for _ in range(self.config["types_maintenances"])
                ]
            )

    # =========================================================================
    # EXPORTATION e-v1 (NOUVEAU FORMAT INTERVALLES + COMMENTAIRES)
    # =========================================================================

    def export_e_v1(self) -> str:
        lines = []
        lines.append(
            "% ============================================================================"
        )
        lines.append("% DONNÉES GÉNÉRÉES POUR MODEL e-v1 (DÉTAILLÉ)")
        lines.append("% Modèle basé sur des PÉRIODES discrètes.")
        lines.append(
            "% ============================================================================"
        )
        lines.append("")

        lines.append("% --- Temps et Unités ---")
        lines.append("% J: Nombre de jours de simulation")
        lines.append("% PJ: Nombre de périodes par jour")
        lines.append(f"J = {self.J}; PJ = {self.PJ};")
        lines.append("% PSetup: Temps de setup entre opérations (en périodes)")
        lines.append(
            "% PVoie: Temps de sécurité entre trains sur une voie (en périodes)"
        )
        lines.append(
            f"PSetup = {self.config['setup']}; PVoie = {self.config['temps_voie']};"
        )
        lines.append("% EtageMax: Nombre maximum d'étages (caténaires) possibles")
        lines.append(f"EtageMax = {self.config['etage_max']};")
        lines.append("")

        lines.append("% --- Voies (Infrastructures) ---")
        lines.append("% VTNb: Nombre de TYPES de voies")
        lines.append(f"VTNb = {self.config['types_voies']};")
        lines.append("% VNbT: Nombre de voies pour chaque type")
        lines.append(f"VNbT = {self.VNbT};")
        lines.append("% VEtage: Étage (équipement caténaire) de chaque voie physique")
        lines.append(f"VEtage = {self.VEtages};")
        lines.append("")

        lines.append("% --- Équipements ---")
        lines.append("% ENb: Nombre de types d'équipements")
        lines.append(f"ENb = {self.config['nb_equipements']};")
        lines.append(
            "% ECapacite: Capacité simultanée (combien d'ops en // sur cet équipement)"
        )
        lines.append(f"ECapacite = {self.ECapacite};")
        lines.append("% EQuantite: Nombre total d'unités de cet équipement")
        lines.append(f"EQuantite = {self.EQuantite};")
        lines.append(
            "% VEDisponible: Matrice [Voie, Equipement] -> Est-ce dispo sur cette voie ?"
        )
        lines.append("VEDisponible = [|")
        for i in range(self.VNb):
            row = [
                "true" if self.VEDisponible[i][j] else "false"
                for j in range(self.config["nb_equipements"])
            ]
            lines.append("  " + ", ".join(row) + (" |" if i < self.VNb - 1 else ""))
        lines.append("|];")
        lines.append("")

        lines.append("% --- Techniciens ---")
        lines.append("% STNb: Nombre de types de techniciens (spécialités)")
        lines.append(f"STNb = {self.config['types_techniciens']};")
        lines.append("% SNbT: Nombre de techniciens par spécialité")
        lines.append(f"SNbT = {self.SNbT};")
        lines.append(
            "% STTempsMin/Max: Temps de travail min/max journalier (en périodes)"
        )
        lines.append(f"STTempsMin = {self.STTempsMin};")
        lines.append(f"STTempsMax = {self.STTempsMax};")
        lines.append("")

        lines.append("% --- Trains ---")
        lines.append("% TTNb: Nombre de TYPES de trains")
        lines.append(f"TTNb = {self.config['types_trains']};")
        lines.append("% TNbT: Nombre de trains par type")
        lines.append(f"TNbT = {self.TNbT};")
        lines.append("% TEtage: Étage requis par type de train")
        lines.append(f"TEtage = {self.TEtage};")
        lines.append("")

        lines.append("% --- Gares et Trajets ---")
        lines.append("% GNb: Nombre de gares périphériques")
        lines.append(f"GNb = {self.config['nb_gares']};")
        lines.append("% GTemps: Temps de trajet Gare <-> Centre (en périodes)")
        lines.append(f"GTemps = {self.GTemps};")
        lines.append("")

        lines.append("% --- Intervalles de Disponibilité (Input) ---")
        lines.append(
            "% Liste plate des intervalles où les trains sont présents au centre."
        )
        lines.append("% Gare=0 signifie 'Au Centre'.")
        lines.append(
            "% InputNbIntervallesParTrain: Combien d'intervalles par train [1..TNb]"
        )
        lines.append(f"InputNbIntervallesParTrain = {self.InputNbIntervallesParTrain};")
        lines.append("% InputIntervallesDebut: Période de début de chaque intervalle")
        lines.append(f"InputIntervallesDebut = {self.InputIntervallesDebut};")
        lines.append("% InputIntervallesFin: Période de fin de chaque intervalle")
        lines.append(f"InputIntervallesFin = {self.InputIntervallesFin};")
        lines.append("% InputIntervallesGareDebut: Gare de provenance (0=Centre)")
        lines.append(f"InputIntervallesGareDebut = {self.InputIntervallesGareDebut};")
        lines.append("% InputIntervallesGareFin: Gare de destination (0=Centre)")
        lines.append(f"InputIntervallesGareFin = {self.InputIntervallesGareFin};")
        lines.append("")

        lines.append("% --- Opérations ---")
        lines.append("% OTNb: Nombre de TYPES d'opérations")
        lines.append(f"OTNb = {self.config['types_operations']};")
        lines.append(
            "% OEquipement: Matrice [OpType, EquipType] -> Besoin équipement ?"
        )
        lines.append("OEquipement = [|")
        for i, row in enumerate(self.OEquipement):
            r_str = ["true" if x else "false" for x in row]
            lines.append(
                "  "
                + ", ".join(r_str)
                + (" |" if i < len(self.OEquipement) - 1 else "")
            )
        lines.append("|];")

        lines.append("% OTemps: Matrice [OpType, Etage] -> Durée (périodes)")
        lines.append("OTemps = [|")
        for i, row in enumerate(self.OTemps):
            lines.append(
                "  "
                + ", ".join(map(str, row))
                + (" |" if i < len(self.OTemps) - 1 else "")
            )
        lines.append("|];")

        lines.append("% ODependance: Matrice [OpA, OpB] -> OpA dépend de OpB ?")
        lines.append("ODependance = [|")
        for i, row in enumerate(self.ODependance):
            r_str = ["true" if x else "false" for x in row]
            lines.append(
                "  "
                + ", ".join(r_str)
                + (" |" if i < len(self.ODependance) - 1 else "")
            )
        lines.append("|];")

        lines.append("% OShift: Type de technicien requis pour l'opération")
        lines.append(f"OShift = {self.OShift};")

        lines.append("% OVoie: Matrice [OpType, VoieType] -> Compatible ?")
        lines.append("OVoie = [|")
        for i, row in enumerate(self.OVoie):
            r_str = ["true" if x else "false" for x in row]
            lines.append(
                "  " + ", ".join(r_str) + (" |" if i < len(self.OVoie) - 1 else "")
            )
        lines.append("|];")
        lines.append("")

        lines.append("% --- Maintenances ---")
        lines.append("% MTNb: Nombre de TYPES de maintenances")
        lines.append(f"MTNb = {self.config['types_maintenances']};")
        lines.append(
            "% MOperation: Matrice [MaintType, OpType] -> L'opération est-elle requise ?"
        )
        lines.append("MOperation = [|")
        for i, row in enumerate(self.MOperation):
            r_str = ["true" if x else "false" for x in row]
            lines.append(
                "  " + ", ".join(r_str) + (" |" if i < len(self.MOperation) - 1 else "")
            )
        lines.append("|];")

        lines.append(
            "% MTPeriode: Périodicité [TrainType, MaintType] (périodes, 0=Urgente, infinity=Jamais)"
        )
        lines.append("MTPeriode = [|")
        for i, row in enumerate(self.MTPeriode):
            lines.append(
                "  "
                + ", ".join(map(str, row))
                + (" |" if i < len(self.MTPeriode) - 1 else "")
            )
        lines.append("|];")

        lines.append(
            "% MDerniereFois: Date dernière maintenance [TrainInstance, MaintType] (négatif = passé)"
        )
        lines.append("MDerniereFois = [|")
        for i, row in enumerate(self.MDerniereFois):
            lines.append(
                "  "
                + ", ".join(map(str, row))
                + (" |" if i < len(self.MDerniereFois) - 1 else "")
            )
        lines.append("|];")

        return "\n".join(lines)

    # =========================================================================
    # EXPORTATION l-v1 (RCPSP Simplifié + COMMENTAIRES)
    # =========================================================================

    def export_l_v1(self) -> str:
        """
        Transforme les données abstraites en données concrètes pour le modèle l-v1.
        Unités: Minutes.
        """
        lines = []
        lines.append(
            "% ============================================================================"
        )
        lines.append("% DONNÉES GÉNÉRÉES POUR MODEL l-v1 (RCPSP)")
        lines.append("% Modèle continu (minutes) avec Sets explicites.")
        lines.append(
            "% ============================================================================"
        )
        lines.append("")

        lines.append("% H: Horizon total de planification en minutes")
        lines.append(f"H = {self.H_minutes};")
        lines.append("")

        lines.append("% --- Ensembles (Sets) : Indices 1..N ---")
        lines.append(f"TRAIN = 1..{self.TNb};")
        lines.append(f"TRACK = 1..{self.VNb};")
        lines.append(f"TECH = 1..{self.config['types_techniciens']};")
        lines.append(f"EQUIP = 1..{self.config['nb_equipements']};")

        # --- GENERATION DES INSTANCES MAINT/OP ---
        maint_list = []
        op_list = []

        train_types_expanded = []
        for t_type, count in enumerate(self.TNbT):
            train_types_expanded.extend([t_type + 1] * count)

        for t_idx in range(self.TNb):
            t_type_idx = train_types_expanded[t_idx] - 1

            for m_type_idx in range(self.config["types_maintenances"]):
                periode_val = self.MTPeriode[t_type_idx][m_type_idx]
                if periode_val == "infinity":
                    continue

                maint_id = len(maint_list) + 1
                derniere = self.MDerniereFois[t_idx][m_type_idx]
                periode_int = int(periode_val) if periode_val != 0 else self.P
                due_date_period = derniere + periode_int

                due_date_min = max(0, due_date_period * self.minutes_par_periode)
                priority = 1 if periode_val == 0 else 2

                maint_obj = {
                    "id": maint_id,
                    "train": t_idx + 1,
                    "periodicity": periode_int * self.minutes_par_periode,
                    "priority": priority,
                    "last_done": derniere * self.minutes_par_periode,
                    "due_date": due_date_min,
                }
                maint_list.append(maint_obj)

                type_to_global_id = {}
                active_ops_types = [
                    o_idx
                    for o_idx, required in enumerate(self.MOperation[m_type_idx])
                    if required
                ]
                train_etage = self.TEtage[t_type_idx] - 1

                current_ops_batch = []
                for op_type_idx in active_ops_types:
                    op_id = len(op_list) + len(current_ops_batch) + 1

                    duree_p = (
                        self.OTemps[op_type_idx][train_etage]
                        if train_etage < len(self.OTemps[op_type_idx])
                        else self.OTemps[op_type_idx][0]
                    )
                    duree_m = duree_p * self.minutes_par_periode

                    op_obj = {
                        "id": op_id,
                        "maint": maint_id,
                        "type_idx": op_type_idx,
                        "duration": duree_m,
                        "req_track": 1,
                        "pred": 0,
                    }
                    type_to_global_id[op_type_idx] = op_id
                    current_ops_batch.append(op_obj)

                for op in current_ops_batch:
                    o_type = op["type_idx"]
                    for potential_pred_type in active_ops_types:
                        if self.ODependance[o_type][potential_pred_type]:
                            if potential_pred_type in type_to_global_id:
                                op["pred"] = type_to_global_id[potential_pred_type]

                op_list.extend(current_ops_batch)

        lines.append(f"MAINT = 1..{len(maint_list)};")
        lines.append(f"OP = 1..{len(op_list)};")
        lines.append("")

        lines.append("% --- Paramètres Trains ---")
        lines.append("% arrival: Heure d'arrivée au centre (minutes)")
        lines.append("arrival = " + str(self.TArrivalMinutes) + ";")
        lines.append("% departure: Heure de départ du centre (minutes)")
        lines.append("departure = " + str(self.TDepartureMinutes) + ";")

        train_complexities = []
        for t_idx in range(self.TNb):
            t_type = train_types_expanded[t_idx] - 1
            train_complexities.append(self.TEtage[t_type])
        lines.append("% train_complexity: Basé sur le nombre d'étages (caténaire)")
        lines.append(f"train_complexity = {train_complexities};")
        lines.append("")

        lines.append("% --- Paramètres Maintenances ---")
        lines.append(f"maint_train = {[m['train'] for m in maint_list]};")
        lines.append(f"periodicity = {[m['periodicity'] for m in maint_list]};")
        lines.append(f"priority = {[m['priority'] for m in maint_list]};")
        lines.append(f"last_done = {[m['last_done'] for m in maint_list]};")
        lines.append(f"due_date = {[m['due_date'] for m in maint_list]};")
        lines.append("")

        lines.append("% --- Paramètres Opérations ---")
        lines.append(f"op_maint = {[o['maint'] for o in op_list]};")
        lines.append(f"duration = {[o['duration'] for o in op_list]};")
        lines.append(f"required_track_type = {[o['req_track'] for o in op_list]};")
        lines.append(f"predecessor = {[o['pred'] for o in op_list]};")
        lines.append("")

        lines.append("% --- Ressources Humaines ---")
        lines.append("% nb_total: Nombre de techniciens par type")
        lines.append(f"nb_total = {self.SNbT};")
        lines.append("% min/max_time: Temps de travail en minutes")
        lines.append(
            f"min_time = {[min_t * self.minutes_par_periode for min_t in self.STTempsMin]};"
        )
        lines.append(
            f"max_time = {[max_t * self.minutes_par_periode for max_t in self.STTempsMax]};"
        )
        lines.append("")

        lines.append("% --- Ressources Matérielles ---")
        lines.append(f"quantity = {self.EQuantite};")
        lines.append(f"simultaneous_capacity = {self.ECapacite};")
        lines.append("")

        lines.append("% --- Matrices de Besoins (Relations N-N) ---")
        lines.append("% tech_required: [Op, TechType] -> 1 si requis, 0 sinon")
        lines.append("tech_required = [|")
        for o in op_list:
            op_type = o["type_idx"]
            required_tech_type = self.OShift[op_type]
            row = []
            for t_tech in range(1, self.config["types_techniciens"] + 1):
                val = 1 if t_tech == required_tech_type else 0
                row.append(str(val))
            lines.append("  " + ", ".join(row) + " |")
        lines.append("|];")

        lines.append("% equip_required: [Op, EquipType] -> 1 si requis, 0 sinon")
        lines.append("equip_required = [|")
        for o in op_list:
            op_type = o["type_idx"]
            row = []
            for eq_idx in range(self.config["nb_equipements"]):
                val = 1 if self.OEquipement[op_type][eq_idx] else 0
                row.append(str(val))
            lines.append("  " + ", ".join(row) + " |")
        lines.append("|];")

        lines.append("% equip_available_on_track: [Voie, EquipType] -> Dispo ?")
        lines.append("equip_available_on_track = [|")
        for v in range(self.VNb):
            row = []
            for eq in range(self.config["nb_equipements"]):
                val = "true" if self.VEDisponible[v][eq] else "false"
                row.append(val)
            lines.append("  " + ", ".join(row) + " |")
        lines.append("|];")
        lines.append("")

        lines.append("% --- Setup ---")
        setup_min = self.config["setup"] * self.minutes_par_periode
        lines.append(f"setup_time_between_trains = {setup_min * 2};")
        lines.append(f"setup_time_between_ops = {setup_min};")

        return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Génère DEUX jeux de données MiniZinc (e-v1 et l-v1) depuis une configuration JSON"
    )
    parser.add_argument(
        "-c", "--config", type=str, required=True, help="Fichier de configuration JSON"
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        default="data",
        help="Nom de base des fichiers de sortie (sans extension)",
    )
    parser.add_argument("-s", "--seed", type=int, default=None, help="Seed aléatoire")

    args = parser.parse_args()

    print(f"📖 Chargement de la configuration : {args.config}")
    config = charger_config(Path(args.config))

    base_name = args.output
    if base_name.endswith(".dzn"):
        base_name = base_name[:-4]

    out_e = f"{base_name}_e-v1.dzn"
    out_l = f"{base_name}_l-v1.dzn"

    print(f"\n⚙️  Génération des données en mémoire...")
    generator = DatasetGenerator(config, seed=args.seed)

    print(f"📄 Écriture de {out_e} (Modèle Périodes)...")
    data_e = generator.export_e_v1()
    Path(out_e).parent.mkdir(parents=True, exist_ok=True)
    Path(out_e).write_text(data_e, encoding="utf-8")

    print(f"📄 Écriture de {out_l} (Modèle RCPSP)...")
    data_l = generator.export_l_v1()
    Path(out_l).write_text(data_l, encoding="utf-8")

    print(f"\n{'=' * 70}")
    print(f"✅ SUCCÈS : 2 fichiers générés")
    print(f"{'=' * 70}")
    print(f"  1. {out_e}")
    print(f"  2. {out_l}")
    print(f"\nStatistiques globales :")
    print(f"  📅 Horizon : {config['jours']} jours")
    print(f"  🚂 Trains  : {generator.TNb}")
    print(f"  🛤️  Voies   : {generator.VNb}")
    print(f"{'=' * 70}\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Opération annulée")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erreur inattendue : {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
