enum GSens = {aller, retour, gare};

% --- PARAMÈTRES GLOBAUX CONFIGURABLES ---
0..: MinPauses = 1; 
% Nombre MINIMUM de pauses (si le technicien travaille).
% 0 = Il peut travailler d'une traite.
% 1 = Il est OBLIGÉ de couper sa journée au moins une fois (ex: déjeuner).

0..: MaxPauses = 3; 
% Nombre MAXIMUM de pauses autorisées.