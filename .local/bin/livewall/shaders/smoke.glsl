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
