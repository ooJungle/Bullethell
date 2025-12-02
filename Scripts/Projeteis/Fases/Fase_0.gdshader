shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// --- CONFIGURAÇÕES DE COR ---
uniform float brightness : hint_range(0.0, 2.0) = 1.0; // Brilho geral ( < 1 escurece)
uniform float contrast : hint_range(0.0, 2.0) = 1.0;   // Contraste
uniform float saturation : hint_range(0.0, 2.0) = 1.0; // Saturação de cor
uniform vec3 tint_color : source_color = vec3(1.0, 1.0, 1.0); // Tinta (ex: azulado para noite)
uniform float tint_strength : hint_range(0.0, 1.0) = 1.0;

// --- CONFIGURAÇÕES DE VINHETA (Bordas Escuras) ---
uniform float vignette_intensity : hint_range(0.0, 5.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// 1. Ler a cor original da tela
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 c = screen_color.rgb;

	// 2. Ajuste de Brilho
	c = c * brightness;

	// 3. Ajuste de Contraste
	c = (c - 0.5) * contrast + 0.5;

	// 4. Ajuste de Saturação (Preto e Branco vs Colorido)
	float gray = dot(c, vec3(0.299, 0.587, 0.114)); // Luminância
	c = mix(vec3(gray), c, saturation);

	// 5. Aplica a Tinta (Cor do ambiente)
	c = mix(c, c * tint_color, tint_strength);

	// --- EFEITO DE VINHETA ---
	vec2 uv = SCREEN_UV;
	uv *= 1.0 - uv.yx; // Cria a curva da vinheta
	float vig = uv.x * uv.y * 15.0; // Força da curva
	vig = pow(vig, vignette_intensity); // Suavidade

	// Mistura o escuro nas bordas
	c = mix(vec3(0.0), c, clamp(vig + (1.0 - vignette_opacity), 0.0, 1.0));

	// Aplica a cor final (mantendo o alpha original para transparência)
	COLOR = vec4(c, screen_color.a);
}