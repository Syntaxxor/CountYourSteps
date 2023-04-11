shader_type canvas_item;

uniform int blur_rad = 3;
uniform float blur_lod = 2.0;

void fragment() {
	vec4 sum = vec4(0.0);
	float weight = 0.0;
	for(int x = -blur_rad; x <= blur_rad; x++){
		for(int y = -blur_rad; y <= blur_rad; y++){
			vec2 off = vec2(float(x), float(y));
			float dist = 1.0 - clamp(length(off) / float(blur_rad), 0.0, 1.0);
			vec2 lod_size = SCREEN_PIXEL_SIZE * pow(2.0, blur_lod);
			sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + off * lod_size, blur_lod) * dist;
			weight += dist;
		}
	}
	
	sum.a = weight;
	
	COLOR *= sum / weight;
}
