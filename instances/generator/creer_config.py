#!/usr/bin/env python3
"""
Créateur de fichiers de configuration JSON pour le générateur de données MiniZinc.
Mode Interactif : Lancez sans arguments.
Mode CLI : Lancez avec des arguments (ex: --preset small --jours 10).
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

# === PRESETS PRÉDÉFINIS ===
PRESETS = {
    "minimal": {
        "nom": "Minimal (test rapide - ~30s)",
        "description": "Configuration minimale pour tests rapides",
        "config": {
            "jours": 1,
            "periodes_par_jour": 48,
            "setup": 1,
            "temps_voie": 2,
            "etage_max": 1,
            "types_voies": 2,
            "voies_par_type": [2, 2],
            "nb_equipements": 2,
            "types_techniciens": 2,
            "techniciens_par_type": [3, 3],
            "types_trains": 2,
            "trains_par_type": [3, 3],
            "nb_gares": 2,
            "types_maintenances": 2,
            "types_operations": 3,
        },
    },
    "small": {
        "nom": "Small (petit - ~1min)",
        "description": "Petit jeu de données pour développement",
        "config": {
            "jours": 3,
            "periodes_par_jour": 96,
            "setup": 2,
            "temps_voie": 4,
            "etage_max": 2,
            "types_voies": 2,
            "voies_par_type": [2, 3],
            "nb_equipements": 3,
            "types_techniciens": 2,
            "techniciens_par_type": [3, 4],
            "types_trains": 2,
            "trains_par_type": [5, 5],
            "nb_gares": 3,
            "types_maintenances": 3,
            "types_operations": 5,
        },
    },
    "medium": {
        "nom": "Medium (moyen - 5-10min)",
        "description": "Configuration moyenne pour simulation hebdomadaire",
        "config": {
            "jours": 7,
            "periodes_par_jour": 96,
            "setup": 2,
            "temps_voie": 4,
            "etage_max": 2,
            "types_voies": 3,
            "voies_par_type": [3, 4, 3],
            "nb_equipements": 5,
            "types_techniciens": 3,
            "techniciens_par_type": [5, 6, 5],
            "types_trains": 4,
            "trains_par_type": [10, 12, 8, 6],
            "nb_gares": 5,
            "types_maintenances": 4,
            "types_operations": 8,
        },
    },
    "large": {
        "nom": "Large (grand - >10min)",
        "description": "Grande configuration pour simulation de 2 semaines",
        "config": {
            "jours": 14,
            "periodes_par_jour": 96,
            "setup": 2,
            "temps_voie": 4,
            "etage_max": 2,
            "types_voies": 4,
            "voies_par_type": [5, 6, 4, 3],
            "nb_equipements": 8,
            "types_techniciens": 4,
            "techniciens_par_type": [8, 10, 6, 5],
            "types_trains": 6,
            "trains_par_type": [15, 20, 18, 12, 10, 8],
            "nb_gares": 8,
            "types_maintenances": 6,
            "types_operations": 12,
        },
    },
    "tgv": {
        "nom": "TGV (réaliste - 5-15min)",
        "description": "Scénario réaliste inspiré de la maintenance TGV",
        "config": {
            "jours": 7,
            "periodes_par_jour": 96,
            "setup": 4,
            "temps_voie": 8,
            "etage_max": 2,
            "types_voies": 3,
            "voies_par_type": [3, 5, 4],
            "nb_equipements": 6,
            "types_techniciens": 3,
            "techniciens_par_type": [10, 8, 5],
            "types_trains": 3,
            "trains_par_type": [15, 12, 10],
            "nb_gares": 6,
            "types_maintenances": 5,
            "types_operations": 10,
        },
    },
}

# === FONCTIONS INTERACTIVES ===


def afficher_presets():
    """Affiche la liste des presets disponibles"""
    print("\n📋 PRESETS DISPONIBLES")
    print("─" * 70)
    for i, (key, preset) in enumerate(PRESETS.items(), 1):
        print(f"\n{i}. {preset['nom']}")
        print(f"   Clé: '{key}'")
        print(f"   {preset['description']}")
        config = preset["config"]
        total_trains = sum(config["trains_par_type"])
        print(f"   → {config['jours']} jours, {total_trains} trains")


def choisir_preset_interactif() -> Optional[Dict[str, Any]]:
    """Demande à l'utilisateur s'il veut utiliser un preset (Mode Interactif)"""
    print("\n" + "=" * 70)
    print("🎯 UTILISATION D'UN PRESET")
    print("=" * 70)

    afficher_presets()

    print("\n" + "─" * 70)
    print("\nOptions:")
    print("  1. Utiliser un preset directement (pas de questions)")
    print("  2. Utiliser un preset comme base (modifier les valeurs)")
    print("  3. Configuration personnalisée (partir de zéro)")

    choix = input("\nVotre choix [1/2/3] : ").strip()

    if choix not in ["1", "2"]:
        return None  # Configuration personnalisée

    # Choisir le preset
    print("\n" + "─" * 70)
    preset_key = (
        input("Entrez la clé du preset (minimal/small/medium/large/tgv) : ")
        .strip()
        .lower()
    )

    if preset_key not in PRESETS:
        print(f"⚠️  Preset '{preset_key}' inconnu, configuration personnalisée")
        return None

    preset_config = PRESETS[preset_key]["config"].copy()

    if choix == "1":
        # Utiliser directement
        print(f"\n✓ Preset '{preset_key}' sélectionné - configuration directe")
        return {"mode": "direct", "config": preset_config}
    else:
        # Utiliser comme base
        print(
            f"\n✓ Preset '{preset_key}' utilisé comme base - vous pouvez modifier les valeurs"
        )
        return {"mode": "base", "config": preset_config}


def demander_int(question: str, defaut: int) -> int:
    reponse = input(f"{question} [{defaut}]: ").strip()
    if not reponse:
        return defaut
    try:
        return int(reponse)
    except ValueError:
        print(f"⚠ Valeur invalide, utilisation de {defaut}")
        return defaut


def demander_liste(
    question: str, taille: int, defaut: Optional[List[int]] = None
) -> Optional[List[int]]:
    print(f"{question}")
    if defaut is not None:
        defaut_str = ", ".join(map(str, defaut))
        reponse = input(
            f"  Entrez {taille} valeurs séparées par des virgules [{defaut_str}] : "
        ).strip()
        if not reponse:
            return defaut
    else:
        reponse = input(
            f"  Entrez {taille} valeurs séparées par des virgules (ou appuyez sur Entrée pour auto) : "
        ).strip()
        if not reponse:
            return None

    try:
        valeurs = [int(x.strip()) for x in reponse.split(",")]
        if len(valeurs) != taille:
            print(f"⚠ Nombre de valeurs incorrect ({len(valeurs)} au lieu de {taille})")
            return defaut if defaut is not None else None
        return valeurs
    except ValueError:
        print("⚠ Format invalide")
        return defaut if defaut is not None else None


def creer_configuration_interactive(preset_base: Optional[Dict[str, Any]] = None):
    """Crée une configuration via des questions interactives"""
    print("╔" + "═" * 68 + "╗")
    print("║" + " " * 15 + "CRÉATEUR DE CONFIGURATION (INTERACTIF)" + " " * 15 + "║")
    print("╚" + "═" * 68 + "╝")
    print()

    defaults = preset_base if preset_base else {}
    config = {}

    # === PÉRIODES ET UNITÉS ===
    print("\n" + "─" * 70)
    print("📅 PÉRIODES ET UNITÉS")
    print("─" * 70)
    config["jours"] = demander_int(
        "Nombre de jours à simuler", defaults.get("jours", 7)
    )
    config["periodes_par_jour"] = demander_int(
        "Périodes par jour", defaults.get("periodes_par_jour", 96)
    )
    config["setup"] = demander_int(
        "Temps de setup (périodes)", defaults.get("setup", 2)
    )
    config["temps_voie"] = demander_int(
        "Temps entre trains sur voie (périodes)", defaults.get("temps_voie", 4)
    )
    config["etage_max"] = demander_int(
        "Nombre maximum d'étages", defaults.get("etage_max", 2)
    )

    # === VOIES ===
    print("\n" + "─" * 70)
    print("🛤️  VOIES")
    print("─" * 70)
    config["types_voies"] = demander_int(
        "Nombre de types de voies", defaults.get("types_voies", 3)
    )
    config["voies_par_type"] = demander_liste(
        f"Nombre de voies pour chaque type ({config['types_voies']} valeurs)",
        config["types_voies"],
        defaults.get("voies_par_type"),
    )

    # === ÉQUIPEMENTS ===
    print("\n" + "─" * 70)
    print("🔧 ÉQUIPEMENTS")
    print("─" * 70)
    config["nb_equipements"] = demander_int(
        "Nombre d'équipements disponibles", defaults.get("nb_equipements", 5)
    )

    # === TECHNICIENS ===
    print("\n" + "─" * 70)
    print("👷 TECHNICIENS")
    print("─" * 70)
    config["types_techniciens"] = demander_int(
        "Nombre de types de techniciens", defaults.get("types_techniciens", 3)
    )
    config["techniciens_par_type"] = demander_liste(
        f"Nombre de techniciens pour chaque type ({config['types_techniciens']} valeurs)",
        config["types_techniciens"],
        defaults.get("techniciens_par_type"),
    )

    # === TRAINS ===
    print("\n" + "─" * 70)
    print("🚂 TRAINS")
    print("─" * 70)
    config["types_trains"] = demander_int(
        "Nombre de types de trains", defaults.get("types_trains", 4)
    )
    config["trains_par_type"] = demander_liste(
        f"Nombre de trains pour chaque type ({config['types_trains']} valeurs)",
        config["types_trains"],
        defaults.get("trains_par_type"),
    )

    # === GARES ===
    print("\n" + "─" * 70)
    print("🏢 GARES")
    print("─" * 70)
    config["nb_gares"] = demander_int(
        "Nombre de gares proches", defaults.get("nb_gares", 5)
    )

    # === MAINTENANCES ===
    print("\n" + "─" * 70)
    print("🔨 MAINTENANCES ET OPÉRATIONS")
    print("─" * 70)
    config["types_maintenances"] = demander_int(
        "Nombre de types de maintenances", defaults.get("types_maintenances", 4)
    )
    config["types_operations"] = demander_int(
        "Nombre de types d'opérations", defaults.get("types_operations", 8)
    )

    return config


# === FONCTIONS CLI ===


def parse_list_arg(arg_str: str) -> Optional[List[int]]:
    """Convertit '1,2,3' en [1, 2, 3]"""
    if not arg_str:
        return None
    try:
        return [int(x.strip()) for x in arg_str.split(",")]
    except ValueError:
        print(f"❌ Erreur de format de liste : '{arg_str}'. Utilisez '1,2,3'")
        sys.exit(1)


def build_config_from_args(args) -> Dict[str, Any]:
    """Construit la configuration basée sur les arguments CLI + Preset éventuel"""

    # 1. Base : Soit vide, soit un preset
    if args.preset:
        if args.preset not in PRESETS:
            print(f"❌ Preset '{args.preset}' inconnu.")
            print(f"   Disponibles: {', '.join(PRESETS.keys())}")
            sys.exit(1)
        config = PRESETS[args.preset]["config"].copy()
        print(f"✓ Base chargée depuis le preset '{args.preset}'")
    else:
        # Si pas de preset, on prend les valeurs par défaut "hardcodées" minimales pour éviter les crashs
        # si l'utilisateur oublie un paramètre, ou on laisse vide.
        # Ici on prend une base vide, si un paramètre manque, on le verra plus tard ou on met des défauts.
        config = PRESETS["minimal"]["config"].copy()
        if not args.quiet:
            print(
                "ℹ️  Aucun preset spécifié, utilisation de la base 'minimal' comme défaut."
            )

    # 2. Surcharge avec les arguments explicites (s'ils ne sont pas None)
    if args.jours is not None:
        config["jours"] = args.jours
    if args.periodes is not None:
        config["periodes_par_jour"] = args.periodes
    if args.setup is not None:
        config["setup"] = args.setup
    if args.temps_voie is not None:
        config["temps_voie"] = args.temps_voie
    if args.etage_max is not None:
        config["etage_max"] = args.etage_max

    if args.types_voies is not None:
        config["types_voies"] = args.types_voies
    if args.voies_par_type is not None:
        config["voies_par_type"] = parse_list_arg(args.voies_par_type)

    if args.nb_equipements is not None:
        config["nb_equipements"] = args.nb_equipements

    if args.types_techs is not None:
        config["types_techniciens"] = args.types_techs
    if args.techs_par_type is not None:
        config["techniciens_par_type"] = parse_list_arg(args.techs_par_type)

    if args.types_trains is not None:
        config["types_trains"] = args.types_trains
    if args.trains_par_type is not None:
        config["trains_par_type"] = parse_list_arg(args.trains_par_type)

    if args.nb_gares is not None:
        config["nb_gares"] = args.nb_gares
    if args.types_maint is not None:
        config["types_maintenances"] = args.types_maint
    if args.types_ops is not None:
        config["types_operations"] = args.types_ops

    return config


def afficher_resume(config: dict):
    print("\n" + "═" * 70)
    print("📋 RÉSUMÉ DE LA CONFIGURATION")
    print("═" * 70)
    total_periodes = config["jours"] * config["periodes_par_jour"]
    print(f"\n⏱️  Simulation : {config['jours']} jours ({total_periodes} périodes)")
    print(
        f"🚂 Trains : {sum(config['trains_par_type'] or [])} ({config['types_trains']} types)"
    )
    print(
        f"🛤️  Voies : {sum(config['voies_par_type'] or [])} ({config['types_voies']} types)"
    )
    print(
        f"👷 Techniciens : {sum(config['techniciens_par_type'] or [])} ({config['types_techniciens']} types)"
    )


def sauvegarder_config(config: dict, filename: str):
    path = Path(filename)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print(f"\n✅ Configuration sauvegardée : {path}")


# === MAIN ===


def main():
    parser = argparse.ArgumentParser(
        description="Créateur de configuration JSON (Interactif ou CLI)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
EXEMPLES:
  1. Mode Interactif (Menu) :
     python creer_config.py

  2. Mode Automatique (Utilise le preset 'medium', sauve dans config.json) :
     python creer_config.py --preset medium --output config.json --quiet

  3. Mode Hybride (Preset 'small' mais avec 10 jours et plus de trains) :
     python creer_config.py --preset small --jours 10 --trains-par-type "10,10" --output test.json
        """,
    )

    # Arguments Généraux
    parser.add_argument(
        "-o", "--output", type=str, help="Fichier de sortie (ex: config.json)"
    )
    parser.add_argument(
        "-p",
        "--preset",
        type=str,
        help="Preset de base (minimal, small, medium, large, tgv)",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Mode silencieux (pas de confirmation)",
    )

    # Arguments de Configuration
    g_temps = parser.add_argument_group("Temps")
    g_temps.add_argument("--jours", type=int, help="Nombre de jours")
    g_temps.add_argument("--periodes", type=int, help="Périodes par jour")
    g_temps.add_argument("--setup", type=int, help="Temps setup")
    g_temps.add_argument("--temps-voie", type=int, help="Temps voie")
    g_temps.add_argument("--etage-max", type=int, help="Etages max")

    g_inf = parser.add_argument_group("Infrastructure")
    g_inf.add_argument("--types-voies", type=int, help="Nb types voies")
    g_inf.add_argument("--voies-par-type", type=str, help="Liste ex: '2,3,2'")
    g_inf.add_argument("--nb-equipements", type=int, help="Nb equipements")
    g_inf.add_argument("--nb-gares", type=int, help="Nb gares")

    g_rh = parser.add_argument_group("Ressources Humaines")
    g_rh.add_argument("--types-techs", type=int, help="Nb types techniciens")
    g_rh.add_argument("--techs-par-type", type=str, help="Liste ex: '5,5'")

    g_train = parser.add_argument_group("Trains & Maintenance")
    g_train.add_argument("--types-trains", type=int, help="Nb types trains")
    g_train.add_argument("--trains-par-type", type=str, help="Liste ex: '10,5,2'")
    g_train.add_argument("--types-maint", type=int, help="Nb types maintenances")
    g_train.add_argument("--types-ops", type=int, help="Nb types opérations")

    args = parser.parse_args()

    # Détection du mode : Si un argument de config ou preset est présent => CLI
    # Sinon (juste output ou rien) => Interactif
    args_cli_utilises = any(
        [
            args.preset,
            args.jours,
            args.periodes,
            args.setup,
            args.temps_voie,
            args.etage_max,
            args.types_voies,
            args.voies_par_type,
            args.nb_equipements,
            args.types_techs,
            args.techs_par_type,
            args.types_trains,
            args.trains_par_type,
            args.nb_gares,
            args.types_maint,
            args.types_ops,
        ]
    )

    if args_cli_utilises:
        # === MODE CLI ===
        print("🤖 Mode Ligne de Commande activé")
        config = build_config_from_args(args)

        # Gestion du fichier de sortie
        nom_fichier = args.output if args.output else "config.json"
        if not nom_fichier.endswith(".json"):
            nom_fichier += ".json"

        if not args.quiet:
            afficher_resume(config)

        sauvegarder_config(config, nom_fichier)

    else:
        # === MODE INTERACTIF ===
        # Si on a juste passé --output mais pas de config, on le garde pour la fin

        preset_choice = choisir_preset_interactif()

        if preset_choice and preset_choice["mode"] == "direct":
            config = preset_choice["config"]
            print("\n✓ Configuration du preset utilisée directement")
        elif preset_choice and preset_choice["mode"] == "base":
            config = creer_configuration_interactive(
                preset_base=preset_choice["config"]
            )
        else:
            config = creer_configuration_interactive()

        afficher_resume(config)

        # Sauvegarde
        print("\n" + "─" * 70)

        if args.output:
            nom_fichier = args.output
            if not nom_fichier.endswith(".json"):
                nom_fichier += ".json"
            print(f"Sauvegarde vers : {nom_fichier}")
            sauvegarder_config(config, nom_fichier)
        else:
            confirmer = (
                input("\n✓ Sauvegarder cette configuration ? [O/n] : ").strip().lower()
            )
            if confirmer not in ["", "o", "oui", "y", "yes"]:
                print("\n❌ Annulé")
                return 1

            nom_defaut = "config.json"
            nom_fichier = input(f"Nom du fichier [{nom_defaut}] : ").strip()
            if not nom_fichier:
                nom_fichier = nom_defaut
            if not nom_fichier.endswith(".json"):
                nom_fichier += ".json"

            sauvegarder_config(config, nom_fichier)

    # Instructions finales
    if not args.quiet:
        print("\n" + "═" * 70)
        print("🎯 SUITE :")
        print(f"   python generer_data.py -c {nom_fichier}")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n❌ Interrompu")
        sys.exit(1)
