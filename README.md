# IFT-4001 / IFT-7020 Projet

Ce projet est conçu pour modéliser et résoudre un problème réel de planification de maintenance ferroviaire sur 24 heures, inspiré des opérations au centre de maintenance SNCF. Actuellement, la planification est réalisée manuellement via Excel, ce qui est extrêmement chronophage. Ce projet vise à transformer ce processus manuel en un système automatisé capable de générer rapidement des plannings optimisés.

Le problème combine l'ordonnancement de tâches avec l'affectation de ressources multiples et des fenêtres temporelles contraintes. Les contraintes incluent :

- **Fenêtres temporelles** : Disponibilité variable des trains.
- **Équipes spécialisées** : Compétences spécifiques et effectifs limités.
- **Capacité d'atelier** : Voies de garage limitées et équipements spécifiques.
- **Priorités** : Dates butoirs et urgences.
- **Modifications** : Replanification rapide en cas de changements.

---

## Prérequis

### Gestionnaire de paquets Nix (recommandé)

Ce projet utilise [Nix](https://nixos.org/) pour gérer les dépendances et configurer l'environnement de développement. Assurez-vous que Nix est installé sur votre système. Suivez les instructions sur [https://nixos.org/download/](https://nixos.org/download/) pour l'installation.

### Dépendances sans Nix

Si vous ne souhaitez pas utiliser Nix, vous devrez installer manuellement les dépendances suivantes :

- **just** : Un outil pour exécuter des recettes. [Documentation officielle](https://github.com/casey/just).
- **texliveFull** : Une distribution complète de LaTeX. [Documentation officielle](https://www.tug.org/texlive/).
- **texlab** : Un serveur de langage pour LaTeX. [Documentation officielle](https://texlab.netlify.app/).

---

## Installation des dépendances

### Windows

1. Installez [Chocolatey](https://chocolatey.org/) ou [Scoop](https://scoop.sh/).
2. Installez les dépendances :
   ```powershell
   choco install just texlive texlab
   ```
   ou
   ```powershell
   scoop install just texlive texlab
   ```

### Mac

1. Installez [Homebrew](https://brew.sh/).
2. Installez les dépendances :
   ```bash
   brew install just texlive texlab
   ```

### Debian/Ubuntu

1. Mettez à jour les dépôts :
   ```bash
   sudo apt update
   ```
2. Installez les dépendances :
   ```bash
   sudo apt install just texlive-full
   ```
3. Installez `texlab` via `npm` ou téléchargez-le depuis [TexLab Releases](https://github.com/latex-lsp/texlab/releases).

---

## Configuration avec Nix

1. Clonez le dépôt :

   ```sh
   git clone git@github.com:untypequicode/IFT-4001-projet.git
   cd IFT-4001-projet
   ```

2. Entrez dans l'environnement de développement Nix :

   ```sh
   nix-shell
   ```

   Cela configurera automatiquement toutes les dépendances nécessaires.

---

## Utilisation

### Just

Ce projet utilise `just` pour automatiser les tâches liées à la compilation des documents LaTeX. Voici les commandes principales :

- Construire le document LaTeX (générer le PDF) :

  ```sh
  just build
  ```

- Nettoyer les fichiers temporaires générés par LaTeX :

  ```sh
  just clean
  ```

- Lister toutes les recettes disponibles :
  ```sh
  just --list
  ```

### Compilation manuelle LaTeX

Si vous préférez compiler manuellement, utilisez `pdflatex` pour générer le document PDF. Par exemple :

```bash
pdflatex main.tex
```
