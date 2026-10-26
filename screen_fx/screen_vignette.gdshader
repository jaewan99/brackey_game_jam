shader_type canvas_item;

uniform vec4  tint     : source_color = vec4(0.6, 0.0, 0.0, 1.0);  // edge color
uniform float strength : hint_range(0.0, 1.0) = 0.0;   // driven by script
uniform float inner = 0.30;   // center stays clear until here
uniform float outer = 0.95;   // full tint by the corners

void fragment() {
	float d = length(UV - 0.5) * 1.41421;      // 0 center -> ~1 corners
	float v = smoothstep(inner, outer, d);
	COLOR = vec4(tint.rgb, v * strength * tint.a);
}