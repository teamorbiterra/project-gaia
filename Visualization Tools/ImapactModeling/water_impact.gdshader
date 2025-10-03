shader_type spatial;
render_mode skip_vertex_transform;

uniform float rim:hint_range(0.0,1.0,0.001)=0.5;
uniform float anisotropy:hint_range(0.0,1.0,0.001)=0.5;
uniform float clearcoat:hint_range(0.0, 1.0, 0.1)=0.1;
uniform float clearcoat_roughness:hint_range(0.0, 1.0, 0.1)=0.1;
uniform vec3 backlight:source_color=vec3(1.0);
uniform float ambient_occlution: hint_range(0.0, 5.0,1.0)= 0.1;
uniform vec4 fog= vec4(0.0);


void vertex() {
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

void fragment(){
	ALBEDO= vec3(0.1,0.5,1.0);
	RIM =rim;
	ANISOTROPY= anisotropy;
	CLEARCOAT=clearcoat;
	CLEARCOAT_ROUGHNESS=clearcoat_roughness;
	BACKLIGHT= backlight;
	AO= ambient_occlution;
	FOG= fog;
}

void light(){
	
	DIFFUSE_LIGHT+=clamp(dot(NORMAL,LIGHT),0.0,1.0)*ATTENUATION*LIGHT_COLOR/PI;
	
	
	
}