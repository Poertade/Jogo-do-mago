// Interface em pixels grandes, como o mundo 3D.
// Cada tela (HUD e menus) é desenhada numa imagem pequena (um SubViewport de 640x360, metade da
// tela) e ampliada 2x sem filtro por um SubViewportContainer com este material. Aqui a imagem
// passa pela mesma redução de cores e pelo mesmo dithering do mundo 3D (opções "Cor limitada"
// e "Dithering"), para a interface não parecer tirada de outro jogo.
shader_type canvas_item;
// A imagem do SubViewport transparente guarda a cor já multiplicada pela transparência.
render_mode blend_premul_alpha;

// Definidos pela GameScreen a partir das opções do jogador (project.godot → shader_globals).
global uniform bool ps1_color_limit;
global uniform bool ps1_dithering;
global uniform float ps1_color_levels;

// Matriz de Bayer 4x4, a mesma do pós-processamento do mundo (ps1_post.gdshader).
const float BAYER_4X4[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (ps1_color_limit && color.a > 0.0) {
		// Volta a cor ao normal (sem a transparência), reduz as cores e multiplica de novo.
		vec3 rgb = color.rgb / color.a;
		float steps = max(ps1_color_levels - 1.0, 1.0);
		if (ps1_dithering) {
			ivec2 pixel = ivec2(floor(UV * vec2(textureSize(TEXTURE, 0)))) % 4;
			rgb += (BAYER_4X4[pixel.y * 4 + pixel.x] / 16.0 - 0.5) / steps;
		}
		rgb = floor(clamp(rgb, 0.0, 1.0) * steps + 0.5) / steps;
		color.rgb = rgb * color.a;
	}
	COLOR = color;
}
