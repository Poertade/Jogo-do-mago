// Material PS1 para superfícies 3D: vertex snapping, mapeamento afim de textura e névoa.
//
// Cada efeito é ligado e desligado por parâmetros GLOBAIS de shader
// (Projeto > Configurações do Projeto > Shader Globals). O menu de opções muda esses
// parâmetros em tempo de jogo, e todos os materiais que usam este shader mudam juntos.
//
// A iluminação é calculada por vértice (render_mode vertex_lighting), como no PS1:
// é barata e deixa as manchas de luz "em blocos" nos polígonos.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

// --- Parâmetros globais (iguais para todos os materiais) ---
global uniform bool ps1_vertex_snap;
global uniform vec2 ps1_snap_grid;       // tamanho da grade, em "pixels" (largura, altura)
global uniform bool ps1_affine_mapping;
global uniform bool ps1_fog;
global uniform vec4 ps1_fog_color;      // cor sRGB (como aparece no seletor de cor)
global uniform float ps1_fog_near;       // metros
global uniform float ps1_fog_far;        // metros

// --- Parâmetros de cada material ---
// Textura pequena, sem filtragem (pixels nítidos) e sem mipmaps.
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
// Se ligado, a textura é projetada pela posição no mundo (útil nos blocos de greybox):
// ela se repete a cada `texture_size_m` metros, qualquer que seja o tamanho do bloco.
uniform bool world_uv = false;
uniform float texture_size_m = 1.0;
// Escala da UV do próprio modelo, quando world_uv está desligado.
uniform vec2 uv_scale = vec2(1.0);

varying vec2 v_uv;            // UV normal (corrigida pela perspectiva)
varying vec3 v_affine_uv;     // (UV * w, w): truque para interpolar a UV sem correção, como o PS1
varying float v_fog;          // 0 = sem névoa, 1 = só névoa

// Parâmetros globais não passam pela conversão de cor automática: convertemos a cor
// de sRGB (como foi escolhida) para linear (como a iluminação calcula).
vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

// UV a partir da posição no mundo, escolhendo o plano pela direção da face.
vec2 world_space_uv(vec3 world_pos, vec3 world_normal) {
	vec3 n = abs(world_normal);
	if (n.y >= n.x && n.y >= n.z) {
		return world_pos.xz;                 // chão e teto
	} else if (n.x >= n.z) {
		return vec2(world_pos.z, -world_pos.y); // paredes viradas para X
	}
	return vec2(world_pos.x, -world_pos.y);     // paredes viradas para Z
}

void vertex() {
	vec2 uv = UV * uv_scale;
	if (world_uv) {
		vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
		uv = world_space_uv(world_pos, world_normal) / texture_size_m;
	}

	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * view_pos;

	// Vertex snapping: arredonda a posição na tela para a grade de pixels.
	// O PS1 não tinha precisão abaixo do pixel, por isso os polígonos "tremem".
	if (ps1_vertex_snap) {
		vec2 half_grid = ps1_snap_grid * 0.5; // a tela vai de -1 a 1: metade da grade para cada lado
		clip.xy = round(clip.xy / clip.w * half_grid) / half_grid * clip.w;
	}
	POSITION = clip;

	v_uv = uv;
	v_affine_uv = vec3(uv * clip.w, clip.w);

	// Névoa linear por distância da câmera, calculada por vértice como no PS1.
	float distance_to_camera = length(view_pos.xyz);
	v_fog = clamp((distance_to_camera - ps1_fog_near) / max(ps1_fog_far - ps1_fog_near, 0.001), 0.0, 1.0);
}

void fragment() {
	// Mapeamento afim: dividir (UV * w) por w depois da interpolação anula a correção
	// de perspectiva da placa de vídeo, e a textura "escorrega" nos polígonos grandes.
	vec2 uv = ps1_affine_mapping ? v_affine_uv.xy / v_affine_uv.z : v_uv;
	vec4 texel = texture(albedo_texture, uv) * albedo_color;
	ALBEDO = texel.rgb;
	FOG = vec4(srgb_to_linear(ps1_fog_color.rgb), ps1_fog ? v_fog : 0.0);
}
