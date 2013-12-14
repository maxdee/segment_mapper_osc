uniform float time;
uniform vec2 resolution;


void main( void ) {
	float rads = radians(time*3.15);
	vec2 position = gl_FragCoord.xy / resolution.xy;
	
	gl_FragColor = vec4(vec3(position,1.0), 1.0);
}
