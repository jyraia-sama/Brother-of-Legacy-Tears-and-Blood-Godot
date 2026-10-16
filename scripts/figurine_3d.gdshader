shader_type spatial;
// FIGURINE PEINTE DES COMBATS 2,5D (combat_3d.gd)
// - Relief automatique : un « normal map » est déduit de l'image elle-même (silhouette arrondie +
//   détails de la peinture), pour que les torches et les sorts éclairent vraiment la figurine.
// - Liseré lumineux de la couleur de l'élément sur les contours.
// - Figurine vivante : léger balancement au repos, écrasement / étirement et inclinaison pilotés
//   par les animations (uniforms « ecrase » et « penche »).
render_mode depth_prepass_alpha, cull_disabled, specular_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 texel = vec2(0.002);       // 1 / taille de l'image
uniform float hauteur = 2.3;            // hauteur de la figurine (mètres)
uniform float retourne = 0.0;           // 1 = image retournée (camp de droite)
uniform float balance = 1.0;            // amplitude du balancement au repos
uniform float phase = 0.0;
uniform float penche = 0.0;             // inclinaison du haut (mètres), signe = côté
uniform float ecrase = 0.0;             // > 0 : tassée, < 0 : étirée
uniform float relief = 2.2;             // force du relief
uniform vec3 couleur_lisere : source_color = vec3(1.0);
uniform float lisere = 0.55;
uniform vec4 eclat : source_color = vec4(0.0);   // flash (coup reçu, sort)
uniform float sombre = 0.0;             // K.O.
uniform float opacite = 1.0;

void vertex() {
	// UV.y = 0 en haut, 1 aux pieds : t = 0 aux pieds, 1 en haut
	float t = 1.0 - UV.y;
	float vent = sin(TIME * 1.25 + phase) * 0.035 + sin(TIME * 2.1 + phase * 1.7) * 0.012;
	VERTEX.x += (vent * balance + penche) * t * t * hauteur * 0.5;
	VERTEX.y *= 1.0 - ecrase;
	VERTEX.x *= 1.0 + ecrase * 0.55 * t;
}

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// « Hauteur » d'un point de l'image : silhouette floutée (dôme) + clarté de la peinture (détails)
float h_large(vec2 uv) {
	return textureLod(tex, uv, 3.0).a;
}
float h_fin(vec2 uv) {
	vec4 c = texture(tex, uv);
	return lum(c.rgb) * c.a;
}

void fragment() {
	vec2 uv = UV;
	if (retourne > 0.5) {
		uv.x = 1.0 - uv.x;
	}
	vec4 c = texture(tex, uv);
	ALPHA = c.a * opacite;

	vec2 o1 = texel * 9.0;
	vec2 o2 = texel * 1.5;
	float dx = (h_large(uv + vec2(o1.x, 0.0)) - h_large(uv - vec2(o1.x, 0.0))) * 1.0
		+ (h_fin(uv + vec2(o2.x, 0.0)) - h_fin(uv - vec2(o2.x, 0.0))) * 0.6;
	float dy = (h_large(uv + vec2(0.0, o1.y)) - h_large(uv - vec2(0.0, o1.y))) * 1.0
		+ (h_fin(uv + vec2(0.0, o2.y)) - h_fin(uv - vec2(0.0, o2.y))) * 0.6;
	if (retourne > 0.5) {
		dx = -dx;
	}
	vec3 n = normalize(vec3(-dx * relief, dy * relief, 1.0));
	NORMAL_MAP = n * 0.5 + 0.5;

	vec3 albedo = c.rgb * (1.0 - sombre * 0.6);
	albedo = mix(albedo, vec3(lum(albedo)), sombre * 0.7);
	ALBEDO = albedo;
	ROUGHNESS = 0.8;

	// Liseré : bord intérieur de la silhouette, surtout en haut et sur les côtés
	float bord = clamp((c.a - textureLod(tex, uv, 3.5).a) * 2.2, 0.0, 1.0) * c.a;
	vec3 em = couleur_lisere * bord * lisere * (1.0 - sombre);
	em += eclat.rgb * eclat.a * (0.35 + lum(c.rgb));
	EMISSION = em;
}
