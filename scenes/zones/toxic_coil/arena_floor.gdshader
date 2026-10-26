shader_type spatial;
// Grimy sewer grating with faintly glowing grid lines, so every cell reads clearly
// from the top-down camera. Lines sit on whole-number world coordinates.

uniform vec4 base_color : source_color = vec4(0.10, 0.11, 0.10, 1.0);
uniform vec4 line_color : source_color = vec4(0.25, 0.75, 0.18, 1.0);
uniform float cell_size = 1.0;
uniform float line_width = 0.035;
uniform float line_emission = 0.5;

varying vec3 world_pos;

float cell_noise(vec2 cell) {
	return fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz / cell_size;
	vec2 to_edge = abs(fract(uv) - 0.5);
	float line = smoothstep(0.5 - line_width, 0.5, max(to_edge.x, to_edge.y));
	float grime = cell_noise(floor(uv));
	vec3 tile = base_color.rgb * (0.8 + 0.4 * grime);
	ALBEDO = mix(tile, line_color.rgb * 0.3, line);
	EMISSION = line_color.rgb * line * line_emission;
	ROUGHNESS = mix(0.85, 0.5, line);
	METALLIC = 0.3;
}
