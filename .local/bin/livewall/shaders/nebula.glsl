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
