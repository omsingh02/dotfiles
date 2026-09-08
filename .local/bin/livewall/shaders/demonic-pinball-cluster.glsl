// @NoMusicInfo
#define POINTS 100  		 // number of stars

// --- GUI utils

float t;

// --- math utils

float dist2(vec2 P0, vec2 P1) { vec2 D=P1-P0; return dot(D,D); }

float hash (float i) { return 2.*fract(sin(i*7467.25)*1e5) - 1.; }
vec2  hash2(float i) { return vec2(hash(i),hash(i-.1)); }
vec4  hash4(float i) { return vec4(hash(i),hash(i-.1),hash(i-.3),hash(i+.1)); }


// === main ===================

// motion of stars
vec2 P(float i) {
	vec4 c = hash4(i);
	return vec2(   cos(t*c.x-c.z)+.15*cos(0.765*t*c.y+c.w),
				 ( sin(t*c.y-c.w)+.15*sin(1.893*t*c.x+c.z) )/0.5	 );
}

// ---

vec3 background(vec2 uv_norm)
{
    // LiveWall uniforms
    t = uTime;
    
    // Normalized pixel coordinates (from 0 to 1) -> scaled to Shadertoy's expectation
    vec2 fragCoord = uv_norm * uResolution;
    
	vec2 uv    = 2.*(fragCoord.xy / uResolution.y - vec2(.8,.5));
    
    // Use uMouse (which is 0.0-1.0)
	float m = .5 * uMouse.x;
	float my = uMouse.y;
	int MODE = int(mod( 6.*m ,3.));
	float fMODE = (1.-cos(6.283*m))/2.;

	const int R = 1;

	float v_val=0.; vec2 V=vec2(0.);
	for (int i=1; i<POINTS; i++) { // sums stars
		vec2 p = P(float(i));
		for (int y=-R; y<=R; y++)  // ghost echos in cycling universe
			for (int x=-R; x<=R; x++) {
				vec2 d = p+2.*vec2(float(x),float(y)) -uv; // pixel to star
				float r2 = dot(d,d);
				r2 = clamp(r2,5e-2*my,1e3);
				V +=  d / r2;  // gravity force field
			}
		}

	v_val = length(V);
	v_val *= 1./(9.*float(POINTS));

	v_val *= 2.+100.*fMODE;
    
    vec4 fColor = vec4(0.0);
	if (MODE==0) fColor = vec4(.2*v_val)+smoothstep(.05,.0,abs(v_val-5.*my))*vec4(1,0,0,0);
	if (MODE==1) fColor = vec4(.2*v_val)+smoothstep(.05,.0,abs(v_val-5.*my))*vec4(1,0,0,0);
	if (MODE==2) fColor = vec4(.2*v_val)+smoothstep(.05,.0,abs(v_val-5.*my))*vec4(1,0,0,0);

    return fColor.rgb;
}
