shader_type spatial;
// render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D gradient;

//resolution must be divisible by pixel_size
const int pixel_size = 8; 

const vec4 texelSize = vec4(float(8));

void fragment() {
	//vec4 color = texture(SCREEN_TEXTURE, UV);
	//float brightness = (color.r + color.g + color.b) / 3.0;
	//vec4 gradientcolor = texture(gradient, vec2(brightness));
	//COLOR = gradientcolor;
	
	//float x = float(int(FRAGCOORD.x) % pixel_size);
	//float y = float(int(FRAGCOORD.y) % pixel_size);

	//x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
	//y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;
	
	// set albedo value on the current coordinate based on vec2(x,y) / viewport_size 
	//vec3 text = texture(SCREEN_TEXTURE, vec2(x, y) / VIEWPORT_SIZE).xyz;
	
	// Pixel upscale
	//vec2 boxSize = clamp(fwidth(UV) * texelSize.zw, 1e-5, 1);
	//vec2 tx = UV * texelSize.zw - 0.5 * boxSize;
	//vec2 txOffset = smoothstep(vec2(1) - boxSize, vec2(1), fract(tx));
	//vec2 uv = (floor(tx) + 0.5 + txOffset) * texelSize.xy;
	
	//ALBEDO = textureGrad(SCREEN_TEXTURE, uv, dFdx(UV), dFdy(UV)).xyz;
}