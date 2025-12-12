#!/bin/bash
# Script de compilation LaTeX pour Linux/Mac
cd "$(dirname "$0")"
echo "Compilation du rapport LaTeX..."
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
echo ""
echo "Compilation terminée!"
echo "Le PDF est disponible dans: main.pdf"

