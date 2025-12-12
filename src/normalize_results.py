#!/usr/bin/env python3
"""
Script pour normaliser tous les fichiers de résultats et extraire les métriques clés.
"""

import re
import os
from pathlib import Path
from typing import Dict, Optional

def parse_time(time_str: str) -> float:
    """Parse le temps au format MiniZinc (ex: '596msec', '4s 795msec', '1s 517msec')."""
    total_ms = 0
    
    # Chercher les secondes
    sec_match = re.search(r'(\d+)s', time_str)
    if sec_match:
        total_ms += int(sec_match.group(1)) * 1000
    
    # Chercher les millisecondes
    msec_match = re.search(r'(\d+)msec', time_str)
    if msec_match:
        total_ms += int(msec_match.group(1))
    
    return total_ms / 1000.0  # Retourner en secondes

def extract_objective(content: str) -> Optional[int]:
    """Extrait l'objectif (retard pondéré) du contenu."""
    # Chercher "Retard pondéré total: X"
    match = re.search(r'Retard pondéré total:\s*(\d+)', content)
    if match:
        return int(match.group(1))
    return None

def parse_result_file(filepath: Path) -> Dict:
    """Parse un fichier de résultat et extrait les métriques."""
    filename = filepath.name
    # Format: instance_modele_solveur.txt
    parts = filename.replace('.txt', '').split('_')
    
    if len(parts) < 3:
        return None
    
    instance = '_'.join(parts[:-2])  # Peut être small_01, medium_02, etc.
    modele = parts[-2]
    solveur = parts[-1]
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        return {
            'instance': instance,
            'modele': modele,
            'solveur': solveur,
            'status': 'ERROR',
            'error': str(e)
        }
    
    result = {
        'instance': instance,
        'modele': modele,
        'solveur': solveur,
        'status': 'UNKNOWN',
        'time_sec': None,
        'objective': None,
        'raw_content': content[:500]  # Garder un peu de contenu pour debug
    }
    
    # Chercher le statut
    if '=====UNSATISFIABLE=====' in content:
        result['status'] = 'UNSATISFIABLE'
    elif 'TIMEOUT' in content.upper() or 'TIMEOUT' in content:
        result['status'] = 'TIMEOUT'
    elif 'Finished in' in content:
        result['status'] = 'SOLVED'
    elif 'UNKNOWN' in content:
        result['status'] = 'UNKNOWN'
    
    # Extraire le temps
    if 'Finished in' in content:
        # Format: "Finished in 596msec" ou "Finished in 4s 795msec"
        time_match = re.search(r'Finished in (.+?)(?:\.|$)', content)
        if time_match:
            result['time_sec'] = parse_time(time_match.group(1))
    elif result['status'] == 'TIMEOUT':
        result['time_sec'] = 300.0  # Temps limite
    
    # Extraire l'objectif
    if result['status'] == 'SOLVED':
        result['objective'] = extract_objective(content)
        # Si pas trouvé dans le format standard, chercher dans les dernières lignes
        if result['objective'] is None:
            lines = content.split('\n')
            for line in reversed(lines[-50:]):  # Chercher dans les 50 dernières lignes
                obj = extract_objective(line)
                if obj is not None:
                    result['objective'] = obj
                    break
    
    return result

def normalize_all_results(results_dir: str = 'results') -> Dict:
    """Normalise tous les fichiers de résultats."""
    results = {}
    errors = []
    
    results_path = Path(results_dir)
    if not results_path.exists():
        print(f"ERREUR: Le dossier {results_dir} n'existe pas.")
        return {}, []
    
    for filepath in results_path.glob('*.txt'):
        parsed = parse_result_file(filepath)
        if parsed:
            key = f"{parsed['instance']}_{parsed['modele']}_{parsed['solveur']}"
            results[key] = parsed
            if parsed.get('status') == 'ERROR':
                errors.append(f"{filepath.name}: {parsed.get('error', 'Unknown error')}")
    
    return results, errors

def generate_summary_table(results: Dict) -> str:
    """Génère un tableau récapitulatif."""
    lines = []
    lines.append("=" * 80)
    lines.append("RÉSUMÉ DES RÉSULTATS")
    lines.append("=" * 80)
    lines.append("")
    
    # Organiser par instance
    instances = sorted(set(r['instance'] for r in results.values()))
    modeles = ['modele1', 'modele2']
    solveurs = ['chuffed', 'gecode']
    
    # En-tête
    header = f"{'Instance':<15}"
    for modele in modeles:
        for solveur in solveurs:
            header += f" {modele[:6]}/{solveur[:3]:<10}"
    lines.append(header)
    lines.append("-" * 80)
    
    # Données
    for instance in instances:
        row = f"{instance:<15}"
        for modele in modeles:
            for solveur in solveurs:
                key = f"{instance}_{modele}_{solveur}"
                if key in results:
                    r = results[key]
                    if r['status'] == 'SOLVED':
                        time_str = f"{r['time_sec']:.1f}s" if r['time_sec'] else "?"
                        obj_str = f" (obj:{r['objective']})" if r['objective'] is not None else ""
                        row += f" {time_str + obj_str:<10}"
                    elif r['status'] == 'UNSATISFIABLE':
                        time_str = f"{r['time_sec']:.1f}s" if r['time_sec'] else "?"
                        row += f" UNSAT({time_str})"
                    elif r['status'] == 'TIMEOUT':
                        row += f" {'TO':<10}"
                    else:
                        row += f" {r['status']:<10}"
                else:
                    row += f" {'MISSING':<10}"
        lines.append(row)
    
    return "\n".join(lines)

def generate_latex_table(results: Dict) -> str:
    """Génère un tableau LaTeX pour le rapport."""
    instances = sorted(set(r['instance'] for r in results.values()))
    modeles = ['modele1', 'modele2']
    solveurs = ['chuffed', 'gecode']
    
    lines = []
    lines.append("\\begin{table}[h]")
    lines.append("\\centering")
    lines.append("\\caption{Temps de résolution (secondes) pour chaque combinaison instance-modèle-solveur}")
    lines.append("\\label{tab:resultats_temps}")
    lines.append("\\begin{tabular}{lcccc}")
    lines.append("\\toprule")
    lines.append("Instance & Modèle 1 & Modèle 1 & Modèle 2 & Modèle 2 \\\\")
    lines.append("         & (Chuffed) & (Gecode) & (Chuffed) & (Gecode) \\\\")
    lines.append("\\midrule")
    
    for instance in instances:
        row = f"{instance.replace('_', '\\_')}"
        for modele in modeles:
            for solveur in solveurs:
                key = f"{instance}_{modele}_{solveur}"
                if key in results:
                    r = results[key]
                    if r['status'] == 'SOLVED':
                        time_str = f"{r['time_sec']:.1f}" if r['time_sec'] else "?"
                        row += f" & {time_str}"
                    elif r['status'] == 'UNSATISFIABLE':
                        time_str = f"{r['time_sec']:.1f}" if r['time_sec'] else "?"
                        row += f" & \\textbf{{UNSAT}}"
                    elif r['status'] == 'TIMEOUT':
                        row += f" & \\textbf{{TO}}"
                    else:
                        row += f" & {r['status']}"
                else:
                    row += " & ---"
        row += " \\\\"
        lines.append(row)
    
    lines.append("\\bottomrule")
    lines.append("\\end{tabular}")
    lines.append("\\end{table}")
    lines.append("")
    lines.append("\\textbf{Note :} TO = Timeout (> 300s), UNSAT = Instance insatisfiable. Les valeurs sont en secondes.")
    
    return "\n".join(lines)

def main():
    """Fonction principale."""
    print("=" * 80)
    print("NORMALISATION DES RÉSULTATS")
    print("=" * 80)
    print()
    
    results, errors = normalize_all_results('src/results')
    
    if not results:
        print("ERREUR: Aucun résultat trouvé.")
        return
    
    print(f"OK: {len(results)} fichiers analysés")
    if errors:
        print(f"ATTENTION: {len(errors)} erreurs détectees:")
        for error in errors:
            print(f"   {error}")
    print()
    
    # Statistiques
    stats = {
        'SOLVED': 0,
        'UNSATISFIABLE': 0,
        'TIMEOUT': 0,
        'UNKNOWN': 0,
        'ERROR': 0
    }
    
    for r in results.values():
        stats[r['status']] = stats.get(r['status'], 0) + 1
    
    print("Statistiques:")
    for status, count in stats.items():
        if count > 0:
            print(f"  {status}: {count}")
    print()
    
    # Générer le résumé
    summary = generate_summary_table(results)
    print(summary)
    print()
    
    # Sauvegarder
    with open('results_summary.txt', 'w', encoding='utf-8') as f:
        f.write(summary)
        f.write("\n\n")
        f.write("Détails par fichier:\n")
        f.write("=" * 80 + "\n")
        for key, r in sorted(results.items()):
            f.write(f"{key}:\n")
            f.write(f"  Statut: {r['status']}\n")
            if r['time_sec']:
                f.write(f"  Temps: {r['time_sec']:.3f}s\n")
            if r['objective'] is not None:
                f.write(f"  Objectif: {r['objective']}\n")
            f.write("\n")
    
    # Générer le tableau LaTeX
    latex_table = generate_latex_table(results)
    with open('results_table.tex', 'w', encoding='utf-8') as f:
        f.write(latex_table)
    
    print("=" * 80)
    print("FICHIERS GENERES")
    print("=" * 80)
    print("OK: results_summary.txt : Resume complet")
    print("OK: results_table.tex : Tableau LaTeX pour votre rapport")
    print()
    print("Pour utiliser le tableau LaTeX :")
    print("1. Ouvrez results_table.tex")
    print("2. Copiez le contenu dans docs/rapport_ift7020/sections/05_resultats.tex")

if __name__ == '__main__':
    main()

