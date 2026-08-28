shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;

uniform int color_levels : hint_range(2, 32) = 6;
uniform float posterize_strength : hint_range(0.0, 1.0) = 1;

void fragment() {
    vec4 original = texture(screen_tex, SCREEN_UV);
    
    vec3 posterized = floor(original.rgb * float(color_levels)) / float(color_levels);
    
    vec3 final_color = mix(original.rgb, posterized, posterize_strength);
    
    COLOR = vec4(final_color, original.a);
}