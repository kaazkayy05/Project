shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture :
	hint_screen_texture, repeat_disable, filter_linear;

uniform float radius_at_720p : hint_range(0.0, 2.0) = 0.9;
uniform float strength : hint_range(0.0, 1.0) = 0.65;

uniform float scanline_strength : hint_range(0.0, 0.3) = 0.10;
uniform float scanline_spacing : hint_range(2.0, 8.0) = 3.0;
uniform float grain_strength : hint_range(0.0, 0.1) = 0.025;
uniform float tracking_frequency : hint_range(0.0, 0.5) = 0.12;
uniform float tracking_strength : hint_range(0.0, 0.3) = 0.12;
uniform float instability : hint_range(0.0, 2.0) = 0.35;
uniform float color_separation : hint_range(0.0, 2.0) = 0.65;

float video_noise(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 reference_pixel = vec2(SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y, 1.0) / 720.0;

	// One brief, smoothly faded tracking event per interval.
	float phase = fract(TIME * tracking_frequency);
	float event_progress = clamp(phase / 0.12, 0.0, 1.0);
	float event_fade = sin(event_progress * 3.14159265);
	float band_center = mix(-0.08, 1.08, event_progress);
	float band = 1.0 - smoothstep(0.004, 0.022,
		abs(SCREEN_UV.y - band_center));
	float tracking = band * event_fade * tracking_strength;

	// Displace the recorded image, never the actual Camera3D.
	float drift = sin(TIME * 1.7) * 0.65
		+ sin(SCREEN_UV.y * 31.0 + TIME * 2.3) * 0.35;
	uv.x += reference_pixel.x * (drift * instability + tracking * 2.0);
	uv = clamp(uv, SCREEN_PIXEL_SIZE * 0.5,
		vec2(1.0) - SCREEN_PIXEL_SIZE * 0.5);

	// Keep the apparent softness proportional across resolutions.
	float resolution_scale = 1.0 / (SCREEN_PIXEL_SIZE.y * 720.0);
	vec2 offset = SCREEN_PIXEL_SIZE * radius_at_720p * resolution_scale;

	vec3 original = texture(screen_texture, uv).rgb;
	vec3 softened = original * 4.0;

	softened += texture(screen_texture, uv + vec2(offset.x, 0.0)).rgb * 2.0;
	softened += texture(screen_texture, uv - vec2(offset.x, 0.0)).rgb * 2.0;
	softened += texture(screen_texture, uv + vec2(0.0, offset.y)).rgb * 2.0;
	softened += texture(screen_texture, uv - vec2(0.0, offset.y)).rgb * 2.0;

	softened += texture(screen_texture, uv + offset).rgb;
	softened += texture(screen_texture, uv - offset).rgb;
	softened += texture(screen_texture, uv + vec2(offset.x, -offset.y)).rgb;
	softened += texture(screen_texture, uv + vec2(-offset.x, offset.y)).rgb;

	softened /= 16.0;
	vec3 image = mix(original, softened, strength);

	// Small horizontal channel offsets make fringing visible at edges.
	if (color_separation > 0.0) {
		vec2 bleed = vec2(reference_pixel.x * color_separation, 0.0);
		float red = texture(screen_texture, uv + bleed).r;
		float blue = texture(screen_texture, uv - bleed).b;
		image.r += (red - original.r) * 0.5;
		image.b += (blue - original.b) * 0.5;
	}

	// Fade scanlines at resolutions where their spacing becomes too fine.
	float spacing = max(scanline_spacing, 2.0);
	float line = 0.5 + 0.5 * cos(SCREEN_UV.y * 720.0
		/ spacing * 6.2831853);
	float spacing_pixels = spacing / (720.0 * SCREEN_PIXEL_SIZE.y);
	float line_visibility = smoothstep(1.0, 2.0, spacing_pixels);
	image *= 1.0 - line * scanline_strength * line_visibility;

	float frame = mod(floor(TIME * 24.0), 4096.0);
	vec2 grain_cell = floor(SCREEN_UV / SCREEN_PIXEL_SIZE);
	float grain = video_noise(grain_cell + vec2(frame * 17.0, frame * 29.0)) - 0.5;
	// Reduce noise in near-black areas to retain the dark atmosphere.
	float grain_visibility = mix(0.35, 1.0,
		smoothstep(0.0, 0.25, dot(image, vec3(0.299, 0.587, 0.114))));
	image += vec3(grain * grain_strength * grain_visibility);

	// Local restrained interference, never an opaque or full-screen flash.
	image *= 1.0 - tracking * 0.25;
	image += vec3(grain * tracking * 0.08);
	COLOR = vec4(clamp(image, vec3(0.0), vec3(1.0)), 1.0);
}
