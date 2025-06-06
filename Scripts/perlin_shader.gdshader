shader_type spatial;

uniform sampler2D base_tex;
uniform sampler2D noise_tex;
uniform float noise_strength = 0.25;
uniform float noise_scale = 25.0;

void fragment() {
    vec2 uv = UV;
    float n = texture(noise_tex, uv * noise_scale).r;
    vec3 base = texture(base_tex, uv).rgb;
    base += n * noise_strength;
    ALBEDO = base;
}
