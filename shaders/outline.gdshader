shader_type spatial;
render_mode unshaded, cull_front;

uniform bool enable = true; // on and off switsch to diesable/enable the outline
// outline costumization
uniform vec4 color : source_color = vec4(0.0); // which color does the outline have?
uniform float scale : hint_range(1.0, 1.5) = 1.1;


void vertex() {
	if (enable) {
		VERTEX *= vec3(scale,scale,scale);
		//VERTEX.y *= 1.1;
		//VERTEX.x += 0.5;
		//VERTEX += 1.0;
	}
}

void fragment() {
	if (enable) {
		ALBEDO = color.rgb; // apply the outlines color
	}
}