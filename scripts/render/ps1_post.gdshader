// Pós-processamento PS1, aplicado na imagem pequena do mundo 3D antes de ampliá-la:
// reduz o número de cores (cor limitada) e espalha a diferença num padrão de pontos (dithering).
// Os parâmetros são definidos pela GameScreen a partir das opções do jogador.
shader_type canvas_item;

uniform bool color_limit = true;
uniform bool dithering = true;
uniform float color_levels = 32.0;                 // níveis por canal: 32 = 5 bits, como o PS1
uniform vec2 source_size = vec2(427.0, 240.0);     // tamanho da imagem interna, em pixels

// Matriz de Bayer 4x4: limiares que formam o padrão do dithering ordenado.
const float BAYER_4X4[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec3 color = texture(TEXTURE, UV).rgb;
	if (color_limit) {
		float steps = color_levels - 1.0;
		if (dithering) {
			// Pixel da imagem interna (não da tela): o padrão acompanha os pixels grandes.
			ivec2 pixel = ivec2(floor(UV * source_size)) % 4;
			float threshold = BAYER_4X4[pixel.y * 4 + pixel.x] / 16.0 - 0.5;
			color += threshold / steps;
		}
		color = floor(color * steps + 0.5) / steps;
	}
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
