% Fonctions utilitaires pour manipuler des tableaux et vérifier des séquences temporelles

/**
 * @brief Calcule les indices de départ pour chaque groupe dans un tableau 1D
 * @param comptes Nombre d'éléments dans chaque groupe
 * @return Tableau des indices de départ (1-indexé) pour chaque groupe
 * @example comptes = [5,3,4] -> retourne [1,6,9]
 */
function array[$$E] of int: calculer_decalages(array[$$E] of int: comptes) =
    [ 1 + sum([ comptes[m2] | m2 in index_set(comptes) where m2 < m ])
      | m in index_set(comptes) ];

/**
 * @brief Extrait un sous-tableau depuis un tableau linéaire 1D
 * @param donnees Tableau linéaire complet
 * @param decalages Résultat de calculer_decalages
 * @param comptes Nombre d'éléments par groupe
 * @param m Groupe à extraire
 * @return Sous-tableau contenant les éléments du groupe m
 */
function array[int] of $$T: extraire_sous_tableau(
    array[int] of $$T: donnees,
    array[$$E] of int: decalages,
    array[$$E] of int: comptes,
    $$E: m
) =
    [ donnees[decalages[m] + i - 1] | i in 1..comptes[m] ];

/**
 * @brief Calcule les indices de départ pour chaque groupe dans un tableau 2D
 * @param comptes Nombre d'éléments par groupe (ligne, colonne)
 * @return Tableau 2D avec l'indice linéaire du début de chaque groupe
 */
function array[$$E1, $$E2] of int: calculer_decalages_2d(
    array[$$E1, $$E2] of int: comptes
) =
    array2d(index_set_1of2(comptes), index_set_2of2(comptes),
           [ let {
               int: lignes_avant = sum([ sum([ comptes[r2, c2] | c2 in index_set_2of2(comptes) ])
                                        | r2 in index_set_1of2(comptes) where r2 < r ]),
               int: cols_avant   = sum([ comptes[r, c2] | c2 in index_set_2of2(comptes) where c2 < c ])
             } in
             1 + lignes_avant + cols_avant
             | r in index_set_1of2(comptes), c in index_set_2of2(comptes)
           ] );

/**
 * @brief Extrait un sous-tableau de variables depuis un tableau 2D linéarisé
 * @param donnees Tableau linéaire de variables
 * @param decalages Résultat de calculer_decalages_2d
 * @param comptes Nombre d'éléments par groupe
 * @param r Ligne du groupe
 * @param c Colonne du groupe
 * @return Sous-tableau contenant les variables du groupe (r,c)
 */
function array[int] of var $$T: extraire_sous_tableau_var_2d(
    array[int] of var $$T: donnees,
    array[$$E1, $$E2] of int: decalages,
    array[$$E1, $$E2] of int: comptes,
    $$E1: r,
    $$E2: c
) =
    [ donnees[decalages[r, c] + i - 1] | i in 1..comptes[r, c] ];

/**
 * @brief Convertit les coordonnées (ligne, colonne, position) vers un index linéaire
 * @param decalages Résultat de calculer_decalages_2d
 * @param r Ligne du groupe
 * @param c Colonne du groupe
 * @param item_pos Position 1-indexée dans le groupe
 * @return Indice linéaire correspondant
 */
function int: calculer_index_lineaire(
    array[$$E1, $$E2] of int: decalages,
    $$E1: r,
    $$E2: c,
    int: item_pos
) = decalages[r, c] + (item_pos - 1);

/**
 * @brief Calcule la somme pondérée d'un tableau booléen
 * @param b Tableau de booléens
 * @param w Poids (true = w, false = 0)
 * @return Somme pondérée
 */
function int: somme_ponderee_bool(array[int] of bool: b, int: w) =
    sum(i in index_set(b))( if b[i] then w else 0 endif );

/**
 * @brief Vérifie qu'une séquence de val_neutre existe depuis val_cible ou le bord gauche
 * @param grille Grille 2D à analyser
 * @param ligne Ligne à examiner
 * @param t Position actuelle (colonne)
 * @param val_neutre Valeur neutre (ex: gare)
 * @param val_cible Valeur qui déclenche la séquence (ex: retour)
 * @param accepter_bord True si le début du tableau est valide
 * @param verifier_actuel True pour forcer grille[ligne, t] == val_neutre
 * @return True si une séquence valide existe
 */
function bool: verifier_sequence_gauche(
    array[int, int] of $$T: grille,
    int: ligne,
    int: t,
    $$T: val_neutre,
    $$T: val_cible,
    bool: accepter_bord,
    bool: verifier_actuel
) =
    let {
        bool: actuel_ok = if verifier_actuel then grille[ligne, t] == val_neutre else true endif;
        bool: trouve_cible = exists(k in index_set_2of2(grille) where k < t)(
            grille[ligne, k] == val_cible /\
            forall(j in k+1..t-1)(grille[ligne, j] == val_neutre)
        );
        bool: atteint_bord = accepter_bord /\
            forall(k in index_set_2of2(grille) where k < t)(grille[ligne, k] == val_neutre);
    } in (actuel_ok /\ (trouve_cible \/ atteint_bord));

/**
 * @brief Vérifie qu'une séquence de val_neutre existe depuis val_cible ou le bord droit
 * @param grille Grille 2D à analyser
 * @param ligne Ligne à examiner
 * @param t Position actuelle (colonne)
 * @param val_neutre Valeur neutre (ex: gare)
 * @param val_cible Valeur qui déclenche la séquence (ex: aller)
 * @param accepter_bord True si la fin du tableau est valide
 * @param verifier_actuel True pour forcer grille[ligne, t] == val_neutre
 * @return True si une séquence valide existe
 */
function bool: verifier_sequence_droite(
    array[int, int] of $$T: grille,
    int: ligne,
    int: t,
    $$T: val_neutre,
    $$T: val_cible,
    bool: accepter_bord,
    bool: verifier_actuel
) =
    let {
        bool: actuel_ok = if verifier_actuel then grille[ligne, t] == val_neutre else true endif;
        bool: trouve_cible = exists(k in index_set_2of2(grille) where k > t)(
            grille[ligne, k] == val_cible /\
            forall(j in t+1..k-1)(grille[ligne, j] == val_neutre)
        );
        bool: atteint_bord = accepter_bord /\
            forall(k in index_set_2of2(grille) where k > t)(grille[ligne, k] == val_neutre);
    } in (actuel_ok /\ (trouve_cible \/ atteint_bord));
