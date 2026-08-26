shader_type canvas_item;

uniform sampler2D rust_texture;
uniform float rust_tiling : hint_range(0.5, 10.0) = 3.0;
uniform float rust_amount : hint_range(0.0, 1.0) = 0.7;
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.2, 0.15); // reddish glow
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.0; // animated from script, 0 = off

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV) * COLOR;
    vec4 rust_sample = texture(rust_texture, UV * rust_tiling);

    float mask = rust_sample.a; // or luminance, depending on your rust image
    vec3 result = mix(tex_color.rgb, rust_sample.rgb, mask * rust_amount);

    // blend toward reddish highlight based on focus/hover strength
    result = mix(result, highlight_tint, highlight_strength * 0.6);

    COLOR = vec4(result, tex_color.a);
}