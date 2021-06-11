#version 330

in vec2 texCoord;
in vec3 vertex_view;
in vec3 normal_view;
in vec4 VColor;

out vec4 FragColor;

// [TODO] passing texture from main.cpp
// Hint: sampler2D

struct Light
{
	vec4 d_position;
	vec4 d_direction;
	vec4 p_position;
	vec4 s_position;
	vec4 s_direction;
	vec4 ambient_intensity;
	vec4 d_diffuse_intensity;
	vec4 p_diffuse_intensity;
	vec4 s_diffuse_intensity;
	vec3 point_attenuation;
	vec3 spot_attenuation;
	float spot_exp;
	float cutoff;
	float shininess;
};

struct PhongMaterial
{
	vec4 Ka;
	vec4 Kd;
	vec4 Ks;
};


uniform PhongMaterial material;
uniform mat4 mvp;
uniform Light light;
uniform int Light_Mode;
uniform int Shading_Mode;

uniform mat4 project_matrix;
uniform mat4 view_matrix;
uniform mat4 rotation_matrix;
uniform mat4 scaling_matrix;
uniform mat4 translation_matrix;

vec4 ambient(vec4 Ia, vec4 Ka){return Ia * Ka;}
vec4 diffuse(vec4 Kd, vec3 N, vec3 L){return Kd * max(dot(N, L), 0);}
vec4 specular(vec4 Ks, vec3 N, vec3 H, float shininess){return Ks * pow(max(dot(N, H), 0), shininess);}
float attenuation(vec3 attenuation, float d){vec3 d_poly2 = {1, d, d*d};return 1/dot(attenuation, d_poly2);}

uniform sampler2D tex;

void main() 
{
	FragColor = vec4(texCoord.xy, 0, 1);

	// [TODO] sampleing from texture
	// Hint: texture

	float distance;
	vec3 att;
	vec4 Ip;

	vec3 N = normal_view;
	vec3 V = vertex_view;
	vec3 View = -vertex_view;
	vec3 Light;
	vec3 H;

	float spotlight_effect = 1;

	if(Light_Mode==0)
	{
		Light = -(view_matrix*(light.d_direction-light.d_position)).xyz;
		distance = 1;
		att = vec3(0.33,0.33,0.33);
		Ip = light.d_diffuse_intensity;
	}
	else if(Light_Mode==1)
	{
		Light = (view_matrix*light.p_position).xyz - V;
		distance = pow( max((Light.x*Light.x+Light.y*Light.y+Light.z*Light.z), 1) , 0.5);
		att=light.point_attenuation;
		Ip = light.p_diffuse_intensity;
	}
	else if(Light_Mode==2)
	{
		vec3 dir = normalize((view_matrix*light.s_direction).xyz);
		vec3 P = (view_matrix*light.s_position).xyz;
		vec3 v_ = normalize(V- P);
		
		if(dot(v_, dir) > cos(light.cutoff)){spotlight_effect = pow( max( dot(v_, dir), 0 ), light.spot_exp );}
		else{spotlight_effect = 0;}

		Light = P-V;
		distance = pow( max((Light.x*Light.x+Light.y*Light.y+Light.z*Light.z), 1) , 0.5);
		att=light.spot_attenuation;
		Ip = light.s_diffuse_intensity;
	}

	Light = normalize(Light);
	H = normalize(Light + View);

	vec4 PColor = ambient(light.ambient_intensity, material.Ka) 
	+ spotlight_effect *  attenuation(att, distance)  * (Ip * diffuse(material.Kd, N, Light) 
	+ specular(material.Ks, N, H, light.shininess) );

	if(Shading_Mode==0)
	{
		FragColor = VColor;
	}
	else
	{FragColor = PColor;}

	vec4 texColor  = vec4(texture(tex, texCoord).rgb, 1.0);
	FragColor = texColor*FragColor;
}

