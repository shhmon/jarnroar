shader_type spatial;


void vertex() {
	VERTEX.y += cos(VERTEX.x) * sin(VERTEX.z);
}

void fragment() {
	// Place fragment code here.
}
