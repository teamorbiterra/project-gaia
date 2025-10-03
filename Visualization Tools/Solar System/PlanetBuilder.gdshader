shader_type spatial;

// Texture uniforms
uniform sampler2D texture_albedo : source_color;
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_bump : hint_default_white;

// Control flags
uniform bool use_bump_map = false;
uniform bool use_normal_map = false;

// Planet parameters
uniform float sphere_radius = 1.0;
uniform float bump_strength : hint_range(0.0, 2.0) = 1.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

// UV mapping mode
uniform int uv_mode : hint_range(0, 2) = 0; // 0=Cube, 1=Spherical, 2=Equirectangular

varying vec3 world_vertex;
varying vec3 sphere_normal;

// Convert cube position to spherical UV
vec2 cube_to_spherical_uv(vec3 dir) {
    float u = 0.5 + atan(dir.z, dir.x) / (2.0 * PI);
    float v = 0.5 - asin(dir.y) / PI;
    return vec2(u, v);
}

// Convert cube face to UV
vec2 cube_face_uv(vec3 pos) {
    vec3 abs_pos = abs(pos);
    vec2 uv;
    
    if (abs_pos.x >= abs_pos.y && abs_pos.x >= abs_pos.z) {
        // X face
        uv = pos.x > 0.0 ? vec2(-pos.z, pos.y) : vec2(pos.z, pos.y);
    } else if (abs_pos.y >= abs_pos.x && abs_pos.y >= abs_pos.z) {
        // Y face
        uv = pos.y > 0.0 ? vec2(pos.x, -pos.z) : vec2(pos.x, pos.z);
    } else {
        // Z face
        uv = pos.z > 0.0 ? vec2(pos.x, pos.y) : vec2(-pos.x, pos.y);
    }
    
    return uv * 0.5 + 0.5;
}

void vertex() {
    // Store original world position
    vec3 local_pos = VERTEX;
    
    // Normalize to get direction from center
    vec3 direction = normalize(local_pos);
    
    // Project onto sphere
    VERTEX = direction * sphere_radius;
    
    // Calculate sphere normal (pointing outward from center)
    sphere_normal = direction;
    
    // Store world vertex for fragment shader
    world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Calculate UV based on mode
    vec2 sphere_uv;
    vec3 local_normal = sphere_normal;
    
    if (uv_mode == 0) {
        // Cube face UV (preserves original box UV layout)
        sphere_uv = cube_face_uv(sphere_normal);
    } else if (uv_mode == 1) {
        // Spherical UV mapping
        sphere_uv = cube_to_spherical_uv(sphere_normal);
    } else {
        // Use original UV
        sphere_uv = UV;
    }
    
    // Sample albedo texture
    ALBEDO = texture(texture_albedo, sphere_uv).rgb;
    
    // Apply normal map if enabled
    if (use_normal_map) {
        vec3 normal_map = texture(texture_normal, sphere_uv).rgb;
        normal_map = normal_map * 2.0 - 1.0; // Convert from [0,1] to [-1,1]
        normal_map.xy *= normal_strength;
        normal_map = normalize(normal_map);
        
        NORMAL_MAP = normal_map;
        NORMAL_MAP_DEPTH = normal_strength;
    } else {
        // Use the sphere normal directly
        NORMAL = normalize(sphere_normal);
    }
    
    // Apply bump map if enabled (for displacement effect in lighting)
    if (use_bump_map) {
        float bump_value = texture(texture_bump, sphere_uv).r;
        
        // Create heightmap-based normal perturbation
        float offset = 0.001;
        float h_right = texture(texture_bump, sphere_uv + vec2(offset, 0.0)).r;
        float h_up = texture(texture_bump, sphere_uv + vec2(0.0, offset)).r;
        
        vec3 bump_normal;
        bump_normal.x = (bump_value - h_right) * bump_strength;
        bump_normal.y = (bump_value - h_up) * bump_strength;
        bump_normal.z = 1.0;
        bump_normal = normalize(bump_normal);
        
        // Combine with normal map or apply directly
        if (use_normal_map) {
            // Blend bump with normal map
            vec3 combined = normalize(NORMAL_MAP + bump_normal * 0.5);
            NORMAL_MAP = combined;
        } else {
            NORMAL_MAP = bump_normal;
            NORMAL_MAP_DEPTH = bump_strength;
        }
    }
    
    // Optional: Add roughness/metallic based on bump
    if (use_bump_map) {
        float bump_val = texture(texture_bump, sphere_uv).r;
        ROUGHNESS = mix(0.3, 0.7, bump_val);
    } else {
        ROUGHNESS = 0.5;
    }
    
    METALLIC = 0.0;
}