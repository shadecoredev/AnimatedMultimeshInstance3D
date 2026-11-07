shader_type spatial;
render_mode cull_back;

/** Albedo texture. */
uniform sampler2D albedo : filter_nearest, hint_default_white;

/** Image containing vertex positions in the RGBF format. */
uniform sampler2D vertex_animation : filter_nearest;

/** Image containing vertex normals in the RGBF format. */
uniform sampler2D normal_animation : filter_nearest;

/** Total frame count in the animation texture (image width in pixels). */
uniform float total_frame_count: hint_range(0.0, 8192.0, 1.0);

/** Total vertex count in the animation texture (image height in pixels). */
uniform float total_vertex_count: hint_range(0.0, 8192.0, 1.0);

void vertex() {

	float frame = 1.0 / total_frame_count;
	float pixel = 1.0 / total_vertex_count;

	int current_frame = int(INSTANCE_CUSTOM.r);
	
	float x = fma(frame, 0.5, float(current_frame) / total_frame_count);
	float y = fma(pixel, 0.5, float(VERTEX_ID) / total_vertex_count);
	vec2 coord = vec2(x, y);

	VERTEX = texture(vertex_animation, coord).rgb;
	NORMAL = texture(normal_animation, coord).rgb;
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}
