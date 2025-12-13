#!/usr/bin/env python3
"""
Générateur de jeux de données pour le modèle MiniZinc de maintenance ferroviaire.
Lit un fichier de configuration JSON et génère un fichier .dzn pour MiniZinc.
"""

import argparse
import json
import random
import sys
from pathlib import Path
from typing import List


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
    """Générateur de jeux de données MiniZinc"""

    def __init__(self, config: dict, seed: int = None):
        self.config = config
        if seed is not None:
            random.seed(seed)

        self.P = config["jours"] * config["periodes_par_jour"]

        # Générer les listes si non fournies
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

        self.VNb = sum(config["voies_par_type"])
        self.SNb = sum(config["techniciens_par_type"])
        self.TNb = sum(config["trains_par_type"])

        self.gtemps = []

    def generate_voies(self) -> str:
        """Génère les paramètres des voies"""
        lines = []
        lines.append(f"VTNb = {self.config['types_voies']};")
        lines.append(f"VNbT = {self.config['voies_par_type']};")

        etages = []
        for i, nb_voies in enumerate(self.config["voies_par_type"]):
            etage = (
                self.config["etage_max"]
                if i == 0
                else random.randint(1, self.config["etage_max"])
            )
            etages.extend([etage] * nb_voies)
        lines.append(f"VEtage = {etages};")

        return "\n".join(lines)

    def generate_equipements(self) -> str:
        """Génère les paramètres des équipements"""
        lines = []
        lines.append(f"ENb = {self.config['nb_equipements']};")

        capacites = [random.randint(1, 4) for _ in range(self.config["nb_equipements"])]
        quantites = [
            min(random.randint(2, 10), self.VNb)
            for _ in range(self.config["nb_equipements"])
        ]

        lines.append(f"ECapacite = {capacites};")
        lines.append(f"EQuantite = {quantites};")

        ENb = self.config["nb_equipements"]
        VNb = self.VNb

        ved = [[False for _ in range(ENb)] for _ in range(VNb)]
        for j in range(ENb):
            k = quantites[j]
            if k >= VNb:
                chosen = list(range(VNb))
            else:
                chosen = random.sample(range(VNb), k)
            for i in chosen:
                ved[i][j] = True

        lines.append("VEDisponible = [|")
        for i in range(VNb):
            row = ["true" if ved[i][j] else "false" for j in range(ENb)]
            line = "  " + ", ".join(row)
            if i < VNb - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        return "\n".join(lines)

    def generate_techniciens(self) -> str:
        """Génère les paramètres des techniciens"""
        lines = []
        lines.append(f"STNb = {self.config['types_techniciens']};")
        lines.append(f"SNbT = {self.config['techniciens_par_type']};")

        temps_min = []
        temps_max = []
        for _ in range(self.config["types_techniciens"]):
            min_h = random.randint(6, 7)
            max_h = random.randint(8, 10)
            temps_min.append(min_h * 4)
            temps_max.append(max_h * 4)

        lines.append(f"STTempsMin = {temps_min};")
        lines.append(f"STTempsMax = {temps_max};")

        return "\n".join(lines)

    def generate_trains(self) -> str:
        """Génère les paramètres des trains"""
        lines = []
        lines.append(f"TTNb = {self.config['types_trains']};")
        lines.append(f"TNbT = {self.config['trains_par_type']};")

        etages = [
            random.randint(1, self.config["etage_max"])
            for _ in range(self.config["types_trains"])
        ]
        lines.append(f"TEtage = {etages};")

        return "\n".join(lines)

    def generate_gares(self) -> str:
        """Génère les paramètres des gares"""
        lines = []
        lines.append(f"GNb = {self.config['nb_gares']};")

        pj = self.config["periodes_par_jour"]
        max_periods = max(1, (pj + 23) // 24)
        temps = [random.randint(1, max_periods) for _ in range(self.config["nb_gares"])]
        self.gtemps = temps[:]

        lines.append(f"GTemps = {temps};")

        return "\n".join(lines)

    def generate_trajets(self) -> str:
        """Génère les trajets des trains avec les nouvelles règles :
        - En GARE : ID = 0
        - En TRAJET (Aller/Retour) : ID = Numéro de la gare concernée
        - Retour obligatoirement à la même gare que l'aller.
        """
        lines = []
        gares = []
        sens = []

        if (
            not getattr(self, "gtemps", None)
            or len(self.gtemps) != self.config["nb_gares"]
        ):
            self.gtemps = [1] * self.config["nb_gares"]

        for train in range(self.TNb):
            gare_train = []
            sens_train = []

            periode_courante = 0
            # Position actuelle (numéro de gare physique)
            position = random.randint(1, self.config["nb_gares"])

            while periode_courante < self.P:
                # --- PHASE 1 : STATIONNEMENT EN GARE ---
                temps_gare = random.randint(8, 24)

                # Conserver l'ID de la gare courante pour le trajet à venir
                current_station_id = position

                for _ in range(min(temps_gare, self.P - periode_courante)):
                    # MODIFICATION : 0 quand on est en gare
                    gare_train.append(0)
                    sens_train.append("gare")
                    periode_courante += 1

                if periode_courante >= self.P:
                    break

                # --- PHASE 2 : ALLER (Gare -> Centre) ---
                # Le retour se fait à la même gare, donc destination = origine
                dest = current_station_id

                # Calcul durée trajet
                min_travel = max(
                    1, self.gtemps[current_station_id - 1] + self.gtemps[dest - 1]
                )
                base_max = random.randint(4, 12)
                travel_len = random.randint(min_travel, max(min_travel, base_max))

                for _ in range(min(travel_len, self.P - periode_courante)):
                    # MODIFICATION : ID de la gare de départ pendant le trajet aller
                    gare_train.append(current_station_id)
                    sens_train.append("aller")
                    periode_courante += 1

                if periode_courante >= self.P:
                    break

                # --- PHASE 3 : AU CENTRE / DESTINATION ---
                # On considère que le train est au centre de maintenance (hors gare commerciale)
                # Donc on met 0, comme pour une gare.

                temps_service = random.randint(8, 24)
                for _ in range(min(temps_service, self.P - periode_courante)):
                    gare_train.append(0)
                    sens_train.append("gare")
                    periode_courante += 1

                if periode_courante >= self.P:
                    break

                # --- PHASE 4 : RETOUR (Centre -> Gare) ---
                # Retour vers la même gare
                min_return = max(
                    1, self.gtemps[dest - 1] + self.gtemps[current_station_id - 1]
                )
                base_max2 = random.randint(4, 12)
                travel_back = random.randint(min_return, max(min_return, base_max2))

                for _ in range(min(travel_back, self.P - periode_courante)):
                    # MODIFICATION : ID de la gare d'arrivée (la même) pendant le trajet retour
                    gare_train.append(current_station_id)
                    sens_train.append("retour")
                    periode_courante += 1

                # Le train est physiquement revenu à sa position initiale
                position = current_station_id

            gares.append(gare_train)
            sens.append(sens_train)

        lines.append("TTrajetGare = [|")
        for i, gare_train in enumerate(gares):
            line = "  " + ", ".join(map(str, gare_train))
            if i < len(gares) - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        lines.append("")
        lines.append("TTrajetSens = [|")
        for i, sens_train in enumerate(sens):
            line = "  " + ", ".join(sens_train)
            if i < len(sens) - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        return "\n".join(lines)

    def generate_operations(self) -> str:
        """Génère les paramètres des opérations"""
        lines = []
        lines.append(f"OTNb = {self.config['types_operations']};")

        lines.append("OEquipement = [|")
        for i in range(self.config["types_operations"]):
            equipements = [
                random.choice(["true", "false"])
                for _ in range(self.config["nb_equipements"])
            ]
            line = "  " + ", ".join(equipements)
            if i < self.config["types_operations"] - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        lines.append("")
        lines.append("OTemps = [|")
        for i in range(self.config["types_operations"]):
            temps = [random.randint(1, 4) for _ in range(self.config["etage_max"])]
            line = "  " + ", ".join(map(str, temps))
            if i < self.config["types_operations"] - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        lines.append("")
        lines.append("ODependance = [|")
        for i in range(self.config["types_operations"]):
            deps = []
            for j in range(self.config["types_operations"]):
                if j < i and random.random() < 0.25:
                    deps.append("true")
                else:
                    deps.append("false")
            line = "  " + ", ".join(deps)
            if i < self.config["types_operations"] - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        lines.append("")
        shifts = [
            random.randint(1, self.config["types_techniciens"])
            for _ in range(self.config["types_operations"])
        ]
        lines.append(f"OShift = {shifts};")

        lines.append("")
        lines.append("OVoie = [|")
        for i in range(self.config["types_operations"]):
            voies = [
                random.choice(["true", "false"])
                for _ in range(self.config["types_voies"])
            ]
            line = "  " + ", ".join(voies)
            if i < self.config["types_operations"] - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        return "\n".join(lines)

    def generate_maintenances(self) -> str:
        """Génère les paramètres des maintenances"""
        lines = []
        lines.append(f"MTNb = {self.config['types_maintenances']};")

        lines.append("MOperation = [|")
        for i in range(self.config["types_maintenances"]):
            ops = [
                random.choice(["true", "false"])
                for _ in range(self.config["types_operations"])
            ]
            if "true" not in ops:
                ops[random.randint(0, len(ops) - 1)] = "true"
            line = "  " + ", ".join(ops)
            if i < self.config["types_maintenances"] - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        lines.append("")
        lines.append("MTPeriode = [|")
        for i in range(self.config["types_trains"]):
            periodes = []
            for j in range(self.config["types_maintenances"]):
                if random.random() < 0.15:
                    periodes.append("infinity")
                elif random.random() < 0.25:
                    periodes.append("0")
                else:
                    jours = random.choice([7, 14, 30, 90, 180, 365])
                    periodes.append(str(jours * self.config["periodes_par_jour"]))
            line = "  " + ", ".join(periodes)
            if i < self.config["types_trains"] - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        lines.append("")
        lines.append("MDerniereFois = [|")
        for i in range(self.TNb):
            dernieres = []
            for j in range(self.config["types_maintenances"]):
                dernieres.append(
                    -random.randint(0, 30 * self.config["periodes_par_jour"])
                )
            line = "  " + ", ".join(map(str, dernieres))
            if i < self.TNb - 1:
                line += " |"
            lines.append(line)
        lines.append("|];")

        return "\n".join(lines)

    def generate(self) -> str:
        """Génère le fichier .dzn complet"""
        sections = []

        sections.append("% Données générées automatiquement depuis configuration JSON")
        sections.append("")

        sections.append("% === PÉRIODES ET UNITÉS ===")
        sections.append(f"J = {self.config['jours']};")
        sections.append(f"PJ = {self.config['periodes_par_jour']};")
        sections.append(f"PSetup = {self.config['setup']};")
        sections.append(f"PVoie = {self.config['temps_voie']};")
        sections.append(f"EtageMax = {self.config['etage_max']};")
        sections.append("")

        sections.append("% === VOIES ===")
        sections.append(self.generate_voies())
        sections.append("")

        sections.append("% === ÉQUIPEMENTS ===")
        sections.append(self.generate_equipements())
        sections.append("")

        sections.append("% === TECHNICIENS ===")
        sections.append(self.generate_techniciens())
        sections.append("")

        sections.append("% === TRAINS ===")
        sections.append(self.generate_trains())
        sections.append("")

        sections.append("% === GARES ===")
        sections.append(self.generate_gares())
        sections.append("")

        sections.append("% === TRAJETS ===")
        sections.append(self.generate_trajets())
        sections.append("")

        sections.append("% === OPÉRATIONS ===")
        sections.append(self.generate_operations())
        sections.append("")

        sections.append("% === MAINTENANCES ===")
        sections.append(self.generate_maintenances())
        sections.append("")

        return "\n".join(sections)


def main():
    parser = argparse.ArgumentParser(
        description="Génère un jeu de données MiniZinc depuis un fichier de configuration JSON"
    )
    parser.add_argument(
        "-c",
        "--config",
        type=str,
        required=True,
        help="Fichier de configuration JSON (requis)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        default="data.dzn",
        help="Fichier de sortie (.dzn) [défaut: data.dzn]",
    )
    parser.add_argument(
        "-s",
        "--seed",
        type=int,
        default=None,
        help="Seed pour la génération aléatoire (reproductibilité)",
    )

    args = parser.parse_args()

    print(f"📖 Chargement de la configuration : {args.config}")
    config = charger_config(Path(args.config))
    print("✓ Configuration chargée")

    print(f"\n⚙️  Génération du jeu de données...")
    generator = DatasetGenerator(config, seed=args.seed)
    data = generator.generate()

    output_path = Path(args.output)
    output_path.write_text(data, encoding="utf-8")

    print(f"\n{'=' * 70}")
    print(f"✅ Jeu de données généré : {output_path}")
    print(f"{'=' * 70}")
    print(
        f"  📅 Simulation : {config['jours']} jours ({config['jours'] * config['periodes_par_jour']} périodes)"
    )
    print(f"  🚂 Trains : {generator.TNb} ({config['types_trains']} types)")
    print(f"  🛤️  Voies : {generator.VNb} ({config['types_voies']} types)")
    print(f"  👷 Techniciens : {generator.SNb} ({config['types_techniciens']} types)")
    print(f"  🏢 Gares : {config['nb_gares']}")
    print(f"  🔧 Équipements : {config['nb_equipements']}")
    print(f"  🔨 Maintenances : {config['types_maintenances']} types")
    print(f"  ⚙️  Opérations : {config['types_operations']} types")
    print(f"{'=' * 70}")

    print(f"\n🎯 Pour résoudre avec MiniZinc :")
    print(f"   minizinc src/main.mzn {output_path}")
    print()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Opération annulée")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erreur : {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
