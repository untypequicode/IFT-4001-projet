% ==========================================================================================
% core/output_functions.mzn
% Fonctions réutilisables pour l'affichage et l'export des résultats (en français)
% ==========================================================================================

% ==========================================================================================
% MAPPAGES VALEUR → SYMBOLE
% ==========================================================================================

% ------------------------------------------------------------------------------------------
% Mappage bool → symbole
% ------------------------------------------------------------------------------------------
function string: bool_vers_symbole(bool: val, string: symbole_vrai, string: symbole_faux) =
    if val then symbole_vrai else symbole_faux endif;

% ------------------------------------------------------------------------------------------
% Mappage int → symbole (avec un tableau de symboles)
% Exemple: int_vers_symbole(2, ["A", "B", "C"]) retourne "B"
% ------------------------------------------------------------------------------------------
function string: int_vers_symbole(int: val, array[int] of string: symboles) =
    if val in index_set(symboles) then symboles[val] else "?" endif;

% ------------------------------------------------------------------------------------------
% Mappage enum → symbole (via un tableau indexé par l'enum)
% Exemple pour GSens: enum_vers_symbole(aller, [aller: "A", retour: "R", gare: "■"])
% ------------------------------------------------------------------------------------------
function string: enum_vers_symbole($$E: val, array[$$E] of string: symboles) =
    symboles[val];

% ==========================================================================================
% FONCTIONS GANTT GÉNÉRIQUES
% ==========================================================================================

% ------------------------------------------------------------------------------------------
% ligne_gantt_bool : Génère une ligne de Gantt à partir d'un array de bool
% Paramètres:
%   - etiquette: Étiquette de la ligne
%   - valeurs: Array de bool
%   - symbole_vrai: Symbole pour true (ex: "█", "X", "1")
%   - symbole_faux: Symbole pour false (ex: "░", ".", "0")
%   - suffixe: Texte à ajouter à la fin
% ------------------------------------------------------------------------------------------
function string: ligne_gantt_bool(
    string: etiquette,
    array[int] of bool: valeurs,
    string: symbole_vrai,
    string: symbole_faux,
    string: suffixe
) =
    etiquette ++ " |" ++
    concat([bool_vers_symbole(valeurs[i], symbole_vrai, symbole_faux) | i in index_set(valeurs)]) ++
    "| " ++ suffixe ++ "\n";

% ------------------------------------------------------------------------------------------
% ligne_gantt_int : Génère une ligne de Gantt à partir d'un array d'int
% Paramètres:
%   - etiquette: Étiquette de la ligne
%   - valeurs: Array d'int
%   - symboles: Array de symboles indexés par les valeurs possibles
%   - suffixe: Texte à ajouter à la fin
% ------------------------------------------------------------------------------------------
function string: ligne_gantt_int(
    string: etiquette,
    array[int] of int: valeurs,
    array[int] of string: symboles,
    string: suffixe
) =
    etiquette ++ " |" ++
    concat([int_vers_symbole(valeurs[i], symboles) | i in index_set(valeurs)]) ++
    "| " ++ suffixe ++ "\n";

% ------------------------------------------------------------------------------------------
% ligne_gantt_enum : Génère une ligne de Gantt à partir d'un array d'enum
% Paramètres:
%   - etiquette: Étiquette de la ligne
%   - valeurs: Array d'enum
%   - symboles: Array de symboles pour chaque valeur de l'enum
%   - suffixe: Texte à ajouter à la fin
% ------------------------------------------------------------------------------------------
function string: ligne_gantt_enum(
    string: etiquette,
    array[int] of $$E: valeurs,
    array[$$E] of string: symboles,
    string: suffixe
) =
    etiquette ++ " |" ++
    concat([enum_vers_symbole(valeurs[i], symboles) | i in index_set(valeurs)]) ++
    "| " ++ suffixe ++ "\n";

% ==========================================================================================
% FONCTIONS GANTT SPÉCIALISÉES (utilisant les fonctions génériques)
% ==========================================================================================

% ------------------------------------------------------------------------------------------
% gantt_technicien_visuel : Ligne Gantt visuelle pour un technicien
% ------------------------------------------------------------------------------------------
function string: gantt_technicien_visuel(
    int: id_tech,
    string: type_tech,
    int: division,
    array[int] of bool: planning,
    int: temps_travaille,
    int: temps_max
) =
    ligne_gantt_bool(
        "Tech " ++ show_int(3, id_tech) ++ " (" ++ type_tech ++ ", D" ++ show(division) ++ ")",
        planning,
        "█",  % true = travail
        "░",  % false = repos
        show(temps_travaille) ++ "/" ++ show(temps_max)
    );

% ------------------------------------------------------------------------------------------
% gantt_technicien_compact : Ligne Gantt compacte pour un technicien
% ------------------------------------------------------------------------------------------
function string: gantt_technicien_compact(
    int: id_tech,
    string: type_tech,
    int: division,
    array[int] of bool: planning,
    int: temps_travaille,
    int: temps_max
) =
    ligne_gantt_bool(
        "T" ++ show_int(3, id_tech),
        planning,
        "X",  % true = travail
        ".",  % false = repos
        show(temps_travaille) ++ "/" ++ show(temps_max)
    );

% ------------------------------------------------------------------------------------------
% gantt_technicien_numerique : Ligne Gantt numérique (1/0)
% ------------------------------------------------------------------------------------------
function string: gantt_technicien_numerique(
    int: id_tech,
    array[int] of bool: planning
) =
    ligne_gantt_bool(
        "Tech " ++ show_int(3, id_tech),
        planning,
        "1",
        "0",
        ""
    );

% ==========================================================================================
% FONCTIONS D'EXPORT JSON
% ==========================================================================================

% ------------------------------------------------------------------------------------------
% tableau_json_bool : Convertit un array de bool en JSON (0/1)
% ------------------------------------------------------------------------------------------
function string: tableau_json_bool(array[int] of bool: arr) =
    "[" ++ concat([
        let {
            string: sep = if i == max(index_set(arr)) then "" else ", " endif;
        } in
        (if arr[i] then "1" else "0" endif) ++ sep
        | i in index_set(arr)
    ]) ++ "]";

% ------------------------------------------------------------------------------------------
% tableau_json_int : Convertit un array d'int en JSON
% ------------------------------------------------------------------------------------------
function string: tableau_json_int(array[int] of int: arr) =
    "[" ++ concat([
        let {
            string: sep = if i == max(index_set(arr)) then "" else ", " endif;
        } in
        show(arr[i]) ++ sep
        | i in index_set(arr)
    ]) ++ "]";

% ------------------------------------------------------------------------------------------
% tableau_json_string : Convertit un array de string en JSON
% ------------------------------------------------------------------------------------------
function string: tableau_json_string(array[int] of string: arr) =
    "[" ++ concat([
        let {
            string: sep = if i == max(index_set(arr)) then "" else ", " endif;
        } in
        "\"" ++ arr[i] ++ "\"" ++ sep
        | i in index_set(arr)
    ]) ++ "]";

% ==========================================================================================
% FONCTIONS EN-TÊTE/PIED DE PAGE
% ==========================================================================================

% ------------------------------------------------------------------------------------------
% entete_gantt : Génère un en-tête pour un diagramme Gantt
% ------------------------------------------------------------------------------------------
function string: entete_gantt(string: titre, string: legende) =
    "==================================================================================================\n" ++
    "=== " ++ titre ++ " ===\n" ++
    "==================================================================================================\n" ++
    legende ++ "\n" ++
    "==================================================================================================\n";

function string: pied_gantt() =
    "==================================================================================================\n";

% ------------------------------------------------------------------------------------------
% delimiteurs_section : Délimiteurs pour les sections (utile pour parsing)
% ------------------------------------------------------------------------------------------
function string: debut_section(string: nom_section) =
    "\n>>> DÉBUT SECTION: " ++ nom_section ++ " <<<\n";

function string: fin_section(string: nom_section) =
    ">>> FIN SECTION: " ++ nom_section ++ " <<<\n\n";
