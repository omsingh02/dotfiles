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
