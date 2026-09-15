shader_type canvas_item;
render_mode unshaded;

uniform sampler2D gait_texture : source_color, filter_nearest, repeat_disable;
uniform float walking = 0.0;
uniform float gait_phase = 0.0;

void fragment() {
	vec2 sample_uv = UV;
	float grounded = smoothstep(1.0, 0.15, UV.y);
	sample_uv.x += sin(gait_phase + UV.y * 5.0) * 0.006 * walking * grounded;
	sample_uv.y += sin(gait_phase * 2.0) * 0.004 * walking;
	COLOR = texture(gait_texture, clamp(sample_uv, vec2(0.0), vec2(1.0))) * COLOR;
}
