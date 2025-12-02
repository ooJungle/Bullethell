shader_type canvas_item;

// Controla o quão rápido o brilho desaparece (suavidade da borda)
uniform float falloff = 1.1;

// Controla a força/opacidade do brilho branco
uniform float intensity = 3.0;

render_mode unshaded;

void fragment() {
	// Centraliza o UV (0,0 no meio)
	vec2 centered_uv = UV - vec2(0.5);

	// Calcula a distância do centro
	float distance_from_center = length(centered_uv);

	// --- LÓGICA DA MÁSCARA RADIAL ---
	// Usamos min() para garantir que não passamos de 1.0 e evitamos bugs visuais
	float base = min(distance_from_center * 2.0, 1.0);

	// Cria o gradiente suave
	float mask = 1.0 - pow(base, falloff);

	// Cor Branca Pura
	vec3 white_color = vec3(1.0, 1.0, 1.0);

	// Aplica a cor com a transparência baseada na máscara e na intensidade
	COLOR = vec4(white_color, mask * intensity);
}