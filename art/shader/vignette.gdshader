shader_type canvas_item;

uniform vec4 shade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float size : hint_range(0.0, 2.0) = 0.4;      // how far the triangle reaches in
uniform float softness : hint_range(0.0, 1.0) = 0.1;  // edge blur
uniform float strength : hint_range(0.0, 1.0) = 1.0;  // darkness
uniform bool flip_x = false;   // flip to the right side
uniform bool flip_y = false;   // flip to the bottom

void fragment() {
	vec2 uv = UV;
	if (flip_x) uv.x = 1.0 - uv.x;
	if (flip_y) uv.y = 1.0 - uv.y;
	float d = uv.x + uv.y;                                   // 0 at the corner
	float a = (1.0 - smoothstep(size - softness, size, d)) * strength;
	COLOR = vec4(shade_color.rgb, a);
}