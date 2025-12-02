shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// Posição do jogador na tela (normalizada de 0.0 a 1.0)
uniform vec2 player_position = vec2(0.5, 0.5);

// Cor da escuridão (preto para caverna)
uniform vec4 dark_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Tamanho do círculo de luz
uniform float radius : hint_range(0.0, 1.0) = 0.3;

// Suavidade da borda da luz
uniform float softness : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// --- CORREÇÃO DE ASPECTO (O Segredo do Círculo) ---
	// Calcula a proporção da tela (largura / altura)
	float aspect_ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	
	// Cria coordenadas UV ajustadas.
	// Multiplicamos o eixo X pelo aspect ratio para "esmagar" o retângulo de volta num quadrado.
	vec2 adjusted_uv = SCREEN_UV;
	adjusted_uv.x *= aspect_ratio;
	
	vec2 adjusted_player_pos = player_position;
	adjusted_player_pos.x *= aspect_ratio;
	
	// --- CÁLCULO DA DISTÂNCIA ---
	// Calcula a distância do pixel atual até a posição ajustada do player
	float dist = distance(adjusted_uv, adjusted_player_pos);
	
	// --- CRIAÇÃO DA MÁSCARA ---
	// Usa smoothstep para criar um círculo suave.
	// O "1.0 -" inverte o resultado, para que o centro seja branco (luz) e as bordas pretas.
	float light_mask = 1.0 - smoothstep(radius, radius + softness, dist);
	
	// --- APLICAÇÃO FINAL ---
	// Mistura a cor da tela com a cor escura baseada na máscara
	// Onde a máscara é 1 (perto do player), mostra a tela. Onde é 0, mostra a escuridão.
	vec3 final_rgb = mix(dark_color.rgb, screen_color.rgb, light_mask);
	
	COLOR = vec4(final_rgb, 1.0);
}