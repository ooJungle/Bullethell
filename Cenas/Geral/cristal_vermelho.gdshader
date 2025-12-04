shader_type canvas_item;

uniform bool ativo = false; // Controla se o efeito está ligado
uniform vec4 cor_energia : source_color = vec4(1.0, 0.4, 0.4, 1.0); // Cor avermelhada do laser
uniform float intensidade_pulso = 0.2; // O quão forte é o brilho

void fragment() {
	vec4 cor_textura = texture(TEXTURE, UV);
	
	if (ativo) {
		// Cria um pulso suave baseado no tempo
		float seno_pulso = (sin(TIME * 15.0) + 1.0) * 0.5; // Vai de 0 a 1 rápido
		
		// Adiciona a cor da energia em cima da cor do cristal, respeitando a transparência
		vec3 brilho = cor_energia.rgb * (intensidade_pulso + (seno_pulso * 0.1));
		
		// Aplica o brilho (soma) na cor original
		cor_textura.rgb += brilho;
		
		// Opcional: Aumenta levemente a saturação/brilho geral
		cor_textura.rgb *= 1.1;
	}
	
	COLOR = cor_textura;
}