// Fantasy Restored 5.4 — configurable SDR anime/fantasy post-process
// SPDX-License-Identifier: MIT
#include "ReShade.fxh"
namespace FantasyRestored {


// Optional painterly art-direction tools. Defaults are neutral for full v1.3 compatibility.
// v1.5 optional additions. All default to zero: v1.4 remains visually unchanged.
// v1.6: opt-in structure-aware larger brush and subtle pigment/lighting quantization.
// Defaults are zero to preserve the v1.5 image and preset compatibility.
// Scene-neutral adaptation: opt-in controls, independent of environment palette.

// v1.8: scene-independent, zero-extra-texture-tap painterly controls.
uniform float AdaptivePaintProtection < ui_category = "03 Painterly"; ui_label = "Adaptive brush: structure protection"; ui_tooltip = "Protects high-contrast texture boundaries using existing brush samples. 0 = exact v1.7 brush behavior."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AdaptivePaintThreshold < ui_category = "03 Painterly"; ui_label = "Adaptive brush: structure threshold"; ui_tooltip = "Higher values treat more areas as smooth materials. Keep above zero."; ui_type = "slider"; ui_min = 0.002; ui_max = 0.25; ui_step = 0.002; > = 0.035;
uniform float ToneHighlightProtection < ui_category = "04 Cel shading"; ui_label = "Tone clustering: protect bright sources"; ui_tooltip = "Reduces tonal clustering on bright snow, lava, magic and reflections. 0 = v1.7 behavior."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;

// Depth of Field controls intentionally last in the ReShade parameter UI.

// v3.8: optional, conservative illustration finishing; no extra texture samples.
uniform float AnimeCharacterColorGuard < ui_category = "02 Fantasy palette"; ui_label = "Anime: preserve warm character/material colors"; ui_tooltip = "Limits chroma shifts on skin-like warm pixels. Color heuristic only; it cannot identify characters."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.35;
uniform float AnimeSilhouetteFinish < ui_category = "04 Cel shading"; ui_label = "Anime: silhouette ink finish"; ui_tooltip = "Subtle extra definition of already detected strong edges, avoiding weak texture gradients."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.25;
uniform float AnimeInkNoiseGuard < ui_category = "04 Cel shading"; ui_label = "Anime: ink microtexture protection"; ui_tooltip = "Suppresses faint ink response to fine texture. Uses existing edge signal; no new taps."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.40;

uniform float Strength < ui_category = "01 Overall"; ui_label = "Master strength"; ui_tooltip = "Final blend with the original image."; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.75;
uniform float FantasyPalette < ui_category = "02 Fantasy palette"; ui_label = "Illustrated light and color"; ui_tooltip = "Separates cool shade, foliage and warm light using the source colors. Zero preserves the previous palette."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float SourcePalette < ui_category = "02 Fantasy palette"; ui_label = "Preserve game palette"; ui_tooltip = "Retains the hue and chroma of the source materials while keeping the new luminance and painted surface shapes."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float SourceVibrance < ui_category = "02 Fantasy palette"; ui_label = "Game palette vibrance"; ui_tooltip = "Boosts the existing pigments when the game palette is active. Bright neutrals and gamut limits soften the boost."; ui_type = "slider"; ui_min = 0; ui_max = 0.30; ui_step = 0.005; > = 0.0;
uniform float HighlightRestraint < ui_category = "02 Fantasy palette"; ui_label = "Highlight restraint"; ui_tooltip = "Softens the brightest tones and limits added chroma in bright saturated colors."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float NativeGlow < ui_category = "07 Fairy glow"; ui_label = "Preserve game light effects"; ui_tooltip = "Keeps the original falloff near bright light effects by fading out stylization and added bloom in those areas."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float ContourSurfaceGuard < ui_category = "05 Contours"; ui_label = "Suppress terrain seams"; ui_tooltip = "Requires a visible boundary in the original image to support color and depth ink. Reduces outlines from depth-only seams."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float CelMaterialMask < ui_category = "04 Cel shading"; ui_label = "Protect smooth surfaces"; ui_tooltip = "Uses the animation brush's texture signal to reduce bands in skies, fog and smooth terrain."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float GraphicInk < ui_category = "05 Contours"; ui_label = "Graphic silhouette ink"; ui_tooltip = "Strengthens visible boundaries that continue along the edge. Keeps the line on the shaded side."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float SurfaceAbstraction < ui_category = "03 Painterly"; ui_label = "Painted color shapes"; ui_tooltip = "Groups texture into broader tonal shapes while protecting fine high-contrast features. Uses the animation brush."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeBrushStrength < ui_category = "03 Painterly"; ui_label = "Animation background brush"; ui_tooltip = "Uses soft variance-weighted regions in place of the other painterly filters when enabled. Zero keeps the legacy brush."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeBrushRadius < ui_category = "03 Painterly"; ui_label = "Animation brush radius"; ui_tooltip = "Outer footprint in 1080p pixels. Larger values group finer textures into broader painted shapes."; ui_type = "slider"; ui_min = 3; ui_max = 16; ui_step = 0.25; > = 9.0;
uniform float FantasyContours < ui_category = "05 Contours"; ui_label = "Illustrated material contours"; ui_tooltip = "Adds narrow contours on the darker side of color boundaries. Zero preserves the previous contours."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float Exposure < ui_category = "02 Fantasy palette"; ui_label = "Exposure (stops)"; ui_tooltip = "Brightness before grading."; ui_type = "slider"; ui_min = -2; ui_max = 2; ui_step = 0.01; > = 0.1;
uniform float Lift < ui_category = "02 Fantasy palette"; ui_label = "Shadow lift"; ui_tooltip = "Opens dark foliage without flattening all contrast."; ui_type = "slider"; ui_min = 0; ui_max = 0.25; ui_step = 0.001; > = 0.035;
// v2.7: scene-neutral midtone volume, off by default for exact v2.6 compatibility.
uniform float AnimeVolume < ui_category = "02 Fantasy palette"; ui_label = "Anime volume: selective midtone contrast"; ui_tooltip = "Gently separates midtone volumes without crushing shadows or altering hue. Zero = original v2.6."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeVolumePivot < ui_category = "02 Fantasy palette"; ui_label = "Anime volume: midtone pivot"; ui_tooltip = "Brightness around which midtone contrast is adjusted."; ui_type = "slider"; ui_min = 0.25; ui_max = 0.65; ui_step = 0.01; > = 0.43;
uniform float Contrast < ui_category = "02 Fantasy palette"; ui_label = "Contrast"; ui_tooltip = "Contrast around middle gray."; ui_type = "slider"; ui_min = 0.5; ui_max = 1.8; ui_step = 0.01; > = 1.02;
uniform float Saturation < ui_category = "02 Fantasy palette"; ui_label = "Saturation"; ui_tooltip = "Global color intensity."; ui_type = "slider"; ui_min = 0; ui_max = 2; ui_step = 0.01; > = 1.06;
uniform float Vibrance < ui_category = "02 Fantasy palette"; ui_label = "Vibrance"; ui_tooltip = "Preferentially boosts muted colors."; ui_type = "slider"; ui_min = -1; ui_max = 1; ui_step = 0.01; > = 0.12;
uniform float Warmth < ui_category = "02 Fantasy palette"; ui_label = "Warm light"; ui_tooltip = "Warm highlights and midtones."; ui_type = "slider"; ui_min = -1; ui_max = 1; ui_step = 0.01; > = 0.12;
uniform float Cool < ui_category = "02 Fantasy palette"; ui_label = "Cool shadows"; ui_tooltip = "Adds restrained blue/teal to dark areas."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.1;
uniform float Greens < ui_category = "02 Fantasy palette"; ui_label = "Fresh greens"; ui_tooltip = "Selective green foliage adjustment."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.15;
uniform float Skin < ui_category = "02 Fantasy palette"; ui_label = "Skin protection"; ui_tooltip = "Reduces selective tinting around warm skin-like colors; heuristic, not a face mask."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.65;
uniform float GoldenHighlights < ui_category = "02 Fantasy palette"; ui_label = "Golden sunlit highlights"; ui_tooltip = "Warm bright regions without adding artificial light sources. 0 = original v1.3."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float HighlightRollOff < ui_category = "02 Fantasy palette"; ui_label = "Soft watercolor highlight rolloff"; ui_tooltip = "Compresses highlights for a softer painted look. 0 = original v1.3."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v3.0: opt-in scene-neutral midtone clarity. No extra texture reads or passes.
uniform float AnimeMaterialClarity < ui_category = "02 Fantasy palette"; ui_label = "Anime: material color separation"; ui_tooltip = "Subtly increases existing chroma in midtones without introducing a fixed hue. Zero restores v2.9."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeBrightBalance < ui_category = "02 Fantasy palette"; ui_label = "Anime: bright-scene balance"; ui_tooltip = "Limits extra color treatment in very bright regions; does not recover clipped image data."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float SnowHighlightProtection < ui_category = "02 Fantasy palette"; ui_label = "Anime: bright surface protection"; ui_tooltip = "Reduce added glow and outline ink on low-chroma bright surfaces. Preserves colorful emissive effects; cannot restore clipped white detail. Zero = v3.2."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AdaptiveHighlightCompression < ui_category = "02 Fantasy palette"; ui_label = "Adaptive highlight compression"; ui_tooltip = "Gently compresses recoverable bright SDR values without changing hue; cannot restore clipped whites. 0 = exact v2.3."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AdaptiveHighlightStart < ui_category = "02 Fantasy palette"; ui_label = "Highlight compression start"; ui_tooltip = "Luminance at which the new shoulder begins. Higher values preserve more midtones and luminous materials."; ui_type = "slider"; ui_min = 0.55; ui_max = 0.95; ui_step = 0.01; > = 0.76;
uniform float ShadowPaint < ui_category = "02 Fantasy palette"; ui_label = "Illustrative shadow recovery"; ui_tooltip = "Lift deep shadows selectively without changing bright regions. Use gently to avoid flat shadows."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float ShadowWarmth < ui_category = "02 Fantasy palette"; ui_label = "Shadow pigment warmth"; ui_tooltip = "Adds a subtle warm earthy tint only where illustrative shadow recovery acts."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float PaletteNeutrality < ui_category = "02 Fantasy palette"; ui_label = "Scene-neutral palette protection"; ui_tooltip = "Reduces fixed green/gold/cool tinting while preserving the existing scene colors. 1 = neutral palette."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float ShadowChromaPreserve < ui_category = "02 Fantasy palette"; ui_label = "Preserve shadow material color"; ui_tooltip = "Recover shadow detail without washing out its original hue. 0 = previous shadow lift."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v3.2: input-driven SDR adaptation, opt-in and scene-neutral.
uniform float SceneHighlightGuard < ui_category = "02 Fantasy palette"; ui_label = "Scene adaptive: protect luminous areas"; ui_tooltip = "Reduce added exposure in already bright source pixels; cannot recover clipping."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float SceneChromaGuard < ui_category = "02 Fantasy palette"; ui_label = "Scene adaptive: preserve saturated materials"; ui_tooltip = "Reduce extra saturation on already colorful materials without targeting any hue."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v3.6: independent edge-aware surface simplification, opt-in; zero restores v3.5.
uniform float AnimeSurfaceSimplify < ui_category = "03 Painterly"; ui_label = "Anime: adaptive surface simplification"; ui_tooltip = "Simplify small texture fluctuations while preserving contrasting boundaries. 0 = v3.5. Uses 8 extra taps when enabled."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeSimplifyRadius < ui_category = "03 Painterly"; ui_label = "Anime: simplification radius"; ui_tooltip = "Sampling radius in 1080p pixels; higher values may soften small details."; ui_type = "slider"; ui_min = 0.5; ui_max = 3; ui_step = 0.1; > = 1.2;
uniform float AnimeSimplifyEdge < ui_category = "03 Painterly"; ui_label = "Anime: boundary protection"; ui_tooltip = "Higher values protect contrasting materials and silhouettes."; ui_type = "slider"; ui_min = 0.5; ui_max = 4; ui_step = 0.1; > = 2.2;
uniform float AnimeCleanClarity < ui_category = "03 Painterly"; ui_label = "Anime: clean selective clarity"; ui_tooltip = "Gently smooth flat midtone noise while preserving real structural transitions. Uses existing cross samples; no added texture reads. Zero = v3.4."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float DarkDetailRecovery < ui_category = "02 Fantasy palette"; ui_label = "Dark subject detail recovery"; ui_tooltip = "Gently recover mid-dark colored materials while preserving deep blacks and bright areas. Color/tonal heuristic, not character detection."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float SceneShadowGuard < ui_category = "02 Fantasy palette"; ui_label = "Scene adaptive: preserve dark material depth"; ui_tooltip = "Limit shadow lifting in originally dark pixels."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v3.7: illustration-oriented detail control, neutral across biomes.
uniform float AnimeIllustrationBlend < ui_category = "03 Painterly"; ui_label = "Illustration: clean painted surfaces"; ui_tooltip = "Edge-aware broad color grouping on low-contrast surfaces. Preserves material boundaries and emissive details."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeIllustrationRadius < ui_category = "03 Painterly"; ui_label = "Illustration: broad brush radius"; ui_tooltip = "Sampling distance in 1080p pixels. Does not affect DoF."; ui_type = "slider"; ui_min = 1; ui_max = 5; ui_step = 0.1; > = 2.3;
uniform float AnimeIllustrationEdgeGuard < ui_category = "03 Painterly"; ui_label = "Illustration: silhouette protection"; ui_tooltip = "Higher values reject neighbors with different colors or brightness."; ui_type = "slider"; ui_min = 1; ui_max = 8; ui_step = 0.1; > = 4.0;
uniform bool Paint < ui_category = "03 Painterly"; ui_label = "Enable painterly filter"; ui_type = "checkbox"; > = true;
uniform float PaintMix < ui_category = "03 Painterly"; ui_label = "Paint blend"; ui_tooltip = "Edge-aware texture smoothing."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.22;
uniform float PaintRadius < ui_category = "03 Painterly"; ui_label = "Brush radius (1080p pixels)"; ui_tooltip = "Scales with image height; independent of aspect ratio."; ui_type = "slider"; ui_min = 0.5; ui_max = 6; ui_step = 0.1; > = 1.4;
uniform float PaintEdge < ui_category = "03 Painterly"; ui_label = "Edge preservation"; ui_tooltip = "Higher values preserve more color boundaries."; ui_type = "slider"; ui_min = 1; ui_max = 80; ui_step = 0.5; > = 18.0;
uniform float Detail < ui_category = "03 Painterly"; ui_label = "Fine detail recovery"; ui_tooltip = "Restores some texture after smoothing."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.16;
// v2.8: lightweight, edge-aware surface unification using existing 4 neighbours.
uniform float AnimeSurfaceClean < ui_category = "03 Painterly"; ui_label = "Anime surfaces: adaptive color unification"; ui_tooltip = "Subtle, edge-protected surface smoothing. 0 restores the v2.7 shader."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v3.1: scene-neutral anime material finish. All controls are opt-in.
uniform float AnimeMaterialFinish < ui_category = "03 Painterly"; ui_label = "Anime: clean material finish"; ui_tooltip = "Reduce small surface variations while preserving luminance, silhouettes and material boundaries. Uses existing neighbours."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeFinishGuard < ui_category = "03 Painterly"; ui_label = "Anime: material finish boundary guard"; ui_tooltip = "Higher values protect different materials and fine edges."; ui_type = "slider"; ui_min = 1; ui_max = 10; ui_step = 0.1; > = 5.0;
uniform float AnimeSurfaceGuard < ui_category = "03 Painterly"; ui_label = "Anime surfaces: material boundary guard"; ui_tooltip = "Higher values protect contrasting materials, facial details and silhouettes."; ui_type = "slider"; ui_min = 1; ui_max = 8; ui_step = 0.1; > = 4.0;
uniform float PigmentFlatten < ui_category = "03 Painterly"; ui_label = "Pigment: local tonal flattening"; ui_tooltip = "Compresses fine-scale luminance variation using the existing contour neighbourhood. 0 = original v1.3."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float PigmentThreshold < ui_category = "03 Painterly"; ui_label = "Pigment: preserve strong edges"; ui_tooltip = "Higher values protect more local structure from tonal flattening."; ui_type = "slider"; ui_min = 0.01; ui_max = 0.30; ui_step = 0.005; > = 0.10;
uniform float PigmentChroma < ui_category = "03 Painterly"; ui_label = "Pigment: chroma consolidation"; ui_tooltip = "Mix local surface pigments without introducing additional texture reads; preserves local luminance and strong edges."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v1.9: 3x3 four-quadrant Kuwahara filter, opt-in; scene-neutral and no additional render passes.
uniform float KuwaharaMix < ui_category = "03 Painterly"; ui_label = "Kuwahara: painterly strength"; ui_tooltip = "0 disables the filter. Compact 3x3 four-quadrant variance-guided painterly filter (9 texture samples)."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float KuwaharaRadius < ui_category = "03 Painterly"; ui_label = "Kuwahara: brush radius"; ui_tooltip = "Sampling spacing in 1080p pixels. Larger values produce broader painted areas."; ui_type = "slider"; ui_min = 0.5; ui_max = 5; ui_step = 0.1; > = 1.8;
uniform float KuwaharaEdgeGuard < ui_category = "03 Painterly"; ui_label = "Kuwahara: boundary protection"; ui_tooltip = "Attenuates painterly blending where the chosen quadrant differs from the original pixel."; ui_type = "slider"; ui_min = 0; ui_max = 4; ui_step = 0.1; > = 1.5;
// v2.0: adaptive dual-scale Kuwahara. Mode OFF retains the exact v1.9 branch.
uniform bool KuwaharaAdaptive < ui_category = "03 Painterly"; ui_label = "Kuwahara: selective large regions"; ui_tooltip = "Selects large brush only on smooth, coherent regions. Off reproduces v1.9 exactly."; ui_type = "checkbox"; > = false;
uniform float KuwaharaLargeScale < ui_category = "03 Painterly"; ui_label = "Kuwahara: large brush scale"; ui_tooltip = "Multiplier for the optional second 3x3 footprint. Larger values simplify broad surfaces."; ui_type = "slider"; ui_min = 1.1; ui_max = 3.0; ui_step = 0.1; > = 1.7;
uniform float KuwaharaStructure < ui_category = "03 Painterly"; ui_label = "Kuwahara: structure protection"; ui_tooltip = "Controls suppression of the large scale near boundaries. Larger values protect detail."; ui_type = "slider"; ui_min = 0.0; ui_max = 4.0; ui_step = 0.1; > = 1.5;
uniform float KuwaharaRegionSoftness < ui_category = "03 Painterly"; ui_label = "Kuwahara: region selection softness"; ui_tooltip = "Soft weighting between low-variance quadrants; reduces hard quadrant transitions."; ui_type = "slider"; ui_min = 0.1; ui_max = 4.0; ui_step = 0.1; > = 1.0;
uniform float IllustrativeRelief < ui_category = "03 Painterly"; ui_label = "Illustrative surface relief"; ui_tooltip = "Restores gentle midtone structure after painterly filtering, while protecting hard edges, dark regions and highlights. Scene-neutral; 0 = exact v2.2."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v2.5: chroma-aware pigment consolidation using the existing four composite neighbours.
// Zero means byte-for-byte-equivalent behavior of the v2.4 processing path.
uniform float AdaptiveColorSeparation < ui_category = "03 Painterly"; ui_label = "Adaptive pigment separation"; ui_tooltip = "Consolidates similar nearby colors while rejecting distinct materials. Luminance is preserved; 0 = v2.4."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float PigmentBoundaryGuard < ui_category = "03 Painterly"; ui_label = "Pigment boundary protection"; ui_tooltip = "Higher values reject neighbors with distinct colors; prevents color bleeding at object edges."; ui_type = "slider"; ui_min = 0.5; ui_max = 8; ui_step = 0.1; > = 3.0;
uniform float BrushScaleMix < ui_category = "03 Painterly"; ui_label = "Multiscale brush blend"; ui_tooltip = "Adds a larger edge-aware brush footprint (4 extra samples when enabled). 0 = v1.5."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float BrushScaleRadius < ui_category = "03 Painterly"; ui_label = "Large brush radius multiplier"; ui_tooltip = "Relative to PaintRadius; larger values merge broad material texture."; ui_type = "slider"; ui_min = 1.2; ui_max = 4; ui_step = 0.1; > = 2.2;
uniform float BrushEdgeGuard < ui_category = "03 Painterly"; ui_label = "Large brush edge protection"; ui_tooltip = "Higher values reject colors across material boundaries."; ui_type = "slider"; ui_min = 0.5; ui_max = 4; ui_step = 0.1; > = 1.6;
uniform float AdaptiveBrushGuard < ui_category = "03 Painterly"; ui_label = "Protect material boundaries"; ui_tooltip = "Reduce large-brush mixing across local contrast edges without extra texture samples."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeStructuralInk < ui_category = "05 Contours"; ui_label = "Anime: structural contours only"; ui_tooltip = "Attenuates low-contrast color micro-edges while retaining prominent shapes. Zero preserves v3.2."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeOutlineCleanup < ui_category = "04 Cel shading"; ui_label = "Anime: suppress noisy outlines"; ui_tooltip = "Suppress weak, busy color contours while keeping strong silhouettes. Does not change depth-contour DoF protection."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v3.9: opt-in illustrative shading. Uses the existing SDR color and edge taps;
// this is screen-space tonal stylization, not access to game normals/material IDs.
uniform float AnimeShapeShading < ui_category = "04 Cel shading"; ui_label = "Anime v3.9: shape shading"; ui_tooltip = "Soft midtone shadow grouping, protected in fog, strong chroma and highlights."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeShapeSoftness < ui_category = "04 Cel shading"; ui_label = "Anime v3.9: shape transition"; ui_tooltip = "Higher values keep facial and atmospheric gradients smoother."; ui_type = "slider"; ui_min = 0.1; ui_max = 1; ui_step = 0.01; > = 0.75;
uniform float AnimeContourStructure < ui_category = "05 Contours"; ui_label = "Anime v3.9: structural silhouette"; ui_tooltip = "Reinforces confident contours without additional texture samples; depth contours remain DoF-aware."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v4.0: adaptive illustration; zero preserves the v3.9 rendering path.
uniform float AnimeAdaptiveCel < ui_category = "04 Cel shading"; ui_label = "Anime v4.0: adaptive cel"; ui_tooltip = "Emphasize readable midtones while protecting bright, dark and strongly colored scenes. 0 = v3.9."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeAdaptiveInk < ui_category = "05 Contours"; ui_label = "Anime v4.0: adaptive contours"; ui_tooltip = "Prefer strong silhouette boundaries and reduce weak texture outlines. 0 = v3.9."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v4.1: optional silhouette-focused finishing; reuse existing samples and depth edge signal.
uniform float AnimeSoftCelTransition < ui_category = "04 Cel shading"; ui_label = "Anime v4.1: soft tonal transitions"; ui_tooltip = "Softens cel band transitions while keeping broad illustrated light/shadow shapes. 0 = v4.0."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeSelectiveContours < ui_category = "05 Contours"; ui_label = "Anime v4.1: selective contour confidence"; ui_tooltip = "Suppresses weak color texture edges without affecting depth contour DoF protection. 0 = v4.0."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v4.2: conservative illustration finishing; these are material/tonal heuristics, NOT semantic character masks.
// v4.3: conservative, independently reversible finishing controls.
uniform float AnimeMicrotextureSoftening < ui_category = "03 Painterly"; ui_label = "Anime v4.3: soften microtexture"; ui_tooltip = "Softens low-contrast microtexture with existing neighbor taps; preserves stronger boundaries. 0 = v4.2."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeWarmMaterialProtection < ui_category = "02 Fantasy palette"; ui_label = "Anime v4.3: warm material protection"; ui_tooltip = "Limits additional color grading on warm skin-like materials without removing original scene lighting. Color heuristic, not face detection."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeEmissiveBloomControl < ui_category = "07 Fairy glow"; ui_label = "Anime v4.3: intense glow control"; ui_tooltip = "Reduces glow on very bright, saturated sources; does not change the game's original emissive pixels. 0 = v4.2."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v4.6: restrained highlight protection. Preserve daylight exposure and warm scenery.
// v4.7: source-color-aware daylight correction, without biome detection.
uniform float AnimeV47WarmBrightSeparation < ui_category = "02 Fantasy palette"; ui_label = "Anime v4.7: warm daylight separation"; ui_tooltip = "Reduces flat yellow/orange glare on already bright warm surfaces; preserves saturated emissives and midtones. 0 disables."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.35;
uniform float AnimeV47SnowTintNeutrality < ui_category = "02 Fantasy palette"; ui_label = "Anime v4.7: pale snow tint correction"; ui_tooltip = "Gently reduces pink tint in bright near-neutral surfaces; also affects other pale surfaces. 0 disables."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.25;
// v4.8: final-stage, near-white-only highlight shoulder; avoids broad desert midtone changes.
uniform float AnimeV48PeakLightControl < ui_category = "02 Fantasy palette"; ui_label = "Anime v4.8: peak light control"; ui_tooltip = "Softly reduces only the highest neutral/pale SDR highlights after glow. Preserves saturated lava and ordinary desert midtones. 0 = v4.7."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.30;
uniform float AnimeV48ContourFinish < ui_category = "05 Contours"; ui_label = "Anime v4.8: subtle contour finish"; ui_tooltip = "Slightly strengthens already detected confident structural edges; no extra texture reads. 0 = v4.7."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.25;
uniform float AnimeV46HighlightGuard < ui_category = "02 Fantasy palette"; ui_label = "Anime v4.6: selective bright-surface guard"; ui_tooltip = "Small highlight-only luminance reduction on bright low-chroma surfaces; protects vivid lava and avoids midtone flattening. 0 disables."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.35;
uniform float AnimeV44HighlightProtection < ui_category = "02 Fantasy palette"; ui_label = "Anime v4.4: bright surface rolloff"; ui_tooltip = "Gentle luminance-only shoulder on bright, relatively low-chroma surfaces. Protects colorful lava. Cannot restore clipped details. 0 = v4.3."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.35;
uniform float AnimeV44WarmHighlightGuard < ui_category = "02 Fantasy palette"; ui_label = "Anime v4.4: warm highlight guard"; ui_tooltip = "Restrains extra highlight gain on bright warm surfaces; not face detection. 0 = v4.3."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.30;
uniform float AnimeFineDefinition < ui_category = "04 Cel shading"; ui_label = "Anime v4.2: clean fine definition"; ui_tooltip = "Slightly restores existing local material detail in midtones; protects highlights, fog and warm skin-like colors. 0 = v4.1."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeCleanSilhouettes < ui_category = "05 Contours"; ui_label = "Anime v4.2: clean strong silhouettes"; ui_tooltip = "Refines only confident existing outlines; no extra samples, not a character detector. 0 = v4.1."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform bool Cel < ui_category = "04 Cel shading"; ui_label = "Enable soft cel shading"; ui_type = "checkbox"; > = true;
uniform float CelMix < ui_category = "04 Cel shading"; ui_label = "Cel blend"; ui_tooltip = "Luminance-based approximation; cannot recover the original game lighting."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.14;
uniform float Bands < ui_category = "04 Cel shading"; ui_label = "Luminance bands"; ui_tooltip = "Luminance-based approximation; cannot recover the original game lighting."; ui_type = "slider"; ui_min = 3; ui_max = 20; ui_step = 1; > = 8.0;
uniform float Softness < ui_category = "04 Cel shading"; ui_label = "Band transition softness"; ui_tooltip = "Luminance-based approximation; cannot recover the original game lighting."; ui_type = "slider"; ui_min = 0.05; ui_max = 1; ui_step = 0.01; > = 0.8;
uniform float ToneClustering < ui_category = "04 Cel shading"; ui_label = "Illustrative tone clustering"; ui_tooltip = "Gentle luminance grouping, 0 = v1.5. Avoid high values on faces."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
// v2.9: scene-neutral adaptive tonal grouping; disabled by default for backwards compatibility.
uniform float AnimeToneAdapt < ui_category = "04 Cel shading"; ui_label = "Anime tone: adaptive grouping"; ui_tooltip = "Softly groups midtone lighting while protecting fog, shadows and highlights. 0 = v2.8 tone behavior."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float AnimeToneSoftness < ui_category = "04 Cel shading"; ui_label = "Anime tone: transition softness"; ui_tooltip = "Higher values preserve gradients and avoid banding in motion."; ui_type = "slider"; ui_min = 0.2; ui_max = 1; ui_step = 0.01; > = 0.80;
uniform float ToneClusters < ui_category = "04 Cel shading"; ui_label = "Illustrative tone steps"; ui_type = "slider"; ui_min = 4; ui_max = 24; ui_step = 1; > = 12.0;
// v2.6: opt-in clean anime line selection. Zero keeps the original v2.5 algorithm.
uniform float CleanAnimeLines < ui_category = "05 Contours"; ui_label = "Clean anime: suppress secondary outlines"; ui_tooltip = "Rejects weak and noisy color/depth outlines. 0 = original v2.5 behavior."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform float CleanLineThreshold < ui_category = "05 Contours"; ui_label = "Clean anime: structural edge threshold"; ui_tooltip = "Higher values retain only prominent boundaries; does not change the original InkThreshold."; ui_type = "slider"; ui_min = 0.04; ui_max = 0.35; ui_step = 0.005; > = 0.15;
uniform bool Ink < ui_category = "05 Contours"; ui_label = "Enable contours"; ui_type = "checkbox"; > = true;
uniform float InkMix < ui_category = "05 Contours"; ui_label = "Contour strength"; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.12;
uniform float InkWidth < ui_category = "05 Contours"; ui_label = "Width (1080p pixels)"; ui_type = "slider"; ui_min = 0.5; ui_max = 4; ui_step = 0.1; > = 1.0;
uniform float InkThreshold < ui_category = "05 Contours"; ui_label = "Color edge threshold"; ui_type = "slider"; ui_min = 0.005; ui_max = 0.4; ui_step = 0.005; > = 0.075;
uniform float InkSoft < ui_category = "05 Contours"; ui_label = "Edge transition"; ui_type = "slider"; ui_min = 0.005; ui_max = 0.4; ui_step = 0.005; > = 0.1;
uniform float DepthInk < ui_category = "05 Contours"; ui_label = "Depth edge sensitivity"; ui_type = "slider"; ui_min = 0.1; ui_max = 10; ui_step = 0.1; > = 1.0;
uniform float3 InkColor < ui_category = "05 Contours"; ui_label = "Ink color"; ui_type = "color"; > = float3(0.07,0.10,0.12);
uniform bool DoFProtectDepthContours < ui_category = "06 Optional depth"; ui_label = "Suppress depth contours in DoF blur"; ui_tooltip = "Fade ONLY depth-based outlines using the same focus/CoC formula as DoF. Turn off if the DoF technique is disabled; ReShade FX cannot detect another technique activation."; ui_type = "checkbox"; > = true;
uniform bool UseDepth < ui_category = "06 Optional depth"; ui_label = "Use depth for contours and atmospheric haze"; ui_tooltip = "Enable only after checking ReShade depth orientation and linearization. Off by default."; ui_type = "checkbox"; > = false;
uniform float FogMix < ui_category = "06 Optional depth"; ui_label = "Atmospheric haze strength"; ui_tooltip = "Depth distances depend on ReShade far-plane configuration."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.1;
uniform float FogStart < ui_category = "06 Optional depth"; ui_label = "Haze start (normalized depth)"; ui_tooltip = "Depth distances depend on ReShade far-plane configuration."; ui_type = "slider"; ui_min = 0; ui_max = 0.99; ui_step = 0.001; > = 0.05;
uniform float FogEnd < ui_category = "06 Optional depth"; ui_label = "Haze end (normalized depth)"; ui_tooltip = "Depth distances depend on ReShade far-plane configuration."; ui_type = "slider"; ui_min = 0.001; ui_max = 1; ui_step = 0.001; > = 0.65;
uniform float3 FogColor < ui_category = "06 Optional depth"; ui_label = "Haze color"; ui_type = "color"; > = float3(0.53,0.68,0.70);
uniform float AdaptiveHaze < ui_category = "06 Optional depth"; ui_label = "Scene-colored atmospheric haze"; ui_tooltip = "Blend atmospheric haze toward the scene's own color rather than fixed blue-green. 0 = original haze."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.0;
uniform bool Bloom < ui_category = "07 Fairy glow"; ui_label = "Enable soft glow"; ui_type = "checkbox"; > = true;
uniform float BloomMix < ui_category = "07 Fairy glow"; ui_label = "Glow strength"; ui_tooltip = "Glow is processed at half resolution; no added light sources."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.1;
uniform float BloomThreshold < ui_category = "07 Fairy glow"; ui_label = "Highlight threshold"; ui_tooltip = "Glow is processed at half resolution; no added light sources."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.72;
uniform float BloomKnee < ui_category = "07 Fairy glow"; ui_label = "Threshold softness"; ui_tooltip = "Glow is processed at half resolution; no added light sources."; ui_type = "slider"; ui_min = 0.01; ui_max = 0.5; ui_step = 0.01; > = 0.15;
uniform float BloomRadius < ui_category = "07 Fairy glow"; ui_label = "Glow radius (1080p pixels)"; ui_tooltip = "Glow is processed at half resolution; no added light sources."; ui_type = "slider"; ui_min = 1; ui_max = 20; ui_step = 0.1; > = 4.0;
uniform float3 BloomTint < ui_category = "07 Fairy glow"; ui_label = "Glow tint"; ui_type = "color"; > = float3(1.0,0.96,0.83);
uniform float Sharp < ui_category = "08 Finish"; ui_label = "Final sharpening"; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.08;
uniform float Vignette < ui_category = "08 Finish"; ui_label = "Vignette"; ui_type = "slider"; ui_min = 0; ui_max = 0.6; ui_step = 0.005; > = 0.025;
uniform float Grain < ui_category = "08 Finish"; ui_label = "Static fine grain"; ui_type = "slider"; ui_min = 0; ui_max = 0.05; ui_step = 0.001; > = 0.0;
uniform float DoFStrength < ui_category="98 Depth of Field"; ui_label="DoF strength"; ui_tooltip="Blend with the input of this technique; independent from the fantasy grade."; ui_type="slider"; ui_min=0; ui_max=1; ui_step=0.01; > = 0.65;
uniform bool DoFAutoFocus < ui_category="98 Depth of Field"; ui_label="Auto focus"; ui_tooltip="Samples one small cross at the focus point each frame. No temporal smoothing; use manual focus to lock focus."; ui_type="checkbox"; > = true;
uniform float2 DoFFocusPoint < ui_category="98 Depth of Field"; ui_label="Auto focus point (X, Y)"; ui_tooltip="Normalized screen coordinates; center by default."; ui_type="slider"; ui_min=0; ui_max=1; ui_step=0.005; > = float2(0.5,0.5);
uniform float DoFSpotRadius < ui_category="98 Depth of Field"; ui_label="Auto focus spot radius"; ui_tooltip="Radius in 1080p pixels; median of five depth samples reduces isolated outliers."; ui_type="slider"; ui_min=0; ui_max=30; ui_step=0.5; > = 3.0;
uniform float DoFFocusDepth < ui_category="98 Depth of Field"; ui_label="Manual focus depth"; ui_tooltip="Normalized linear depth from ReShade; easiest to read using the DoF diagnostic view."; ui_type="slider"; ui_min=0.0001; ui_max=1; ui_step=0.0001; > = 0.02;
uniform float DoFFocusRange < ui_category="98 Depth of Field"; ui_label="Sharp focus range"; ui_tooltip="Relative depth tolerance around focus. Higher keeps a larger region sharp."; ui_type="slider"; ui_min=0.01; ui_max=1; ui_step=0.01; > = 0.20;
uniform bool DoFNear < ui_category="98 Depth of Field"; ui_label="Near blur"; ui_tooltip="Blur foreground objects nearer than the focus band."; ui_type="checkbox"; > = true;
uniform bool DoFFar < ui_category="98 Depth of Field"; ui_label="Far blur"; ui_tooltip="Blur background objects farther than the focus band."; ui_type="checkbox"; > = true;
uniform float DoFNearTransition < ui_category="98 Depth of Field"; ui_label="Near blur transition"; ui_tooltip="Relative distance beyond the focus band before maximum near blur."; ui_type="slider"; ui_min=0.02; ui_max=2; ui_step=0.01; > = 0.55;
uniform float DoFFarTransition < ui_category="98 Depth of Field"; ui_label="Far blur transition"; ui_tooltip="Relative distance beyond the focus band before maximum far blur."; ui_type="slider"; ui_min=0.02; ui_max=10; ui_step=0.01; > = 1.50;
uniform float DoFNearRadius < ui_category="98 Depth of Field"; ui_label="Near blur radius"; ui_tooltip="Maximum radius in 1080p pixels, scaled with image height."; ui_type="slider"; ui_min=0; ui_max=24; ui_step=0.5; > = 4.0;
uniform float DoFFarRadius < ui_category="98 Depth of Field"; ui_label="Far blur radius"; ui_tooltip="Maximum radius in 1080p pixels, scaled with image height."; ui_type="slider"; ui_min=0; ui_max=24; ui_step=0.5; > = 5.0;
uniform int DoFQuality < ui_category="98 Depth of Field"; ui_label="Quality: 0 Fast, 1 Balanced, 2 High"; ui_tooltip="12 / 24 / 40 taps per active near/far layer at half resolution. High costs more."; ui_type="slider"; ui_min=0; ui_max=2; ui_step=1; > = 1;
uniform float DoFEdgeTolerance < ui_category="98 Depth of Field"; ui_label="Depth edge tolerance"; ui_tooltip="Relative tolerance for rejecting foreground in background blur. Higher may introduce halos."; ui_type="slider"; ui_min=0.002; ui_max=0.3; ui_step=0.002; > = 0.04;
uniform bool DoFDebug < ui_category="98 Depth of Field"; ui_label="Show focus zones"; ui_tooltip="Green = sharp, red = near blur, blue = far blur."; ui_type="checkbox"; > = false;
uniform bool DoFProtectHUD < ui_category="98 Depth of Field"; ui_label="Protect HUD rectangles from DoF"; ui_tooltip="Uses RectA, RectB and Feather from section 10. Does not remove HUD colors from the blur kernel."; > = false;
uniform bool Split < ui_category = "99 Comparison and masks"; ui_label = "Split comparison"; ui_tooltip = "Original on the left, processed on the right."; ui_type = "checkbox"; > = false;
uniform float SplitPos < ui_category = "99 Comparison and masks"; ui_label = "Split position"; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.01; > = 0.5;
uniform bool MaskHUD < ui_category = "99 Comparison and masks"; ui_label = "Protect two HUD rectangles"; ui_tooltip = "Manual masks only; cannot automatically separate HUD from scene."; ui_type = "checkbox"; > = false;
uniform float4 RectA < ui_category = "99 Comparison and masks"; ui_label = "HUD rectangle A: left, top, right, bottom"; ui_tooltip = "Normalized coordinates."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.005; > = float4(0.0,0.0,0.14,0.12);
uniform float4 RectB < ui_category = "99 Comparison and masks"; ui_label = "HUD rectangle B: left, top, right, bottom"; ui_tooltip = "Normalized coordinates."; ui_type = "slider"; ui_min = 0; ui_max = 1; ui_step = 0.005; > = float4(0.84,0.68,1.0,1.0);
uniform float Feather < ui_category = "99 Comparison and masks"; ui_label = "HUD mask feather"; ui_type = "slider"; ui_min = 0.001; ui_max = 0.05; ui_step = 0.001; > = 0.008;

texture Work { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler WorkS { Texture = Work; AddressU = CLAMP; AddressV = CLAMP; };
texture GlowA { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
texture GlowB { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
sampler GlowAS { Texture = GlowA; AddressU = CLAMP; AddressV = CLAMP; };
sampler GlowBS { Texture = GlowB; AddressU = CLAMP; AddressV = CLAMP; };
texture NativeLightA { Width = (BUFFER_WIDTH+7)/8; Height = (BUFFER_HEIGHT+7)/8; Format = R16F; };
texture NativeLightB { Width = (BUFFER_WIDTH+7)/8; Height = (BUFFER_HEIGHT+7)/8; Format = R16F; };
sampler NativeLightAS { Texture = NativeLightA; AddressU = CLAMP; AddressV = CLAMP; };
sampler NativeLightBS { Texture = NativeLightB; AddressU = CLAMP; AddressV = CLAMP; };
float Luma(float3 c) { return dot(c,float3(0.2126,0.7152,0.0722)); }

float3 FitPalette(float3 chroma, float y)
{
 // Compress toward the same luminance when a channel would leave SDR gamut.
 float upper = max(chroma.r, max(chroma.g, chroma.b));
 float lower = min(chroma.r, min(chroma.g, chroma.b));
 float room = min((1.0-y)/max(upper,0.0001), y/max(-lower,0.0001));
 const float knee = 0.94;
 float reach = rcp(max(room,0.0001));
 float excess = max(reach-knee,0.0);
 float compressed = knee+excess/(1.0+excess/(1.0-knee));
 return y + chroma*min(1.0,compressed*room);
}

float3 IllustratedPalette(float3 graded, float3 source)
{
 float sourceY = Luma(source);
 float maximum = max(source.r,max(source.g,source.b));
 float spread = maximum-min(source.r,min(source.g,source.b));
 float relativeChroma = spread/max(maximum,0.05);
 float toe = smoothstep(0.012,0.10,sourceY);
 float shoulder = 1.0-smoothstep(0.67,0.95,sourceY);
 float shade = toe*(1.0-smoothstep(0.17,0.49,sourceY));
 float muted = 1.0-smoothstep(0.18,0.46,relativeChroma);
 float emissive = smoothstep(0.71,0.98,maximum)*smoothstep(0.36,0.75,relativeChroma)
                  *smoothstep(0.20,0.53,sourceY);

 float yellowGreen = smoothstep(0.004,0.095,min(source.r,source.g)-source.b);
 float greenLead = smoothstep(-0.018,0.041,source.g-source.r);
 float foliage = yellowGreen*greenLead*toe*shoulder;
 float blueLead = smoothstep(0.008,0.13,source.b-source.r)
                * smoothstep(-0.025,0.09,source.b-source.g);
 float amber = smoothstep(0.016,0.23,source.r-source.b)
             * smoothstep(-0.015,0.12,source.r-source.g)*toe;
 float cyan = smoothstep(0.012,0.17,min(source.g,source.b)-source.r);
 float coolSky = blueLead*smoothstep(0.33,0.54,sourceY)
                 *(1.0-smoothstep(0.71,0.87,sourceY))*muted;
 float warmStone = amber*smoothstep(0.36,0.64,sourceY)*(1.0-emissive)*shoulder;
 float redStone = smoothstep(0.095,0.28,source.r-source.g)*shade*(1.0-emissive);
 float paleIce = cyan*smoothstep(0.34,0.66,sourceY)*(1.0-smoothstep(0.29,0.67,relativeChroma));
 float y = Luma(graded);
 float sun = smoothstep(0.23,0.67,sourceY)*shoulder;
 float warmLight = smoothstep(0.10,0.33,sourceY)*shoulder
                   *smoothstep(-0.012,0.075,source.r-source.b)*(1.0-emissive);
 float3 pigment = graded-y;
 float midtones = toe*shoulder;
 pigment *= 1.0+midtones*(0.19*muted+0.16*(1.0-emissive)-0.24*redStone)-0.13*warmStone;
 pigment *= 1.0-0.24*paleIce;
 pigment += float3(-0.034,0.012,0.040)*shade*muted*(1.0-0.70*warmLight);
 pigment += float3(-0.055,0.075,-0.036)*foliage;
 pigment += float3(-0.028,-0.010,0.071)*blueLead*midtones*(0.30+0.70*muted);
 pigment += float3(-0.070,0.002,0.103)*coolSky;
 pigment += float3(0.062,0.021,-0.075)*warmLight*(1.0-0.55*redStone)*(1.0-0.55*warmStone);
 pigment += float3(0.025,0.019,-0.049)*sun*foliage;
 pigment += float3(0.021,0.007,-0.018)*shade*cyan;
 pigment += float3(-0.033,0.003,0.028)*redStone;
 pigment -= Luma(pigment);

 float lift = shade*(0.038+0.015*blueLead+0.025*muted)+0.073*foliage;
 float contrast = 0.11*midtones*clamp(sourceY-0.41,-0.24,0.24);
 float light = 0.022*sun*blueLead+0.034*paleIce-0.085*warmStone-0.039*coolSky-0.018*redStone;
 light += 0.025*shade*warmLight;
 float targetY = saturate(y+(lift+contrast+light)*(1.0-emissive));
 return FitPalette(pigment,targetY);
}

float IllustratedContour(float3 center, float3 n, float3 s, float3 e, float3 w)
{
 float3 horizontal = e-w;
 float3 vertical = s-n;
 float gradientY = length(float2(Luma(horizontal),Luma(vertical)));
 float gradientRGB = sqrt(dot(horizontal,horizontal)+dot(vertical,vertical));
 float y = Luma(center);
 float sensitivity = lerp(1.55,1.0,smoothstep(0.07,0.34,y));
 float response = max(gradientY,gradientRGB*0.52)*sensitivity;
 float threshold = Paint?lerp(1.0,0.72,AnimeBrushStrength):1.0;
 float boundary = smoothstep(0.09,0.29,response/threshold);
 float bright = max(max(Luma(n),Luma(s)),max(Luma(e),Luma(w)));
 float dark = min(min(Luma(n),Luma(s)),min(Luma(e),Luma(w)));
 float darkSide = smoothstep(0.46,0.76,(bright-y)/max(bright-dark,0.025));
 // A thin mark on the shaded side avoids bright halos around silhouettes.
 return boundary*darkSide;
}

float3 Source(float2 uv) { return tex2D(ReShade::BackBuffer,saturate(uv)).rgb; }
float2 Px(float radius) { return BUFFER_PIXEL_SIZE * radius * (BUFFER_HEIGHT / 1080.0); }

float4 SeedNativeLightPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 if(NativeGlow<=0.0) return 0.0;
 float peakY=0.0;
 float seed=0.0;
 // Keep narrow light cores visible through the reduction to one eighth.
 [unroll] for(int y=-3;y<=3;y+=2) {
  [unroll] for(int x=-3;x<=3;x+=2) {
   float3 sampleColor=Source(uv+float2(x,y)*BUFFER_PIXEL_SIZE);
   float ySample=Luma(sampleColor);
   float peak=max(sampleColor.r,max(sampleColor.g,sampleColor.b));
   float candidate=smoothstep(0.80,0.98,peak)*smoothstep(0.48,0.82,ySample);
   peakY=max(peakY,ySample);
   seed=max(seed,candidate);
  }
 }
 if(seed<=0.0) return 0.0;
 float2 radius=max(Px(13.0),8.0*BUFFER_PIXEL_SIZE);
 float left=Luma(Source(uv-float2(radius.x,0)));
 float right=Luma(Source(uv+float2(radius.x,0)));
 float top=Luma(Source(uv-float2(0,radius.y)));
 float bottom=Luma(Source(uv+float2(0,radius.y)));
 // A narrow light falls away on both sides of at least one axis.
 float surround=min(max(left,right),max(top,bottom));
 return float4(seed*smoothstep(0.10,0.37,peakY-surround),0.0,0.0,1.0);
}

float NativeLightBlur(sampler2D field,float2 uv,float2 axis)
{
 const float weights[10]={0.107,0.103,0.093,0.078,0.061,0.045,0.030,0.019,0.011,0.006};
 float value=tex2D(field,uv).r*weights[0];
 [unroll] for(int i=1;i<=9;i++) {
  float2 offset=axis*i;
  value+=(tex2D(field,uv+offset).r+tex2D(field,uv-offset).r)*weights[i];
 }
 return value;
}

float4 NativeLightHorizontalPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 if(NativeGlow<=0.0) return 0.0;
 float amount=NativeLightBlur(NativeLightAS,uv,float2(max(Px(8.5).x,8.0*BUFFER_PIXEL_SIZE.x),0.0));
 return float4(amount,0.0,0.0,1.0);
}

float4 NativeLightVerticalPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 if(NativeGlow<=0.0) return 0.0;
 float amount=NativeLightBlur(NativeLightBS,uv,float2(0.0,max(Px(8.5).y,8.0*BUFFER_PIXEL_SIZE.y)));
 return float4(amount,0.0,0.0,1.0);
}

float3 MaterialVector(float3 c)
{
 return float3(Luma(c),(c.r-c.g)*0.45,(c.b-c.g)*0.45);
}

float GraphicBoundary(float2 uv,float3 sourceDx,float3 sourceDy,float sourceY,out float highlight)
{
 highlight=0.0;
 float2 normal=float2(sourceDx.x,sourceDy.x);
 float2 redGreen=float2(sourceDx.y,sourceDy.y);
 float2 blueGreen=float2(sourceDx.z,sourceDy.z);
 if(dot(redGreen,redGreen)>dot(normal,normal))
  normal=redGreen;
 if(dot(blueGreen,blueGreen)>dot(normal,normal))
  normal=blueGreen;
 float rawContrast=length(normal);
 if(rawContrast<0.037)
  return 0.0;

 normal/=rawContrast;
 float2 across=normal*Px(InkWidth*1.10);
 float2 along=float2(-normal.y,normal.x)*Px(InkWidth*1.35);
 float3 p0=tex2D(WorkS,saturate(uv+across+along)).rgb;
 float3 p1=tex2D(WorkS,saturate(uv+across-along)).rgb;
 float3 n0=tex2D(WorkS,saturate(uv-across+along)).rgb;
 float3 n1=tex2D(WorkS,saturate(uv-across-along)).rgb;
 float3 a=MaterialVector(p0-n0);
 float3 b=MaterialVector(p1-n1);
 // Dot product requires the same material transition in both neighborhoods.
 float continuity=sqrt(max(dot(a,b),0.0));
 float supported=smoothstep(0.037,0.125,rawContrast)*smoothstep(0.028,0.125,continuity);
 float positiveY=Luma((p0+p1)*0.5);
 float negativeY=Luma((n0+n1)*0.5);
 float lumaGap=abs(positiveY-negativeY);
 float darkSide=(max(positiveY,negativeY)-sourceY)/max(lumaGap,0.032);
 float peak=max(max(Luma(p0),Luma(p1)),max(Luma(n0),Luma(n1)));
 highlight=smoothstep(0.77,0.96,peak)*smoothstep(0.20,0.45,lumaGap);
 return supported*smoothstep(0.36,0.73,darkSide)*(1.0-highlight);
}

// Stagger the angular offsets at each radius to avoid repeating rows or columns.
static const float2 AnimationBrushDisk[20]={
 float2(0.25,0.08),float2(-0.08,0.25),float2(-0.25,-0.08),float2(0.08,-0.25),
 float2(0.52,0.35),float2(0.10,0.60),float2(-0.35,0.52),float2(-0.60,0.10),
 float2(-0.52,-0.35),float2(-0.10,-0.60),float2(0.35,-0.52),float2(0.60,-0.10),
 float2(0.90,0.19),float2(0.44,0.80),float2(-0.19,0.90),float2(-0.80,0.44),
 float2(-0.90,-0.19),float2(-0.44,-0.80),float2(0.19,-0.90),float2(0.80,-0.44)
};

float4 AnimationBrush(float2 uv,float3 center)
{
 float2 footprint=Px(AnimeBrushRadius);
 float3 centerMaterial=MaterialVector(center);
 float centerEnergy=dot(centerMaterial,centerMaterial);
 float centerWeight=lerp(0.68,0.43,SurfaceAbstraction);
 const float4 origin=float4(center,1.0)*centerWeight;
 float4 region[4]={origin,origin,origin,origin};
 float initialMoment=centerEnergy*centerWeight;
 float moment[4]={initialMoment,initialMoment,initialMoment,initialMoment};
 float innerLuma=0.0;
 [unroll] for(int i=0;i<20;i++) {
  float2 sampleOffset=AnimationBrushDisk[i];
  float3 sampleColor=Source(uv+sampleOffset*footprint);
  float3 material=MaterialVector(sampleColor);
  float3 delta=material-centerMaterial;
  float spatial=rcp(1.0+0.75*dot(sampleOffset,sampleOffset));
  float weight=spatial*rcp(1.0+12.0*dot(delta,delta));
  float4 sampleSum=float4(sampleColor,1.0)*weight;
  float energy=dot(material,material)*weight;
  float2 sector=0.5+0.5*sampleOffset/length(sampleOffset);
  float4 overlap=float4((1.0-sector.x)*(1.0-sector.y),sector.x*(1.0-sector.y),
                        (1.0-sector.x)*sector.y,sector.x*sector.y);
  overlap*=overlap;
  [unroll] for(int j=0;j<4;j++) {
   region[j]+=sampleSum*overlap[j];
   moment[j]+=energy*overlap[j];
  }
  if(i<4) innerLuma+=material.x*0.25;
 }
 float3 result=0.0;
 float total=0.0;
 float variation=0.0;
 [unroll] for(int i=0;i<4;i++) {
  float inverseWeight=rcp(region[i].a);
  float3 mean=region[i].rgb*inverseWeight;
  float3 material=MaterialVector(mean);
  float variance=max(moment[i]*inverseWeight-dot(material,material),0.0);
  float3 offset=material-centerMaterial;
  float affinity=dot(offset,offset);
  float vote=rcp(1.0+520.0*variance+66.0*affinity);
  float weight=vote*vote*vote;
  result+=mean*weight;
  total+=weight;
  variation+=variance*weight;
 }
 float inverseTotal=rcp(total);
 float3 painted=result*inverseTotal;
 float3 materialOffset=MaterialVector(painted)-centerMaterial;
 float transition=length(materialOffset);
 float boundary=1.0-smoothstep(0.040,0.17,transition);
 // Shape texture masses locally. Continuous steps protect smooth skies and fog.
 float textureSignal=smoothstep(0.00012,0.0016,variation*inverseTotal);
 float y=Luma(painted);
 float bandCount=lerp(12.0,8.0,SurfaceAbstraction);
 float band=y*bandCount;
 float grouped=(floor(band)+smoothstep(0.16,0.84,frac(band)))/bandCount;
 painted+=(grouped-y)*textureSignal*lerp(0.66,0.94,SurfaceAbstraction);
 float preserveDark=smoothstep(0.005,0.035,centerEnergy);
 float accuracy=lerp(0.76,1.0,preserveDark);
 float fineLines=smoothstep(0.012,0.068,abs(centerMaterial.x-innerLuma));
 float detailRetention=lerp(0.58,0.70,SurfaceAbstraction);
 float3 color=lerp(center,painted,AnimeBrushStrength*boundary*accuracy*(1.0-detailRetention*fineLines));
 float celDetail=smoothstep(0.00004,0.00066,variation*inverseTotal);
 return float4(color,celDetail);
}

float4 PaintPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 float3 c=Source(uv);
 if(Paint && AnimeBrushStrength>0.0)
  return AnimationBrush(uv,c);
 if (Paint && PaintMix>0.0) {
  float2 d=Px(PaintRadius); float3 sum=c; float weights=1.0; float localVariance=0.0;
  [unroll] for(int y=-1;y<=1;y++) { [unroll] for(int x=-1;x<=1;x++) {
   if(x!=0 || y!=0) {
    float3 n=Source(uv+float2(x,y)*d);
    float w=exp2(-dot(n-c,n-c)*PaintEdge*4.0)*((x==0||y==0)?0.75:0.5);
    sum+=n*w;weights+=w; localVariance+=dot(n-c,n-c);
   }
  }}
  float3 smoothColor=sum/weights;
  // Adapt the existing 3x3 brush: smooth uniform materials, protect high-contrast edges.
  float structure=smoothstep(AdaptivePaintThreshold*0.25,AdaptivePaintThreshold,max(localVariance/8.0,0.0));
  float brushStrength=PaintMix*(1.0-Detail)*(1.0-AdaptivePaintProtection*structure);
  c=lerp(c,smoothColor,brushStrength);
 }
 // Larger diagonal footprint: low-cost second scale, gated by color distance.
 // The original 3x3 brush remains unchanged; the second scale is opt-in.
 if(Paint && BrushScaleMix>0.0) {
  float3 center=c;
  float2 d=Px(PaintRadius*BrushScaleRadius);
  float3 acc=center*2.0;
  float total=2.0;
  [unroll] for(int i=0;i<4;i++) {
   float2 offset=float2((i&1)==0?-1.0:1.0, i<2?-1.0:1.0)*d;
   float3 sampleColor=Source(uv+offset);
   float difference=dot(sampleColor-center,sampleColor-center);
   float lumaGap=abs(Luma(sampleColor)-Luma(center));
   float edgeReject=1.0+AdaptiveBrushGuard*3.0*smoothstep(0.025,0.18,lumaGap);
   float weight=exp2(-difference*PaintEdge*BrushEdgeGuard*4.0*edgeReject);
   acc+=sampleColor*weight;
   total+=weight;
  }
  float3 largeBrush=acc/total;
  // Preserve the original blend when protection is zero; avoid mixing dissimilar materials.
  float difference=dot(largeBrush-center,largeBrush-center);
  float boundary=smoothstep(AdaptivePaintThreshold*0.25,AdaptivePaintThreshold,difference);
  c=lerp(c,largeBrush,BrushScaleMix*(1.0-Detail)*(1.0-AdaptivePaintProtection*boundary));
 }
 // Selective mode: retain the exact v1.9 minimum-variance 3x3 result as the base.
 // Use a larger footprint only on very smooth, structurally consistent areas.
 if (KuwaharaMix > 0.0 && KuwaharaAdaptive) {
  float2 kd=Px(KuwaharaRadius);
  float3 k[9];
  [unroll] for(int ky=0;ky<3;ky++) { [unroll] for(int kx=0;kx<3;kx++) {
   k[ky*3+kx]=Source(uv+float2(kx-1,ky-1)*kd);
  }}
  float bestVar=1e10; float3 bestMean=c;
  [unroll] for(int q=0;q<4;q++) {
   int ox=q&1; int oy=q>>1;
   float3 a=k[oy*3+ox],b=k[oy*3+ox+1];
   float3 d=k[(oy+1)*3+ox],e=k[(oy+1)*3+ox+1];
   float3 mean=(a+b+d+e)*0.25;
   float3 variance=max((a*a+b*b+d*d+e*e)*0.25-mean*mean,0.0);
   float score=dot(variance,float3(0.2126,0.7152,0.0722));
   if(score<bestVar){bestVar=score;bestMean=mean;}
  }
  float3 painter=bestMean;
  // Both local variance and center-to-quadrant contrast must be low.
  // Avoid the larger texture footprint entirely on detailed pixels.
  float localContrast=dot(bestMean-c,bestMean-c);
  float structure=max(bestVar*max(KuwaharaStructure,0.01),localContrast*0.5);
  float threshold=0.0025/max(KuwaharaRegionSoftness,0.1);
  float flatness=1.0-smoothstep(threshold*0.4,threshold,structure);
  if(flatness>0.12) {
   float2 ld=kd*KuwaharaLargeScale;
   float3 t[9];
   [unroll] for(int ly=0;ly<3;ly++) { [unroll] for(int lx=0;lx<3;lx++) {
    t[ly*3+lx]=Source(uv+float2(lx-1,ly-1)*ld);
   }}
   float largeVar=1e10; float3 largeMean=bestMean;
   [unroll] for(int q=0;q<4;q++) {
    int ox=q&1;int oy=q>>1;
    float3 a=t[oy*3+ox],b=t[oy*3+ox+1];
    float3 d=t[(oy+1)*3+ox],e=t[(oy+1)*3+ox+1];
    float3 mean=(a+b+d+e)*0.25;
    float3 variance=max((a*a+b*b+d*d+e*e)*0.25-mean*mean,0.0);
    float score=dot(variance,float3(0.2126,0.7152,0.0722));
    if(score<largeVar){largeVar=score;largeMean=mean;}
   }
   // Select the large result only if it is consistent with the small region.
   float separation=dot(largeMean-bestMean,largeMean-bestMean);
   float consistency=1.0-smoothstep(0.001,0.012/max(KuwaharaStructure,0.1),separation);
   float largeAllowed=flatness*consistency;
   // Limit large-scale contribution to preserve the crisp v1.9 appearance.
   painter=lerp(bestMean,largeMean,0.35*largeAllowed);
  }
  float delta=dot(painter-c,painter-c);
  float guard=1.0/(1.0+KuwaharaEdgeGuard*delta*32.0);
  c=lerp(c,painter,saturate(KuwaharaMix*guard));
 }
 else {
 // Compact four-quadrant Kuwahara: reuse nine samples for four overlapping 2x2 regions.
 // The minimum-variance quadrant preserves local edges more faithfully than a box blur.
 if (KuwaharaMix > 0.0) {
  float2 kd=Px(KuwaharaRadius);
  float3 k[9];
  [unroll] for (int ky=0; ky<3; ky++) {
   [unroll] for (int kx=0; kx<3; kx++) {
    k[ky*3+kx]=Source(uv+float2(kx-1,ky-1)*kd);
   }
  }
  float bestVar=1e10;
  float3 bestMean=c;
  [unroll] for (int q=0;q<4;q++) {
   int ox=(q&1);
   int oy=(q>>1);
   float3 a=k[oy*3+ox];
   float3 b=k[oy*3+ox+1];
   float3 d=k[(oy+1)*3+ox];
   float3 e=k[(oy+1)*3+ox+1];
   float3 mean=(a+b+d+e)*0.25;
   float3 var=(a*a+b*b+d*d+e*e)*0.25-mean*mean;
   float score=dot(max(var,0.0),float3(0.2126,0.7152,0.0722));
   if(score<bestVar) { bestVar=score; bestMean=mean; }
  }
  float delta=dot(bestMean-c,bestMean-c);
  float guard=1.0/(1.0+KuwaharaEdgeGuard*delta*32.0);
  c=lerp(c,bestMean,saturate(KuwaharaMix*guard));
 }
 }
 // v3.6: bilateral 8-neighbor simplification in the painterly pass.
 // No contour enhancement; DoF remains downstream and retains its own blur.
 if(AnimeSurfaceSimplify>0.0) {
  float3 center=c;
  float2 d=Px(AnimeSimplifyRadius);
  float3 accum=center*2.0;
  float total=2.0;
  float variation=0.0;
  [unroll] for(int j=0;j<8;j++) {
   float2 offset=float2(
    (j==0||j==4||j==6)?-1.0:((j==1||j==5||j==7)?1.0:0.0),
    (j==2||j==4||j==5)?-1.0:((j==3||j==6||j==7)?1.0:0.0)
   )*d;
   float3 sampleColor=Source(uv+offset);
   float3 delta=sampleColor-center;
   float colorDistance=dot(delta,delta);
   float luminanceDistance=abs(Luma(sampleColor)-Luma(center));
   float weight=exp2(-colorDistance*(65.0*AnimeSimplifyEdge))
                *(1.0-smoothstep(0.045,0.15,luminanceDistance));
   accum+=sampleColor*weight;
   total+=weight;
   variation+=min(colorDistance,0.2);
  }
  float structure=1.0-smoothstep(0.008,0.055,variation/8.0);
  float centerY=Luma(center);
  float tonalGuard=smoothstep(0.025,0.12,centerY)
                   *(1.0-smoothstep(0.88,0.99,centerY));
  float blend=AnimeSurfaceSimplify*0.72*structure*tonalGuard;
  c=lerp(center,accum/max(total,0.0001),blend);
 }
 // v3.7: broad bilateral illustration brush. Restrict to quiet surfaces;
 // avoid averaging across silhouettes, colored emissives or snowy highlights.
 if (AnimeIllustrationBlend > 0.0) {
  float3 center=c;
  float centerY=Luma(center);
  float2 d=Px(AnimeIllustrationRadius);
  float3 sum=center*2.0;
  float total=2.0;
  float variation=0.0;
  [unroll] for (int i=0;i<8;i++) {
   float2 o=float2((i==0||i==4||i==6)?-1.0:((i==1||i==5||i==7)?1.0:0.0),
                    (i==2||i==4||i==5)?-1.0:((i==3||i==6||i==7)?1.0:0.0))*d;
   float3 sampleColor=Source(uv+o);
   float3 diff=sampleColor-center;
   float dist=dot(diff,diff);
   float yd=abs(Luma(sampleColor)-centerY);
   float weight=exp2(-dist*(25.0*AnimeIllustrationEdgeGuard))
               *(1.0-smoothstep(0.035,0.13,yd));
   sum+=sampleColor*weight;
   total+=weight;
   variation+=min(dist,0.2);
  }
  float quiet=1.0-smoothstep(0.004,0.045,variation*0.125);
  float protectHighlights=1.0-smoothstep(0.80,0.97,centerY);
  float protectDark= smoothstep(0.035,0.14,centerY);
  float blend=AnimeIllustrationBlend*0.68*quiet*protectHighlights*protectDark;
  c=lerp(center,sum/max(total,0.0001),saturate(blend));
 }
 return float4(c,1);
}
float4 ExtractPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 if(!Bloom || BloomMix<=0.0) return 0;
 float2 d=BUFFER_PIXEL_SIZE*0.5;
 float3 c=(tex2D(WorkS,uv+d).rgb+tex2D(WorkS,uv-d).rgb+
 tex2D(WorkS,uv+float2(d.x,-d.y)).rgb+tex2D(WorkS,uv+float2(-d.x,d.y)).rgb)*0.25;
 float l=Luma(c);float w=smoothstep(BloomThreshold-BloomKnee,BloomThreshold+BloomKnee,l);
 return float4(c*w,1);
}
float4 BlurHPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 if(!Bloom || BloomMix<=0.0) return 0;
 float2 d=float2(Px(BloomRadius).x,0);
 float3 c=tex2D(GlowAS,uv).rgb*0.227027;
 c+=(tex2D(GlowAS,uv+d*1.384615).rgb+tex2D(GlowAS,uv-d*1.384615).rgb)*0.316216;
 c+=(tex2D(GlowAS,uv+d*3.230769).rgb+tex2D(GlowAS,uv-d*3.230769).rgb)*0.070270;
 return float4(c,1);
}
float4 BlurVPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 if(!Bloom || BloomMix<=0.0) return 0;
 float2 d=float2(0,Px(BloomRadius).y);
 float3 c=tex2D(GlowBS,uv).rgb*0.227027;
 c+=(tex2D(GlowBS,uv+d*1.384615).rgb+tex2D(GlowBS,uv-d*1.384615).rgb)*0.316216;
 c+=(tex2D(GlowBS,uv+d*3.230769).rgb+tex2D(GlowBS,uv-d*3.230769).rgb)*0.070270;
 return float4(c,1);
}
float MaskRect(float2 uv,float4 r) {
 float2 lo=min(r.xy,r.zw), hi=max(r.xy,r.zw);
 float2 a=smoothstep(lo,lo+Feather,uv)*(1.0-smoothstep(hi-Feather,hi,uv));
 return a.x*a.y;
}
float FRMedian5(float a,float b,float c,float d,float e) {
 float t=min(a,b); b=max(a,b); a=t;
 t=min(d,e); e=max(d,e); d=t;
 t=min(a,c); c=max(a,c); a=t;
 t=min(b,c); c=max(b,c); b=t;
 t=min(a,d); d=max(a,d); a=t;
 t=min(c,d); d=max(c,d); c=t;
 t=min(b,e); e=max(b,e); b=t;
 t=min(b,c); c=max(b,c); b=t;
 return min(c,e);
}

float4 CompositePS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target
{
 float4 original=tex2D(ReShade::BackBuffer,uv);
 // The split's untouched half and fully masked HUD pixels require no grading.
 if(Strength<=0.0 || (Split && uv.x<SplitPos)) return original;
 if(MaskHUD && max(MaskRect(uv,RectA),MaskRect(uv,RectB))>=1.0) return original;
 // Scene masks based on the original SDR image, with no extra texture samples.
 float3 sceneInput=saturate(original.rgb);
 float sceneY=Luma(sceneInput);
 float sceneMax=max(sceneInput.r,max(sceneInput.g,sceneInput.b));
 float sceneMin=min(sceneInput.r,min(sceneInput.g,sceneInput.b));
 float sceneChroma=(sceneMax-sceneMin)/max(sceneMax,0.04);
 float brightGuard=SceneHighlightGuard*smoothstep(0.40,0.83,sceneY);
 float chromaGuard=SceneChromaGuard*smoothstep(0.30,0.80,sceneChroma);
 float neutralBright=smoothstep(0.68,0.92,sceneY)*(1.0-smoothstep(0.08,0.30,sceneChroma));
 float nativeLight=0.0;
 if(NativeGlow>0.0)
  nativeLight=NativeGlow*smoothstep(0.002,0.029,tex2D(NativeLightAS,uv).r);
 float hotColor=smoothstep(0.73,0.97,sceneMax)*smoothstep(0.22,0.65,sceneMax-sceneMin);
 float darkGuard=SceneShadowGuard*(1.0-smoothstep(0.08,0.34,sceneY));
 float4 painted=tex2D(WorkS,uv);
 float3 c=painted.rgb;
 float3 paintedSource=c;
 float l=Luma(c);
 float3 n=c,s=c,e=c,w=c;
 if((Ink && InkMix>0.0) || Sharp>0.0 || PigmentFlatten>0.0 || PigmentChroma>0.0 || IllustrativeRelief>0.0 || AdaptiveColorSeparation>0.0 || AnimeSurfaceClean>0.0 || AnimeMaterialFinish>0.0 || AnimeCleanClarity>0.0 || AnimeMicrotextureSoftening>0.0) {
  float2 d=Px(InkWidth);
  n=tex2D(WorkS,uv-float2(0,d.y)).rgb; s=tex2D(WorkS,uv+float2(0,d.y)).rgb;
  e=tex2D(WorkS,uv+float2(d.x,0)).rgb; w=tex2D(WorkS,uv-float2(d.x,0)).rgb;
 }
 float edge=0;
 float illustratedEdge=0;
 float graphicEdge=0;
 float lineHighlight=0;
 float3 sourceDx=0.0,sourceDy=0.0;
 if(Ink && InkMix>0.0) {
  if(FantasyContours>0.0)
   illustratedEdge=IllustratedContour(c,n,s,e,w);
  float gradient=length(float2(Luma(e)-Luma(w),Luma(s)-Luma(n)));
  edge=smoothstep(InkThreshold,InkThreshold+InkSoft,gradient);
  // Reweight existing luminance gradient; no additional texture samples.
  float structural=smoothstep(CleanLineThreshold,CleanLineThreshold+0.10,gradient);
  edge*=lerp(1.0,structural,CleanAnimeLines);
  // v3.1: reduce weak micro-edges, but retain strong silhouette gradients.
  float cleanWeight=smoothstep(InkThreshold+0.035,InkThreshold+0.19,gradient);
  edge*=lerp(1.0,cleanWeight,AnimeOutlineCleanup);
  // v3.3: use the existing gradient to reject minor photographic texture edges.
  edge*=lerp(1.0,smoothstep(InkThreshold+0.055,InkThreshold+0.24,gradient),AnimeStructuralInk);
  // v4.1: reject faint texture gradients before merging depth silhouettes.
  // Reuses the existing four color taps; no temporal history or extra sampling.
  if(AnimeSelectiveContours>0.0) {
   float confidence=smoothstep(InkThreshold+0.075,InkThreshold+0.245,gradient);
   edge*=lerp(1.0,0.25+0.75*confidence,AnimeSelectiveContours);
  }

  if(ContourSurfaceGuard>0.0 || GraphicInk>0.0) {
   float2 d=Px(InkWidth);
   sourceDx=MaterialVector(Source(uv+float2(d.x,0))-Source(uv-float2(d.x,0)));
   sourceDy=MaterialVector(Source(uv+float2(0,d.y))-Source(uv-float2(0,d.y)));
   if(ContourSurfaceGuard>0.0) {
    float visibleGradient=sqrt(dot(sourceDx,sourceDx)+dot(sourceDy,sourceDy));
    float colorSupport=lerp(1.0,smoothstep(0.020,0.068,visibleGradient),ContourSurfaceGuard);
    edge*=colorSupport;
    illustratedEdge*=colorSupport;
   }
   if(GraphicInk>0.0)
    graphicEdge=GraphicBoundary(uv,sourceDx,sourceDy,sceneY,lineHighlight);
  }
 }
 float z=0;
 if(UseDepth) {
  z=ReShade::GetLinearizedDepth(uv);
  if(Ink && InkMix>0.0) {
   float2 d=Px(InkWidth);
   float zn=ReShade::GetLinearizedDepth(saturate(uv-float2(0,d.y)));
   float zs=ReShade::GetLinearizedDepth(saturate(uv+float2(0,d.y)));
   float ze=ReShade::GetLinearizedDepth(saturate(uv+float2(d.x,0)));
   float zw=ReShade::GetLinearizedDepth(saturate(uv-float2(d.x,0)));
   float2 depthGradient=float2(ze-zw,zs-zn);
   float depthMagnitude=length(depthGradient);
   float dz=depthMagnitude/max(z,0.002);
   float depthEdge=smoothstep(0.02,0.10,dz*DepthInk);
   // Apply the same signed circle-of-confusion transitions as the DoF resolve.
   // Focus is recomputed for auto-focus because this pass runs BEFORE the DoF
   // Focus pass; sampling DoFFocusTex here would read stale/uninitialized data.
   if(DoFProtectDepthContours && DoFStrength>0.0 &&
      ((DoFFar && DoFFarRadius>0.0) || (DoFNear && DoFNearRadius>0.0))) {
    float focus=DoFFocusDepth;
    if(DoFAutoFocus) {
     float2 fp=DoFFocusPoint, fd=Px(DoFSpotRadius);
     focus=FRMedian5(ReShade::GetLinearizedDepth(fp),
      ReShade::GetLinearizedDepth(saturate(fp+float2(fd.x,0))),
      ReShade::GetLinearizedDepth(saturate(fp-float2(fd.x,0))),
      ReShade::GetLinearizedDepth(saturate(fp+float2(0,fd.y))),
      ReShade::GetLinearizedDepth(saturate(fp-float2(0,fd.y))));
    }
    float delta=(z-focus)/max(focus,0.0001);
    float farCoC=(DoFFar && DoFFarRadius>0.0) ?
     smoothstep(0.0,DoFFarTransition,max(delta-DoFFocusRange,0.0)) : 0.0;
    float nearCoC=(DoFNear && DoFNearRadius>0.0) ?
     smoothstep(0.0,DoFNearTransition,max(-delta-DoFFocusRange,0.0)) : 0.0;
    float blur=saturate(max(farCoC,nearCoC)*DoFStrength);
    depthEdge*=1.0-blur;
   }
   // Color-gradient outlines remain untouched: only depth contribution fades.
   // Suppress tiny depth discontinuities, but retain strong silhouettes.
   float structuralDepth=smoothstep(0.10,0.35,dz*DepthInk);
   depthEdge*=lerp(1.0,structuralDepth,CleanAnimeLines);
   if(ContourSurfaceGuard>0.0 && depthEdge>0.0) {
    // A seam must coincide with a color boundary across the same direction.
    float2 direction=depthGradient/max(depthMagnitude,0.000001);
    float visibleBoundary=length(sourceDx*direction.x+sourceDy*direction.y);
    depthEdge*=lerp(1.0,smoothstep(0.027,0.085,visibleBoundary),ContourSurfaceGuard);
   }
   edge=max(edge,depthEdge);
  }
 }
 // Reuse four already available taps to suppress photographic micro-contrast.
 // Gate the operation at strong local edges to avoid bleeding across silhouettes.
 if(PigmentFlatten>0.0) {
  float3 localMean=(n+s+e+w)*0.25;
  float edgeDelta=abs(Luma(c)-Luma(localMean));
  float preserve=smoothstep(PigmentThreshold*0.35,PigmentThreshold,edgeDelta);
  float targetLuma=lerp(Luma(c),Luma(localMean),PigmentFlatten*(1.0-preserve));
  c*=targetLuma/max(Luma(c),0.001);
 }
 if(PigmentChroma>0.0) {
  float3 meanPigment=(n+s+e+w)*0.25;
  float localEdge=abs(Luma(c)-Luma(meanPigment));
  float edgeGuard=1.0-smoothstep(PigmentThreshold*0.35,PigmentThreshold,localEdge);
  float3 pigment=lerp(c,meanPigment,PigmentChroma*edgeGuard);
  // Maintain center-pixel brightness: chroma is smoothed, not the lighting.
  c=max(pigment*(max(Luma(c),0.001)/max(Luma(pigment),0.001)),0.0);
 }
 // v2.3: mild local luminance shaping, not an additional smoothing pass.
 // The four taps are shared with ink/pigment/sharpening. Never introduce a color cast.
 if(IllustrativeRelief>0.0) {
  float centerY=max(Luma(c),0.0);
  float meanY=max(Luma((n+s+e+w)*0.25),0.0);
  float deltaY=centerY-meanY;
  float edgeGuard=1.0-smoothstep(0.035,0.14,abs(deltaY));
  float midtoneGuard=smoothstep(0.08,0.23,centerY)*(1.0-smoothstep(0.72,0.94,centerY));
  float boost=IllustrativeRelief*0.45*edgeGuard*midtoneGuard;
  float targetY=max(centerY+clamp(deltaY,-0.09,0.09)*boost,0.0);
  c*=targetY/max(centerY,0.001);
 }
 // v2.5: hue-neutral, structure-aware pigment grouping. Reuse four taps above.
 // Weighted neighbours cannot cross a strong color boundary; keep original luminance.
 if(AdaptiveColorSeparation>0.0) {
  float3 center=max(c,0.0);
  float3 cn=max(n,0.0), cs=max(s,0.0), ce=max(e,0.0), cw=max(w,0.0);
  float guard=PigmentBoundaryGuard*18.0;
  float wn=1.0/(1.0+guard*dot(cn-center,cn-center));
  float ws=1.0/(1.0+guard*dot(cs-center,cs-center));
  float we=1.0/(1.0+guard*dot(ce-center,ce-center));
  float ww=1.0/(1.0+guard*dot(cw-center,cw-center));
  float weight=wn+ws+we+ww;
  float3 local=(cn*wn+cs*ws+ce*we+cw*ww)/max(weight,0.0001);
  float localDiff=abs(Luma(center)-Luma(local));
  float protect=1.0-smoothstep(0.025,0.105,localDiff);
  float3 blended=lerp(center,local,AdaptiveColorSeparation*0.28*protect);
  c=max(blended*(max(Luma(center),0.001)/max(Luma(blended),0.001)),0.0);
 }
 // v2.8: preserve silhouettes and fine detail while consolidating similar
 // local surface colors. Uses existing cross taps; no additional GPU samples.
 // Weights reject material transitions; luminance is preserved to avoid flat lighting.
 if(AnimeSurfaceClean>0.0) {
  float3 center=max(c,0.0);
  float3 localMean=(n+s+e+w)*0.25;
  float3 d0=n-center, d1=s-center, d2=e-center, d3=w-center;
  float k=AnimeSurfaceGuard*30.0;
  float a=rcp(1.0+k*dot(d0,d0));
  float b=rcp(1.0+k*dot(d1,d1));
  float d=rcp(1.0+k*dot(d2,d2));
  float f=rcp(1.0+k*dot(d3,d3));
  float3 smoothColor=(n*a+s*b+e*d+w*f)/max(a+b+d+f,0.0001);
  float contrast=abs(Luma(center)-Luma(localMean));
  float edgeProtect=1.0-smoothstep(0.025,0.115,contrast);
  float midtoneProtect=smoothstep(0.055,0.18,Luma(center))*(1.0-smoothstep(0.80,0.98,Luma(center)));
  float blend=AnimeSurfaceClean*0.30*edgeProtect*midtoneProtect;
  float3 result=lerp(center,smoothColor,blend);
  c=max(result*(max(Luma(center),0.0001)/max(Luma(result),0.0001)),0.0);
 }
 // v3.1: chroma-only, edge-aware material finish. No hue assumptions and
 // no additional texture reads. Keep local luminance so faces and lighting stay defined.
 if(AnimeMaterialFinish>0.0) {
  float3 center=max(c,0.0);
  float centerY=max(Luma(center),0.0001);
  float k=AnimeFinishGuard*35.0;
  float3 dn=n-center, ds=s-center, de=e-center, dw=w-center;
  float wn=rcp(1.0+k*dot(dn,dn));
  float ws=rcp(1.0+k*dot(ds,ds));
  float we=rcp(1.0+k*dot(de,de));
  float ww=rcp(1.0+k*dot(dw,dw));
  float3 mean=(n*wn+s*ws+e*we+w*ww)/max(wn+ws+we+ww,0.0001);
  float localDifference=abs(Luma(mean)-centerY);
  float boundary=1.0-smoothstep(0.018,0.09,localDifference);
  float protectedRange=smoothstep(0.07,0.19,centerY)*(1.0-smoothstep(0.78,0.96,centerY));
  float blend=AnimeMaterialFinish*0.34*boundary*protectedRange;
  float3 result=lerp(center,mean,blend);
  c=max(result*(centerY/max(Luma(result),0.0001)),0.0);
 }
 // v3.5: restrained anime clarity without a generic unsharp mask.
 // Reuse four existing neighbors; low-contrast surfaces receive subtle
 // chroma cleanup, while strong material edges and fine high-frequency
 // details are left alone. Preserve center luminance and original hue.
 if(AnimeCleanClarity>0.0) {
  float3 center=max(c,0.0);
  float y=max(Luma(center),0.0001);
  float3 avg=(n+s+e+w)*0.25;
  float difference=abs(y-Luma(avg));
  float3 dn=n-center, ds=s-center, de=e-center, dw=w-center;
  float k=110.0;
  float wn=rcp(1.0+k*dot(dn,dn));
  float ws=rcp(1.0+k*dot(ds,ds));
  float we=rcp(1.0+k*dot(de,de));
  float ww=rcp(1.0+k*dot(dw,dw));
  float3 filtered=(n*wn+s*ws+e*we+w*ww)/max(wn+ws+we+ww,0.0001);
  float smoothRegion=1.0-smoothstep(0.014,0.065,difference);
  float tonalRange=smoothstep(0.045,0.16,y)*(1.0-smoothstep(0.78,0.96,y));
  float blend=AnimeCleanClarity*0.22*smoothRegion*tonalRange;
  float3 result=lerp(center,filtered,blend);
  c=max(result*(y/max(Luma(result),0.0001)),0.0);
 }
 // v4.3: gentle edge-aware microtexture softening, no additional taps.
 if(AnimeMicrotextureSoftening>0.0) {
  float3 center=max(c,0.0);
  float y=max(Luma(center),0.0001);
  float3 dn=n-center, ds=s-center, de=e-center, dw=w-center;
  float k=180.0;
  float wn=rcp(1.0+k*dot(dn,dn));
  float ws=rcp(1.0+k*dot(ds,ds));
  float we=rcp(1.0+k*dot(de,de));
  float ww=rcp(1.0+k*dot(dw,dw));
  float3 local=(n*wn+s*ws+e*we+w*ww)/max(wn+ws+we+ww,0.0001);
  float difference=abs(y-Luma(local));
  float quiet=1.0-smoothstep(0.012,0.075,difference);
  float mid=smoothstep(0.07,0.20,y)*(1.0-smoothstep(0.73,0.94,y));
  float blend=AnimeMicrotextureSoftening*0.16*quiet*mid*(1.0-0.65*brightGuard);
  float3 result=lerp(center,local,blend);
  c=max(result*(y/max(Luma(result),0.0001)),0.0);
 }
 // v4.2: bounded fine-detail recovery using the four existing neighbors.
 // Keep warm skin-like gradients smooth and avoid amplifying snow/lava highlights.
 if(AnimeFineDefinition>0.0) {
  float3 localMean=(n+s+e+w)*0.25;
  float y=Luma(c);
  float mid=smoothstep(0.12,0.28,y)*(1.0-smoothstep(0.68,0.86,y));
  float warmSkin=smoothstep(0.035,0.14,c.r-c.b)*smoothstep(0.0,0.13,c.g);
  float guard=(1.0-0.80*brightGuard)*(1.0-0.65*chromaGuard)*(1.0-0.65*darkGuard);
  float3 detail=c-localMean;
  float detailLimit=smoothstep(0.006,0.035,abs(Luma(detail)))*(1.0-smoothstep(0.09,0.20,abs(Luma(detail))));
  c=max(c+detail*(0.11*AnimeFineDefinition*mid*guard*detailLimit*(1.0-0.65*warmSkin)),0.0);
 }
 if(Sharp>0.0) c=max(c+(c-(n+s+e+w)*0.25)*Sharp,0.0);
 c*=exp2(Exposure*(1.0-0.85*brightGuard));
 l=Luma(c);
 c+=Lift*(1.0-smoothstep(0.0,0.55,l))*(1.0-0.70*darkGuard)*(1.0-0.65*brightGuard);
 if(ShadowPaint>0.0) {
  float shadow=1.0-smoothstep(0.08,0.48,max(l,0.0));
  float gain=ShadowPaint*shadow*(1.0-0.70*darkGuard);
  float liftAmount=gain*(0.13+0.10*saturate(l));
  float3 huePreserving= max(c,0.0)/max(Luma(max(c,0.0)),0.025);
  c+=liftAmount*lerp(float3(1.0,1.0,1.0),huePreserving,ShadowChromaPreserve);
  if(ShadowWarmth>0.0) c+=float3(0.025,0.012,-0.012)*(gain*ShadowWarmth*(1.0-PaletteNeutrality));
 }

 // v3.4: bounded, chroma-aware recovery of mid-dark material detail.
 // Uses the ungraded input for scene classification; no additional samples.
 // Not a semantic character mask: dark colored scenery can also be affected.
 if(DarkDetailRecovery>0.0) {
  float midDark=smoothstep(0.045,0.16,sceneY)*(1.0-smoothstep(0.29,0.52,sceneY));
  float material=smoothstep(0.07,0.25,sceneChroma);
  float influence=midDark*lerp(0.25,1.0,material);
  float y=max(Luma(max(c,0.0)),0.0001);
  float lift=DarkDetailRecovery*0.055*influence;
  float desired=y+lift*(1.0-smoothstep(0.32,0.60,y));
  c=max(c,0.0)*(desired/y);
 }
 c=(c-0.18)*Contrast+0.18;
 // v2.7: low-cost luminance-only midtone separation.
 // Soft guards avoid boosting deep shadows, sky glare and emissive effects.
 if(AnimeVolume>0.0) {
  float y=max(Luma(c),0.0);
  float guard=smoothstep(0.08,0.24,y)*(1.0-smoothstep(0.70,0.94,y));
  float delta=clamp(y-AnimeVolumePivot,-0.28,0.28);
  float desired=max(y+delta*(AnimeVolume*0.28)*guard,0.0);
  c*=desired/max(y,0.0001);
 }

 l=max(Luma(c),0.0);
 float mx=max(c.r,max(c.g,c.b)),mn=min(c.r,min(c.g,c.b));
 float sat=1.0+Vibrance*(1.0-saturate((mx-mn)/max(mx,0.001)));
 c=lerp(float3(l,l,l),c,lerp(Saturation*sat,1.0,chromaGuard*0.85));
 float skin=smoothstep(0.0,0.10,c.r-c.b)*(1.0-smoothstep(0.05,0.25,c.g-c.r));
 float protection=(1.0-skin*Skin)*(1.0-0.65*AnimeWarmMaterialProtection*skin);
 float light=smoothstep(0.12,0.8,l);
 c+=float3(0.055,0.018,-0.035)*Warmth*(1.0-PaletteNeutrality)*light*protection*(1.0-0.7*chromaGuard);
 c+=float3(-0.022,0.012,0.055)*Cool*(1.0-PaletteNeutrality)*(1.0-light)*protection;
 float green=smoothstep(0.015,0.20,c.g-max(c.r,c.b));
 c+=float3(-0.03,0.075,0.012)*Greens*(1.0-PaletteNeutrality)*green;
 // v3.0: neutral chroma separation, protected in near-black, sky glare
 // and near-white highlights. No color-classification or extra samples.
 if(AnimeMaterialClarity>0.0) {
  float y=max(Luma(c),0.0);
  float3 chroma=c-float3(y,y,y);
  float chromaMagnitude=max(abs(chroma.r),max(abs(chroma.g),abs(chroma.b)));
  float guard=smoothstep(0.08,0.25,y)*(1.0-smoothstep(0.70,0.94,y));
  float colored=smoothstep(0.012,0.09,chromaMagnitude);
  c+=chroma*(AnimeMaterialClarity*0.18*guard*colored)*(1.0-0.85*chromaGuard);
 }
 // Selective warm illumination and shoulder compression, both opt-in.
 if(GoldenHighlights>0.0) {
  float brightness=smoothstep(0.28,0.90,max(Luma(c),0.0));
  c+=float3(0.065,0.035,-0.015)*GoldenHighlights*(1.0-PaletteNeutrality)*brightness*protection*(1.0-0.8*brightGuard);
 }
 if(HighlightRollOff>0.0) {
  float brightness=max(Luma(c),0.0);
  float shoulder=max(brightness-0.55,0.0);
  float compressed=0.55+shoulder/(1.0+shoulder*HighlightRollOff*1.6);
  c*=lerp(1.0,compressed/max(brightness,0.001),step(0.55,brightness));
 }
 // Opt-in scene-neutral SDR shoulder. Only bright values are affected;
 // preserve hue by scaling all channels equally and avoid clipping in midtones.
 // No extra texture samples. Fully clipped whites cannot be recovered.
 if(AdaptiveHighlightCompression>0.0) {
  float lum=max(Luma(c),0.0);
  float start=AdaptiveHighlightStart;
  float delta=max(lum-start,0.0);
  float shoulder=delta/(1.0+delta*AdaptiveHighlightCompression*2.0);
  float target=lum-(delta-shoulder)*smoothstep(start,min(start+0.12,1.0),lum);
  c*=target/max(lum,0.0001);
 }
 // v4.4: protect recoverable bright sand, snow and warm materials.
 // Classification uses original SDR pixels: no biome/character detection.
 // Highly saturated lava and magic remain largely unaffected.
 if(AnimeV44HighlightProtection>0.0 || AnimeV44WarmHighlightGuard>0.0) {
  float y=max(Luma(max(c,0.0)),0.0001);
  float bright=smoothstep(0.64,0.93,sceneY);
  float neutral=1.0-smoothstep(0.25,0.65,sceneChroma);
  float warm=smoothstep(0.025,0.16,sceneInput.r-sceneInput.b)
            *smoothstep(0.22,0.52,sceneInput.g)
            *(1.0-smoothstep(0.42,0.75,sceneChroma));
  float influence=bright*(AnimeV44HighlightProtection*neutral*0.38
                  +AnimeV44WarmHighlightGuard*warm*0.18);
  float excess=max(y-0.68,0.0);
  float target=y-excess*influence;
  c*=target/y;
 }
 // v4.6: limit only the upper end of bright, low-chroma SDR surfaces.
 // No broad midtone shoulder: desert sunlight and contrast remain intact.
 if(AnimeV46HighlightGuard>0.0) {
  float y=max(Luma(max(c,0.0)),0.0001);
  float sourceBright=smoothstep(0.76,0.96,sceneY);
  float neutral=1.0-smoothstep(0.25,0.65,sceneChroma);
  float lavaGuard=1.0-smoothstep(0.48,0.80,sceneChroma);
  float amount=AnimeV46HighlightGuard*0.24*sourceBright*neutral*lavaGuard;
  float excess=max(y-0.79,0.0);
  c*=max(y-excess*amount,0.0)/y;
 }
 // v4.7: selective bright warm material separation. Use input chroma to
 // avoid suppressing lava; protect medium-lit skin-like colors by source brightness.
 if(AnimeV47WarmBrightSeparation>0.0) {
  float y=max(Luma(max(c,0.0)),0.0001);
  float warm=smoothstep(0.06,0.22,sceneInput.r-sceneInput.b)
            *smoothstep(0.015,0.12,sceneInput.r-sceneInput.g);
  float bright=smoothstep(0.66,0.94,sceneY);
  float nonEmissive=1.0-smoothstep(0.40,0.73,sceneChroma);
  float influence=AnimeV47WarmBrightSeparation*warm*bright*nonEmissive;
  float excess=max(y-0.72,0.0);
  c*=max(y-excess*influence*0.32,0.0)/y;
 }
 // v4.7: temper magenta bias on pale high-value surfaces, without
 // neutralizing strongly colored light or dark environments.
 if(AnimeV47SnowTintNeutrality>0.0) {
  float pale=smoothstep(0.69,0.92,sceneY)
            *(1.0-smoothstep(0.11,0.35,sceneChroma));
  float magenta=max(c.r-c.g,0.0)*smoothstep(0.0,0.07,c.b-c.g);
  float correction=min(magenta,0.10)*AnimeV47SnowTintNeutrality*pale*0.38;
  c.g+=correction;
 }
 // v3.0: gentle luminance-only compression of bright but non-clipped
 // regions; avoids dimming the darkest materials. Does not invent detail.
 if(AnimeBrightBalance>0.0) {
  float y=max(Luma(c),0.0);
  float excess=max(y-0.64,0.0);
  float amount=AnimeBrightBalance*0.22;
  float target=y-excess*(amount*smoothstep(0.64,0.93,y));
  c*=target/max(y,0.0001);
 }
 // Group subtle local tonal differences without adding texture reads.
 // Smooth band boundaries to avoid hard posterization on skin and fog.
 if(ToneClustering>0.0) {
  float lum=max(Luma(c),0.0001);
  float scaled=saturate(lum)*ToneClusters;
  float fraction=frac(scaled);
  float softened=smoothstep(0.15,0.85,fraction);
  float clustered=(floor(scaled)+softened)/ToneClusters;
  float highlightGuard=1.0-ToneHighlightProtection*smoothstep(0.70,1.05,lum);
  float blend=ToneClustering*0.35*highlightGuard;
  // v2.9: no additional pass or texture lookup. A wider smoothstep and
  // reduced step displacement protect gentle gradients (fog, sky, water).
  if(AnimeToneAdapt>0.0) {
   float halfWidth=lerp(0.24,0.49,AnimeToneSoftness);
   float softFraction=smoothstep(0.5-halfWidth,0.5+halfWidth,fraction);
   float adaptiveCluster=(floor(scaled)+softFraction)/ToneClusters;
   float midtoneGuard=smoothstep(0.10,0.27,lum)*(1.0-smoothstep(0.65,0.90,lum));
   float bandDelta=adaptiveCluster-lum;
   float safeDelta=clamp(bandDelta,-0.018,0.018);
   float safeTarget=max(lum+safeDelta,0.0001);
   float adaptiveBlend=ToneClustering*0.48*midtoneGuard;
   float legacyRatio=lerp(1.0,clustered/lum,blend);
   float adaptiveRatio=lerp(1.0,safeTarget/lum,adaptiveBlend);
   c*=lerp(legacyRatio,adaptiveRatio,AnimeToneAdapt);
  } else {
   c*=lerp(1.0,clustered/lum,blend);
  }
 }
 // v3.9: gently separate midtone light/shadow without globally shifting hue.
 // Avoid flat snow/lava highlights, dark fog, and strongly chromatic lighting.
 if(AnimeShapeShading>0.0) {
  float y=max(Luma(c),0.0001);
  float midGuard=smoothstep(0.10,0.27,y)*(1.0-smoothstep(0.68,0.90,y));
  float sceneGuard=(1.0-0.65*chromaGuard)*(1.0-0.65*brightGuard)*(1.0-0.65*darkGuard);
  float skinGuard=1.0-0.55*skin*Skin;
  float transition=lerp(0.035,0.18,AnimeShapeSoftness);
  float shadow=smoothstep(0.44-transition,0.44+transition,y);
  float tonalOffset=(shadow-1.0)*0.035 + shadow*0.008;
  float target=max(y+tonalOffset*AnimeShapeShading*midGuard*sceneGuard*skinGuard,0.0001);
  c*=target/y;
 }
 if(Cel && CelMix>0.0) {
  l=max(Luma(c),0.0001);float v=saturate(l)*Bands;
  // v4.1: widen tonal transitions without modifying band count or scene hue.
  float transitionSoftness=lerp(Softness,max(Softness,0.96),AnimeSoftCelTransition);
  float t=smoothstep(0.5-transitionSoftness*0.5,0.5+transitionSoftness*0.5,frac(v));
  float target=(floor(v)+t)/Bands;
  float3 celColor=c*(target/l);
  float celStrength=CelMix*(1.0-skin*Skin*0.5);
  if(AnimeAdaptiveCel>0.0) {
   float midtone=smoothstep(0.10,0.27,l)*(1.0-smoothstep(0.70,0.90,l));
   float protection=(1.0-0.65*brightGuard)*(1.0-0.55*darkGuard)*(1.0-0.65*chromaGuard);
   float adaptiveFactor=lerp(1.0,0.78+0.40*midtone*protection,AnimeAdaptiveCel);
   celStrength*=adaptiveFactor;
  }
  if(CelMaterialMask>0.0)
   celStrength*=lerp(1.0,lerp(0.16,1.0,painted.a),CelMaterialMask);
  c=lerp(c,celColor,saturate(celStrength));
 }
 if(UseDepth && FogMix>0.0) {
  float haze=smoothstep(FogStart,max(FogEnd,FogStart+0.001),z)*FogMix;
  float3 sceneHaze = lerp(FogColor,lerp(c,float3(Luma(c),Luma(c),Luma(c)),0.20),AdaptiveHaze);
  c=lerp(c,sceneHaze,haze);
 }
 if(Ink && InkMix>0.0) {
  // Reuse the identical saturated edge signal across the five contour gates.
  float boundedEdge=saturate(edge);
  // Strengthen only confident existing edges; do not create a new edge detector.
  float strongEdge=smoothstep(0.30,0.82,boundedEdge);
  float cleanedEdge=lerp(edge,edge*strongEdge,AnimeInkNoiseGuard*0.55);
  float finalEdge=saturate(cleanedEdge+AnimeSilhouetteFinish*0.18*strongEdge);
  // Reinforce only the already-detected strong edges, with scene-neutral gating.
  float shapeEdge=smoothstep(0.50,0.92,boundedEdge);
  finalEdge=saturate(finalEdge+AnimeContourStructure*0.16*shapeEdge*(1.0-0.45*neutralBright));
  if(AnimeAdaptiveInk>0.0) {
   float confident=smoothstep(0.32,0.78,boundedEdge);
   float silhouetteOnly=finalEdge*(0.55+0.45*confident);
   finalEdge=lerp(finalEdge,silhouetteOnly,AnimeAdaptiveInk);
  }
  // v4.2: only already-confident edges gain a small, highlight-aware finish.
  float strongSilhouette=smoothstep(0.68,0.96,boundedEdge);
  finalEdge=saturate(finalEdge+AnimeCleanSilhouettes*0.09*strongSilhouette*(1.0-0.60*neutralBright));
  // v4.8: strengthen existing confident silhouettes only, not microtexture.
  float v48Strong=smoothstep(0.52,0.91,boundedEdge);
  finalEdge=saturate(finalEdge+AnimeV48ContourFinish*0.105*v48Strong*(1.0-0.45*neutralBright));
  float lineScale=1.0-0.85*GraphicInk*lineHighlight;
  c=lerp(c,InkColor,finalEdge*InkMix*lineScale*(1.0-0.60*SnowHighlightProtection*neutralBright));
  if(FantasyContours>0.0) {
   float darkProtection=smoothstep(0.025,0.13,sceneY);
   c*=1.0-illustratedEdge*FantasyContours*min(1.4*InkMix,0.25)*lineScale*darkProtection*(1.0-0.75*neutralBright);
  }
  if(GraphicInk>0.0) {
   float inkOpacity=GraphicInk*min(1.7*InkMix,0.36);
   c*=1.0-graphicEdge*inkOpacity*(1.0-0.70*neutralBright);
  }
 }
 if(Bloom && BloomMix>0.0) {
  float intenseSource=smoothstep(0.66,0.96,sceneY)*smoothstep(0.24,0.72,sceneChroma);
  float glowGuard=1.0-0.45*AnimeEmissiveBloomControl*intenseSource;
  glowGuard*=1.0-nativeLight;
  c+=tex2D(GlowAS,uv).rgb*BloomTint*BloomMix*(1.0-0.70*SnowHighlightProtection*neutralBright)*glowGuard;
 }
 // v4.8: final SDR peak shoulder after bloom, with no global exposure shift.
 // Restrict to recoverable high-value pixels; chromatic emissives remain protected.
 if(AnimeV48PeakLightControl>0.0) {
  float y=max(Luma(max(c,0.0)),0.0001);
  float chroma=max(c.r,max(c.g,c.b))-min(c.r,min(c.g,c.b));
  float pale=1.0-smoothstep(0.28,0.68,chroma);
  float gate=smoothstep(0.81,0.96,y);
  float excess=max(y-0.81,0.0);
  float shoulder=excess/(1.0+excess*AnimeV48PeakLightControl*1.6);
  float target=y-(excess-shoulder)*gate*pale;
  c*=target/y;
 }
 float2 p=uv*2.0-1.0;
 c*=1.0-Vignette*smoothstep(0.15,1.6,dot(p,p));
 if(Grain>0.0) {
  float noise=frac(sin(dot(floor(uv*BUFFER_SCREEN_SIZE),float2(12.9898,78.233)))*43758.5453)-0.5;
  c+=noise*Grain;
 }
 float mask=MaskHUD?max(MaskRect(uv,RectA),MaskRect(uv,RectB)):0.0;
 float amount=Strength*(1.0-mask);
 if(Split) amount*=step(SplitPos,uv.x);
 // Retain the original chroma of warm, skin-like materials without flattening
 // the shader's lighting. This is not semantic segmentation.
 if(AnimeCharacterColorGuard>0.0) {
  float3 base=original.rgb;
  float warmth=smoothstep(0.015,0.11,base.r-base.g);
  float redLead=smoothstep(0.015,0.12,base.g-base.b);
  float y=Luma(base);
  float range=smoothstep(0.09,0.22,y)*(1.0-smoothstep(0.78,0.96,y));
  float guard=AnimeCharacterColorGuard*warmth*redLead*range*0.42;
  float targetY=max(Luma(c),0.0001);
  float3 originalChroma=base*(targetY/max(y,0.0001));
  c=lerp(c,originalChroma,guard);
 }
 if(FantasyPalette>0.0)
  c=lerp(c,IllustratedPalette(c,sceneInput),FantasyPalette);
 float resolvedY=saturate(Luma(c));
 float unrestrictedY=resolvedY;
 if(HighlightRestraint>0.0) {
  float upperTone=smoothstep(0.66,0.95,resolvedY);
  float excess=max(resolvedY-0.67,0.0);
  float coloredGlare=hotColor*smoothstep(0.38,0.79,resolvedY);
  float shoulder=upperTone*excess*0.22+coloredGlare*0.024;
  float reduction=HighlightRestraint*shoulder;
  c*=1.0-reduction/max(resolvedY,0.0001);
  resolvedY-=reduction;
 }
 if(SourcePalette>0.0) {
  float paintedY=Luma(paintedSource);
  float3 sourceChroma=sceneInput-sceneY;
  float3 paintedChroma=paintedSource-paintedY;
  float3 pigment=lerp(sourceChroma,paintedChroma,0.55);
  float gain=1.0;
  if(SourceVibrance>0.0) {
   float richColor=smoothstep(0.22,0.72,sceneMax-sceneMin);
   gain+=SourceVibrance*(1.0-0.22*richColor)*(1.0-0.30*neutralBright);
  }
  float hotRestraint=HighlightRestraint*hotColor;
  float limitedGain=lerp(gain,min(gain,0.97),hotRestraint);
  float3 paletteColor=FitPalette(pigment*limitedGain,resolvedY);
  if(hotRestraint>0.0) {
   // The luminance shoulder opens red/blue headroom. Keep that headroom
   // from making hot pigments more saturated than the unrestricted fit.
   float3 reference=FitPalette(pigment*gain,unrestrictedY);
   float referenceSpread=max(reference.r,max(reference.g,reference.b))-min(reference.r,min(reference.g,reference.b));
   float paletteSpread=max(paletteColor.r,max(paletteColor.g,paletteColor.b))-min(paletteColor.r,min(paletteColor.g,paletteColor.b));
   float chromaLimit=saturate(referenceSpread*(1.0-0.09*hotRestraint)/max(paletteSpread,0.0001));
   paletteColor=resolvedY+(paletteColor-resolvedY)*chromaLimit;
  }
  c=lerp(c,paletteColor,SourcePalette);
 }
 if(NativeGlow>0.0)
  c=lerp(c,original.rgb,nativeLight);
 return float4(lerp(original.rgb,saturate(c),amount),original.a);
}
}
technique FantasyRestored < ui_label="Fantasy Restored"; ui_tooltip="SDR anime/fantasy grading, painterly smoothing, soft cel shading, contours and fairy glow. Optional depth is off by default."; >
{
 pass Paint { VertexShader=PostProcessVS; PixelShader=FantasyRestored::PaintPS; RenderTarget=FantasyRestored::Work; }
 pass Extract { VertexShader=PostProcessVS; PixelShader=FantasyRestored::ExtractPS; RenderTarget=FantasyRestored::GlowA; }
 pass BlurH { VertexShader=PostProcessVS; PixelShader=FantasyRestored::BlurHPS; RenderTarget=FantasyRestored::GlowB; }
 pass BlurV { VertexShader=PostProcessVS; PixelShader=FantasyRestored::BlurVPS; RenderTarget=FantasyRestored::GlowA; }
 pass NativeLightSeed { VertexShader=PostProcessVS; PixelShader=FantasyRestored::SeedNativeLightPS; RenderTarget=FantasyRestored::NativeLightA; }
 pass NativeLightH { VertexShader=PostProcessVS; PixelShader=FantasyRestored::NativeLightHorizontalPS; RenderTarget=FantasyRestored::NativeLightB; }
 pass NativeLightV { VertexShader=PostProcessVS; PixelShader=FantasyRestored::NativeLightVerticalPS; RenderTarget=FantasyRestored::NativeLightA; }
 pass Composite { VertexShader=PostProcessVS; PixelShader=FantasyRestored::CompositePS; }
}

namespace FantasyRestored {

texture DoFFocusTex { Width=1; Height=1; Format=RGBA16F; };
sampler DoFFocusS { Texture=DoFFocusTex; AddressU=CLAMP; AddressV=CLAMP; };
texture DoFData { Width=BUFFER_WIDTH/2; Height=BUFFER_HEIGHT/2; Format=RGBA16F; };
texture DoFFarTex { Width=BUFFER_WIDTH/2; Height=BUFFER_HEIGHT/2; Format=RGBA16F; };
texture DoFNearTex { Width=BUFFER_WIDTH/2; Height=BUFFER_HEIGHT/2; Format=RGBA16F; };
sampler DoFDataS { Texture=DoFData; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
sampler DoFFarS { Texture=DoFFarTex; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
sampler DoFNearS { Texture=DoFNearTex; AddressU=CLAMP; AddressV=CLAMP; };
float4 FRFocusPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target {
 float z=DoFFocusDepth;
 if(DoFAutoFocus && DoFStrength>0.0) {
  float2 p=DoFFocusPoint;float2 d=Px(DoFSpotRadius);
  z=FRMedian5(ReShade::GetLinearizedDepth(p),
   ReShade::GetLinearizedDepth(saturate(p+float2(d.x,0))),
   ReShade::GetLinearizedDepth(saturate(p-float2(d.x,0))),
   ReShade::GetLinearizedDepth(saturate(p+float2(0,d.y))),
   ReShade::GetLinearizedDepth(saturate(p-float2(0,d.y))));
 }
 return float4(max(z,0.0001),0,0,1);
}
// Separate signed CoC components avoid evaluating the opposite layer inside
// the expensive per-tap loops. Their formulae match the v1.2 components.
float FRFarCoC(float z,float focus) {
 if(!DoFFar) return 0.0;
 float delta=(z-focus)/max(focus,0.0001);
 return smoothstep(0.0,DoFFarTransition,max(delta-DoFFocusRange,0.0));
}
float FRNearCoC(float z,float focus) {
 if(!DoFNear) return 0.0;
 float delta=(z-focus)/max(focus,0.0001);
 return smoothstep(0.0,DoFNearTransition,max(-delta-DoFFocusRange,0.0));
}
float FRCoC(float z,float focus) {
 return FRFarCoC(z,focus)-FRNearCoC(z,focus);
}
float4 FRPrepareDoFPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target {
 if(DoFStrength<=0.0) return 0;
 // Pick the nearest layer during reduction; average only taps on that layer.
 // This protects silhouettes from background contamination at half resolution.
 float2 p=BUFFER_PIXEL_SIZE*0.5;
 float2 a=saturate(uv+float2(-p.x,-p.y)),b=saturate(uv+float2(p.x,-p.y));
 float2 c=saturate(uv+float2(-p.x,p.y)),d=saturate(uv+p);
 float za=ReShade::GetLinearizedDepth(a),zb=ReShade::GetLinearizedDepth(b);
 float zc=ReShade::GetLinearizedDepth(c),zd=ReShade::GetLinearizedDepth(d);
 float z=min(min(za,zb),min(zc,zd));float tolerance=max(z*DoFEdgeTolerance,0.00002);
 float4 weights=1.0-smoothstep(tolerance,tolerance*2.0,float4(za,zb,zc,zd)-z);
 float3 col=Source(a)*weights.x+Source(b)*weights.y+Source(c)*weights.z+Source(d)*weights.w;
 return float4(col/max(dot(weights,float4(1,1,1,1)),0.001),z);
}
static const float2 FRDisk[40] = {
 float2(0.11180340,0.00000000),
 float2(-0.14279087,0.13080813),
 float2(0.02185643,-0.24904276),
 float2(0.17997864,0.23475027),
 float2(-0.33028294,-0.05842240),
 float2(0.31287284,-0.19902409),
 float2(-0.10464984,0.38929219),
 float2(-0.19957860,-0.38427644),
 float2(0.43300572,0.15813300),
 float2(-0.45047030,0.18594759),
 float2(0.21715645,-0.46405072),
 float2(0.16047309,0.51161351),
 float2(-0.48366777,-0.28029536),
 float2(0.56739735,-0.12474072),
 float2(-0.34627377,0.49253881),
 float2(-0.07999726,-0.61733333),
 float2(0.49110471,0.41390357),
 float2(-0.66087300,0.02732917),
 float2(0.48205612,-0.47971022),
 float2(-0.03225142,0.69746673),
 float2(-0.45867794,-0.54964947),
 float2(0.72659651,0.09776253),
 float2(-0.61564375,0.42834889),
 float2(0.16822928,-0.74779603),
 float2(0.38910558,0.67904112),
 float2(-0.76066418,-0.24267262),
 float2(0.73888845,-0.34138521),
 float2(-0.32010494,0.76487439),
 float2(-0.28568660,-0.79428154),
 float2(0.76018139,0.39953004),
 float2(-0.84437026,0.22257329),
 float2(0.47994588,-0.74642612),
 float2(0.15267362,0.88836410),
 float2(-0.72353900,-0.56034927),
 float2(0.92553787,-0.07667892),
 float2(-0.63974176,0.69154210),
 float2(0.00465997,-0.95523729),
 float2(0.65055002,0.71713644),
 float2(-0.97688432,-0.09053742),
 float2(0.79156529,-0.60076983)
};

float2 FRTap(int i,int count) {
 int index=(i*40)/count;
 return FRDisk[index];
}
float4 FRFarDoFPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target {
 if(DoFStrength<=0.0 || !DoFFar || DoFFarRadius<=0.0) return 0;
 float4 center=tex2D(DoFDataS,uv);float focus=tex2D(DoFFocusS,float2(0.5,0.5)).r;
 float coc=FRFarCoC(center.a,focus);
 if(coc<0.005) return float4(center.rgb,center.a);
 float3 sum=center.rgb;float weightSum=1.0;
 int count=DoFQuality==0?12:(DoFQuality==1?24:40);
 float2 radius=Px(DoFFarRadius*coc);
 float tolerance=max(center.a*DoFEdgeTolerance,0.00002);
 float cocTolerance=max(coc*0.5,0.001);
 [loop] for(int i=0;i<40;i++) {
  if(i>=count) break;
  float4 sampleValue=tex2Dlod(DoFDataS,float4(saturate(uv+FRTap(i,count)*radius),0,0));
  float weight=smoothstep(center.a-tolerance*2.0,center.a-tolerance,sampleValue.a);
  // Never spread a sharp/foreground layer over the defocused background.
  weight*=smoothstep(0.0,cocTolerance,FRFarCoC(sampleValue.a,focus));
  sum+=sampleValue.rgb*weight;weightSum+=weight;
 }
 return float4(sum/weightSum,center.a);
}
float4 FRNearDoFPS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target {
 if(DoFStrength<=0.0 || !DoFNear || DoFNearRadius<=0.0) return 0;
 float4 center=tex2D(DoFDataS,uv);float focus=tex2D(DoFFocusS,float2(0.5,0.5)).r;
 float nearCenter=FRNearCoC(center.a,focus);
 float3 sum=center.rgb*nearCenter;float sumWeight=nearCenter;
 float2 radius=Px(DoFNearRadius);
 float tolerance=max(center.a*DoFEdgeTolerance,0.00002);
 int count=DoFQuality==0?12:(DoFQuality==1?24:40);
 [loop] for(int i=0;i<40;i++) {
  if(i>=count) break;
  float2 disk=FRTap(i,count);float distance=length(disk);
  float4 sampleValue=tex2Dlod(DoFDataS,float4(saturate(uv+disk*radius),0,0));
  float nearSample=FRNearCoC(sampleValue.a,focus);
  // Foreground can cover adjacent background, but only within its own blur radius.
  float weight=(1.0-smoothstep(max(nearSample-0.08,0.0),nearSample+0.08,distance));
  weight*=step(0.005,nearSample);
  weight*=1.0-smoothstep(center.a+tolerance,center.a+tolerance*2.0,sampleValue.a);
  sum+=sampleValue.rgb*weight;sumWeight+=weight;
 }
 float coverage=saturate(sumWeight/(count+1.0));
 coverage=max(coverage,nearCenter);
 return float4((sum/max(sumWeight,0.0001))*coverage,coverage);
}
float4 FRDoFCompositePS(float4 pos:SV_Position,float2 uv:TEXCOORD):SV_Target {
 float4 original=tex2D(ReShade::BackBuffer,uv);
 if(DoFStrength<=0.0) return original;
 // Keep the diagnostic view unaffected by masks and split comparison.
 if(!DoFDebug) {
  if(Split && uv.x<SplitPos) return original;
  if(DoFProtectHUD && max(MaskRect(uv,RectA),MaskRect(uv,RectB))>=1.0) return original;
 }
 float z=ReShade::GetLinearizedDepth(uv),focus=tex2D(DoFFocusS,float2(0.5,0.5)).r;
 float coc=FRCoC(z,focus);
 if(DoFDebug) return float4(max(-coc,0.0),1.0-abs(coc),max(coc,0.0),original.a);
 // Only reconstruct FAR where it contributes to the output. This avoids four
 // depth-aware texture reads and exponentials on sharp and foreground pixels.
 float3 color=original.rgb;
 if(DoFFar && DoFFarRadius>0.0 && coc>0.0) {
  float2 size=float2(BUFFER_WIDTH/2,BUFFER_HEIGHT/2);
  float2 grid=uv*size-0.5,base=floor(grid),fracGrid=frac(grid);
  float3 farColor=0;float total=0;
  float depthTolerance=max(z*DoFEdgeTolerance,0.00002);
  [unroll] for(int y=0;y<2;y++) { [unroll] for(int x=0;x<2;x++) {
   float2 p=saturate((base+float2(x,y)+0.5)/size);
   float4 value=tex2Dlod(DoFFarS,float4(p,0,0));
   float bilinear=(x==0?1.0-fracGrid.x:fracGrid.x)*(y==0?1.0-fracGrid.y:fracGrid.y);
   float weight=bilinear*exp2(-abs(value.a-z)/depthTolerance*4.0);
   farColor+=value.rgb*weight;total+=weight;
  }}
  farColor=total>0.0001?farColor/max(total,0.0001):original.rgb;
  color=lerp(original.rgb,farColor,coc);
 }
 // The near pass stores premultiplied color and coverage.
 if(DoFNear && DoFNearRadius>0.0) {
  float4 nearValue=tex2D(DoFNearS,uv);
  color=color*(1.0-nearValue.a)+nearValue.rgb;
 }
 float mask=DoFProtectHUD?max(MaskRect(uv,RectA),MaskRect(uv,RectB)):0.0;
 float amount=DoFStrength*(1.0-mask);
 if(Split) amount*=step(SplitPos,uv.x);
 return float4(lerp(original.rgb,color,amount),original.a);
}
}
technique FantasyRestoredDoF < ui_label="Fantasy Restored - Depth of Field"; ui_tooltip="Place AFTER Fantasy Restored. Near/far half-resolution disk blur with depth rejection. Requires correctly configured depth. Optional: disabled until you enable this technique."; >
{
 pass Focus { VertexShader=PostProcessVS; PixelShader=FantasyRestored::FRFocusPS; RenderTarget=FantasyRestored::DoFFocusTex; }
 pass Prepare { VertexShader=PostProcessVS; PixelShader=FantasyRestored::FRPrepareDoFPS; RenderTarget=FantasyRestored::DoFData; }
 pass FarBlur { VertexShader=PostProcessVS; PixelShader=FantasyRestored::FRFarDoFPS; RenderTarget=FantasyRestored::DoFFarTex; }
 pass NearBlur { VertexShader=PostProcessVS; PixelShader=FantasyRestored::FRNearDoFPS; RenderTarget=FantasyRestored::DoFNearTex; }
 pass Resolve { VertexShader=PostProcessVS; PixelShader=FantasyRestored::FRDoFCompositePS; }
}
