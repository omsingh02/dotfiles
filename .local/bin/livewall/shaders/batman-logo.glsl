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
