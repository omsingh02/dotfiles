// aurora — Flowing aurora bands
// Defines: vec3 background(vec2 uv)

float _anoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = fract(sin(dot(i, vec2(127.1,311.7)))*43758.5453);
    float b = fract(sin(dot(i+vec2(1,0), vec2(127.1,311.7)))*43758.5453);
    float c = fract(sin(dot(i+vec2(0,1), vec2(127.1,311.7)))*43758.5453);
    float d = fract(sin(dot(i+vec2(1,1), vec2(127.1,311.7)))*43758.5453);
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float _afbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 5; i++) { v += a * _anoise(p); p = rot * p * 2.0 + 100.0; a *= 0.5; }
    return v;
}

vec3 background(vec2 uv) {
    float t = uTime * 0.15;
    float n1 = _afbm(uv * 2.0 + vec2(t*0.3, t*0.1));
    float n2 = _afbm(uv * 3.0 + vec2(-t*0.2, t*0.4));
    float n3 = _afbm(uv * 1.5 + vec2(t*0.1, -t*0.15));

    float w1 = smoothstep(0.3, 0.7, sin(uv.y*6.283 + n1*4.0 + t)*0.5+0.5);
    float w2 = smoothstep(0.4, 0.8, sin(uv.y*9.425 + n2*3.0 - t*0.7)*0.5+0.5);
    float w3 = smoothstep(0.2, 0.6, sin(uv.y*4.712 + n3*5.0 + t*0.5)*0.5+0.5);

    vec3 col = uColor1 * w1 * 0.6 + uColor2 * w2 * 0.5 + uColor3 * w3 * 0.4;
    col = max(col, mix(uColor1, uColor2, 0.5) * 0.05);
    col += uColor3 * exp(-3.0 * length(uv - vec2(0.5, 0.7))) * 0.2 * (0.8 + 0.2*sin(t*2.0));
    col *= clamp(1.0 - 0.4 * length((uv-0.5)*1.8), 0.0, 1.0);
    return col;
}
//r33v01v3 2022
// @NoMusicInfo

//line segment
float DistLine(vec2 p,vec2 a,vec2 b){
	vec2 pa = p-a;
	vec2 ba = b-a;
	float t = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
	return length(pa - ba*t);
}
//HASH 1 out, 1 in...
float Hash(float p){
	vec3 p3  = fract(vec3(p,p,p) * fract(uTime));
    p3 += dot(p3, p3.yzx + 342.092);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 background(vec2 uv_norm)
{
    // Convert 0..1 to Screen aspect ratio coords
    vec2 fragCoord = uv_norm * uResolution;
    vec2 uv = (fragCoord.xy - 0.5 * uResolution.xy) / uResolution.y;
    
    vec3 col = vec3(0.0);
    vec3 red = vec3(1.0,0.0,0.0);
    float t = uTime;

//Lines
	vec2 s_[32];
	s_[0]  = vec2( 0.043,-0.111);
	s_[1]  = vec2(-0.043,-0.111);
	s_[2]  = vec2(-0.177,-0.019);
	s_[3]  = vec2(-0.349,-0.007);
	s_[4]  = vec2(-0.382, 0.062);
	s_[5]  = vec2(-0.534, 0.108);
	s_[6]  = vec2(-0.594, 0.089);
	s_[7]  = vec2(-0.592, 0.113);
	s_[8]  = vec2(-0.265, 0.244);
	s_[9]  = vec2(-0.253, 0.170);
	s_[10] = vec2(-0.162, 0.084);
	s_[11] = vec2(-0.142, 0.079);
	s_[12] = vec2(-0.057, 0.023);
	s_[13] = vec2(-0.048, 0.060);
	s_[14] = vec2(-0.023, 0.111);
	s_[15] = vec2(-0.016, 0.051);
	s_[16] = vec2( 0.000, 0.046);
	s_[17] = vec2( 0.016, 0.051);
	s_[18] = vec2( 0.023, 0.111);
	s_[19] = vec2( 0.048, 0.060);
	s_[20] = vec2( 0.057, 0.023);
	s_[21] = vec2( 0.142, 0.079);
	s_[22] = vec2( 0.162, 0.084);
	s_[23] = vec2( 0.253, 0.170);
	s_[24] = vec2( 0.265, 0.244);
	s_[25] = vec2( 0.592, 0.113);
	s_[26] = vec2( 0.594, 0.089);
	s_[27] = vec2( 0.534, 0.108);
	s_[28] = vec2( 0.382, 0.062);
	s_[29] = vec2( 0.349,-0.007);
	s_[30] = vec2( 0.177,-0.019);
	s_[31] = vec2( 0.043,-0.110);

//
//line effect
	float scan = 18e-4;
	float rA = 0.0, rB = 0.0, myline = 0.0;
	float thickness = 11e-4;
	float glow = 0.01;
	float gmod = 0.01;
	float flicker = 0.5;
	float mx = sin(t*0.5)*0.3;
	float my = cos(t*0.2)*0.2;

//draw lines
	for (int i = 0; i < 31; i ++){
		rA = Hash(t + 34.129)* scan;
		rB = Hash(t + 114.543)* scan;
		float scale = sin(t*0.05)*0.4+1.0;

		float d = DistLine(uv,vec2(s_[i].x+mx+rA,s_[i].y+my+rA)*scale,
		vec2(s_[1+i].x+mx+rB,s_[1+i].y+my+rB)*scale);

		float d1 = mix(d,DistLine(uv,vec2(s_[i].x+mx+rA,s_[i].y+my+rA)
		*scale,vec2(0.0,-0.35)),0.9);
		float d2 = min(d1*1.5,d);
		float myglow = Hash(t+float(i))*flicker;

		myline = mix(((thickness/d2-glow)+gmod),
		((thickness/d2-glow)+gmod)*myglow,0.6);

		col += myline*red;
	}

    return col;
}
// @NoMusicInfo

mat3 rotx(float a) { mat3 rot; rot[0] = vec3(1.0, 0.0, 0.0); rot[1] = vec3(0.0, cos(a), -sin(a)); rot[2] = vec3(0.0, sin(a), cos(a)); return rot; }
mat3 roty(float a) { mat3 rot; rot[0] = vec3(cos(a), 0.0, sin(a)); rot[1] = vec3(0.0, 1.0, 0.0); rot[2] = vec3(-sin(a), 0.0, cos(a)); return rot; }
mat3 rotz(float a) { mat3 rot; rot[0] = vec3(cos(a), -sin(a), 0.0); rot[1] = vec3(sin(a), cos(a), 0.0); rot[2] = vec3(0.0, 0.0, 1.0); return rot; }

const float mouseRotateSpeed = 5.0;

struct sdObject
{
    vec3 pos;
    float rad;
    int index;
    float wingAngle;
};

// Amount of butterflies    
#define OBJECTS 40
    
// We can't use global array uniforms easily, so we compute procedural targets on the fly
sdObject sdObjects[OBJECTS];    

// objects that will be potentially hit, found at prestep
#define CACHED 5
sdObject cachedObjects[CACHED];

int maxCacheIndex = 0;
    
// distance functions from https://iquilezles.org/articles/distfunctions

float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

const float MATERIAL_BODY = 0.0;
const float MATERIAL_WING = 1.0;

const float OBJECT_SIZE = 0.5;    
vec2 getModel(in vec3 pos, in sdObject obj)
{
    float l = length(pos);
	
    float bl = (sin(pos.z * 12.0 - 5.0) * 0.5 + 0.5) + 0.3;
    float body = sdHexPrism(pos - vec3(0.0), vec2(OBJECT_SIZE * 0.04 * bl, OBJECT_SIZE * 0.2));         

    float wx = max(abs(l * 6. + .2) - .4, 0.0);
    float sl = 1.5 * abs(sin(wx)) + 0.05;
    
    vec3 wing = vec3(OBJECT_SIZE * 0.5, OBJECT_SIZE * 0.01, OBJECT_SIZE * 0.25 * sl);
    
    float wa = obj.wingAngle;
    float w1 = udBox(rotz(wa) * pos - vec3(OBJECT_SIZE * 0.5, 0.0, 0.0), wing);
    float w2 = udBox(rotz(-wa) * pos + vec3(OBJECT_SIZE * 0.5, 0.0, 0.0), wing);
    
    float id = MATERIAL_BODY;
    if(w1 < body || w2 < body)
    {
        id = MATERIAL_WING;
    }
    
    float m = min(body, min(w1, w2));
    
    return vec2(m, id);
}


vec2 map(in vec3 rp, in sdObject[CACHED] objects, inout vec3 localPos, inout int index)
{
    float m = 9999.0;
    vec2 ret = vec2(m, 0.0);
    
    for (int i = 0; i < CACHED; ++i)
    {
        if ( i <= maxCacheIndex)
        {
            vec3 lp = rp - objects[i].pos;
            float boundDist = length(lp) - objects[i].rad;
            
            float dist;
            float id = 0.0;
            if (boundDist > 0.05) {
                // If completely outside bounding sphere, just use bound distance to push ray fast
                dist = boundDist;
            } else {
                // Inside bounding sphere, evaluate expensive precise distance function
                vec2 mat = getModel(lp, objects[i]);     
                dist = mat.x;
                id = mat.y;
            }
            
            if (dist < m)
            {
                m = dist;
                ret = vec2(dist, id);
                localPos = lp;
                index = objects[i].index;
            }
        }
    }
    return ret;
}

float prestep(in vec3 ro, in vec3 rp, in vec3 rd, in vec3 rd90degXAxis, in vec3 rd90degYAxis)
{
    maxCacheIndex = -1;
    float m = 99999.0;
    for (int i = 0; i < OBJECTS; ++i)
    {
        vec3 sp = sdObjects[i].pos - ro;
        
        float distToPlaneY = abs(dot(rd90degYAxis, sp));
    	float distToPlaneX = abs(dot(rd90degXAxis, sp));
        
        float distanceToPlanes = max(distToPlaneY, distToPlaneX) - sdObjects[i].rad;

        // Use strict bounding sphere distance for the initial travel skip
        float l = length(sp) - sdObjects[i].rad;
        m = min(m, max(0.0, l));
        
        if(distanceToPlanes <= 0.0 && ++maxCacheIndex < CACHED)
        {
            if (maxCacheIndex == 0) cachedObjects[0] = sdObjects[i];
            else if (maxCacheIndex == 1) cachedObjects[1] = sdObjects[i];
            else if (maxCacheIndex == 2) cachedObjects[2] = sdObjects[i];
            else if (maxCacheIndex == 3) cachedObjects[3] = sdObjects[i];
            else if (maxCacheIndex == 4) cachedObjects[4] = sdObjects[i];
        }
    }
    
    return m;
}

void trace(in vec3 rp, in vec3 rd, inout vec4 color)
{
    vec3 ro = rp;
    float travel = 0.0;
    const int STEPS = 50;
    // build orthonormal frame to get right and up vectors to be used in distance calculations 
    vec3 tmp = normalize(cross(rd, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(rd, tmp));
    vec3 right = cross(rd, up);
    
    // pre-step and move ray
    travel = prestep(ro, rp, rd, right, up);
    rp += travel * rd;
    
    vec3 local = vec3(0.0);
    int hitindex = 0;
    
    for (int i = 0; i < STEPS; ++i)
    {
       vec2 mat = map(rp, cachedObjects, local, hitindex);
       float dist = mat.x;
        
       if(dist <= 0.0)
       {
           float id = mat.y;
           float indx = float(hitindex);
           float c1 = sin(indx * 0.1) * 0.5 + 0.5;
           float c2 = abs(cos(abs(local.z * 15.0)) + sin(abs(local.x) * 15.0));
           float c3 = cos(indx * 0.4);
           color = vec4(id, c2 * id, c1 * id, 1.0) * abs(sin(indx * 0.1));
           color.a = 1.0;
               
           return;
       }
       float dst = max(0.01, dist);
       travel += dst;
       rp += rd * dst;
       if(travel > 30.0) return;
    }
}

// Simple procedural noise to replace iChannel0
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

vec3 background(vec2 uv_norm)
{
    vec4 fragColor = vec4(0.0);
    vec2 fragCoord = uv_norm * uResolution;
    
	vec2 uv = fragCoord.xy / uResolution.xy;
    uv -= vec2(0.5);
    uv.y /= uResolution.x / uResolution.y;
    vec2 mouse = uMouse.xy;
    mouse -= vec2(0.5);   
    mouse *= mouseRotateSpeed;
    
    float baseHashTime = sin(uTime * 0.001);
    float baseFlapTime = uTime * 22.0;
    mat3 timeRotY = roty(uTime * 2.0);
    float pzAdd = (sin(uTime) * 0.5 + 0.5) * 1.0;
    float pxMult = 1.0 + (sin(uTime * 0.1) * 0.5 + 0.5) * 0.25;
    float pyMult = 1.0 + (cos(uTime * 0.1) * 0.5 + 0.5) * 0.25;

    for (int i = 0; i < OBJECTS; ++i)
    {
        vec3 hash_val = hash31(baseHashTime + 0.21 * float(i));
        vec3 p = hash_val - vec3(0.5);
        p *= timeRotY;
        p.z += pzAdd;
        p.x *= pxMult;
        p.y *= pyMult;
        // Keep 0.5 radius to match previous cache limits
        sdObjects[i] = sdObject(p * 10.0, OBJECT_SIZE * 1.0, i, sin(baseFlapTime + float(i)));
    }
    
    vec3 rp = vec3(0.0, .0, 1.0);
    vec3 rd = normalize(vec3(uv, 0.3));
    
    rd *= rotx(mouse.y);
    rd *= roty(mouse.x);
    
    trace(rp, rd, fragColor);
    
    // Sample the environment cubemap background
    vec3 rd_bg = rd * roty(3.14159 * 0.5); // Math matches Shadertoy's iChannel1 coordinate projection
    vec3 envColor = texture(uCubeMap, rd_bg * vec3(-1.0, 1.0, 1.0)).rgb;
    fragColor = mix(fragColor, vec4(envColor, 1.0), 1.0 - fragColor.a);
    
    float luma = (fragColor.r + fragColor.g + fragColor.b) * 0.33;
    fragColor -= (luma) * vec4(.9, .5, .0, 1.) * clamp(rd.y - 0.05, 0.0, 1.0);
    
    fragColor += vec4(.2, 0.4, 0.0, 0.0) * abs(clamp(rd.y, -1.0, .0));
	
    // frame
    fragColor = mix(fragColor, vec4(0.0), 1.0 - smoothstep(0.5, 0.45, abs(uv.x)));
    fragColor = mix(fragColor, vec4(0.0), 1.0 - smoothstep(0.28, 0.2, abs(uv.y)));
    
    return fragColor.rgb;
}// Fork of "Cyclotron" by ChunderFPV. https://shadertoy.com/view/McV3Dm
// 2024-04-12 08:13:09
// @NoMusicInfo

#define A(a) mat2(cos((a)*6.2832 + vec4(0, -1.5708, 1.5708, 0)))
#define H(a) (cos(radians(vec3(0, 60, 120))+(a)*6.2832)*.5+.5)
#define R uResolution.xy

float cube(vec3 p, mat2 h, mat2 v)
{
    float a, b;
    
    p.yz *= h;
    p.xz *= v;
    p = abs(p);
    
    // Low-mid frequency mapped to uAudio.y
    float x_audio = uAudio.y; 
    
    a = max(p.x, max(p.y, p.z))-2.414*(1.+x_audio);
    p = abs(p-round(p));
    b = max(p.x, max(p.y, p.z))-.3*(1.+x_audio);
    return max(a, b);
}

vec3 background(vec2 uv_norm)
{
    vec2 U = uv_norm * R;
    
    float t = uTime/60.,
          s = 1., d = 0., i = d, r, r2;
    
    // High-bass and deep-bass frequencies
    float x = uAudio.y; // Was 0.2
    float y = uAudio.x; // Was 0.05
    
    vec2 m = vec2((R.y+sin(x))/R.y,1.);
       
    vec3 o = vec3(0, -6, -40./(m.y+1.)),
         u = normalize(vec3(U-.5*R, R.y*sin(3.141592*t*pow(t,.55)))),
         c = vec3(.1), p;
    
    mat2 h = A(m.x),
         v = A(m.y/30.),
         ch = A(cos(uTime/2.)*.1),
         cv = A(sin(-uTime/2.)*.5);
    
    for (; i++<90.;)
    {
        p = o+u*d;
        p.yz *= v;
        p.xz *= h;
        r = length(p.xz);
        r2 = length(p);
        s = cube(p, ch, cv);
        s = min(s, max(length(p)-5.5, 5.4-length(p.xy)));
        p.xz = vec2( atan(p.x, p.z)/6.2832, r );
        p.x -= round(p.z)*t*sign(p.y);
        p.xz = abs(p.xz-round(p.xz));
        p.y = abs(p.y)-15.+3.*x;
        s = min(s, max(abs(p.y) - min(12.*y, 20./r), max(p.x, p.z) - min(1., .5/r)) );
        
        if (s < .001 || d > 1e3) break;
        d += s*.5;
        c += min(vec3(s), .003/s * (H(s + 5./r2 - .1)*.6+.1));
    }
    
    return c*c;
}
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
// @NoMusicInfo
#define bufferless

// Warning: Raymarching reflections can be extremely heavy for a 4K desktop background.
// Bounces reduced from 4096 to prevent GPU hangs. Increase if you have an RTX 4090.
const int bounces = 18184;

const float phi = (1.+sqrt(5.))*.5;
float dodecahedron(vec3 p){
    const vec3 n = normalize(vec3(phi,1,0));

    p = abs(p);
	float a = dot(p,n.xyz);
    float b = dot(p,n.zxy);
    float c = dot(p,n.yzx);
    return max(max(a,b),c)-phi*n.y;
} // Stolen *ahem* Permanently Borrowed™ from https://www.shadertoy.com/view/XtKfWW

#define n_(x) m=min(m, x)
float df(vec3 p){
    float m = 1e9;
    n_(dodecahedron(p));
    return m;
}

vec3 norm(vec3 p, float e){
    return normalize(vec3(
        df(p + vec3(e, 0, 0)) - df(p - vec3(e, 0, 0)),
        df(p + vec3(0, e, 0)) - df(p - vec3(0, e, 0)),
        df(p + vec3(0, 0, e)) - df(p - vec3(0, 0, e))
    ));
}

vec3 background(vec2 uv_norm){
    vec2 r = uResolution.xy;
    vec2 U = uv_norm * r;
    vec2 cuv = (2.*U-r)/r.y;

    // Bufferless mouse controls + auto rotation
    vec2 muv = (uMouse * 2.0 - 1.0) * vec2(2.0, 1.0) + vec2(uTime * 0.2, 0.3);

    vec3 o = vec3(0);
    vec3 dir = vec3(sin(muv.x)*cos(muv.y), cos(muv.x)*cos(muv.y), sin(muv.y));
    o -= dir*3.;

    vec3 right = normalize(cross(dir, vec3(0, 0, 1)));
    vec3 up = cross(right, dir);

    vec2 camUV = cuv * .5;
    vec3 dirV = vec3(sin(camUV.x)*cos(camUV.y), cos(camUV.x)*cos(camUV.y), sin(camUV.y));
    dirV = normalize(dir * dirV.y + right * dirV.x + up * dirV.z);

    vec3 p = o;
    float d, t = 0.;
    for (int i = 128; i-->0;){
        p = o + dirV * t;
        d = df(p);
        t += d*1.1;
        if (d < 0.) i--;
    }

    vec3 normal = norm(p, 1e-4);
    float edge = 1.-dot(norm(p, 32./r.y), normal);

    if (length(p) > 2.){ // Skybox
        vec3 col = vec3(0);
        if (dirV.z < 0.){
            t = (o.z + 1.) / -dirV.z;
            p = o + dirV * t;
            col = vec3(1.) / (1. + p.x*p.x*2. + p.y*p.y);
        }
        return col;
    }

    // Surface reflection
    float fresnel = pow(1.+dot(normal, dirV), 5.);

    if (edge > 1e-4){ // Outer frame styling
        return vec3(0);
    }

    // Recursive reflection stuff!
    vec4 O = vec4(1,0,0,1);

    float totalT = t;
    t = 0.;
    float attenuation = 1.;
    p += dirV * .1;

    // Light bar thickness. Cannot be zero.
    normal = norm(p, 1e-4);
    edge = 1.-dot(norm(p, .05), normal);

    if (edge > 1e-4){ // First visible light
        return vec3(1);
    }

    for (int b = 0; b<bounces; b++){
        for (int i = 0; i < int(max(exp(-float(b))*64., 12.)); i++){
            d = df(p);
            p -= dirV * d;
            totalT -= d;
        }

        normal = norm(p, 1e-4);
        edge = 1.-dot(norm(p, .05), normal);

        attenuation *= .9;

        if (edge > 1e-4){
            O = vec4(attenuation);
            break;
        }

        dirV = reflect(dirV, normal);
        p += dirV;
    }

    return mix(O.rgb, vec3(0), fresnel);
}
//CBS
//Parallax scrolling fractal galaxy.
// @NoMusicInfo
//Inspired by JoshP's Simplicity shader: https://www.shadertoy.com/view/lslGWr

// http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/
float field(in vec3 p,float s) {
	float strength = 7. + .03 * log(1.e-6 + fract(sin(uTime) * 4373.11));
	float accum = s/4.;
	float prev = 0.;
	float tw = 0.;
	for (int i = 0; i < 26; ++i) {
		float mag = dot(p, p);
		p = abs(p) / mag + vec3(-.5, -.4, -1.5);
		float w = exp(-float(i) / 7.);
		accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
		tw += w;
		prev = mag;
	}
	return max(0., 5. * accum / tw - .7);
}

// Less iterations for second layer
float field2(in vec3 p, float s) {
	float strength = 7. + .03 * log(1.e-6 + fract(sin(uTime) * 4373.11));
	float accum = s/4.;
	float prev = 0.;
	float tw = 0.;
	for (int i = 0; i < 18; ++i) {
		float mag = dot(p, p);
		p = abs(p) / mag + vec3(-.5, -.4, -1.5);
		float w = exp(-float(i) / 7.);
		accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
		tw += w;
		prev = mag;
	}
	return max(0., 5. * accum / tw - .7);
}

vec3 nrand3( vec2 co )
{
	vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
	vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
	vec3 c = mix(a, b, 0.5);
	return c;
}


vec3 background(vec2 uv_norm) {
    // Convert 0..1 uv to -1..1
    vec2 uv = 2.0 * uv_norm - 1.0;
	vec2 uvs = uv * uResolution.xy / max(uResolution.x, uResolution.y);
	vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
	p += .2 * vec3(sin(uTime / 16.), sin(uTime / 12.),  sin(uTime / 128.));
	
	float freqs[4];
	//Sound from uAudio uniform (x=bass, y=low-mid, z=mid, w=high)
	freqs[0] = uAudio.x;
	freqs[1] = uAudio.y;
	freqs[2] = uAudio.z;
	freqs[3] = uAudio.w;

	float t = field(p, freqs[2]);
	float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
	
    //Second Layer
	vec3 p2 = vec3(uvs / (4.+sin(uTime*0.11)*0.2+0.2+sin(uTime*0.15)*0.3+0.4), 1.5) + vec3(2., -1.3, -1.);
	p2 += 0.25 * vec3(sin(uTime / 16.), sin(uTime / 12.),  sin(uTime / 128.));
	float t2 = field2(p2, freqs[3]);
	vec4 c2 = mix(.4, 1., v) * vec4(1.3 * t2 * t2 * t2, 1.8 * t2 * t2, t2 * freqs[0], t2);
	
	//Let's add some stars
	vec2 seed = p.xy * 2.0;	
	seed = floor(seed * uResolution.x);
	vec3 rnd = nrand3( seed );
	vec4 starcolor = vec4(pow(rnd.y,40.0));
	
	//Second Layer
	vec2 seed2 = p2.xy * 2.0;
	seed2 = floor(seed2 * uResolution.x);
	vec3 rnd2 = nrand3( seed2 );
	starcolor += vec4(pow(rnd2.y,40.0));
	
	vec4 finalCol = mix(freqs[3]-.3, 1., v) * vec4(1.5*freqs[2] * t * t* t , 1.2*freqs[1] * t * t, freqs[3]*t, 1.0) + c2 + starcolor;
    
    // Slight boost for dark desktop backgrounds
    return finalCol.rgb * 1.5;
}// @NoMusicInfo
#define S(a, b, t) smoothstep(a, b, t)

mat2 Rot(float a){
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float TaperBox(vec2 p, float wb, float wt, float yb, float yt, float blur){
    float m = S(-blur, blur, p.y - yb);
    m *= S(blur, -blur, p.y - yt);

    p.x = abs(p.x);

    float w = mix(wb, wt, (p.y - yb) / (yt - yb));
    m *= S(blur, -blur, p.x - w);
    return m;
}

vec4 Tree(vec2 uv, vec3 col, float blur, float stage){
    float m = TaperBox(uv, 0.03, 0.03, 0.0, 1.0/(stage+1.0), blur);
    float shadow = 0.0;

    for(float i = 1.0; i < (stage+1.0); i++){
        m += TaperBox(vec2(uv.x, uv.y-1.0/(stage+1.0)), (stage-i)*0.05+0.1, (stage-i)*0.05, 1.0/(stage+1.0)*(i-1.0), 1.0/(stage+1.0)*i, blur);
        vec2 _uv = uv;
        if((int(i)%2)==0){
            _uv -= vec2(0.25, 0);
        }
        else{
            _uv += vec2(0.25, 0);
        }
        shadow += TaperBox(_uv, 0.1, 0.5, 1.0/(stage+1.0)*i-0.05, 1.0/(stage+1.0)*i, blur);
    }

    col -= shadow * 0.8;

    return vec4(col, m);
}

float GetHeight(float x){
    return sin(x*0.494)+sin(x)*0.3;
}

vec4 Layer(vec2 uv, float blur){
    vec4 col = vec4(0);

    float id = floor(uv.x);
    float n = fract(sin(id*532.45)*5541.21)*2.0-1.0;
    float x = n*0.3;
    float y = GetHeight(uv.x);
    float ground = S(blur, -blur, uv.y+y);
    col += ground;

    y = GetHeight(id+0.5+x);
    uv.x = fract(uv.x)-0.5;

    vec4 tree = Tree((uv-vec2(x, -y-0.01))*vec2(1.0, 1.0+n*0.2), vec3(1.0), blur, float(int(3.5+sin(x)*3.0)));
    col = mix(col, tree, tree.a);
    col.a = max(ground, col.a);
    return col;
}

float Hash21(vec2 p){
    p = fract(p*vec2(534.02, 964.547));
    p += dot(p, p+531.154);
    return fract(p.x*p.y);
}

float Stars(vec2 uv){
    float v = TaperBox(uv * Rot(0.5) - vec2(-0.3, 0.1), 0.1, 0.1, -2.0, 0.5, 0.3);
    return pow(Hash21(uv), 300.0/pow(v+1.0, 4.0));
}

vec3 background(vec2 uv_norm)
{
    vec2 fragCoord = uv_norm * uResolution;
    vec2 uv = (fragCoord - 0.5 * uResolution.xy)/uResolution.y;

    vec2 M = uMouse * 2.0 - 1.0;

    float t = uTime*0.5;

    float blur;

    vec4 layer;

    vec4 col = vec4(0.0);
    col += Stars(uv);

    float moon = S(0.01, -0.01, length(uv-vec2(0.4, 0.2))-0.15);
    col *= 1.0-moon;
    moon *= S(-0.01, 0.1, length(uv-vec2(0.48, 0.24))-0.15);
    col += moon;

    for(float i = 0.0; i<1.0; i+=1.0/10.){
        blur = mix(0.04, 0.001, i);
        float scale = mix(30.0, 1.0, i);
        layer = Layer(uv*scale+vec2(t+sin(i)*1354.2, i*2.0)-M, blur);
        layer.rgb *= (1.0-i)*vec3(0.9, 0.9, 1.0);

        col = mix(col, layer, layer.a);
    }
    layer = Layer(uv+vec2(t, 1.5)-M, 0.07);

    col = mix(col, layer*0.1, layer.a);

    return col.rgb;
}
// nebula — Deep space swirling gas clouds + stars

float _nnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = fract(sin(dot(i, vec2(127.1,311.7)))*43758.5453);
    float b = fract(sin(dot(i+vec2(1,0), vec2(127.1,311.7)))*43758.5453);
    float c = fract(sin(dot(i+vec2(0,1), vec2(127.1,311.7)))*43758.5453);
    float d = fract(sin(dot(i+vec2(1,1), vec2(127.1,311.7)))*43758.5453);
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float _nfbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 6; i++) { v += a * _nnoise(p); p = rot * p * 2.0 + 100.0; a *= 0.5; }
    return v;
}

vec3 background(vec2 uv) {
    float t = uTime * 0.08;
    vec2 q = vec2(_nfbm(uv + t*0.1), _nfbm(uv + vec2(1.7, 9.2)));
    vec2 r = vec2(_nfbm(uv + 4.0*q + vec2(1.7,9.2) + t*0.15),
                  _nfbm(uv + 4.0*q + vec2(8.3,2.8) + t*0.126));
    float f = _nfbm(uv + 3.0*r);

    vec3 col = mix(uColor1*0.3, uColor2, clamp(f*f*2.0, 0.0, 1.0));
    col = mix(col, uColor3, clamp(length(q)*0.5, 0.0, 1.0));
    col = mix(col, uColor1*0.8, clamp(length(r.x)*0.6, 0.0, 1.0));
    col *= (f*f*f + 0.6*f*f + 0.5*f) * 0.9;

    // Stars
    col += vec3(pow(fract(sin(dot(uv*500.0, vec2(12.9898,78.233)))*43758.5453), 20.0) * 0.4);
    col *= clamp(1.0 - 0.35*length((uv-0.5)*1.6), 0.0, 1.0);
    return col;
}
// Original made by nimitz 2017 (twitter: @stormoid)
//   See here https://www.shadertoy.com/view/XtGGRt
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options
// This is a modified purple version
// @NoMusicInfo

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}
mat2 m2 = mat2(0.95534, 0.29552, -0.29552, 0.95534); // 17.4 degrees
float tri(in float x){return clamp(abs(fract(x)-.5),0.01,0.49);}
vec2 tri2(in vec2 p){return vec2(tri(p.x)+tri(p.y),tri(p.y+tri(p.x)));}

float triNoise2d(in vec2 p, float spd)
{
    float z=1.8;
    float z2=1.1;
	float rz = 0.;
    p *= mm2(p.x*0.06);
    vec2 bp = p;
	for (float i=0.; i<5.; i++ )
	{
        vec2 dg = tri2(bp*1.85)*.75;
        dg *= mm2(uTime*spd);
        p -= dg/z2;

        bp *= 1.3;
        z2 *= .45;
        z *= .42;
		p *= 1.21 + (rz-1.0)*.02;

        rz += tri(p.x+tri(p.y))*z;
        p*= -m2;
	}
    return clamp(1./pow(rz*29., 1.3),0.,.55);
}

float hash21(in vec2 n){ return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453); }

vec4 aurora(vec3 ro, vec3 rd, vec2 fragCoord)
{
    vec4 col = vec4(0);
    vec4 avgCol = vec4(0);

    for(float i=0.;i<50.;i++)
    {
        float of = 0.006*hash21(fragCoord)*smoothstep(0.,15., i);
        float pt = ((.8+pow(i,1.4)*.002)-ro.y)/(rd.y*2.+0.4);
        pt -= of;
    	vec3 bpos = ro + pt*rd;
        vec2 p = bpos.zx;
        float rzt = triNoise2d(p, 0.06);
        vec4 col2 = vec4(0,0,0, rzt);
        col2.rgb = (sin(2.-vec3(-10,-.7, 1.3)+i*0.03)*0.5+0.5)*rzt;
        avgCol =  mix(avgCol, col2, .5);
        col += avgCol*exp2(-i*0.065 - 2.5)*smoothstep(0.7,5., i);

    }

    col *= (clamp(rd.y*17.+.4,0.,1.));
    return col*1.8;
}

//-------------------Background and Stars--------------------

vec3 nmzHash33(vec3 q)
{
    uvec3 p = uvec3(ivec3(q));
    p = p*uvec3(374761393U, 1103515245U, 668265263U) + p.zxy + p.yzx;
    p = p.yzx*(p.zxy^(p >> 3U));
    return vec3(p^(p >> 16U))*(1.0/vec3(0xffffffffU));
}

vec3 stars(in vec3 p)
{
    vec3 c = vec3(0.);
    float res = pow(uResolution.x / 400., 0.5) * 400.;

	for (float i=0.;i<4.;i++)
    {
        vec3 q = fract(p*(.15*res))-0.5;
        vec3 id = floor(p*(.15*res));
        vec2 rn = nmzHash33(id).xy;
        float c2 = 1.-smoothstep(0.,0.7, length(q));
        c2 *= step(rn.x,.0005+i*i*0.001);
        c += c2*(mix(vec3(1.0,0.49,0.1),vec3(0.75,0.9,1.),rn.y)*0.1+0.9);
        p *= 1.3;
    }
    return c*c*.8;
}

vec3 bg(in vec3 rd)
{
    float sd = dot(normalize(vec3(-0.3, -0.6, 0.9)), rd)*0.5+0.5;
    sd = pow(sd, 5.);
    vec3 col = mix(vec3(0.1,0.1,0.2), vec3(0.8,0.035,0.15), sd);
    return col*0.89;
}
//-----------------------------------------------------------

vec3 background(vec2 uv_norm)
{
    vec2 fragCoord = uv_norm * uResolution;
    float aspectRatio = uResolution.x/uResolution.y;
	vec2 q = fragCoord.xy / uResolution.xy;
	q.y*= aspectRatio;
    vec2 p = q - 0.5;
    vec3 ro = vec3(0,0,-6.7);
    vec3 rd = vec3(p,1.3);
    vec2 mo = q+1.4;
    rd.xz *= mm2(mo.x + sin(uTime*0.05)*0.2);

    float fade = smoothstep(0.,0.09,abs(rd.y))*0.1+0.9;

    vec3 col;
    if (rd.y > -0.0) {

        vec4 aur = smoothstep(0.,1.5,aurora(ro,rd,fragCoord))*fade;
        col = bg(rd)*fade + (1. - fade)*vec3(.4);
        rd = normalize(rd);
        col += stars(rd);
        col = col*(1.-aur.a) + aur.rgb;
    }
    else //Reflections
    {
        rd.y = abs(rd.y);
        col = bg(rd)*fade*0.6;
        rd = normalize(rd);
        vec4 aur = smoothstep(0.0,2.5,aurora(ro,rd,fragCoord));
        col += stars(rd)*0.1;
        col = col*(1.-aur.a) + aur.rgb;
        vec3 pos = ro + ((0.5-ro.y)/rd.y)*rd;
        float nz2 = triNoise2d(pos.xz*vec2(.5,.7), 0.);
        col += mix(vec3(0.2,0.25,0.5)*0.08,vec3(0.3,0.3,0.5)*0.7, nz2*0.4);
    }

	return col;
}
// @NoMusicInfo
const uint antiA = 2u; // Lowered for live wallpaper perf

const mat4x3 bgPal = mat4x3(0.5,0.5,0.5,0.5,0.5,0.5,1.0,1.0,1.0,0.0,0.33,0.67);
const mat4x3 sfPal = mat4x3(0.5,0.5,0.5,0.5,0.5,0.5,1.0,1.0,1.0,0.0,0.10,0.20);

const float err = 1e10;
mat3  fA, cA;
vec3  fB, cB;
float fC, cC;

vec3 bgCol;
vec3 sfCol;


vec3 hash3(uint n)
{
    //https://www.shadertoy.com/view/llGSzw
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    uvec3 k = n * uvec3(n,n*16807U,n*48271U);
    return vec3( k & uvec3(0x7fffffffU))/float(0x7fffffff);
}

mat2x3 boxM(uint n) {
    vec3 U = hash3(n), V = hash3(n + 2568758767u);
    U = sqrt(-2.*log(U));
    V *= 2.*3.14159265;
    return mat2x3(U*cos(V), U*sin(V));
}

vec3 pal(float t, mat4x3 a) {
    //https://www.shadertoy.com/view/ll2GD3
    return a[0] + a[1]*cos(2.*3.14159265*(a[2]*t+a[3]));
}

void set(uint n) {
    n *= 100u;
    for (uint i = 0u; i < 3u; ++i) {
        mat2x3 tmp = boxM(n++);
        fA[i] = tmp[0];
        cA[i] = tmp[1];
        fA[i][i] /= sqrt(2.);
        cA[i][i] /= sqrt(2.);
    }

    fB = 2.*(hash3(n++) - 1.);
    cB = 2.*(hash3(n++) - 1.);
    fA *= .3;

    cB *= .3;
    cA *= .2;
    cC = 0.;
    fC = 0.;

    bgCol = pow(pal(hash3(n++).x, bgPal), vec3(.35));
    sfCol = pow(pal(hash3(n++).x, sfPal), vec3(1.));

}

float eval(vec3 x, mat3 A, vec3 B, float C) {
    return dot(x, A*x) + dot(B, x) + C;
}

vec3 grad(vec3 x, mat3 A, vec3 B) {
    return B + A*x + x*A;
}

vec3 param(vec3 x, vec3 d, mat3 A, vec3 B, float C) {
    return vec3(eval(x,A,B,C), dot(grad(x,A,B), d), dot(d, A*d));
}

float func(vec3 x) {
    return eval(x, fA, fB, fC);
}

float cond(vec3 x) {
    return eval(x, cA, cB, cC);
}

vec3 funcGrad(vec3 x) {
    return grad(x, fA, fB);
}

vec3 condGrad(vec3 x) {
   return grad(x, cA, cB);
}

vec2 solve(vec3 p) {
    float a = p.z, b = p.y, c = p.x;
    float disc = b*b - 4.*a*c;

    if (disc < 0.) return vec2(err);

    vec2 tmp;

    if (false && abs(a) < 1e-6 )
        tmp = vec2(-c/b, err);
    else if (false && abs(c) < 1e-6)
        tmp = vec2(0., -a/b);
    else {
        tmp.x = (-b - sign(b)*sqrt(disc))/2./a;
        tmp.y = c/a/tmp.x;
    }
    if (tmp.y < tmp.x) tmp = tmp.yx;
    if (tmp.x < 0.)    tmp = vec2(tmp.y, err);
    if (tmp.x < 0.)    tmp = vec2(err);
    return tmp;
}

vec3 background(vec2 uv_norm)
{
    const float duration = 3., speed = 1.;
    set(uint(uTime/duration) + 0u);
    fC -= uTime * speed;

    const float delta = 1.5, focal = 1.3;
    
    vec2 fragCoord = uv_norm * uResolution;
    vec2 uv = (2.*fragCoord - uResolution.xy) / uResolution.y;
    float pixel = 1./uResolution.y;

    vec3 ro = vec3(0., 0., 4.);

    vec3 colTot = vec3(0.);

    for (uint nAA = 0u; nAA < antiA*antiA; ++nAA) {
        const float aaStep = 1./float(antiA);
        vec2 uv1 = vec2(float(nAA/antiA), float(nAA%antiA))*aaStep + .5*aaStep;
        uv1 = (uv1 - .5) * 2.*pixel;
        vec3 rd = normalize(vec3(uv+uv1, -focal));

        vec3 fPar = param(ro, rd, fA, fB, fC);
        vec3 cPar = param(ro, rd, cA, cB, cC);
        vec2 cIsect = solve(cPar);

        vec3 col;

        if (cIsect.x < err) {
            float hit = func(ro+rd*cIsect.x);
            vec2 pot = delta * (floor(hit / delta) + vec2(0., 1.));
            
            vec2 solve1 = solve(fPar-vec3(pot.x,0.,0.));
            vec2 solve2 = solve(fPar-vec3(pot.y,0.,0.));
            vec4 fIsect = vec4(solve1.x, solve1.y, solve2.x, solve2.y);

            float t = err;
            for (int i = 0; i < 4; ++i) {
                if (fIsect[i] < min(t, cIsect.y) && fIsect[i] > cIsect.x)
                    t = fIsect[i];
            }

            vec3 pos = ro + t*rd;
            vec3 fGrad = funcGrad(pos)/delta;
            vec3 cGrad = condGrad(pos)/abs(cond(pos));

            float occ = length(fGrad) / length(cGrad);
            occ = sqrt(occ);
            occ = 1. - occ/sqrt(1. + occ*occ);
            occ = sqrt(occ);

            col = t < err ? sfCol * occ : bgCol;
            col = mix(col, sfCol, smoothstep(-2.*pixel, -pixel, -1./cIsect.x));
        }
        else
            col = bgCol;
        colTot += col;
    }
    colTot /= float(antiA*antiA);

    colTot = pow(colTot, vec3(1./2.2));
    return colTot;
}
// smoke — Wispy curling smoke tendrils

float _snoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = fract(sin(dot(i, vec2(127.1,311.7)))*43758.5453);
    float b = fract(sin(dot(i+vec2(1,0), vec2(127.1,311.7)))*43758.5453);
    float c = fract(sin(dot(i+vec2(0,1), vec2(127.1,311.7)))*43758.5453);
    float d = fract(sin(dot(i+vec2(1,1), vec2(127.1,311.7)))*43758.5453);
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0); // quintic smoothstep
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float _sfbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(0.866, 0.5, -0.5, 0.866);
    for (int i = 0; i < 6; i++) { v += a * _snoise(p); p = rot * p * 2.1 + 50.0; a *= 0.48; }
    return v;
}

vec3 background(vec2 uv) {
    float t = uTime * 0.06;

    // Deep dark base
    vec3 col = mix(uColor1, uColor2, 0.5) * 0.02;

    // Multiple smoke layers rising
    for (float layer = 0.0; layer < 3.0; layer++) {
        float speed = 0.1 + layer * 0.05;
        float scale = 2.0 + layer * 1.5;

        vec2 smokeUV = uv * scale;
        smokeUV.y -= t * speed * 2.0;  // Rising
        smokeUV.x += sin(uv.y * 3.0 + t + layer) * 0.3;  // Swirl

        float smoke = _sfbm(smokeUV);
        smoke = smoothstep(0.3, 0.7, smoke);

        // Color varies by layer
        vec3 smokeCol;
        if (layer < 1.0) smokeCol = uColor1 * 0.4;
        else if (layer < 2.0) smokeCol = uColor2 * 0.3;
        else smokeCol = uColor3 * 0.25;

        // Density fades with height
        float density = (1.0 - uv.y * 0.5) * 0.6;
        col += smokeCol * smoke * density / (1.0 + layer * 0.3);
    }

    col *= clamp(1.0 - 0.3 * length((uv-0.5)*1.6), 0.0, 1.0);
    return col;
}
// waves — Smooth flowing ocean waves

float _wnoise(vec2 p) {
    return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453);
}
float _wsnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = _wnoise(i), b = _wnoise(i+vec2(1,0));
    float c = _wnoise(i+vec2(0,1)), d = _wnoise(i+vec2(1,1));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float _wfbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) { v += a * _wsnoise(p); p *= 2.0; a *= 0.5; }
    return v;
}

vec3 background(vec2 uv) {
    float t = uTime * 0.1;
    float w1 = sin(uv.x*4.0 + t*1.5 + _wfbm(uv*3.0+t*0.3)*3.0)*0.5+0.5;
    float w2 = sin(uv.x*6.0 - t*0.8 + _wfbm(uv*2.0-t*0.2)*4.0)*0.5+0.5;
    float w3 = sin(uv.x*2.5 + t*0.6 + _wfbm(uv*4.0+t*0.15)*2.0)*0.5+0.5;

    float b1 = smoothstep(0.0, 0.08, abs(uv.y - 0.3 - w1*0.15));
    float b2 = smoothstep(0.0, 0.06, abs(uv.y - 0.5 - w2*0.12));
    float b3 = smoothstep(0.0, 0.1, abs(uv.y - 0.7 - w3*0.1));

    vec3 col = mix(uColor1, uColor2, 0.3) * 0.08;
    col = mix(uColor1*0.7, col, b1);
    col = mix(uColor2*0.6, col, b2);
    col = mix(uColor3*0.5, col, b3);

    float foam = pow(1.0-b1, 3.0)*0.15 + pow(1.0-b2, 3.0)*0.1;
    col += vec3(foam);
    col *= clamp(1.0 - 0.3*length((uv-0.5)*1.6), 0.0, 1.0);
    return col;
}
#!/usr/bin/env python3
"""
LiveWall — GPU-animated wallpaper with album cover overlay for Hyprland.

Uses GTK3 + gtk-layer-shell for Wayland wallpaper layer,
GtkGLArea for GLSL shader rendering, and file-based IPC
for receiving cover art updates from medianotify-daemon.

Usage:
    livewall.py [--shader aurora.glsl] [--cover /path/to/image]
    livewall.py --kill
"""

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_version("Gdk", "3.0")
gi.require_version("PangoCairo", "1.0")

from gi.repository import Gtk, GtkLayerShell, GLib, Gdk, Gio, Pango, PangoCairo
from OpenGL.GL import *
from PIL import Image
import argparse
import cairo
import numpy as np
import os
import signal
import sys
import struct
import time
import ctypes
from audio import AudioMonitor
from camera import CameraMonitor

# ─── Constants ──────────────────────────────────────────

IPC_DIR        = "/tmp/livewall"
COVER_FILE     = os.path.join(IPC_DIR, "cover.jpg")
COLORS_FILE    = os.path.join(IPC_DIR, "colors")
META_FILE      = os.path.join(IPC_DIR, "meta")
SHADER_FILE    = os.path.join(IPC_DIR, "shader")
TRANSITION_FILE = os.path.join(IPC_DIR, "transition")
RESTORE_FILE   = os.path.join(IPC_DIR, "restore")
PID_FILE       = os.path.join(IPC_DIR, "pid")

TRANSITION_TYPES = ["simple", "center"]

COVER_FRACTION = 0.60      # Cover height as fraction of screen height (~650px on 1080p)
COVER_RADIUS   = 0.012     # Corner radius in normalized coords
CROSSFADE_MS   = 1200      # Crossfade duration in ms
COLOR_LERP_MS  = 2000      # Color transition duration
SCREEN_TRANS_MS = 800      # Full-screen transition duration
FPS            = 60
FRAME_MS       = 1000 // FPS

DEFAULT_COLORS = [
    (0.2, 0.5, 0.8),   # Calm blue
    (0.1, 0.3, 0.6),   # Deep blue
    (0.4, 0.2, 0.7),   # Purple accent
]


# ─── Helpers ────────────────────────────────────────────

def hex_to_rgb(h):
    """Convert '#RRGGBB' or 'RRGGBB' to (r, g, b) floats."""
    h = h.strip().lstrip("#")
    if len(h) != 6:
        return None
    try:
        return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    except ValueError:
        return None

def lerp3(a, b, t):
    """Linearly interpolate between two 3-tuples."""
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


# ─── Texture Loading ────────────────────────────────────

def load_texture_from_file(path):
    """Load an image file into an OpenGL texture. Returns tex ID or None."""
    try:
        img = Image.open(path).convert("RGBA")
        data = img.tobytes()
        w, h = img.size

        tex = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, tex)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, data)
        return tex
    except Exception as e:
        print(f"[livewall] Failed to load texture {path}: {e}", file=sys.stderr)
        return None

def create_placeholder_texture(r=0.1, g=0.1, b=0.1, a=0.0):
    """Create a 1x1 transparent placeholder texture."""
    tex = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, tex)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    data = struct.pack("BBBB", int(r*255), int(g*255), int(b*255), int(a*255))
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, data)
    return tex


# ─── Shader Compilation ─────────────────────────────────

VERTEX_SHADER = """
#version 330 core
in vec2 position;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
"""

def compile_shader(source, shader_type):
    """Compile a GLSL shader, raise on error."""
    shader = glCreateShader(shader_type)
    glShaderSource(shader, source)
    glCompileShader(shader)
    if not glGetShaderiv(shader, GL_COMPILE_STATUS):
        log = glGetShaderInfoLog(shader).decode()
        raise RuntimeError(f"Shader compile error:\n{log}")
    return shader

def build_program(frag_path):
    """Build shader program from background-only shader + injected cover code."""
    with open(frag_path, "r") as f:
        frag_source = f.read()

    # If shader already has a main() (full/legacy shader), use as-is
    if "void main()" in frag_source:
        if not frag_source.startswith("#version"):
            frag_source = "#version 330 core\nout vec4 fragColor;\n" + frag_source
    else:
        # Background-only shader: inject cover compositing code
        frag_source = _build_full_shader(frag_source)

    vert = compile_shader(VERTEX_SHADER, GL_VERTEX_SHADER)
    frag = compile_shader(frag_source, GL_FRAGMENT_SHADER)

    prog = glCreateProgram()
    glAttachShader(prog, vert)
    glAttachShader(prog, frag)
    glLinkProgram(prog)

    if not glGetProgramiv(prog, GL_LINK_STATUS):
        log = glGetProgramInfoLog(prog).decode()
        raise RuntimeError(f"Shader link error:\n{log}")

    glDeleteShader(vert)
    glDeleteShader(frag)
    return prog


# Shared cover compositing code injected after the background function
COVER_TEMPLATE = """
// ─── Shared Cover Compositing (auto-injected) ──────────

uniform sampler2D uCoverTex;
uniform sampler2D uCoverNextTex;
uniform sampler2D uPrevFrame;
uniform float     uBlend;
uniform float     uCoverAlpha;
uniform vec2      uCoverCenter;
uniform vec2      uCoverSize;
uniform float     uCoverRadius;
uniform float     uScreenBlend;      // 0=old frame, 1=new state
uniform int       uScreenTransition; // 0..3

float roundedBoxSDF(vec2 center, vec2 halfSize, float radius) {
    vec2 d = abs(center) - halfSize + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

vec4 renderCover(vec2 uv) {
    vec2 coverUV = (uv - uCoverCenter) / uCoverSize + 0.5;
    if (coverUV.x < 0.0 || coverUV.x > 1.0 || coverUV.y < 0.0 || coverUV.y > 1.0)
        return vec4(0.0);

    vec2 pixelPos = uv - uCoverCenter;
    float dist = roundedBoxSDF(pixelPos, uCoverSize * 0.5, uCoverRadius);
    if (dist > 0.002) return vec4(0.0);
    float aa = 1.0 - smoothstep(-0.003, 0.002, dist);

    vec2 tc = vec2(coverUV.x, 1.0 - coverUV.y);
    vec4 cover = mix(texture(uCoverTex, tc), texture(uCoverNextTex, tc), uBlend);
    cover.a *= aa * uCoverAlpha;
    return cover;
}

float coverShadow(vec2 uv) {
    vec2 sp = uv - uCoverCenter - vec2(0.0, -0.012);
    float d = roundedBoxSDF(sp, uCoverSize * 0.52, uCoverRadius * 1.2);
    return 0.5 * smoothstep(0.0, 0.06, -d);
}

// ─── Transition Helpers ────────────────────────────────

// Cubic ease-in-out
float easeInOut(float t) {
    return t < 0.5 ? 4.0*t*t*t : 1.0 - pow(-2.0*t + 2.0, 3.0) / 2.0;
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;

    // Render current state
    vec3 bg = background(uv);

    if (uCoverAlpha > 0.001) {
        bg *= (1.0 - coverShadow(uv) * uCoverAlpha);
        vec4 cover = renderCover(uv);
        bg = mix(bg, cover.rgb, cover.a);
    }

    // Full-screen transition
    if (uScreenBlend < 0.999) {
        float t = easeInOut(uScreenBlend);
        vec3 prev = texture(uPrevFrame, uv).rgb;

        float mask = t; // simple crossfade (default)

        if (uScreenTransition == 1) {
            // ── center ── circle growing from center
            float dist = length((uv - 0.5) * vec2(uResolution.x / uResolution.y, 1.0));
            float radius = t * 1.0;
            float coverMask = 0.0;
            if (uCoverAlpha > 0.001) {
                float cd = roundedBoxSDF(uv - uCoverCenter, uCoverSize * 0.55, uCoverRadius);
                coverMask = smoothstep(0.01, -0.01, cd);
            }
            float geo = 1.0 - smoothstep(radius - 0.06, radius, dist);
            mask = mix(geo, t, coverMask);
        }

        bg = mix(prev, bg, mask);
    }

    fragColor = vec4(bg, 1.0);
}
"""

def _build_full_shader(bg_source):
    """Combine a background-only shader with shared cover code."""
    header = "#version 330 core\nout vec4 fragColor;\n\n"
    header += "uniform vec2  uResolution;\n"
    header += "uniform float uTime;\n"
    header += "uniform vec2  uMouse;\n"
    header += "uniform vec4  uAudio;\n"
    header += "uniform sampler2D uCamera;\n"
    header += "uniform samplerCube uCubeMap;\n"
    header += "uniform vec3  uColor1, uColor2, uColor3;\n\n"
    return header + bg_source + "\n" + COVER_TEMPLATE


# ─── LiveWall Application ───────────────────────────────

class LiveWall:
    def __init__(self, shader_path, initial_cover=None):
        self.shader_path = shader_path
        self.initial_cover = initial_cover
        self.start_time = time.monotonic()

        # State
        self.program = None
        self.vao = None
        self.vbo = None
        self.width = 1920
        self.height = 1080

        # Cover textures
        self.tex_current = None
        self.tex_next = None
        self.cover_alpha = 0.0
        self.cover_alpha_target = 0.0

        # Crossfade state
        self.blend = 0.0
        self.blend_start = 0.0
        self.blending = False

        # Color state
        self.colors_current = list(DEFAULT_COLORS)
        self.colors_target = list(DEFAULT_COLORS)
        self.color_lerp_start = 0.0
        self.color_lerping = False

        # File monitor state
        self.cover_mtime = 0
        self.colors_mtime = 0
        self.meta_mtime = 0
        self.shader_mtime = 0
        self.transition_mtime = 0

        # Song metadata for text overlay
        self.song_title = ""
        self.song_artist = ""
        self.text_alpha = 0.0
        self.text_alpha_target = 0.0
        self.show_music_info = True

        # Full-screen transition (awww-style)
        # 0=fade, 1=grow, 2=wipe_left, 3=wipe_up
        self.transition_type = 0
        self.snapshot_tex = None
        self.screen_blending = False
        self.screen_blend = 1.0  # 1.0 = fully new (no transition)
        self.screen_blend_start = 0.0
        self.snapshot_ready = False

        # Mouse tracking
        self.mouse_x = 0.5
        self.mouse_y = 0.5

        # Pending shader swap (deferred to render for GL context)
        self.pending_shader_path = None

        # Background threads (lazy loading based on shader uniform usage)
        self.audio_monitor = None
        self.camera_monitor = None
        
        # Camera GL state
        self.camera_tex = None
        
        # Cubemap GL state
        self.cubemap_tex = None

        self._setup_ipc_dir()
        self._build_window()

    def _setup_ipc_dir(self):
        """Create IPC directory and write PID file."""
        os.makedirs(IPC_DIR, exist_ok=True)
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
        # Remove stale restore file
        try:
            os.unlink(RESTORE_FILE)
        except FileNotFoundError:
            pass

    def _build_window(self):
        """Create GTK window with layer-shell and GL area."""
        self.window = Gtk.Window()

        # Layer shell setup — anchor to all edges, background layer
        GtkLayerShell.init_for_window(self.window)
        GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.BACKGROUND)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_exclusive_zone(self.window, -1)
        GtkLayerShell.set_namespace(self.window, "livewall")

        # GL area
        self.gl_area = Gtk.GLArea()
        self.gl_area.set_has_depth_buffer(False)
        self.gl_area.set_has_stencil_buffer(False)
        self.gl_area.set_required_version(3, 3)

        self.gl_area.connect("realize", self._on_realize)
        self.gl_area.connect("render", self._on_render)
        self.gl_area.connect("resize", self._on_resize)

        # Use an Overlay so we can draw text on top of the GL area
        overlay = Gtk.Overlay()
        overlay.add(self.gl_area)

        # Transparent text overlay
        self.text_area = Gtk.DrawingArea()
        self.text_area.set_halign(Gtk.Align.FILL)
        self.text_area.set_valign(Gtk.Align.FILL)
        self.text_area.connect("draw", self._on_draw_text)
        overlay.add_overlay(self.text_area)

        self.window.add(overlay)
        self.window.connect("destroy", self._on_quit)
        self.window.show_all()

        # Render loop
        GLib.timeout_add(FRAME_MS, self._tick)

        # File monitor — check every 150ms for responsiveness
        GLib.timeout_add(150, self._poll_files)

    def _on_realize(self, gl_area):
        """Initialize GL resources when the context is ready."""
        gl_area.make_current()
        if gl_area.get_error():
            print(f"[livewall] GL error: {gl_area.get_error()}", file=sys.stderr)
            return

        print(f"[livewall] GL Version: {glGetString(GL_VERSION).decode()}")
        print(f"[livewall] Shader: {os.path.basename(self.shader_path)}")

        self._check_shader_metadata(self.shader_path)

        # Build shader program
        try:
            self.program = build_program(self.shader_path)
        except RuntimeError as e:
            print(f"[livewall] {e}", file=sys.stderr)
            self._on_quit()
            return

        # VAO is required in Core Profile
        self.vao = glGenVertexArrays(1)
        glBindVertexArray(self.vao)

        # Fullscreen quad vertices
        vertices = [
            -1.0, -1.0,
             1.0, -1.0,
            -1.0,  1.0,
             1.0,  1.0,
        ]
        vertex_data = (ctypes.c_float * len(vertices))(*vertices)

        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER,
                     ctypes.sizeof(vertex_data), vertex_data, GL_STATIC_DRAW)

        # Placeholder textures
        self.tex_current = create_placeholder_texture()
        self.tex_next = create_placeholder_texture()

        # Snapshot texture for full-screen transitions
        self.snapshot_tex = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, self.snapshot_tex)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.width, self.height, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, None)

        # Load initial cover if provided
        if self.initial_cover and os.path.isfile(self.initial_cover):
            tex = load_texture_from_file(self.initial_cover)
            if tex:
                old = self.tex_current
                self.tex_current = tex
                glDeleteTextures(1, [old])
                if self.show_music_info:
                    self.cover_alpha = 1.0
                    self.cover_alpha_target = 1.0
                self._load_colors_from_cover(self.initial_cover)

        self._load_cubemap()

    def _load_cubemap(self):
        """Loads a predetermined set of 6 cubemap faces into a GL_TEXTURE_CUBE_MAP."""
        faces_dir = os.path.join(os.path.dirname(self.shader_path), "butterfly-cubemap-faces")
        if not os.path.isdir(faces_dir):
            return
            
        faces = [
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0.png",   # Face 0: Right (+X)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_1.png", # Face 1: Left (-X)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_2.png", # Face 2: Top (+Y)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_3.png", # Face 3: Bottom (-Y)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_4.png", # Face 4: Front (+Z)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_5.png"  # Face 5: Back (-Z)
        ]
        
        self.cubemap_tex = glGenTextures(1)
        glBindTexture(GL_TEXTURE_CUBE_MAP, self.cubemap_tex)
        
        for i, face_name in enumerate(faces):
            filepath = os.path.join(faces_dir, face_name)
            try:
                img = Image.open(filepath).convert('RGB')
                img_data = np.array(list(img.getdata()), np.uint8)
                glTexImage2D(
                    GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,
                    0, GL_RGB, img.width, img.height, 0,
                    GL_RGB, GL_UNSIGNED_BYTE, img_data
                )
            except Exception as e:
                print(f"[livewall-cubemap] Failed to load {filepath}: {e}")
                
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE)

    def _on_quit(self, *args):
        """Cleanup and exit."""
        if self.audio_monitor:
            self.audio_monitor.stop()
        if self.camera_monitor:
            self.camera_monitor.stop()
        Gtk.main_quit()

    def _on_resize(self, gl_area, width, height):
        """Handle window resize."""
        self.width = width
        self.height = height
        # Resize snapshot texture
        if self.snapshot_tex:
            gl_area.make_current()
            glBindTexture(GL_TEXTURE_2D, self.snapshot_tex)
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
                         GL_RGBA, GL_UNSIGNED_BYTE, None)

    def _check_shader_metadata(self, path):
        """Parse shader for metadata flags and required uniforms."""
        self.show_music_info = True
        uses_audio = False
        uses_camera = False
        
        try:
            with open(path) as f:
                source = f.read()
                if "// @NoMusicInfo" in source:
                    self.show_music_info = False
                    
                # Lazy-load required peripherals based on shader signature
                if "uAudio" in source:
                    uses_audio = True
                if "uCamera" in source:
                    uses_camera = True
        except IOError:
            pass
            
        # Manage AudioMonitor
        if uses_audio and self.audio_monitor is None:
            self.audio_monitor = AudioMonitor()
            self.audio_monitor.start()
        elif not uses_audio and self.audio_monitor is not None:
            self.audio_monitor.stop()
            self.audio_monitor = None
            
        # Manage CameraMonitor
        if uses_camera and self.camera_monitor is None:
            self.camera_monitor = CameraMonitor()
            self.camera_monitor.start()
        elif not uses_camera and self.camera_monitor is not None:
            self.camera_monitor.stop()
            self.camera_monitor = None
            if self.camera_tex:
                # We can't immediately delete GL textures outside the context, 
                # but we stop fetching new frames.
                pass

        if not self.show_music_info:
            self.cover_alpha_target = 0.0
            self.text_alpha_target = 0.0
        else:
            if os.path.isfile(COVER_FILE):
                self.cover_alpha_target = 1.0
            if self.song_title:
                self.text_alpha_target = 1.0

    def _take_snapshot(self):
        """Copy current framebuffer into snapshot texture for transitions."""
        if self.snapshot_tex:
            glBindTexture(GL_TEXTURE_2D, self.snapshot_tex)
            glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0,
                                self.width, self.height)

    def _start_screen_transition(self):
        """Begin full-screen transition. Snapshot must already be current."""
        self.screen_blending = True
        self.screen_blend = 0.0
        self.screen_blend_start = time.monotonic()

    def _on_render(self, gl_area, ctx):
        """Render one frame."""
        if not self.program:
            return True

        # Handle deferred shader swap (needs GL context)
        if self.pending_shader_path:
            self._check_shader_metadata(self.pending_shader_path)
            # Snapshot is already current from end-of-frame capture
            self._start_screen_transition()
            try:
                new_prog = build_program(self.pending_shader_path)
                old_prog = self.program
                self.program = new_prog
                self.shader_path = self.pending_shader_path
                glDeleteProgram(old_prog)
                print(f"[livewall] Shader loaded: {os.path.basename(self.shader_path)}")
            except RuntimeError as e:
                print(f"[livewall] Shader swap failed: {e}", file=sys.stderr)
                self.screen_blending = False
            self.pending_shader_path = None

        now = time.monotonic()
        t = now - self.start_time

        glViewport(0, 0, self.width, self.height)
        glClear(GL_COLOR_BUFFER_BIT)

        glUseProgram(self.program)

        # ── Update animations ──

        # Crossfade blend (cover art)
        if self.blending:
            elapsed = (now - self.blend_start) * 1000
            self.blend = min(elapsed / CROSSFADE_MS, 1.0)
            if self.blend >= 1.0:
                self._finish_crossfade()

        # Color lerp
        colors_now = None
        if self.color_lerping:
            elapsed = (now - self.color_lerp_start) * 1000
            ct = min(elapsed / COLOR_LERP_MS, 1.0)
            colors_now = [lerp3(self.colors_current[i], self.colors_target[i], ct)
                          for i in range(3)]
            if ct >= 1.0:
                self.colors_current = list(self.colors_target)
                self.color_lerping = False
                colors_now = None

        # Cover alpha
        da = 0.05 if self.cover_alpha_target > self.cover_alpha else -0.03
        if abs(self.cover_alpha - self.cover_alpha_target) > 0.01:
            self.cover_alpha = max(0.0, min(1.0, self.cover_alpha + da))
        else:
            self.cover_alpha = self.cover_alpha_target

        # Screen transition blend
        if self.screen_blending:
            elapsed = (now - self.screen_blend_start) * 1000
            self.screen_blend = min(elapsed / SCREEN_TRANS_MS, 1.0)
            if self.screen_blend >= 1.0:
                self.screen_blending = False
                self.snapshot_ready = False

        # ── Set uniforms ──

        def u(name):
            return glGetUniformLocation(self.program, name)

        glUniform2f(u("uResolution"), float(self.width), float(self.height))
        glUniform1f(u("uTime"), t)

        # Colors
        c = colors_now if colors_now else self.colors_current
        glUniform3f(u("uColor1"), *c[0])
        glUniform3f(u("uColor2"), *c[1])
        glUniform3f(u("uColor3"), *c[2])

        # Cover geometry
        aspect = self.width / max(self.height, 1)
        cover_h = COVER_FRACTION
        cover_w = cover_h / aspect
        glUniform2f(u("uCoverCenter"), 0.5, 0.5)
        glUniform2f(u("uCoverSize"), cover_w, cover_h)
        glUniform1f(u("uCoverRadius"), COVER_RADIUS)
        glUniform1f(u("uCoverAlpha"), self.cover_alpha)
        glUniform1f(u("uBlend"), self.blend)
        glUniform2f(u("uMouse"), self.mouse_x, self.mouse_y)
        
        # Audio bands
        if self.audio_monitor:
            b0, b1, b2, b3 = self.audio_monitor.get_bands()
            glUniform4f(u("uAudio"), float(b0), float(b1), float(b2), float(b3))
        else:
            glUniform4f(u("uAudio"), 0.0, 0.0, 0.0, 0.0)
        
        # Camera Texture update
        if self.camera_monitor:
            frame, is_new = self.camera_monitor.get_frame()
            if self.camera_tex is None:
                self.camera_tex = glGenTextures(1)
                glBindTexture(GL_TEXTURE_2D, self.camera_tex)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
                
            if is_new and frame is not None:
                glBindTexture(GL_TEXTURE_2D, self.camera_tex)
                h, w, _ = frame.shape
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, frame)

        # Full-screen transition uniforms
        sb = self.screen_blend if self.screen_blending else 1.0
        glUniform1f(u("uScreenBlend"), sb)
        glUniform1i(u("uScreenTransition"), self.transition_type)

        # Textures
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, self.tex_current or 0)
        glUniform1i(u("uCoverTex"), 0)

        glActiveTexture(GL_TEXTURE1)
        glBindTexture(GL_TEXTURE_2D, self.tex_next or 0)
        glUniform1i(u("uCoverNextTex"), 1)

        glActiveTexture(GL_TEXTURE2)
        glBindTexture(GL_TEXTURE_2D, self.snapshot_tex or 0)
        glUniform1i(u("uSnapshotTex"), 2)
        
        glActiveTexture(GL_TEXTURE3)
        glBindTexture(GL_TEXTURE_2D, self.camera_tex or 0)
        glUniform1i(u("uCamera"), 3)

        # Cubemap texture
        glActiveTexture(GL_TEXTURE4)
        glBindTexture(GL_TEXTURE_CUBE_MAP, self.cubemap_tex or 0)
        glUniform1i(u("uCubeMap"), 4)

        # Snapshot texture for screen transitions redundant mapping
        glActiveTexture(GL_TEXTURE5)
        glBindTexture(GL_TEXTURE_2D, self.snapshot_tex or 0)
        glUniform1i(u("uPrevFrame"), 5)

        # ── Draw quad ──

        glBindVertexArray(self.vao)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        pos_loc = glGetAttribLocation(self.program, "position")
        glEnableVertexAttribArray(pos_loc)
        glVertexAttribPointer(pos_loc, 2, GL_FLOAT, GL_FALSE, 0, None)

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)

        glDisableVertexAttribArray(pos_loc)
        glBindVertexArray(0)

        # Keep snapshot fresh — only when NOT transitioning
        if not self.screen_blending:
            self._take_snapshot()

        return True  # We handled the rendering

    def _tick(self):
        """Request redraw each frame and track mouse."""
        self.gl_area.queue_render()

        # Update mouse position
        seat = Gdk.Display.get_default().get_default_seat()
        if seat:
            pointer = seat.get_pointer()
            if pointer:
                screen, x, y = pointer.get_position()
                # Normalize to 0.0-1.0 and flip Y to match GL coords
                self.mouse_x = x / self.width
                self.mouse_y = 1.0 - (y / self.height)

        # Also update text overlay alpha
        da = 0.05 if self.text_alpha_target > self.text_alpha else -0.03
        if abs(self.text_alpha - self.text_alpha_target) > 0.01:
            self.text_alpha = max(0.0, min(1.0, self.text_alpha + da))
            self.text_area.queue_draw()
        elif self.text_alpha != self.text_alpha_target:
            self.text_alpha = self.text_alpha_target
            self.text_area.queue_draw()
        return True  # Keep the timeout alive

    def _on_draw_text(self, widget, cr):
        """Draw song title and artist with Cairo — bottom-left like gen-cover-wall."""
        if self.text_alpha < 0.01 or (not self.song_title and not self.song_artist):
            return

        w = widget.get_allocated_width()
        h = widget.get_allocated_height()

        x_offset = 80  # 80px from left edge

        # Artist (closer to bottom: 50px from bottom)
        if self.song_artist:
            layout = PangoCairo.create_layout(cr)
            font = Pango.FontDescription.from_string("Cal Sans 13")
            layout.set_font_description(font)
            layout.set_text(self.song_artist, -1)

            cr.set_source_rgba(1.0, 1.0, 1.0, self.text_alpha * 0.55)
            cr.move_to(x_offset, h - 50)
            PangoCairo.show_layout(cr, layout)

        # Title (above artist: 72px from bottom)
        if self.song_title:
            layout = PangoCairo.create_layout(cr)
            font = Pango.FontDescription.from_string("Cal Sans 44")
            layout.set_font_description(font)
            layout.set_text(self.song_title, -1)

            cr.set_source_rgba(1.0, 1.0, 1.0, self.text_alpha * 0.95)
            cr.move_to(x_offset, h - 72 - 44)  # account for font height
            PangoCairo.show_layout(cr, layout)

    # ─── Cover Management ────────────────────────────────

    def _start_crossfade(self, new_tex):
        """Begin crossfading from current cover to new texture."""
        if self.blending:
            self._finish_crossfade()

        # Move new texture into the 'next' slot
        old_next = self.tex_next
        self.tex_next = new_tex
        if old_next:
            glDeleteTextures(1, [old_next])

        self.blend = 0.0
        self.blend_start = time.monotonic()
        self.blending = True
        self.cover_alpha_target = 1.0

    def _finish_crossfade(self):
        """Complete the crossfade — swap textures."""
        old = self.tex_current
        self.tex_current = self.tex_next
        self.tex_next = create_placeholder_texture()
        if old:
            glDeleteTextures(1, [old])
        self.blend = 0.0
        self.blending = False

    def _start_color_lerp(self, new_colors):
        """Begin lerping background colors to new palette."""
        if self.color_lerping:
            # Snap current to wherever the lerp is
            now = time.monotonic()
            elapsed = (now - self.color_lerp_start) * 1000
            ct = min(elapsed / COLOR_LERP_MS, 1.0)
            self.colors_current = [lerp3(self.colors_current[i],
                                         self.colors_target[i], ct)
                                   for i in range(3)]

        self.colors_target = new_colors
        self.color_lerp_start = time.monotonic()
        self.color_lerping = True

    def _load_colors_from_cover(self, path):
        """Extract dominant colors from an image using Pillow."""
        try:
            img = Image.open(path).convert("RGB").resize((64, 64))
            raw = img.tobytes()
            pixels = [(raw[i], raw[i+1], raw[i+2]) for i in range(0, len(raw), 3)]

            # Simple dominant color extraction: sort by brightness buckets
            from collections import Counter
            # Quantize to reduce palette
            quantized = [(r // 32 * 32, g // 32 * 32, b // 32 * 32)
                         for r, g, b in pixels]
            common = Counter(quantized).most_common(10)

            # Pick 3 distinct colors
            colors = []
            for color, _ in common:
                r, g, b = color[0] / 255.0, color[1] / 255.0, color[2] / 255.0
                # Skip very dark or very light
                lum = 0.299 * r + 0.587 * g + 0.114 * b
                if 0.05 < lum < 0.9:
                    colors.append((r, g, b))
                if len(colors) >= 3:
                    break

            # Pad with defaults if needed
            while len(colors) < 3:
                colors.append(DEFAULT_COLORS[len(colors)])

            self._start_color_lerp(colors)
        except Exception as e:
            print(f"[livewall] Color extraction failed: {e}", file=sys.stderr)

    # ─── File Monitoring IPC ─────────────────────────────

    def _poll_files(self):
        """Poll IPC files for changes (runs every 500ms)."""

        # Check restore signal
        if os.path.isfile(RESTORE_FILE):
            if self.cover_alpha_target > 0:
                print("[livewall] Restore signal — hiding cover")
                self.cover_alpha_target = 0.0
                self.text_alpha_target = 0.0
                self._start_color_lerp(list(DEFAULT_COLORS))
            # Don't remove the file — let toggle manage it
        else:
            # Check for new cover
            try:
                mt = os.path.getmtime(COVER_FILE)
                if mt > self.cover_mtime:
                    self.cover_mtime = mt
                    print(f"[livewall] New cover detected")
                    self.gl_area.make_current()
                    tex = load_texture_from_file(COVER_FILE)
                    if tex:
                        # Screen transition handles the visual blend.
                        # Swap cover instantly — no crossfade needed.
                        self._start_screen_transition()
                        old = self.tex_current
                        self.tex_current = tex
                        if old:
                            glDeleteTextures(1, [old])
                        self.blend = 0.0
                        self.blending = False
                        if self.show_music_info:
                            self.cover_alpha = 1.0
                            self.cover_alpha_target = 1.0
                        self._load_colors_from_cover(COVER_FILE)
            except FileNotFoundError:
                pass

        # Check for metadata (title/artist)
        try:
            mt = os.path.getmtime(META_FILE)
            if mt > self.meta_mtime:
                self.meta_mtime = mt
                with open(META_FILE) as f:
                    lines = f.read().strip().split("\n")
                self.song_title = lines[0] if len(lines) > 0 else ""
                self.song_artist = lines[1] if len(lines) > 1 else ""
                if self.show_music_info:
                    self.text_alpha_target = 1.0 if self.song_title else 0.0
                print(f"[livewall] Meta: {self.song_title} — {self.song_artist}")
                self.text_area.queue_draw()
        except FileNotFoundError:
            pass

        # Check for shader hot-swap (deferred — needs GL context in render)
        try:
            mt = os.path.getmtime(SHADER_FILE)
            if mt > self.shader_mtime:
                self.shader_mtime = mt
                with open(SHADER_FILE) as f:
                    shader_name = f.read().strip()
                if shader_name:
                    new_path = find_shader(shader_name)
                    if new_path != self.shader_path:
                        print(f"[livewall] Queuing shader swap → {os.path.basename(new_path)}")
                        self.pending_shader_path = new_path
        except FileNotFoundError:
            pass

        # Check for transition style change
        try:
            mt = os.path.getmtime(TRANSITION_FILE)
            if mt > self.transition_mtime:
                self.transition_mtime = mt
                with open(TRANSITION_FILE) as f:
                    tname = f.read().strip().lower()
                if tname in TRANSITION_TYPES:
                    self.transition_type = TRANSITION_TYPES.index(tname)
                    print(f"[livewall] Transition: {tname}")
                elif tname.isdigit() and 0 <= int(tname) < len(TRANSITION_TYPES):
                    self.transition_type = int(tname)
                    print(f"[livewall] Transition: {TRANSITION_TYPES[self.transition_type]}")
        except FileNotFoundError:
            pass

        # Check for explicit color file
        try:
            mt = os.path.getmtime(COLORS_FILE)
            if mt > self.colors_mtime:
                self.colors_mtime = mt
                with open(COLORS_FILE) as f:
                    lines = [l.strip() for l in f.readlines() if l.strip()]
                colors = []
                for line in lines[:3]:
                    rgb = hex_to_rgb(line)
                    if rgb:
                        colors.append(rgb)
                if len(colors) >= 3:
                    print(f"[livewall] New colors: {colors}")
                    self._start_color_lerp(colors)
        except FileNotFoundError:
            pass

        return True  # Keep polling

    def cleanup(self):
        """Remove PID file on exit."""
        try:
            os.unlink(PID_FILE)
        except FileNotFoundError:
            pass


# ─── CLI ─────────────────────────────────────────────────

def kill_existing():
    """Kill any running livewall instance."""
    try:
        with open(PID_FILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        print(f"[livewall] Killed PID {pid}")
        os.unlink(PID_FILE)
    except (FileNotFoundError, ProcessLookupError, ValueError):
        print("[livewall] No running instance found")

def find_shader(name):
    """Resolve shader path — check local shaders/ dir."""
    # Direct path
    if os.path.isfile(name):
        return os.path.abspath(name)

    # Relative to script's shaders/ directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    shader_dir = os.path.join(script_dir, "shaders")
    candidate = os.path.join(shader_dir, name)
    if os.path.isfile(candidate):
        return candidate

    # Without extension
    candidate_ext = candidate + ".glsl"
    if os.path.isfile(candidate_ext):
        return candidate_ext

    print(f"[livewall] Shader not found: {name}", file=sys.stderr)
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="GPU-animated wallpaper with album cover")
    parser.add_argument("--shader", "-s", default="aurora.glsl",
                        help="GLSL shader file (default: aurora.glsl)")
    parser.add_argument("--cover", "-c", default=None,
                        help="Initial album cover image path")
    parser.add_argument("--kill", "-k", action="store_true",
                        help="Kill running livewall instance")
    args = parser.parse_args()

    if args.kill:
        kill_existing()
        return

    # Kill existing before starting new
    try:
        with open(PID_FILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        import time as _t
        _t.sleep(0.3)
    except (FileNotFoundError, ProcessLookupError, ValueError):
        pass

    shader_path = find_shader(args.shader)
    print(f"[livewall] Starting with shader: {shader_path}")

    app = LiveWall(shader_path, initial_cover=args.cover)

    # Graceful shutdown
    def on_signal(sig, frame):
        print(f"\n[livewall] Signal {sig}, shutting down...")
        app.cleanup()
        Gtk.main_quit()

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)

    try:
        Gtk.main()
    finally:
        app.cleanup()


if __name__ == "__main__":
    main()
import os
import sys
import time
import struct
import numpy as np
import threading
import subprocess
import pulsectl

class AudioMonitor:
    def __init__(self):
        self.running = False
        self.thread = None
        
        # 4 frequency bands: Bass, Low-Mid, Mid, High
        self.bands = [0.0, 0.0, 0.0, 0.0]
        
        # Smoothing (attack/release for snappiness + low jitter)
        self.smooth_bands = [0.0, 0.0, 0.0, 0.0]
        self.attack = 0.2  # Fast rise (low latency)
        self.release = 0.85 # Slow fall (removes jitter)
        
        # Audio params
        self.rate = 44100
        self.chunk_size = 512  # Smaller chunk = lower latency
        
    def _get_monitor_device(self):
        try:
            with pulsectl.Pulse('livewall') as pulse:
                return pulse.server_info().default_sink_name + '.monitor'
        except Exception as e:
            print(f"[livewall-audio] Warning: Could not get pulse monitor: {e}")
            return None

    def start(self):
        if self.running: return
        self.running = True
        self.thread = threading.Thread(target=self._audio_loop, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=1.0)
            
    def get_bands(self):
        return tuple(self.smooth_bands)

    def _audio_loop(self):
        device = self._get_monitor_device()
        if not device:
            return

        print(f"[livewall-audio] Listening on {device}")
        
        cmd = [
            'parec',
            '--format=s16le',
            '--rate=44100',
            '--channels=1',
            '--latency-msec=10',
            '--process-time-msec=10',
            f'--device={device}'
        ]
        
        try:
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            
            bytes_to_read = self.chunk_size * 2 # 16-bit = 2 bytes per sample
            
            while self.running:
                data = process.stdout.read(bytes_to_read)
                if not data or len(data) != bytes_to_read:
                    time.sleep(0.01)
                    continue
                    
                # Convert binary to numpy array of 16-bit ints
                samples = np.frombuffer(data, dtype=np.int16)
                
                # Apply Hann window to reduce spectral leakage
                windowed = samples * np.hanning(len(samples))
                
                # Compute FFT
                fft_out = np.abs(np.fft.rfft(windowed)) / len(samples)
                
                # Normalize kinda
                fft_out = fft_out / 256.0
                
                # Frequency bins mapping (rate=44100, chunk=512 -> ~86Hz per bin)
                # Band 0 (Bass): 20Hz - 250Hz (bins 1-3)
                # Band 1 (Low Mid): 250Hz - 1000Hz (bins 3-12)
                # Band 2 (Mid): 1000Hz - 4000Hz (bins 12-46)
                # Band 3 (High): 4000Hz - 16000Hz (bins 46-186)
                
                b0 = np.mean(fft_out[1:3])   if len(fft_out) > 3 else 0
                b1 = np.mean(fft_out[3:12])  if len(fft_out) > 12 else 0
                b2 = np.mean(fft_out[12:46]) if len(fft_out) > 46 else 0
                b3 = np.mean(fft_out[46:186]) if len(fft_out) > 186 else 0
                
                # Update current bands (reduced multipliers for much lower sensitivity)
                self.bands = [
                    min(1.0, b0 * 0.4),
                    min(1.0, b1 * 0.5),
                    min(1.0, b2 * 0.6),
                    min(1.0, b3 * 0.7),
                ]
                
                # Smooth the data with attack/release envelopes
                for i in range(4):
                    if self.bands[i] > self.smooth_bands[i]:
                        # Attack: fast rise
                        self.smooth_bands[i] = (self.smooth_bands[i] * self.attack) + (self.bands[i] * (1.0 - self.attack))
                    else:
                        # Release: slow fall to reduce jitter
                        self.smooth_bands[i] = (self.smooth_bands[i] * self.release) + (self.bands[i] * (1.0 - self.release))
                    
        except Exception as e:
            print(f"[livewall-audio] Audio loop error: {e}")
        finally:
            if 'process' in locals():
                process.terminate()
import cv2
import threading
import time
import numpy as np

class CameraMonitor:
    def __init__(self, camera_index=0, width=640, height=480):
        self.camera_index = camera_index
        self.width = width
        self.height = height
        self.running = False
        self.thread = None
        self.cap = None
        
        # Latest frame as RGB numpy array
        self.current_frame = None
        self.frame_lock = threading.Lock()
        
        # Flag to indicate if a new frame is available for texture upload
        self.new_frame = False

    def start(self):
        if self.running: return
        self.running = True
        self.thread = threading.Thread(target=self._camera_loop, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=1.0)
        if self.cap:
            self.cap.release()

    def get_frame(self):
        """Returns (frame_rgb, is_new). If no frame, returns (None, False)."""
        with self.frame_lock:
            if self.current_frame is not None:
                is_new = self.new_frame
                self.new_frame = False
                return self.current_frame, is_new
            return None, False

    def _camera_loop(self):
        # Open the default camera using V4L2 (Linux)
        self.cap = cv2.VideoCapture(self.camera_index, cv2.CAP_V4L2)
        if not self.cap.isOpened():
            print(f"[livewall-camera] Error: Could not open camera {self.camera_index}.")
            self.running = False
            return
            
        # Try to set resolution
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.width)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.height)
        
        print(f"[livewall-camera] Started capturing from camera {self.camera_index}")
        
        while self.running:
            ret, frame = self.cap.read()
            if not ret:
                time.sleep(0.05)
                continue
                
            # OpenCV returns BGR, convert to RGB for OpenGL
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Flip horizontally for mirror effect (standard for webcams)
            frame_rgb = cv2.flip(frame_rgb, 1)
            
            with self.frame_lock:
                self.current_frame = frame_rgb
                self.new_frame = True
                
            # ~30fps limit
            time.sleep(0.033)
