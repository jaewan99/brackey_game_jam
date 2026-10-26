shader_type canvas_item;

uniform vec2  size = vec2(320.0, 90.0);               // set per-button from script
uniform vec4  ink_color   : source_color = vec4(0.07, 0.065, 0.05, 1.0);  // near-black warm ink
uniform vec4  ink_accent  : source_color = vec4(0.14, 0.12, 0.08, 1.0);   // internal texture tone
uniform vec4  edge_color  : source_color = vec4(0.85, 0.70, 0.36, 1.0);   // gold rim
uniform float slant        : hint_range(-0.5, 0.5) = 0.18;   // italic lean
uniform float roughness    : hint_range(0.0, 1.0)  = 0.45;   // ragged edge amount
uniform float taper        : hint_range(0.0, 0.5)  = 0.22;   // how pointed the ends are
uniform float hover        : hint_range(0.0, 1.0)  = 0.0;    // driven by script
uniform float seed = 0.0;

float hash(vec2 p){
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise(vec2 p){
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm(vec2 p){
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++){
		v += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	float aspect = size.x / size.y;

	// shear so the whole stroke leans like italics
	vec2 uv = UV;
	uv.x += (uv.y - 0.5) * slant;

	vec2 c = uv - 0.5;                       // centered, -0.5..0.5

	// vertical mask: rough top/bottom brush edges
	float ny = fbm(vec2(uv.x * 9.0 + seed, 3.0));
	float yd = abs(c.y) * 2.0;
	float ymask = 1.0 - smoothstep(0.78, 1.0, yd + (ny - 0.5) * roughness);

	// horizontal mask: tapered + frayed ends
	float nx = fbm(vec2(uv.x * 5.0 + seed * 2.0, uv.y * 4.0));
	float xd = abs(c.x) * 2.0;
	// taper pulls the ends to points; noise frays them
	float ends = 1.0 - smoothstep(1.0 - taper, 1.0, xd + (nx - 0.5) * roughness);
	float xmask = ends;

	float mask = xmask * ymask;

	// drybrush grain: punch flecks out near the edges only
	float grain = fbm(vec2(uv.x * aspect * 26.0, uv.y * 16.0) + seed);
	float coreness = smoothstep(0.15, 0.6, mask);         // 1 in the solid core
	mask *= mix(smoothstep(0.30, 0.55, grain), 1.0, coreness);
	mask = clamp(mask, 0.0, 1.0);

	// ink body with subtle internal variation
	vec3 col = mix(ink_color.rgb, ink_accent.rgb, grain * 0.5);

	// gold rim hugging the stroke edge, stronger on hover
	float rim = smoothstep(0.35, 0.05, mask) * smoothstep(0.02, 0.18, mask);
	col = mix(col, edge_color.rgb, rim * (0.10 + 0.75 * hover));
	col += edge_color.rgb * hover * 0.06;                 // overall warm lift on hover

	COLOR = vec4(col, mask * ink_color.a);
}