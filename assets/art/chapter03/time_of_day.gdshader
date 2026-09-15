shader_type canvas_item;
render_mode unshaded;

uniform float night : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 moonlit = source.rgb * vec3(0.48, 0.55, 0.78);
	moonlit += vec3(0.015, 0.02, 0.06);
	source.rgb = mix(source.rgb, moonlit, night);
	COLOR = source * COLOR;
}
