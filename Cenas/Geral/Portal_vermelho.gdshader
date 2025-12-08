shader_type canvas_item;

// --- CONFIGURAÇÕES DO PULSO ---
uniform float pulse_speed = 3.0; // Quão rápido ele pulsa
uniform float falloff_min = 0.01; // O valor mínimo (brilho mais suave/espalhado)
uniform float falloff_max = 0.05; // O valor máximo (brilho mais focado/duro)

// Controla a força/opacidade geral do brilho
uniform float intensity = 8.0;

render_mode unshaded;

void fragment() {
	// Centraliza o UV
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	float base = min(distance_from_center * 2.0, 1.0);

	// --- LÓGICA DO PULSO (A MÁGICA ACONTECE AQUI) ---

	// 1. Criamos uma onda que vai de -1 a 1 baseada no tempo
	float sine_wave = sin(TIME * pulse_speed);

	// 2. Transformamos essa onda para ir de 0 a 1
	float normalized_wave = (sine_wave + 1.0) / 2.0;

	// 3. Usamos essa onda para oscilar o falloff entre o Mínimo e o Máximo
	float current_falloff = mix(falloff_min, falloff_max, normalized_wave);

	// --- FIM DA LÓGICA DO PULSO ---

	// Calcula a máscara usando o falloff animado
	float mask = 1.0 - pow(base, current_falloff);

	vec3 white_color = vec3(1.0, 0.0, 0.2);

	COLOR = vec4(white_color, mask * intensity);
}