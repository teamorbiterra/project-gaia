// === final version
// == bug fixed: looks fuzzy when close to camera
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
uniform float roughness_value : hint_range(0.0, 1.0) = 0.0;

// World space center control
uniform vec3 world_center = vec3(0.0, 0.0, 0.0);

// Solution selector
uniform int seam_fix_method : hint_range(0, 4) = 4;

// Distance-based amplitude control
uniform float max_distance : hint_range(1.0, 100.0) = 20.0;
uniform float min_amplitude_ratio : hint_range(0.0, 1.0) = 0.1;

// Parallax parameters for close-up detail
uniform float parallax_scale : hint_range(0.0, 0.1) = 0.02;
uniform int parallax_steps : hint_range(1, 32) = 8;

varying vec3 local_normal;
varying vec3 world_pos_for_sampling;
varying vec3 world_position;
varying vec3 view_dir;
varying float distance_to_camera;

// 3D Noise sampling
float sample_3d_noise(sampler2D noise_tex, vec3 pos, float scale) {
    vec3 scaled_pos = pos * scale;

    float noise1 = texture(noise_tex, scaled_pos.xy).r;
    float noise2 = texture(noise_tex, scaled_pos.yz).r;
    float noise3 = texture(noise_tex, scaled_pos.zx).r;

    vec3 blend_weights = abs(normalize(pos));
    blend_weights = blend_weights / (blend_weights.x + blend_weights.y + blend_weights.z);

    return noise1 * blend_weights.z + noise2 * blend_weights.x + noise3 * blend_weights.y;
}

// Improved spherical UV
vec2 improved_spherical_uv(vec3 pos) {
    vec3 normalized_pos = normalize(pos);
    float u = 0.5 + atan(normalized_pos.z, normalized_pos.x) / (2.0 * PI);
    float v = 0.5 - asin(clamp(normalized_pos.y, -1.0, 1.0)) / PI;
    return vec2(u, v);
}

// Parallax Occlusion Mapping for close-up detail
vec2 parallax_mapping(vec2 uv, vec3 view_dir_tangent, sampler2D height_map, float scale, int steps) {
    float layer_depth = 1.0 / float(steps);
    float current_layer_depth = 0.0;

    vec2 delta_uv = view_dir_tangent.xy * scale / float(steps);
    vec2 current_uv = uv;

    float current_depth_map_value = 1.0 - sample_3d_noise(height_map, vec3(current_uv, 0.0), uv_scale.x);

    while(current_layer_depth < current_depth_map_value && current_layer_depth < 1.0) {
        current_uv -= delta_uv;
        current_depth_map_value = 1.0 - sample_3d_noise(height_map, vec3(current_uv, 0.0), uv_scale.x);
        current_layer_depth += layer_depth;
    }

    // Binary search refinement
    vec2 prev_uv = current_uv + delta_uv;
    float after_depth = current_depth_map_value - current_layer_depth;
    float before_depth = (1.0 - sample_3d_noise(height_map, vec3(prev_uv, 0.0), uv_scale.x)) - current_layer_depth + layer_depth;

    float weight = after_depth / (after_depth - before_depth);
    vec2 final_uv = prev_uv * weight + current_uv * (1.0 - weight);

    return final_uv;
}

// Calculate finite difference normals
vec3 calculate_surface_normal(vec3 pos, float offset) {
    vec3 sampling_pos = pos + world_center;

    float h = sample_3d_noise(noise, sampling_pos, uv_scale.x);
    float hx = sample_3d_noise(noise, sampling_pos + vec3(offset, 0.0, 0.0), uv_scale.x);
    float hy = sample_3d_noise(noise, sampling_pos + vec3(0.0, offset, 0.0), uv_scale.x);
    float hz = sample_3d_noise(noise, sampling_pos + vec3(0.0, 0.0, offset), uv_scale.x);

    vec3 gradient = vec3(hx - h, hy - h, hz - h) / offset;
    vec3 surface_normal = normalize(pos);

    // Calculate tangent vectors
    vec3 tangent1 = normalize(cross(surface_normal, vec3(0.0, 1.0, 0.0)));
    if (length(tangent1) < 0.1) {
        tangent1 = normalize(cross(surface_normal, vec3(1.0, 0.0, 0.0)));
    }
    vec3 tangent2 = normalize(cross(surface_normal, tangent1));

    // Project gradient onto tangent plane
    vec3 projected_gradient = gradient - dot(gradient, surface_normal) * surface_normal;

    // Calculate perturbed normal
    return normalize(surface_normal - projected_gradient * amplitude);
}

void vertex() {
    // Calculate world position for distance measurement
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    distance_to_camera = length(world_position - CAMERA_POSITION_WORLD);

    // Distance-based amplitude scaling
    float distance_factor = clamp(distance_to_camera / max_distance, 0.0, 1.0);
    float scaled_amplitude = amplitude * mix(1.0, min_amplitude_ratio, distance_factor);

    // Step 1: Convert box vertex to sphere
    vec3 sphere_vertex = normalize(VERTEX) * sphere_radius;
    sphere_vertex *= axis_scale;

    // Step 2: Create sampling position
    vec3 sampling_pos = sphere_vertex + world_center;
    world_pos_for_sampling = sampling_pos;

    float height_displacement = 0.0;
    vec2 sphere_uv = improved_spherical_uv(sphere_vertex);

    if (seam_fix_method == 4) {
        // Method 4: Distance-adaptive displacement
        if (distance_to_camera > max_distance * 0.3) {
            // Far: use full vertex displacement
            height_displacement = sample_3d_noise(noise, sampling_pos, uv_scale.x) * scaled_amplitude;
        } else {
            // Close: reduced vertex displacement, rely on parallax mapping
            height_displacement = sample_3d_noise(noise, sampling_pos, uv_scale.x) * scaled_amplitude * 0.5;
        }
    } else {
        // Other methods
        if (seam_fix_method == 0) {
            vec3 normalized_pos = normalize(sphere_vertex);
            sphere_uv = vec2(
                atan(normalized_pos.x, normalized_pos.z) / (2.0 * PI) + 0.5,
                acos(clamp(normalized_pos.y, -1.0, 1.0)) / PI
            );
            height_displacement = texture(noise, sphere_uv * uv_scale).r * scaled_amplitude;
        }
        else if (seam_fix_method == 1 || seam_fix_method == 2) {
            height_displacement = sample_3d_noise(noise, sampling_pos, uv_scale.x) * scaled_amplitude;
        }
        else if (seam_fix_method == 3) {
            sphere_uv = improved_spherical_uv(sphere_vertex);
            height_displacement = texture(noise, sphere_uv * uv_scale).r * scaled_amplitude;
        }
    }

    // Apply displacement
    vec3 scaled_normal = normalize(sphere_vertex);
    vec3 displaced_vertex = sphere_vertex + scaled_normal * height_displacement;

    // Calculate view direction for parallax
    vec3 world_pos = (MODEL_MATRIX * vec4(displaced_vertex, 1.0)).xyz;
    view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);

    // Calculate normals
    vec3 final_normal;
    if (seam_fix_method >= 1) {
        final_normal = calculate_surface_normal(sphere_vertex, 0.01);
    } else {
        // Standard normal mapping
        vec3 normal_sample = texture(normal_map, sphere_uv * uv_scale).rgb;
        vec3 normal_from_map = normalize(normal_sample * 2.0 - 1.0);

        vec3 tangent = normalize(cross(scaled_normal, vec3(0.0, 1.0, 0.0)));
        if (length(tangent) < 0.1) {
            tangent = normalize(cross(scaled_normal, vec3(1.0, 0.0, 0.0)));
        }
        vec3 bitangent = normalize(cross(scaled_normal, tangent));

        mat3 tbn = mat3(tangent, bitangent, scaled_normal);
        final_normal = normalize(tbn * normal_from_map);
    }

    VERTEX = displaced_vertex;
    NORMAL = final_normal;
    UV = sphere_uv;
    local_normal = scaled_normal;
}

void fragment() {
    vec2 final_uv = UV;

    // Apply parallax mapping for close distances
    if (seam_fix_method == 4 && distance_to_camera < max_distance * 0.5) {
        // Create tangent space view direction
        vec3 tangent = normalize(cross(local_normal, vec3(0.0, 1.0, 0.0)));
        if (length(tangent) < 0.1) {
            tangent = normalize(cross(local_normal, vec3(1.0, 0.0, 0.0)));
        }
        vec3 bitangent = normalize(cross(local_normal, tangent));
        mat3 tbn = mat3(tangent, bitangent, local_normal);

        vec3 view_dir_tangent = normalize(transpose(tbn) * view_dir);

        // Apply parallax mapping
        float parallax_intensity = clamp((max_distance * 0.5 - distance_to_camera) / (max_distance * 0.3), 0.0, 1.0);
        final_uv = parallax_mapping(UV * uv_scale, view_dir_tangent, noise, parallax_scale * parallax_intensity, parallax_steps);
    }

    vec3 noise_color;
    if (seam_fix_method >= 1) {
        float noise_value = sample_3d_noise(noise, world_pos_for_sampling, uv_scale.x);
        noise_color = vec3(noise_value);
    } else {
        noise_color = texture(noise, final_uv).rgb;
    }

    ALBEDO = mix(noise_color, mix_color, mix_ratio);
    ROUGHNESS = roughness_value;
}