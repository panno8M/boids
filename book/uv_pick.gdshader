shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform float object_id: hint_range(0.0, 10.0);

void fragment() {
    vec2 uv = UV;
    ALBEDO = vec3(uv, object_id / 10.0); // R=U, G=V
    ALPHA = 1.0;
}
