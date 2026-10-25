shader_type canvas_item;

uniform vec2  size = vec2(120.0, 48.0);               // set per-button from script (for even corners)
uniform vec4  base_color   : source_color = vec4(0.09, 0.12, 0.18, 1.0);
uniform vec4  accent_color : source_color = vec4(0.18, 0.42, 0.72, 1.0);
uniform vec4  edge_color   : source_color = vec4(0.60, 0.85, 1.00, 1.0);
uniform float corner_radius : hint_range(0.0, 0.5) = 0.22;
uniform float border_width  : hint_range(0.0, 0.2) = 0.05;
uniform float hover         : hint_range(0.0, 1.0) = 0.0;   // driven by script
uniform float sheen_speed = 1.2;

// signed distance to a rounded box centered at origin, half-size b, radius r
float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
	float aspect = size.x / size.y;
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);           // aspect-correct so corners aren't stretched
	vec2 b = vec2(0.5 * aspect, 0.5);
	float d = sd_round_box(p, b - 0.01, corner_radius);

	// body: gradient, brighter at top, lifts on hover
	vec3 body = mix(base_color.rgb, accent_color.rgb, 1.0 - UV.y);
	body += accent_color.rgb * hover * 0.30;

	// diagonal sheen sweep
	float s = sin((UV.x + UV.y) * 3.14159 - TIME * sheen_speed);
	body += smoothstep(0.75, 1.0, s) * (0.08 + 0.30 * hover);

	float fill   = smoothstep(0.004, -0.004, d);        // inside the rounded shape
	float border = smoothstep(-border_width, 0.0, d) * fill;  // glowing inner rim
	vec3 col = mix(body, edge_color.rgb, border * (0.5 + 0.5 * hover));

	COLOR = vec4(col, fill * base_color.a);
}