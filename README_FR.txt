# Fantasy Restored

Shader ReShade configurable pour une ambiance anime/fantasy : palette fraîche, éclairage doré, ombres douces bleutées, textures adoucies, cel-shading léger, contours fins et lueurs féeriques. Les paramètres par défaut sont modérés mais visibles.

## Installation

1. Copiez `Shaders/FantasyRestored.fx` dans le dossier de shaders utilisé par ReShade (habituellement `reshade-shaders/Shaders`).
2. Rechargez les effets et activez **Fantasy Restored**. Les contrôles portent des noms anglais pour faciliter le partage des réglages.
3. Commencez en SDR. L'entrée doit être une image normalisée 0–1 après tone mapping ; la sortie est limitée à 0–1. Cette version n'est pas un shader HDR/scRGB/PQ natif.

## Les dix sections

- **01 Overall** : dosage final avec *Master strength*. À 0, l'image originale est restituée.
- **02 Fantasy palette** : exposition en stops, ouverture des ombres, contraste, saturation, vibrance, lumières chaudes, ombres froides, verts frais et protection approximative des tons chair. Cette protection est fondée sur la couleur, pas sur une reconnaissance des visages.
- **03 Painterly** : lissage spatial à préservation des bords. *Brush radius* agrandit les touches ; *Edge preservation* conserve les séparations de couleurs ; *Paint blend* dose le mélange. *Fine detail recovery* conserve une part du détail original. Il ne s'agit pas d'une véritable peinture neuronale ou d'un filtre Kuwahara.
- **04 Cel shading** : simplification de luminance avec transitions réglables. Augmenter *Cel blend* et réduire *Luminance bands* renforce l'aspect animé. C'est une approximation sur l'image finale, pas une modification de l'éclairage du moteur.
- **05 Contours** : intensité, largeur, seuil, transition et couleur des traits. Sans profondeur, les contours sont calculés à partir de la luminance et peuvent aussi souligner les textures. Un seuil plus élevé réduit ce phénomène.
- **06 Optional depth** : contours de profondeur et brume. Désactivés par défaut. Vérifiez la profondeur avec DisplayDepth avant activation : orientation, inversion, mise à l'échelle et far plane doivent être corrects dans ReShade. *Haze start/end* sont des profondeurs normalisées, pas des mètres. Si End <= Start, une petite plage minimale évite une division dégénérée.
- **07 Fairy glow** : bloom doux en demi-résolution. Le seuil choisit les zones lumineuses, la transition évite les découpes, le rayon étale le halo et la teinte le colore. Le shader n'ajoute ni lucioles ni sources lumineuses inexistantes.
- **08 Finish** : netteté, vignette et grain statique optionnel. Le grain reste à zéro par défaut ; aucun effet ne repose sur un bruit qui change chaque frame.
- **09 Depth of Field** : flou proche et lointain, autofocus ou focus manuel, plage nette, transitions, rayons, qualité et diagnostic. Voir la section DoF ci-dessous.
- **10 Comparison and masks** : comparaison gauche originale / droite traitée, séparation déplaçable, deux rectangles de protection HUD réglables en coordonnées normalisées (gauche, haut, droite, bas). Ce sont des masques manuels, pas une détection HUD-less automatique. Leur dégradé évite les coutures dures.

Les rayons en pixels sont référencés à 1080p et s'adaptent à la hauteur. Le filtrage conserve donc des proportions cohérentes en 16:9 et 32:9. Toutes les sections peuvent être ajustées séparément ; cliquer droit sur les réglages dans ReShade permet de revenir à leur défaut.

## Profondeur de champ (DoF)

### Activation et mise au point

Activez **Fantasy Restored - Depth of Field** séparément et placez cette technique **après Fantasy Restored**. Les deux techniques sont dans le même fichier `.fx` ; le DoF peut aussi fonctionner seul. Ses réglages sont regroupés dans **09 Depth of Field**, au-dessus de **10 Comparison and masks** et de Split comparison.

Un depth buffer correct est nécessaire. L'option **Use depth for contours and atmospheric haze** n'a pas besoin d'être activée : elle est indépendante du DoF.

1. Activez **Show focus zones** : vert = zone nette, rouge = flou proche, bleu = flou lointain.
2. Avec **Auto focus**, déplacez **Auto focus point (X,Y)** sur le sujet à garder net. `(0.5,0.5)` est le centre ; pour un personnage, visez son corps plutôt que le décor derrière lui.
3. Ajustez **Sharp focus range**, puis désactivez le diagnostic. Une plage plus grande garde davantage de profondeur nette autour du sujet.
4. Réglez **DoF strength** et les rayons **Near/Far blur radius**. Pour flouter uniquement le fond, désactivez le flou proche (`DoFNear=0`) ; pour l'avant-plan uniquement, désactivez le flou lointain (`DoFFar=0`).

### Principaux réglages

- **Auto focus / Manual focus depth** : l'autofocus utilise la médiane de cinq profondeurs autour du point choisi, sans suivi temporel. Il peut changer brusquement si un autre objet passe sous ce point. Pour un plan stable, désactivez-le et réglez la profondeur manuelle avec le diagnostic. Cette profondeur est linéarisée et normalisée ; elle dépend du far plane et n'est pas exprimée en mètres.
- **Sharp focus range** : tolérance relative autour de la profondeur de focus, 0.20 par défaut (environ +/-20%).
- **Near/Far blur transition** : distance relative au-delà de la plage nette nécessaire pour atteindre le flou maximal. Une valeur plus grande donne une transition plus progressive.
- **Near/Far blur radius** : étendue du flou, référencée à 1080p et adaptée à la hauteur de l'image.
- **Quality** : 0 = Fast (12 échantillons par couche), 1 = Balanced (24), 2 = High (40). Commencez à Balanced ; High est utile pour les grands rayons.
- **Depth edge tolerance** : une valeur plus basse protège davantage les contours mais peut laisser une bordure nette ; une valeur plus haute diffuse mieux le flou mais peut produire des halos.
- **Protect HUD rectangles from DoF** : protège les deux rectangles de la section 10 indépendamment du masque du filtre couleur. Le HUD peut encore diffuser autour des rectangles, car le shader n'a pas accès à une image sans interface.

### Valeurs par défaut à copier

Ajoutez les lignes suivantes dans votre section `[FantasyRestored.fx]` existante, sans créer de section en double. Ce bloc ne coche pas automatiquement la technique DoF dans ReShade.

```ini
DoFStrength=0.650000
DoFAutoFocus=1
DoFFocusPoint=0.500000,0.500000
DoFSpotRadius=3.000000
DoFFocusDepth=0.020000
DoFFocusRange=0.200000
DoFNear=1
DoFFar=1
DoFNearTransition=0.550000
DoFFarTransition=1.500000
DoFNearRadius=4.000000
DoFFarRadius=5.000000
DoFQuality=1
DoFEdgeTolerance=0.040000
DoFDebug=0
DoFProtectHUD=0
```

### Performances et limites

Le DoF ajoute cinq passes : focus 1x1, préparation couleur/profondeur en demi-résolution, flou lointain, flou proche et composition pleine résolution. Ses textures ajoutent environ **42.2 MiB à 5120×1440**. Décochez sa technique pour supprimer son traitement ; les allocations peuvent rester présentes. Aucun gain ou coût précis en FPS n'est garanti.

Le fond et l'avant-plan sont filtrés séparément ; la reconstruction du fond est guidée par la profondeur et les couleurs proches sont prémultipliées pour limiter les liserés. Il n'y a ni lecture CPU de profondeur, ni historique temporel, ni jitter généré par ce shader.

Ce post-traitement ne reconstruit pas les surfaces cachées. Cheveux transparents, particules, silhouettes et HUD peuvent produire des halos ou franges, même avec une profondeur correcte. Évitez les rayons extrêmes. Avec Turkey, appliquez-le de préférence aux images réelles avant FrameGen et calculez les vecteurs de mouvement avant le DoF, si le pipeline le permet.

## Réglages de départ

**Fantasy léger (défaut)** : Master 0.75, Paint blend 0.22, Cel blend 0.14, Contour strength 0.12 et Glow strength 0.10. Le bloom dépend des hautes lumières présentes dans le jeu.

**Anime plus marqué** : Master 0.90, Paint blend 0.40, Brush radius 2.0, Cel blend 0.35, Luminance bands 6, Contour strength 0.25. Vérifiez les cheveux, grilles et feuillages en mouvement : trop de simplification fait scintiller les petits détails.

**Forêt enchantée** : Warm light 0.25, Cool shadows 0.22, Fresh greens 0.35, Glow strength 0.18. Remontez le seuil de bloom si l'ensemble de l'image devient voilé. N'activez la brume qu'avec une profondeur correcte.

**Préserver les visages** : Skin protection 0.8, Paint blend <= 0.30, Cel blend <= 0.20. La teinte de peau est une estimation et peut également protéger des pierres ou tissus de couleur proche.

## Licence

FantasyRestored.fx : MIT (voir LICENSE.txt). ReShade.fxh : CC0, auteur/projet ReShade ; copie de dépendance non modifiée. Sources du compilateur utilisées pour les vérifications : https://github.com/crosire/reshade ; en-tête : https://github.com/crosire/reshade-shaders/tree/slim/Shaders.

Version 3.7 : voir V3.7_NOTES_FR.txt et PARAMETERS_V3.7.ini.
