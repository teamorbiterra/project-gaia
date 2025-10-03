shader_type spatial;
render_mode cull_disabled;

// Textures
uniform sampler2D noise_tex;
uniform sampler2D normal_map : hint_normal;

// Shape parameters
uniform float sphere_radius : hint_range(0.1, 5.0) = 1.0;
uniform float amplitude : hint_range(0.0, 0.5) = 0.15; // Reduced - real asteroids have subtle surface variation
uniform vec3 axis_scale = vec3(1.0, 1.0, 1.0);

// Realistic NEO colors (based on meteorite and mission data)
uniform vec3 base_color : source_color = vec3(0.2, 0.18, 0.16); // Dark carbonaceous
uniform vec3 weathered_color : source_color = vec3(0.15, 0.13, 0.11); // Space-weathered (darker)
uniform vec3 fresh_material : source_color = vec3(0.3, 0.25, 0.22); // Recently exposed material
uniform vec3 iron_bearing : source_color = vec3(0.25, 0.2, 0.15); // Iron-rich areas

// Scientific surface features
uniform float regolith_roughness : hint_range(0.0, 2.0) = 0.8;
uniform float space_weathering : hint_range(0.0, 1.0) = 0.6;
uniform float boulder_density : hint_range(0.0, 10.0) = 3.0; // Large rocks, not craters
uniform float micrometeorite_pitting : hint_range(0.0, 1.0) = 0.4;

// Material properties
uniform float base_roughness : hint_range(0.0, 1.0) = 0.9; // Very rough regolith
uniform float base_metallic : hint_range(0.0, 1.0) = 0.1; // Slightly metallic due to iron

// Stylization controls
uniform float toon_steps : hint_range(2.0, 8.0) = 4.0;
uniform float rim_power : hint_range(0.1, 5.0) = 2.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_pos_for_sampling;
varying vec3 world_normal;
varying vec3 view_dir;

// Cube to sphere transformation
vec3 cube_to_sphere(vec3 cube_pos) {
    vec3 cube_squared = cube_pos * cube_pos;
    vec3 sphere_pos;

    sphere_pos.x = cube_pos.x * sqrt(1.0 - cube_squared.y * 0.5 - cube_squared.z * 0.5 + cube_squared.y * cube_squared.z / 3.0);
    sphere_pos.y = cube_pos.y * sqrt(1.0 - cube_squared.z * 0.5 - cube_squared.x * 0.5 + cube_squared.z * cube_squared.x / 3.0);
    sphere_pos.z = cube_pos.z * sqrt(1.0 - cube_squared.x * 0.5 - cube_squared.y * 0.5 + cube_squared.x * cube_squared.y / 3.0);

    return normalize(sphere_pos) * sphere_radius;
}

// Multi-scale regolith texture (based on real particle size distributions)
float regolith_fbm(vec3 pos, int octaves) {
    float value = 0.0;
    float amplitude_f = 1.0;
    float frequency = 1.0;
    float max_value = 0.0;

    for(int i = 0; i < octaves; i++) {
        // Sample different planes for 3D-like noise
        float sample1 = texture(noise_tex, pos.xy * frequency * 0.05).r;
        float sample2 = texture(noise_tex, pos.yz * frequency * 0.05).r;
        float sample3 = texture(noise_tex, pos.xz * frequency * 0.05).r;

        float combined = (sample1 + sample2 + sample3) / 3.0;
        value += combined * amplitude_f;
        max_value += amplitude_f;

        frequency *= 2.5; // Slightly different scaling for more natural look
        amplitude_f *= 0.6;
        pos = pos * 2.0 + vec3(0.07, 0.11, 0.13); // Irregular offset
    }

    return value / max_value;
}

// Boulder/rock distribution (not craters - most NEOs lack large craters)
float boulder_pattern(vec3 pos, float density) {
    float total = 0.0;
    int max_boulders = int(density);

    for(int i = 0; i < max_boulders; i++) {
        float fi = float(i);
        vec3 center = vec3(
            fract(sin(fi * 12.9898 + 78.233) * 43758.5453),
            fract(sin(fi * 39.3467 + 12.9898) * 43758.5453),
            fract(sin(fi * 78.233 + 39.3467) * 43758.5453)
        ) * 2.0 - 1.0;

        center = normalize(center);
        float dist = distance(normalize(pos), center);

        // Boulder sizes vary significantly
        float boulder_size = 0.05 + fract(sin(fi * 67.123) * 23456.789) * 0.1;
        float boulder_height = smoothstep(boulder_size, boulder_size * 0.7, dist);

        total += boulder_height;
    }

    return clamp(total, 0.0, 1.0);
}

// Micrometeorite impact pitting
float micro_pitting(vec3 pos) {
    float pits = regolith_fbm(pos * 50.0, 3); // Very fine scale
    return smoothstep(0.3, 0.7, pits);
}

// Space weathering simulation
float space_weathering_factor(vec3 pos, vec3 normal, vec3 light_dir) {
    // Space weathering is stronger on sun-facing surfaces
    float sun_exposure = max(0.0, dot(normal, light_dir));
    float base_weathering = regolith_fbm(pos * 0.8, 2);
    return mix(base_weathering, sun_exposure * base_weathering, space_weathering);
}

// Toon shading ramp
float toon_ramp(float value, float steps) {
    return floor(value * steps) / steps;
}

void vertex() {
    // Transform cube to sphere
    vec3 sphere_pos = cube_to_sphere(VERTEX);
    sphere_pos *= axis_scale;
    world_pos_for_sampling = sphere_pos;

    // Regolith surface roughness (multiple scales)
    float coarse_regolith = regolith_fbm(sphere_pos * 2.0, 4) * amplitude;
    float fine_regolith = regolith_fbm(sphere_pos * 12.0, 3) * amplitude * 0.3;
    float micro_texture = regolith_fbm(sphere_pos * 40.0, 2) * amplitude * 0.1;

    float height = coarse_regolith + fine_regolith + micro_texture;

    // Add boulders (positive displacement, unlike craters)
    height += boulder_pattern(sphere_pos, boulder_density) * amplitude * 0.5;

    // Apply displacement
    vec3 sphere_normal = normalize(sphere_pos);
    vec3 final_pos = sphere_pos + sphere_normal * height;

    VERTEX = final_pos;

    // Calculate world space vectors
    world_normal = normalize((MODEL_MATRIX * vec4(sphere_normal, 0.0)).xyz);
    vec3 world_position = (MODEL_MATRIX * vec4(final_pos, 1.0)).xyz;
    view_dir = normalize(CAMERA_POSITION_WORLD - world_position);

    // Calculate normals
    vec3 tangent = normalize(cross(sphere_normal, vec3(0.0, 1.0, 0.0)));
    if(length(tangent) < 0.01) {
        tangent = normalize(cross(sphere_normal, vec3(1.0, 0.0, 0.0)));
    }
    vec3 bitangent = cross(sphere_normal, tangent);

    vec3 normal_sample = texture(normal_map, UV).rgb * 2.0 - 1.0;
    mat3 TBN = mat3(tangent, bitangent, sphere_normal);
    NORMAL = normalize(TBN * normal_sample);
}

void fragment() {
    vec3 light_dir = normalize(vec3(0.3, 0.8, 0.2)); // Simulated sun direction

    // Surface texture analysis
    float regolith_texture = regolith_fbm(world_pos_for_sampling * 2.0, 4);
    float fine_detail = regolith_fbm(world_pos_for_sampling * 15.0, 3);
    float boulder_mask = boulder_pattern(world_pos_for_sampling, boulder_density);
    float pitting = micro_pitting(world_pos_for_sampling);

    // Space weathering effects
    float weathering = space_weathering_factor(world_pos_for_sampling, world_normal, light_dir);

    // Realistic color mixing based on NEO composition
    vec3 color = base_color;

    // Space weathering darkens and reddens surfaces
    color = mix(color, weathered_color, weathering * space_weathering);

    // Fresh material from recent impacts or boulder faces
    float fresh_exposure = boulder_mask + (1.0 - smoothstep(0.4, 0.8, regolith_texture));
    color = mix(color, fresh_material, fresh_exposure * 0.3);

    // Iron-bearing minerals (common in meteorites)
    float iron_areas = smoothstep(0.6, 0.9, regolith_texture + fine_detail * 0.5);
    color = mix(color, iron_bearing, iron_areas * 0.2);

    // Micrometeorite pitting creates slightly different reflectance
    color *= (0.95 + pitting * 0.1);

    // Toon lighting for stylization
    float NdotL = dot(world_normal, light_dir);
    NdotL = toon_ramp(max(0.0, NdotL), toon_steps);

    // Subtle rim lighting (space is harsh environment)
    float rim_factor = 1.0 - max(0.0, dot(world_normal, view_dir));
    rim_factor = pow(rim_factor, rim_power);
    vec3 rim_light = fresh_material * rim_factor * rim_intensity;

    // Apply lighting
    color *= (0.2 + NdotL * 0.8); // Harsh space lighting
    color += rim_light;

    // Final surface variation
    color *= (0.9 + fine_detail * 0.2);

    ALBEDO = color;

    // Regolith is very rough, with variations
    ROUGHNESS = base_roughness * (0.8 + regolith_texture * 0.4);

    // Slight metallic content from iron-bearing minerals
    METALLIC = base_metallic * iron_areas;
}