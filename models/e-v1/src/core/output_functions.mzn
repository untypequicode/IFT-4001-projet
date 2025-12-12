/**
 * @brief Convertit un booléen en symbole
 * @param val Valeur booléenne
 * @param symbole_vrai Symbole pour true
 * @param symbole_faux Symbole pour false
 * @return Symbole correspondant
 */
function string: bool_vers_symbole(bool: val, string: symbole_vrai, string: symbole_faux) =
    if val then symbole_vrai else symbole_faux endif;

/**
 * @brief Convertit un entier en symbole depuis un tableau
 * @param val Valeur entière
 * @param symboles Tableau de symboles indexé par les valeurs possibles
 * @return Symbole correspondant ou "?" si non trouvé
 */
function string: int_vers_symbole(int: val, array[int] of string: symboles) =
    if val in index_set(symboles) then symboles[val] else "?" endif;

/**
 * @brief Convertit une valeur enum en symbole
 * @param val Valeur enum
 * @param symboles Tableau de symboles indexé par l'enum
 * @return Symbole correspondant
 */
function string: enum_vers_symbole($$E: val, array[$$E] of string: symboles) =
    symboles[val];

/**
 * @brief Génère une ligne Gantt depuis un tableau de booléens
 * @param etiquette Étiquette de la ligne
 * @param valeurs Tableau de booléens
 * @param symbole_vrai Symbole pour true (ex: "█", "X", "1")
 * @param symbole_faux Symbole pour false (ex: "░", ".", "0")
 * @param suffixe Texte à ajouter à la fin
 * @return Ligne Gantt formatée
 */
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

/**
 * @brief Génère une ligne Gantt depuis un tableau d'entiers
 * @param etiquette Étiquette de la ligne
 * @param valeurs Tableau d'entiers
 * @param symboles Tableau de symboles indexé par les valeurs possibles
 * @param suffixe Texte à ajouter à la fin
 * @return Ligne Gantt formatée
 */
function string: ligne_gantt_int(
    string: etiquette,
    array[int] of int: valeurs,
    array[int] of string: symboles,
    string: suffixe
) =
    etiquette ++ " |" ++
    concat([int_vers_symbole(valeurs[i], symboles) | i in index_set(valeurs)]) ++
    "| " ++ suffixe ++ "\n";

/**
 * @brief Génère une ligne Gantt depuis un tableau d'enums
 * @param etiquette Étiquette de la ligne
 * @param valeurs Tableau d'enum
 * @param symboles Tableau de symboles pour chaque valeur de l'enum
 * @param suffixe Texte à ajouter à la fin
 * @return Ligne Gantt formatée
 */
function string: ligne_gantt_enum(
    string: etiquette,
    array[int] of $$E: valeurs,
    array[$$E] of string: symboles,
    string: suffixe
) =
    etiquette ++ " |" ++
    concat([enum_vers_symbole(valeurs[i], symboles) | i in index_set(valeurs)]) ++
    "| " ++ suffixe ++ "\n";

/**
 * @brief Ligne Gantt visuelle pour un technicien
 * @param id_tech Identifiant du technicien
 * @param type_tech Type du technicien (ex: "electricien")
 * @param division Numéro de division
 * @param planning Planning binaire du technicien
 * @param temps_travaille Temps total travaillé
 * @param temps_max Temps maximum disponible
 * @return Ligne Gantt avec symboles █/░
 */
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
        "█",
        "░",
        show(temps_travaille) ++ "/" ++ show(temps_max)
    );

/**
 * @brief Ligne Gantt compacte pour un technicien
 * @param id_tech Identifiant du technicien
 * @param type_tech Type du technicien
 * @param division Numéro de division
 * @param planning Planning binaire du technicien
 * @param temps_travaille Temps total travaillé
 * @param temps_max Temps maximum disponible
 * @return Ligne Gantt avec symboles X/.
 */
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
        "X",
        ".",
        show(temps_travaille) ++ "/" ++ show(temps_max)
    );

/**
 * @brief Ligne Gantt numérique (1/0) pour un technicien
 * @param id_tech Identifiant du technicien
 * @param planning Planning binaire du technicien
 * @return Ligne Gantt avec symboles 1/0
 */
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

/**
 * @brief Convertit un tableau de booléens en JSON
 * @param arr Tableau de booléens
 * @return Chaîne JSON (ex: [0,1,1,0])
 */
function string: tableau_json_bool(array[int] of bool: arr) =
    "[" ++ concat([
        let {
            string: sep = if i == max(index_set(arr)) then "" else ", " endif;
        } in
        (if arr[i] then "1" else "0" endif) ++ sep
        | i in index_set(arr)
    ]) ++ "]";

/**
 * @brief Convertit un tableau d'entiers en JSON
 * @param arr Tableau d'entiers
 * @return Chaîne JSON (ex: [1,2,3])
 */
function string: tableau_json_int(array[int] of int: arr) =
    "[" ++ concat([
        let {
            string: sep = if i == max(index_set(arr)) then "" else ", " endif;
        } in
        show(arr[i]) ++ sep
        | i in index_set(arr)
    ]) ++ "]";

/**
 * @brief Convertit un tableau de chaînes en JSON
 * @param arr Tableau de chaînes
 * @return Chaîne JSON (ex: ["a","b","c"])
 */
function string: tableau_json_string(array[int] of string: arr) =
    "[" ++ concat([
        let {
            string: sep = if i == max(index_set(arr)) then "" else ", " endif;
        } in
        "\"" ++ arr[i] ++ "\"" ++ sep
        | i in index_set(arr)
    ]) ++ "]";

/**
 * @brief Génère un en-tête pour un diagramme Gantt
 * @param titre Titre du diagramme
 * @param legende Légende explicative
 * @return En-tête formaté
 */
function string: entete_gantt(string: titre, string: legende) =
    "==================================================================================================\n" ++
    "=== " ++ titre ++ " ===\n" ++
    "==================================================================================================\n" ++
    legende ++ "\n" ++
    "==================================================================================================\n";

/**
 * @brief Génère un pied de page pour un diagramme Gantt
 * @return Pied de page formaté
 */
function string: pied_gantt() =
    "==================================================================================================\n";

/**
 * @brief Délimiteur de début de section pour le parsing
 * @param nom_section Nom de la section
 * @return Délimiteur formaté
 */
function string: debut_section(string: nom_section) =
    "\n>>> DÉBUT SECTION: " ++ nom_section ++ " <<<\n";

/**
 * @brief Délimiteur de fin de section pour le parsing
 * @param nom_section Nom de la section
 * @return Délimiteur formaté
 */
function string: fin_section(string: nom_section) =
    ">>> FIN SECTION: " ++ nom_section ++ " <<<\n\n";
