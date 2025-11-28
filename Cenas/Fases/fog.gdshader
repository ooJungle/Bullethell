shader_type canvas_item;

uniform vec3 fog_color : source_color = vec3(0.2, 0.2, 0.4);
uniform float density : hint_range(0.0, 1.0) = 0.5; // Aumentei o padrão para facilitar o teste
uniform float speed_x = 0.02;
uniform float speed_y = 0.01;

// Textura de Ruído
uniform sampler2D noise_texture : repeat_enable;

void fragment() {
	// Calcula o movimento da fumaça
	vec2 uv_move = UV + vec2(TIME * speed_x, TIME * speed_y);
	
	// Lê o valor do ruído (branco = fumaça, preto = vazio)
	float noise_val = texture(noise_texture, uv_move).r;
	
	// Desenha a cor da neblina
	// O Alpha (transparência) é definido pelo ruído vezes a densidade
	COLOR = vec4(fog_color, noise_val * density);
}