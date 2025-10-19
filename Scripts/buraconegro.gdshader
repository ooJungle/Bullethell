// Shader para Godot 4.x (versões 4.2+)
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float falloff = 1.5;
uniform float red_intensity = 0.4; // <<-- NOVA VARIÁVEL: Controla a força da máscara vermelha

render_mode unshaded;

void fragment() {
	float distortion_strength = 0.15;
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	float mask = 1.0 - pow(distance_from_center * 2.0, falloff);

	// Efeito de Puxar (Pinch/Gravitacional)
	vec2 pull_offset = normalize(centered_uv) * distortion_strength * mask;

	vec2 total_offset = pull_offset;

	vec2 distorted_screen_uv = SCREEN_UV - total_offset;

	vec3 background_color = texture(SCREEN_TEXTURE, distorted_screen_uv).rgb;

	// --- NOVA LÓGICA DA MÁSCARA VERMELHA ---
	// Define a cor alvo (vermelho puro)
	vec3 red_color = vec3(1.0, 0.0, 0.0);

	// Mistura a cor de fundo com a cor vermelha.
	// A intensidade da mistura é controlada pela 'mask' (proximidade ao centro)
	// e pela nova variável 'red_intensity'.
	vec3 final_color = mix(background_color, red_color, mask * red_intensity);

	// Define a cor final, usando a máscara geral para a transparência nas bordas
	COLOR = vec4(final_color, mask);
}