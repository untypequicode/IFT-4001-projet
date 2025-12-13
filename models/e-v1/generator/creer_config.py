#!/usr/bin/env python3
"""
Créateur de fichiers de configuration JSON pour le générateur de données MiniZinc.
Ce script pose des questions interactives pour créer un fichier de configuration.
"""

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


def choisir_preset() -> Optional[Dict[str, Any]]:
    """Demande à l'utilisateur s'il veut utiliser un preset"""
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
    """Demande un entier à l'utilisateur avec une valeur par défaut"""
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
    """Demande une liste d'entiers à l'utilisateur"""
    print(f"{question}")

    if defaut is not None:
        # Afficher la valeur par défaut du preset
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
            return None  # Génération automatique

    try:
        valeurs = [int(x.strip()) for x in reponse.split(",")]
        if len(valeurs) != taille:
            print(f"⚠ Nombre de valeurs incorrect ({len(valeurs)} au lieu de {taille})")
            if defaut is not None:
                print(f"   Utilisation de la valeur par défaut : {defaut}")
                return defaut
            else:
                print("   Génération automatique")
                return None
        return valeurs
    except ValueError:
        print("⚠ Format invalide")
        if defaut is not None:
            print(f"   Utilisation de la valeur par défaut : {defaut}")
            return defaut
        else:
            print("   Génération automatique")
            return None


def creer_configuration(preset_base: Optional[Dict[str, Any]] = None):
    """Crée une configuration via des questions interactives"""

    print("╔" + "═" * 68 + "╗")
    print("║" + " " * 15 + "CRÉATEUR DE CONFIGURATION JSON" + " " * 23 + "║")
    print("╚" + "═" * 68 + "╝")
    print()

    if preset_base is None:
        print("Ce script va vous poser des questions pour créer un fichier de")
        print(
            "configuration JSON. Appuyez sur Entrée pour utiliser la valeur par défaut."
        )
        print()
        defaults = {}
    else:
        print("Configuration basée sur le preset. Les valeurs par défaut sont celles")
        print(
            "du preset. Appuyez sur Entrée pour les conserver ou entrez une nouvelle valeur."
        )
        print()
        defaults = preset_base

    config = {}

    # === PÉRIODES ET UNITÉS ===
    print("\n" + "─" * 70)
    print("📅 PÉRIODES ET UNITÉS")
    print("─" * 70)

    config["jours"] = demander_int(
        "Nombre de jours à simuler", defaults.get("jours", 7)
    )

    print("\nPériodes par jour :")
    print("  - 96 périodes = 15 minutes par période (recommandé)")
    print("  - 48 périodes = 30 minutes par période")
    print("  - 24 périodes = 1 heure par période")
    config["periodes_par_jour"] = demander_int(
        "Périodes par jour", defaults.get("periodes_par_jour", 96)
    )

    config["setup"] = demander_int(
        "Temps de setup entre opérations (périodes)", defaults.get("setup", 2)
    )
    config["temps_voie"] = demander_int(
        "Temps entre deux trains sur une même voie (périodes)",
        defaults.get("temps_voie", 4),
    )
    config["etage_max"] = demander_int(
        "Nombre maximum d'étages pour un train", defaults.get("etage_max", 2)
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
    print("👷 TECHNICIENS (par spécialité)")
    print("─" * 70)
    print("Exemples de spécialités : mécaniciens, électriciens, nettoyage, etc.")

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
    print("Exemples de types de trains : TGV, TER, Intercités, etc.")

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
        "Nombre de gares proches du centre de maintenance", defaults.get("nb_gares", 5)
    )

    # === MAINTENANCES ===
    print("\n" + "─" * 70)
    print("🔨 MAINTENANCES ET OPÉRATIONS")
    print("─" * 70)
    print(
        "Exemples de types de maintenances : journalière, hebdomadaire, mensuelle, annuelle"
    )
    print("(La périodicité est définie dans le générateur)")

    config["types_maintenances"] = demander_int(
        "Nombre de types de maintenances", defaults.get("types_maintenances", 4)
    )

    print(
        "\nExemples de types d'opérations : nettoyage, contrôle électrique, révision mécanique, etc."
    )
    config["types_operations"] = demander_int(
        "Nombre de types d'opérations", defaults.get("types_operations", 8)
    )

    return config


def afficher_resume(config: dict):
    """Affiche un résumé de la configuration"""
    print("\n" + "═" * 70)
    print("📋 RÉSUMÉ DE LA CONFIGURATION")
    print("═" * 70)

    total_voies = sum(config["voies_par_type"]) if config["voies_par_type"] else "auto"
    total_techs = (
        sum(config["techniciens_par_type"])
        if config["techniciens_par_type"]
        else "auto"
    )
    total_trains = (
        sum(config["trains_par_type"]) if config["trains_par_type"] else "auto"
    )
    total_periodes = config["jours"] * config["periodes_par_jour"]

    print(f"\n⏱️  Simulation : {config['jours']} jours ({total_periodes} périodes)")
    print(f"🚂 Trains : {total_trains} trains ({config['types_trains']} types)")
    print(f"🛤️  Voies : {total_voies} voies ({config['types_voies']} types)")
    print(
        f"👷 Techniciens : {total_techs} techniciens ({config['types_techniciens']} types)"
    )
    print(f"🏢 Gares : {config['nb_gares']}")
    print(f"🔧 Équipements : {config['nb_equipements']}")
    print(f"🔨 Maintenances : {config['types_maintenances']} types")
    print(f"⚙️  Opérations : {config['types_operations']} types")


def sauvegarder_config(config: dict, filename: str):
    """Sauvegarde la configuration dans un fichier JSON"""
    path = Path(filename)

    with open(path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Configuration sauvegardée : {path}")
    print(f"   Taille : {path.stat().st_size} octets")


def main():
    # Parser pour gérer -h / --help
    import argparse

    parser = argparse.ArgumentParser(
        description="Créateur interactif de fichiers de configuration JSON pour le générateur de données MiniZinc",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemples:
  python create_config.py
    Lance le mode interactif pour créer une configuration

Options de presets:
  1. Utiliser un preset directement (pas de questions)
  2. Utiliser un preset comme base (modifier les valeurs)
  3. Configuration personnalisée (partir de zéro)

Presets disponibles: minimal, small, medium, large, tgv

Le script vous posera des questions pour chaque paramètre.
Appuyez sur Entrée pour utiliser les valeurs par défaut.

Note sur les listes 'null' dans le JSON:
  Quand une liste est 'null' (ex: "voies_par_type": null), le générateur
  décide automatiquement en générant des valeurs aléatoires.
        """,
    )
    parser.parse_args()

    # Demander le preset
    preset_choice = choisir_preset()

    if preset_choice and preset_choice["mode"] == "direct":
        # Utiliser le preset directement sans poser de questions
        config = preset_choice["config"]
        print("\n✓ Configuration du preset utilisée directement")
    elif preset_choice and preset_choice["mode"] == "base":
        # Utiliser le preset comme base et poser les questions
        config = creer_configuration(preset_base=preset_choice["config"])
    else:
        # Configuration personnalisée
        config = creer_configuration()

    # Afficher le résumé
    afficher_resume(config)

    # Demander confirmation
    print("\n" + "─" * 70)
    confirmer = input("\n✓ Sauvegarder cette configuration ? [O/n] : ").strip().lower()

    if (
        confirmer
        and confirmer != "o"
        and confirmer != "oui"
        and confirmer != "y"
        and confirmer != "yes"
    ):
        print("\n❌ Configuration annulée")
        return 1

    # Demander le nom du fichier
    print("\n" + "─" * 70)
    nom_defaut = "config.json"
    nom_fichier = input(f"Nom du fichier de configuration [{nom_defaut}] : ").strip()
    if not nom_fichier:
        nom_fichier = nom_defaut

    # Ajouter l'extension .json si nécessaire
    if not nom_fichier.endswith(".json"):
        nom_fichier += ".json"

    # Vérifier si le fichier existe déjà
    if Path(nom_fichier).exists():
        ecraser = (
            input(f"⚠️  Le fichier {nom_fichier} existe déjà. Écraser ? [o/N] : ")
            .strip()
            .lower()
        )
        if ecraser not in ["o", "oui", "y", "yes"]:
            print("\n❌ Sauvegarde annulée")
            return 1

    # Sauvegarder
    sauvegarder_config(config, nom_fichier)

    # Instructions finales
    print("\n" + "═" * 70)
    print("🎯 PROCHAINES ÉTAPES")
    print("═" * 70)
    print(f"\n1. Vérifier la configuration :")
    print(f"   cat {nom_fichier}")
    print(f"\n2. Générer les données :")
    print(f"   python generate_data.py -c {nom_fichier} -o data.dzn")
    print(f"\n3. Résoudre avec MiniZinc :")
    print(f"   minizinc src/main.mzn data.dzn")
    print()

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n❌ Opération annulée par l'utilisateur")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erreur : {e}")
        sys.exit(1)
