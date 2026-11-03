// Material PS1 com recorte: igual ao ps1.gdshader, mas os pixels transparentes da textura
// somem (pano rasgado, folhas, rosto da caveira) e as duas faces do polígono aparecem.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled, cull_disabled;

#define PS1_CUTOUT
#include "res://scripts/render/ps1_common.gdshaderinc"
