shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D paper_tex : source_color;       // 紙のベーステクスチャ
uniform sampler2D overlay_tex : source_color;     // オーバーレイ（UIや絵など）
uniform float overlay_strength : hint_range(0.0, 1.0) = 0.8;
uniform float paper_brightness : hint_range(0.0, 2.0) = 1.0;
uniform float paper_roughness : hint_range(0.0, 1.0) = 0.8;
uniform float paper_metallic : hint_range(0.0, 1.0) = 0.0;
uniform float bump_strength : hint_range(0.0, 0.1) = 0.02; // 紙の微細凹凸
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.3;
uniform float vignette_radius : hint_range(0.1, 2.0) = 1.0;
uniform vec2 vignette_center = vec2(0.5, 0.5); // UV空間での中心
uniform vec3 tint_color : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
    vec2 uv = UV;

    vec4 paper_color = texture(paper_tex, uv) * paper_brightness;

    vec2 grad = vec2(
        texture(paper_tex, uv + vec2(0.001, 0.0)).r - texture(paper_tex, uv - vec2(0.001, 0.0)).r,
        texture(paper_tex, uv + vec2(0.0, 0.001)).r - texture(paper_tex, uv - vec2(0.0, 0.001)).r
    );
    NORMAL = normalize(NORMAL + vec3(grad * bump_strength, 0.0));

    vec4 overlay_color = texture(overlay_tex, uv);
    vec3 mixed_rgb = mix(paper_color.rgb, overlay_color.rgb, overlay_color.a * overlay_strength);

    vec2 centered = (uv - vignette_center) * vignette_radius * 2.0;
    float vignette = 1.0 - dot(centered, centered) * vignette_strength;
    vignette = clamp(vignette, 0.0, 1.0);

    ALBEDO = mixed_rgb * tint_color * vignette;
    ROUGHNESS = paper_roughness;
    METALLIC = paper_metallic;
    ALPHA = 1.0;
}
