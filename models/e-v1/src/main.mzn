% ==============================================================================
% MAIN.MZN
% ==============================================================================

include "core/output_functions.mzn";
include "constant.mzn";

% Inclusions des contraintes
include "constraints/maintenances.mzn";
include "constraints/operations.mzn";
include "constraints/trajets.mzn";
include "constraints/techniciens.mzn";

solve satisfy;

output [
    entete_gantt("PLANNING DE MAINTENANCE", 
                 "Horizon: " ++ show(H) ++ " min | Périodes: " ++ show(PNb)),

    % --------------------------------------------------------------------------
    % 1. GANTT DES TRAJETS + DETAILS (Sur la même ligne)
    % --------------------------------------------------------------------------
    debut_section("TRAJETS_ET_DISPONIBILITE"),
    "\n",
    "Légende : A = Aller  │  R = Retour  │  ■ = En gare  │  · = Autre\n",
    "Format  : |GANTT| [Debut..Fin GareDebut->GareFin]\n",
    "\n"
] ++ [
    let {
        % --- Partie 1 : Données pour le Gantt ---
        array[int] of GSens: sens = [GTrajetSens[n, p] | p in 1..GP];
        array[GSens] of string: symboles = [aller: "A", retour: "R", gare: "■"];
        TId: tid = T[n]; 

        % --- Partie 2 : Construction de la chaîne d'infos (Intervalles) ---
        int: nb_creneaux = GNbIntervalles[n];
        int: offset = GOffsetsIntervalles[n];
        
        string: info_intervalles = 
            if nb_creneaux == 0 then "" 
            else
                concat([
                    let {
                        % Index linéaire dans les tableaux de computed.mzn
                        int: idx = offset + k;
                        int: deb = GIntervallesDebut[idx];
                        int: fin = GIntervallesFin[idx];
                        GType: g_deb = GIntervallesTypeDebut[idx];
                        GType: g_fin = GIntervallesTypeFin[idx];
                    } in
                    " [P" ++ show(deb) ++ ".." ++ show(fin) ++ " " ++ 
                    show(g_deb) ++ "->" ++ show(g_fin) ++ "]"
                    | k in 0..nb_creneaux-1
                ])
            endif;
    } in
    % --- Assemblage de la ligne ---
    " T" ++ show_int(3, n) ++ " (" ++ show(tid) ++ ") |" ++
    concat([
        if sens[p] == gare then
            (if GPresent[n, p] then "■" else "·" endif)
        else
            enum_vers_symbole(sens[p], symboles)
        endif
        | p in 1..GP
    ]) ++ "| " ++ info_intervalles ++ "\n"
    | n in 1..NbTrains
] ++ [
    fin_section("TRAJETS_ET_DISPONIBILITE"),

    % --------------------------------------------------------------------------
    % 2. URGENCES & MAINTENANCE
    % --------------------------------------------------------------------------
    debut_section("ETAT_MAINTENANCES"),
    "Dates butoirs (Deadlines) par rapport à H=" ++ show(H) ++ ":\n",
    concat([
        let { TId: tid = T[i] } in
        "Train " ++ show(tid) ++ " : " ++
        concat([ 
            let { int: deadline = MUrgence[tid, m] } in
            if deadline < H then
                " [" ++ show(m) ++ ": Urgence à T=" ++ show(deadline) ++ "] "
            else " ." endif
            | m in MType 
        ]) ++ "\n"
        | i in 1..NbTrains
    ]),
    fin_section("ETAT_MAINTENANCES"),

    % --------------------------------------------------------------------------
    % 3. PLANNING TECHNICIENS
    % --------------------------------------------------------------------------
    debut_section("PLANNING_RESSOURCES"),
    "Légende: [X] = Travail | [.] = Pause\n",
    concat([
        let {
            % Conversion var bool -> bool avec fix()
            array[1..SDTemps] of bool: planning_fixe = [ fix(STravail[i, p]) | p in 1..SDTemps ],
            
            int: total_travail = fix(sum(d in 1..SDivision)(STemps[i, d])),
            int: total_max = SDTemps * SDivision
        } in
        gantt_technicien_visuel(
            i, 
            "Tech", 
            1, 
            planning_fixe, 
            total_travail, 
            total_max
        )
        | i in 1..SNb
    ]),
    fin_section("PLANNING_RESSOURCES"),

    pied_gantt()
];