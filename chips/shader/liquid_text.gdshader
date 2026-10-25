shader_type canvas_item;

uniform vec4 cloud_dark  : source_color = vec4(0.55, 0.02, 0.06, 1.0);
uniform vec4 cloud_mid   : source_color = vec4(0.95, 0.15, 0.12, 1.0);
uniform vec4 cloud_light : source_color = vec4(1.0, 0.6, 0.45, 1.0);
uniform float cloud_scale = 0.025;   // smaller = bigger puffs
uniform float cloud_speed = 0.4;
uniform float brightness = 1.15;

uniform float bob_amp = 3.0;
uniform float bob_speed = 3.0;
uniform float bob_spread = 0.012;
uniform float highlight_strength = 0.0;

varying vec2 local;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
			   mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	local = VERTEX;   // before the wobble, so the cloud sticks to the letters
	float ph = TIME * bob_speed + VERTEX.x * bob_spread;
	VERTEX.y += sin(ph) * bob_amp;
}

void fragment() {
	vec2 p = local * cloud_scale;
	float t = TIME * cloud_speed;

	// domain warp -> swirly smoke instead of plain blobs
	vec2 warp = vec2(fbm(p + vec2(t, 0.0)), fbm(p + vec2(0.0, -t) + 5.2));
	float n = fbm(p + warp * 1.5 + vec2(t * 0.5, t * 0.3));

	vec3 cloud = mix(cloud_dark.rgb, cloud_mid.rgb, smoothstep(0.25, 0.55, n));
	cloud = mix(cloud, cloud_light.rgb, smoothstep(0.55, 0.8, n));

	vec3 col = COLOR.rgb * cloud * brightness;   // shadow/outline color stays dark
	col = mix(col, vec3(1.0), highlight_strength * 0.4);
	COLOR = vec4(col, COLOR.a);
}