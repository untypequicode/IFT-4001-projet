include "core/types.mzn";

% ==========================================================================================
% PARAMÈTRES UTILISATEUR - À DÉFINIR DANS LE FICHIER .dzn
% Ce fichier contient UNIQUEMENT les paramètres à renseigner par l'utilisateur
% Les constantes calculées automatiquement sont dans computed.mzn
% ==========================================================================================

% ==========================================================================================
% Horizon et unités
% ==========================================================================================
int: H;                                                                                    % Horizon de planification (minutes)
int: P;                                                                                    % Période de temps (minutes)
int: Setup;                                                                                % Temps de setup entre opérations (minutes)
int: Deplacement;                                                                          % Temps de déplacement entre voies (minutes)
int: Nettoyage;                                                                            % Temps de nettoyage obligatoire avant départ (minutes)
int: Preparation;                                                                          % Temps minimal de préparation avant service (minutes)
int: Transfert;                                                                            % Temps de transfert train de remplacement (minutes)

% ==========================================================================================
% Trains
% ==========================================================================================
array[TType] of int: TNb;                                                                  % Nombre de trains par type
array[1..sum(TNb)] of TId: T;                                                              % Liste des trains
array[TType] of Plexite: TDuplex;                                                          % Plexité d'un train

% ==========================================================================================
% Voies
% ==========================================================================================
array[VType] of int: VNb;                                                                  % Nombre de voie par type
array[1..sum(VNb)] of VId: V;                                                              % Liste des voies
array[VType] of Plexite: VDuplex;                                                          % Plexité d'une voie

% ==========================================================================================
% Equipements
% ==========================================================================================
array[EType] of int: ECapacite;                                                            % Capacité d'un équipement
array[EType] of int: EQuantite;                                                            % Quantité d'un équipement

% ==========================================================================================
% Shifts
% ==========================================================================================
int: SDivision;                                                                            % Nombre de division des équipes de techniciens au sein d'une même journée
int: SDCalibration;                                                                        % Début de la premiere division pour calibrer le temps
array[1..SDivision, SType] of int: SCapacite;                                              % Capacité du personnel de technicien pour une division
array[1..SDivision, SType] of 1..SDTemps: STempsMin;                                       % Temps minimal de travail pour une équipe de techniciens sur une division (minutes)
array[1..SDivision, SType] of 1..SDTemps: STempsMax;                                       % Temps minimal de travail pour une équipe de techniciens sur une division (minutes)

% ==========================================================================================
% Trajets & Gares
% ==========================================================================================
array[GType] of int: GTemps;                                                               % Temps de la distance entre la gare et le centre de maintenance (minutes)
1..H: GPeriode;                                                                            % Periodicité des trajets (minutes)

array[1..sum(TNb), 1..GP] of GType: GTrajetGare;                                           % Gare du trajet (par train et période)
array[1..sum(TNb), 1..GP] of GSens: GTrajetSens;                                           % Sens du trajet (par train et période)

% ==========================================================================================
% Maintenances & Opérations
% ==========================================================================================
array[OType, EType] of bool: OEquipement;                                                  % Equipement nécessaire par opération
array[OType, Plexite] of int: OTemps;                                                      % Temps nécessaire par opération en fonction de la plexité du train
array[OType, OType] of bool: ODependance;                                                  % Opérations dépendantes d'autres opérations
array[OType] of int: OShift;                                                               % Shifts nécessaire par opération
array[OType] of VType: OVType;                                                             % Type de voie nécessaire par opération

array[MType, OType] of bool: MOperation;                                                   % Operations nécessaire par maintenance
array[TType, MType] of int: MPeriode;                                                      % Periodicite d'une maintenance par type de train (minutes)
array[TId, MType] of ..0: MDerniereFois;                                                   % Derniere execution d'une maintenance par train (timestamp négatif ou 0)

% ==========================================================================================
% CONSTANTES CALCULÉES (à inclure après ce fichier)
% ==========================================================================================
include "computed.mzn";
