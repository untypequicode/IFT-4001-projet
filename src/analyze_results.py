#!/usr/bin/env python3
"""
Script pour analyser les résultats MiniZinc et générer des tableaux pour le rapport.
"""

import re
import os
from pathlib import Path
from typing import Dict, List, Optional

def parse_minizinc_output(content: str) -> Dict:
    """Parse la sortie MiniZinc pour extraire les métriques."""
    result = {
        'status': 'UNKNOWN',
        'time_ms': None,
        'time_sec': None,
        'objective': None,
        'solved': False,
        'solution': content
    }
    
    # Chercher le statut
    if '=====UNSATISFIABLE=====' in content:
        result['status'] = 'UNSATISFIABLE'
    elif '=====UNKNOWN=====' in content or 'TIMEOUT' in content:
        result['status'] = 'TIMEOUT'
    elif 'Finished in' in content:
        result['status'] = 'SOLVED'
        result['solved'] = True
        
        # Extraire le temps
        time_match = re.search(r'Finished in (\d+)msec', content)
        if time_match:
            result['time_ms'] = int(time_match.group(1))
            result['time_sec'] = result['time_ms'] / 1000.0
        
        # Extraire l'objectif
        obj_match = re.search(r'Retard pondéré total: (\d+)', content)
        if obj_match:
            result['objective'] = int(obj_match.group(1))
    
    return result

def collect_results(results_dir: str = 'results') -> Dict:
    """Collecte tous les résultats depuis le dossier results."""
    results = {}
    
    if not os.path.exists(results_dir):
        print(f"⚠️  Le dossier {results_dir} n'existe pas.")
        print("   Créez-le et placez-y vos fichiers de résultats.")
        return results
    
    for filename in os.listdir(results_dir):
        if filename.endswith('.txt'):
            # Format attendu: instance_solveur.txt
            parts = filename.replace('.txt', '').split('_')
            if len(parts) >= 2:
                solver = parts[-1]
                instance = '_'.join(parts[:-1])
                
                filepath = os.path.join(results_dir, filename)
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                
                parsed = parse_minizinc_output(content)
                parsed['instance'] = instance
                parsed['solver'] = solver
                parsed['filename'] = filename
                
                key = f"{instance}_{solver}"
                results[key] = parsed
    
    return results

def generate_latex_table(results: Dict) -> str:
    """Génère un tableau LaTeX pour le rapport."""
    # Organiser par instance
    instances = sorted(set(r['instance'] for r in results.values() if 'instance' in r))
    solvers = ['chuffed', 'gecode', 'ortools']
    
    lines = []
    lines.append("\\begin{table}[h]")
    lines.append("\\centering")
    lines.append("\\begin{tabular}{lccc}")
    lines.append("\\toprule")
    lines.append("Instance & Chuffed & Gecode & OR-Tools \\\\")
    lines.append("\\midrule")
    
    for instance in instances:
        row = [instance.replace('_', '\\_')]
        for solver in solvers:
            key = f"{instance}_{solver}"
            if key in results:
                r = results[key]
                if r['solved']:
                    time_str = f"{r['time_sec']:.2f}s" if r['time_sec'] else "N/A"
                    obj_str = f" ({r['objective']})" if r['objective'] is not None else ""
                    cell = f"{time_str}{obj_str}"
                else:
                    cell = r['status']
            else:
                cell = "---"
            row.append(cell)
        lines.append(" & ".join(row) + " \\\\")
    
    lines.append("\\bottomrule")
    lines.append("\\end{tabular}")
    lines.append("\\caption{Résultats des tests : temps de résolution (objectif) par instance et solveur}")
    lines.append("\\label{tab:resultats}")
    lines.append("\\end{table}")
    
    return "\n".join(lines)

def generate_summary_table(results: Dict) -> str:
    """Génère un tableau récapitulatif simple."""
    instances = sorted(set(r['instance'] for r in results.values() if 'instance' in r))
    solvers = ['chuffed', 'gecode', 'ortools']
    
    lines = []
    lines.append("=" * 100)
    lines.append("TABLEAU RECAPITULATIF DES RESULTATS")
    lines.append("=" * 100)
    lines.append("")
    lines.append(f"{'Instance':<20} {'Chuffed':<25} {'Gecode':<25} {'OR-Tools':<25}")
    lines.append("-" * 100)
    
    for instance in instances:
        row = [instance[:18]]
        for solver in solvers:
            key = f"{instance}_{solver}"
            if key in results:
                r = results[key]
                if r['solved']:
                    time_str = f"{r['time_sec']:.2f}s" if r['time_sec'] else "N/A"
                    obj_str = f" obj={r['objective']}" if r['objective'] is not None else ""
                    cell = f"{time_str}{obj_str}".strip()
                else:
                    cell = r['status'][:23]
            else:
                cell = "N/A"
            row.append(cell[:23])
        lines.append(" ".join(f"{cell:<25}" for cell in row))
    
    lines.append("")
    lines.append("=" * 100)
    
    return "\n".join(lines)

def generate_statistics(results: Dict) -> str:
    """Génère des statistiques par solveur."""
    lines = []
    lines.append("=" * 100)
    lines.append("STATISTIQUES PAR SOLVEUR")
    lines.append("=" * 100)
    lines.append("")
    
    solvers = ['chuffed', 'gecode', 'ortools']
    
    for solver in solvers:
        solver_results = [r for r in results.values() if r.get('solver') == solver]
        solved = [r for r in solver_results if r['solved']]
        times = [r['time_sec'] for r in solved if r['time_sec'] is not None]
        objectives = [r['objective'] for r in solved if r['objective'] is not None]
        
        lines.append(f"{solver.upper()}:")
        lines.append(f"  Instances resolues: {len(solved)}/{len(solver_results)}")
        if times:
            lines.append(f"  Temps moyen: {sum(times)/len(times):.2f}s")
            lines.append(f"  Temps min: {min(times):.2f}s")
            lines.append(f"  Temps max: {max(times):.2f}s")
        if objectives:
            lines.append(f"  Objectif moyen: {sum(objectives)/len(objectives):.1f}")
            lines.append(f"  Meilleur objectif: {min(objectives)}")
        lines.append("")
    
    return "\n".join(lines)

def main():
    """Fonction principale."""
    print("=" * 60)
    print("ANALYSE DES RESULTATS MINIZINC")
    print("=" * 60)
    print()
    
    results = collect_results('results')
    
    if not results:
        print("❌ Aucun résultat trouvé dans le dossier 'results/'")
        print()
        print("Pour collecter les résultats :")
        print("1. Créez un dossier 'src/results/'")
        print("2. Pour chaque test dans MiniZinc IDE :")
        print("   - Copiez la sortie complète")
        print("   - Sauvegardez dans 'results/[instance]_[solveur].txt'")
        print("   - Exemple: 'results/small_01_chuffed.txt'")
        return
    
    print(f"✓ {len(results)} résultats trouvés")
    print()
    
    # Générer le résumé texte
    summary = generate_summary_table(results)
    print(summary)
    print()
    
    # Générer les statistiques
    stats = generate_statistics(results)
    print(stats)
    
    # Générer le tableau LaTeX
    latex_table = generate_latex_table(results)
    
    # Sauvegarder tout
    with open('results_analysis.txt', 'w', encoding='utf-8') as f:
        f.write(summary)
        f.write("\n\n")
        f.write(stats)
    
    with open('results_table.tex', 'w', encoding='utf-8') as f:
        f.write(latex_table)
    
    print("=" * 60)
    print("FICHIERS GENERES")
    print("=" * 60)
    print("✓ results_analysis.txt : Analyse complète")
    print("✓ results_table.tex : Tableau LaTeX pour votre rapport")
    print()
    print("Pour utiliser le tableau LaTeX :")
    print("1. Ouvrez results_table.tex")
    print("2. Copiez le contenu dans votre section 5 (Résultats)")
    print("3. Ajustez la légende si nécessaire")

if __name__ == '__main__':
    main()


