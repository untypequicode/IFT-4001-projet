function array[$$E] of int: calc_offsets(array[$$E] of int: counts) = % Calcul générique des offsets
    [m: 1 + sum([counts[m2] | m2 in index_set(counts) where m2 < m]) 
     | m in index_set(counts)];

function array[int] of $$T: get_subarray(                             % Extraction générique de sous-tableau
    array[int] of $$T: data,
    array[$$E] of int: offsets,
    array[$$E] of int: counts,
    $$E: m
) = [data[offsets[m] + i - 1] | i in 1..counts[m]];


int: HEURE = 60;                                                      % Nombre de minutes dans une heure
int: JOUR = HEURE * 24;                                               % Nombre de minutes dans un jour