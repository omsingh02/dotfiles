// Fork of "Cyclotron" by ChunderFPV. https://shadertoy.com/view/McV3Dm
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
