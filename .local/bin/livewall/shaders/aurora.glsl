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
