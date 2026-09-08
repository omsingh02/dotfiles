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
