shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.08;
uniform float flicker : hint_range(0.0, 0.5) = 0.04;
uniform float vignette : hint_range(0.0, 2.0) = 0.9;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 color = texture(screen_tex, uv);

	// film grain
	float noise = random(uv + fract(TIME)) * 2.0 - 1.0;   // fract(TIME): avoids drift over long runs
	color.rgb += noise * noise_intensity;

	// ~24fps projector flicker
	color.rgb *= 1.0 - flicker * random(vec2(floor(TIME * 24.0), 2.0));

	// vignette toward edges
	float d = distance(uv, vec2(0.5));
	color.rgb *= smoothstep(0.9, 0.25, d * vignette);

	COLOR = color;
}