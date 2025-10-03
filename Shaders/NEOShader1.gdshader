// Shader version 1



shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise;
uniform sampler2D normal_map : hint_normal;
uniform float sphere_radius : hint_range(0.1, 5.0) = 1.0;
uniform float amplitude : hint_range(0.0, 2.0) = 0.3;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec3 mix_color : source_color = vec3(1.0);
uniform float mix_ratio : hint_range(0.0, 1.0) = 0.5;
uniform vec3 axis_scale = vec3(1.0, 1.0, 1.0);
uniform float roughtness_value : hint_range(0.0, 1.0) = 0.0;

// World space center control
uniform vec3 world_center = vec3(0.0, 0.0, 0.0);

// Solution selector
uniform int seam_fix_method : hint_range(0, 2) = 1;

varying vec3 local_normal;
varying vec3 world_pos_for_sampling;

// Method 1: 3D Noise sampling (best solution)
float sample_3d_noise(sampler2D noise_tex, vec3 pos, float scale) {
    // Sample noise at multiple octaves using 3D position
    vec3 scaled_pos = pos * scale;
    
    // Create pseudo-3D sampling by taking multiple 2D samples
    float noise1 = texture(noise_tex, scaled_pos.xy).r;
    float noise2 = texture(noise_tex, scaled_pos.yz).r;
    float noise3 = texture(noise_tex, scaled_pos.zx).r;
    
    // Blend the samples based on surface normal weights
    vec3 blend_weights = abs(normalize(pos));
    blend_weights = blend_weights / (blend_weights.x + blend_weights.y + blend_weights.z);
    
    return noise1 * blend_weights.z + noise2 * blend_weights.x + noise3 * blend_weights.y;
}

// Method 2: Improved spherical UV with better wrapping
vec2 improved_spherical_uv(vec3 pos) {
    vec3 normalized_pos = normalize(pos);
    float u = 0.5 + atan(normalized_pos.z, normalized_pos.x) / (2.0 * PI);
    float v = 0.5 - asin(clamp(normalized_pos.y, -1.0, 1.0)) / PI;
    return vec2(u, v);
}

void vertex() {
    // Step 1: Convert box vertex to sphere by normalizing and scaling
    vec3 sphere_vertex = normalize(VERTEX) * sphere_radius;
    
    // Step 2: Apply axis scaling to deform the sphere
    sphere_vertex *= axis_scale;
    
    // Step 3: Create sampling position with world_center offset (but keep in local space)
    vec3 sampling_pos = sphere_vertex + world_center;
    world_pos_for_sampling = sampling_pos;
    
    float height_displacement = 0.0;
    vec2 sphere_uv = vec2(0.0);
    
    if (seam_fix_method == 0) {
        // Method 0: Original method (for comparison)
        vec3 normalized_pos = normalize(sphere_vertex);
        sphere_uv = vec2(
            atan(normalized_pos.x, normalized_pos.z) / (2.0 * PI) + 0.5,
            acos(clamp(normalized_pos.y, -1.0, 1.0)) / PI
        );
        height_displacement = texture(noise, sphere_uv * uv_scale).r * amplitude;
    }
    else if (seam_fix_method == 1) {
        // Method 1: 3D noise sampling (RECOMMENDED)
        height_displacement = sample_3d_noise(noise, sampling_pos, uv_scale.x) * amplitude;
        // Still calculate UV for fragment shader using local coordinates
        sphere_uv = improved_spherical_uv(sphere_vertex);
    }
    else if (seam_fix_method == 2) {
        // Method 2: Improved spherical UV
        sphere_uv = improved_spherical_uv(sphere_vertex);
        height_displacement = texture(noise, sphere_uv * uv_scale).r * amplitude;
    }
    
    // Step 5: Calculate the scaled surface normal (local space)
    vec3 scaled_normal = normalize(sphere_vertex);
    
    // Step 6: Displace vertex along the scaled normal (local space)
    vec3 displaced_vertex = sphere_vertex + scaled_normal * height_displacement;
    
    // Step 7: Calculate normal mapping
    vec3 normal_sample;
    if (seam_fix_method == 1) {
        // For 3D method, blend normal samples too using sampling position
        vec3 scaled_pos = sampling_pos * uv_scale.x;
        vec3 normal1 = texture(normal_map, scaled_pos.xy).rgb;
        vec3 normal2 = texture(normal_map, scaled_pos.yz).rgb;
        vec3 normal3 = texture(normal_map, scaled_pos.zx).rgb;
        
        vec3 blend_weights = abs(scaled_normal);
        blend_weights = blend_weights / (blend_weights.x + blend_weights.y + blend_weights.z);
        
        normal_sample = normal1 * blend_weights.z + normal2 * blend_weights.x + normal3 * blend_weights.y;
    } else {
        normal_sample = texture(normal_map, sphere_uv * uv_scale).rgb;
    }
    
    vec3 normal_from_map = normalize(normal_sample * 2.0 - 1.0);
    
    // Create tangent space
    vec3 tangent = normalize(cross(scaled_normal, vec3(0.0, 1.0, 0.0)));
    if (length(tangent) < 0.1) {
        tangent = normalize(cross(scaled_normal, vec3(1.0, 0.0, 0.0)));
    }
    vec3 bitangent = normalize(cross(scaled_normal, tangent));
    
    // Transform normal from tangent space to world space
    mat3 tbn = mat3(tangent, bitangent, scaled_normal);
    vec3 final_normal = normalize(tbn * normal_from_map);
    
    // Apply transformations (local space)
    VERTEX = displaced_vertex;
    NORMAL = final_normal;
    UV = sphere_uv;
    
    local_normal = scaled_normal;
}

void fragment() {
    vec3 noise_color;
    
    if (seam_fix_method == 1) {
        // Use 3D sampling for fragment shader too
        float noise_value = sample_3d_noise(noise, world_pos_for_sampling, uv_scale.x);
        noise_color = vec3(noise_value);
    } else {
        // Use UV-based sampling
        noise_color = texture(noise, UV * uv_scale).rgb;
    }
    
    ALBEDO = mix(noise_color, mix_color, mix_ratio);
    ROUGHNESS = roughtness_value;
	
}


