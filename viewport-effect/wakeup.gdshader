shader_type canvas_item;

uniform sampler2D viewport_texture;
uniform sampler2D normal : hint_normal;
uniform float distortion_size = 0.2;
uniform float distortion : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform vec3 gray_color : source_color;

void fragment() {
	vec2 d = texture(normal, UV).rg * 2.0 - vec2(1.0);
	vec2 distorted_uv = mix(UV, UV + d * distortion_size, distortion);

	vec4 distorted_rgba = texture(viewport_texture, distorted_uv);

  float gray = dot(distorted_rgba.rgb, vec3(0.299, 0.587, 0.114));
  vec3 distorted_saturated_rgb = mix(gray_color * gray, distorted_rgba.rgb, saturation);

  COLOR = vec4(distorted_saturated_rgb, distorted_rgba.a);
}