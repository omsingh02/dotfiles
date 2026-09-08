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
