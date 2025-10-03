shader_type spatial;
render_mode world_vertex_coords;

// Asteroid impact parameters
uniform vec3 impact_position  = vec3(0.0, 0.0, 0.0);
uniform float crater_radius : hint_range(0.1, 10.0) = 2.0;
uniform float crater_depth : hint_range(0.1, 5.0) = 1.0;
uniform float rim_height : hint_range(0.0, 2.0) = 0.3;
uniform float rim_width : hint_range(0.1, 2.0) = 0.5;
uniform float impact_strength : hint_range(0.1, 3.0) = 1.0;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.2;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;

// Noise function for surface roughness
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Crater profile function
float crater_profile(float distance, float radius, float depth, float _rim_height, float _rim_width) {
    float normalized_dist = distance / radius;
    
    if (normalized_dist > 1.0 + _rim_width) {
        return 0.0; // Outside crater influence
    }
    
    if (normalized_dist <= 1.0) {
        // Inside crater - parabolic depression
        float crater_factor = 1.0 - normalized_dist * normalized_dist;
        return -depth * crater_factor;
    } else {
        // Rim area - raised edge that falls off
        float rim_factor = (normalized_dist - 1.0) / _rim_width;
        rim_factor = 1.0 - rim_factor;
        rim_factor = rim_factor * rim_factor; // Smooth falloff
        return _rim_height * rim_factor;
    }
}

void vertex() {
    // VERTEX is already in world coordinates due to render_mode world_vertex_coords
    vec2 impact_pos_2d = impact_position.xz;
    vec2 vertex_pos_2d = VERTEX.xz;
    float distance_to_impact = length(vertex_pos_2d - impact_pos_2d);
    
    // Calculate base crater deformation
    float deformation = crater_profile(
        distance_to_impact,
        crater_radius,
        crater_depth * impact_strength,
        rim_height * impact_strength,
        rim_width
    );
    
    // Add surface roughness using noise
    float surface_noise = noise(vertex_pos_2d * noise_scale) * 2.0 - 1.0;
    surface_noise += noise(vertex_pos_2d * noise_scale * 2.0) * 0.5 - 0.25;
    surface_noise += noise(vertex_pos_2d * noise_scale * 4.0) * 0.25 - 0.125;
    
    // Apply roughness more strongly in the crater area
    float roughness_factor = 1.0;
    if (distance_to_impact < crater_radius * (1.0 + rim_width)) {
        roughness_factor = 2.0;
    }
    
    deformation += surface_noise * surface_roughness * roughness_factor;
    
    // Apply deformation to vertex Y position
    VERTEX.y += deformation;
    
    // Calculate proper normals by sampling the height function at nearby points
    float epsilon = 0.1;
    
    // Sample height at offset positions
    float height_x_pos = crater_profile(
        length((vertex_pos_2d + vec2(epsilon, 0.0)) - impact_pos_2d),
        crater_radius, crater_depth * impact_strength, rim_height * impact_strength, rim_width
    );
    float height_x_neg = crater_profile(
        length((vertex_pos_2d + vec2(-epsilon, 0.0)) - impact_pos_2d),
        crater_radius, crater_depth * impact_strength, rim_height * impact_strength, rim_width
    );
    float height_z_pos = crater_profile(
        length((vertex_pos_2d + vec2(0.0, epsilon)) - impact_pos_2d),
        crater_radius, crater_depth * impact_strength, rim_height * impact_strength, rim_width
    );
    float height_z_neg = crater_profile(
        length((vertex_pos_2d + vec2(0.0, -epsilon)) - impact_pos_2d),
        crater_radius, crater_depth * impact_strength, rim_height * impact_strength, rim_width
    );
    
    // Add noise to the height samples too
    height_x_pos += (noise((vertex_pos_2d + vec2(epsilon, 0.0)) * noise_scale) * 2.0 - 1.0) * surface_roughness * roughness_factor;
    height_x_neg += (noise((vertex_pos_2d + vec2(-epsilon, 0.0)) * noise_scale) * 2.0 - 1.0) * surface_roughness * roughness_factor;
    height_z_pos += (noise((vertex_pos_2d + vec2(0.0, epsilon)) * noise_scale) * 2.0 - 1.0) * surface_roughness * roughness_factor;
    height_z_neg += (noise((vertex_pos_2d + vec2(0.0, -epsilon)) * noise_scale) * 2.0 - 1.0) * surface_roughness * roughness_factor;
    
    // Calculate gradient
    vec3 gradient = vec3(
        (height_x_pos - height_x_neg) / (2.0 * epsilon),
        1.0,
        (height_z_pos - height_z_neg) / (2.0 * epsilon)
    );
    
    // Set the normal (pointing up from the surface)
    NORMAL = normalize(gradient);
}

void fragment() {
    // VERTEX is already in world coordinates due to render_mode world_vertex_coords
    vec2 vertex_pos_2d = VERTEX.xz;
    vec2 impact_pos_2d = impact_position.xz;
    float distance_to_impact = length(vertex_pos_2d - impact_pos_2d);
    
    // Base surface color
    vec3 base_color = vec3(0.6, 0.5, 0.4); // Sandy/rocky color
    
    // Calculate normalized distance for smooth color transitions
    float normalized_dist = distance_to_impact / crater_radius;
    
    // Crater interior - darker, exposed subsurface material
    if (normalized_dist < 1.0) {
        // Smooth transition from center to edge
        float crater_factor = smoothstep(0.0, 1.0, normalized_dist);
        vec3 crater_color = vec3(0.2, 0.15, 0.1); // Dark crater material
        base_color = mix(crater_color, base_color, crater_factor);
    }
    
    // Rim area - lighter ejected material
    else if (normalized_dist < (1.0 + rim_width)) {
        float rim_factor = (normalized_dist - 1.0) / rim_width;
        rim_factor = smoothstep(0.0, 1.0, rim_factor);
        vec3 rim_color = vec3(0.8, 0.7, 0.6); // Lighter ejected material
        base_color = mix(rim_color, base_color, rim_factor);
    }
    
    // Add subtle color variation based on surface noise
    float color_variation = noise(vertex_pos_2d * noise_scale * 0.3);
    base_color += (color_variation - 0.5) * 0.05;
    
    // Clamp colors to valid range
    base_color = clamp(base_color, 0.0, 1.0);
    
    ALBEDO = base_color;
    ROUGHNESS = 0.8 + (color_variation - 0.5) * 0.2; // Vary roughness slightly
    METALLIC = 0.0;
}