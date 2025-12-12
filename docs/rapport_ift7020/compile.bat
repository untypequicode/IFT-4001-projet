@echo off
REM Script de compilation LaTeX pour Windows
cd /d "%~dp0"
echo Compilation du rapport LaTeX...
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
echo.
echo Compilation terminee!
echo Le PDF est disponible dans: main.pdf
pause

