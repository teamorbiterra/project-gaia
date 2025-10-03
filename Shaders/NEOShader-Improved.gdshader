// Simple Realistic Asteroid Shader
// Clean approach: minimal noise layers, smooth surface
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise_texture;

// Shape
uniform vec3 axis_deformation = vec3(1.0, 0.9, 1.0);
uniform float overall_scale : hint_range(0.1, 5.0) = 1.0;

// Surface displacement - SIMPLIFIED
uniform float displacement_scale : hint_range(0.1, 5.0) = 1.5;
uniform float displacement_strength : hint_range(0.0, 0.5) = 0.2;
uniform int octaves : hint_range(1, 4) = 2;

// Craters
uniform int crater_count : hint_range(0, 20) = 6;
uniform float crater_size : hint_range(0.05, 0.4) = 0.15;
uniform float crater_depth : hint_range(0.0, 0.5) = 0.2;
uniform float crater_seed : hint_range(0.0, 10000.0) = 42.0;

// Simple color scheme
uniform vec3 dark_color : source_color = vec3(0.08, 0.07, 0.06);
uniform vec3 light_color : source_color = vec3(0.18, 0.16, 0.14);
uniform float color_contrast : hint_range(0.0, 1.0) = 0.4;

// Surface
uniform float roughness_value : hint_range(0.0, 1.0) = 0.98;

varying vec3 world_pos;

// Simple hash
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453123);
}

// Simple FBM noise
float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;

    for(int i = 0; i < octaves; i++) {
        // Tri-planar sampling
        vec3 blend = abs(normalize(p));
        blend = blend / (blend.x + blend.y + blend.z);

        float xy = texture(noise_texture, p.xy * 0.5).r;
        float xz = texture(noise_texture, p.xz * 0.5).r;
        float yz = texture(noise_texture, p.yz * 0.5).r;

        float n = xy * blend.z + xz * blend.y + yz * blend.x;

        value += n * amplitude;
        amplitude *= 0.5;
        p *= 2.0;
    }

    return value;
}

// Smooth crater
float crater(vec3 pos, vec3 center, float size) {
    float dist = acos(clamp(dot(normalize(pos), center), -1.0, 1.0));

    if (dist > size * 1.3) return 0.0;

    float t = dist / size;

    // Simple smooth bowl
    float bowl = smoothstep(1.3, 0.0, t);
    bowl = bowl * bowl * bowl;

    // Small rim
    float rim = smoothstep(0.8, 1.0, t) * smoothstep(1.3, 1.0, t) * 0.08;

    return -bowl + rim;
}

// Get all craters
float get_craters(vec3 pos) {
    float total = 0.0;

    for(int i = 0; i < crater_count; i++) {
        vec3 seed = vec3(crater_seed + float(i) * 13.7);
        vec3 center = normalize(hash3(seed) * 2.0 - 1.0);

        float size_var = hash(seed * 7.3);
        float size = crater_size * (0.7 + size_var * 0.6);

        total += crater(pos, center, size);
    }

    return total * crater_depth;
}

// Total height
float get_height(vec3 pos) {
    // Single smooth noise layer
    float noise = fbm(pos * displacement_scale);
    noise = (noise - 0.5) * 2.0;

    // Add craters
    float craters = get_craters(pos);

    return noise * displacement_strength + craters;
}

void vertex() {
    // Sphere from cube
    vec3 sphere_pos = normalize(VERTEX) * overall_scale;
    sphere_pos *= axis_deformation;

    vec3 norm = normalize(sphere_pos);

    // Displace
    float height = get_height(sphere_pos);
    VERTEX = sphere_pos + norm * height;

    world_pos = sphere_pos;

    // Simple normal from gradient
    float eps = 0.01;
    vec3 e1 = vec3(eps, 0, 0);
    vec3 e2 = vec3(0, eps, 0);

    float h = get_height(sphere_pos);
    float hx = get_height(sphere_pos + e1);
    float hy = get_height(sphere_pos + e2);

    vec3 grad = vec3(hx - h, hy - h, eps);
    NORMAL = normalize(norm - grad * 0.5);
}

void fragment() {
    // Simple color variation
    float color_var = fbm(world_pos * 2.0);
    vec3 color = mix(dark_color, light_color, color_var * color_contrast + 0.5);

    // Darken craters slightly
    float crater_amount = clamp(-get_craters(world_pos) * 4.0, 0.0, 1.0);
    color *= mix(1.0, 0.75, crater_amount);

    ALBEDO = color;
    ROUGHNESS = roughness_value;
    METALLIC = 0.0;
}