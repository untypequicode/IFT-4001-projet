#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <dossier>"
    exit 1
fi

TARGET_DIR="$1"

find "$TARGET_DIR" -name "*.mzn" -type f | while read -r file; do
    echo "Traitement de : $file"

    # 1. Calculer la colonne cible (la plus longue ligne de code avant un %)
    max_pos=$(awk '
        /%/ && !/^[[:space:]]*%/ {
            split($0, a, "%");
            code = a[1];
            sub(/[[:space:]]+$/, "", code);
            len = length(code);
            if (len > max) max = len;
        }
        END { print (max ? max : 0) }
    ' "$file")

    if [ "$max_pos" -gt 0 ]; then
        target_col=$((max_pos + 1))

        awk -v target="$target_col" '
            # CAS 1 : Détecter les lignes de séparation (ex: % === ou ===)
            # On cherche au moins trois "=" consécutifs
            /===+/ {
                # On regarde si la ligne commence par un %
                prefix = ($0 ~ /^[[:space:]]*%/) ? "% " : ""

                # On génère la nouvelle ligne
                new_line = prefix
                # Calcul du nombre de "=" à mettre
                # Si prefix est "% ", on retire 2 à la cible
                fill_len = (prefix == "% ") ? (target - 2) : target

                # Sécurité : au moins 3 "="
                if (fill_len < 3) fill_len = 3

                for(i=1; i<=fill_len; i++) new_line = new_line "="
                print new_line
                next
            }

            # CAS 2 : Ligne avec code + commentaire
            /%/ && !/^[[:space:]]*%/ {
                pos = index($0, "%");
                code = substr($0, 1, pos-1);
                comment_text = substr($0, pos + 1);

                sub(/[[:space:]]+$/, "", code);
                sub(/^[[:space:]]+/, "", comment_text);

                printf "%-*s%% %s\n", target, code, comment_text;
                next
            }

            # CAS 3 : Le reste
            { print }
        ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
done

echo "Terminé ! Les barres de '=' sont désormais alignées sur les commentaires."
