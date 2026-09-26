# Écrans des Actes : installation

## Installation
Décompresse ce dossier à la racine de ton projet Godot (là où se trouve `project.godot`) :

- `assets/actes/acte_01.png` : ton image de l'Acte I
- `assets/actes/acte_02.png` à `acte_12.png` : images PROVISOIRES, à remplacer par celles de ChatGPT
- `scripts/actes_data.gd` : titres et descriptions des 12 Actes et des 72 chapitres
- `scripts/ecran_acte.gd` : script de l'écran (boutons invisibles)
- `scenes/ecran_acte.tscn` : la scène à ouvrir

## Tester
Ouvre `scenes/ecran_acte.tscn`. Dans l'Inspecteur, règle **Acte** (1 à 12), puis appuie sur **F6** (lancer la scène courante).
Clique sur une vignette : la console affiche « Acte 1 - Chapitre 3 : ... ».

## Ouvrir l'écran d'un Acte depuis ta scène « Histoire principale »
```gdscript
func _on_bouton_acte_3_pressed():
    ActesData.acte_courant = 3
    get_tree().change_scene_to_file("res://scenes/ecran_acte.tscn")
```
Pour que la flèche retour ramène à ton écran précédent, choisis sa scène dans **Scene Retour** (Inspecteur).

## Changer une image
Remplace le fichier dans `assets/actes/` en gardant EXACTEMENT le même nom. Tu n'as rien d'autre à faire.

## Régler les zones (si une nouvelle image a ses vignettes ailleurs)
1. Lance la scène et appuie sur **F2** : les zones cliquables s'affichent en rouge.
2. Dans `scripts/ecran_acte.gd`, ajoute une ligne dans `ZONES_PAR_ACTE` pour cet Acte. Tu n'indiques que les zones à corriger :
   ```gdscript
   const ZONES_PAR_ACTE := {
       5: { 1: Rect2(0.14, 0.25, 0.23, 0.30) },
   }
   ```
   Les 4 nombres sont des fractions de l'image : position x, position y, largeur, hauteur (0.5 = le milieu).

## Lancer le vrai chapitre
Dans `ecran_acte.gd`, fonction `_on_chapitre` : remplace la ligne `# TODO` par l'ouverture de ta scène de combat.
