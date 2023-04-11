shader_type spatial;

uniform vec3 floor_col: source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 grid_col: source_color = vec3(0.0, 0.0, 0.0);
uniform float roughness: hint_range(0.0, 1.0) = 0.2;

uniform float grid_size = 1.0;
uniform float grid_sharpness = 16.0;

void fragment() {
	vec3 world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float grid_z = clamp(abs(fract(world_position.z * 0.5 + 0.5) * 2.0 - 1.0) * grid_sharpness - grid_size, 0.0, 1.0);
	float grid_x = clamp(abs(fract(world_position.x * 0.5 + 0.5) * 2.0 - 1.0) * grid_sharpness - grid_size, 0.0, 1.0);
	float grid = grid_z * grid_x;
	ALBEDO = mix(grid_col, floor_col, grid);
	ROUGHNESS = roughness;
}
