#version 450

/*
   TriggerExcited's grow2x Shader based on Hyllian's DDT
   
   Copyright (c) 2022 TriggerExcited - triggerexcited@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/

// This filter upscales an image 2 times by remapping the colors of the source image to a DDT copy of itself
// This type of filter is intended to be used with retro / pixel art images

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#define decal Source

const vec3 Y = vec3(.2126, .7152, .0722);

float get_luma(vec3 color)
{
  return dot(color, Y);
}

vec3 bilinear(float p, float q, vec3 A, vec3 B, vec3 C, vec3 D)
{
	return ((1-p)*(1-q)*A + p*(1-q)*B + (1-p)*q*C + p*q*D);
}

float color_comparison_luma(vec3 color0, vec3 color1, float luma0, float luma1){
	vec3 dif = abs(color0 - color1);
	float luma_dif = abs(luma0 - luma1);
	return (dif.r + dif.g + dif.b + luma_dif * 2.0);
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec4 t1;
layout(location = 2) out vec2 loc;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord * 1.0001;
   
	vec2 ps = vec2(params.SourceSize.z, params.SourceSize.w);
	float dx = ps.x;
	float dy = ps.y;

	t1.xy = vec2( dx,  0); // F
	t1.zw = vec2(  0, dy); // H
	loc = vTexCoord*params.SourceSize.xy;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4 t1;
layout(location = 2) in vec2 loc;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

vec3 cdr(float score[4], vec3 scd[4]){
	float min = score[0];
	int pos = 0;
	for(int i = 1; i < 4; i++){
		if(score[i] < min){
			min = score[i];
			pos = i;
		}
	}
	return scd[pos];
}

void main()
{
	vec2 pos = fract(loc)-vec2(0.5, 0.5); // pos = pixel position
	vec2 dir = sign(pos); // dir = pixel direction

	vec2 g1 = dir*t1.xy;
	vec2 g2 = dir*t1.zw;
	
	vec4 tap[4] = {
		texture(decal, vTexCoord       ),
		texture(decal, vTexCoord +g1   ),
		texture(decal, vTexCoord    +g2),
		texture(decal, vTexCoord +g1+g2)
	};
	
	vec3 color[4] = {
		tap[0].rgb,
		tap[1].rgb,
		tap[2].rgb,
		tap[3].rgb
	};
	
	vec3 scd[4] = {
		color[0],
		color[1],
		color[2],
		color[3]
	};
	
	float luma[4] = { 
		get_luma(color[0]), get_luma(color[1]),
		get_luma(color[2]), get_luma(color[3])
	};
	
	float p = abs(pos.x);
	float q = abs(pos.y);

	float k = distance(pos,g1 * params.SourceSize.xy);
	float l = distance(pos,g2 * params.SourceSize.xy);

	float wd1 = abs(luma[0]-luma[3]);
	float wd2 = abs(luma[1]-luma[2]);

	if ( wd1 < wd2 )
	{
		if (k < l)
		{
			color[2] = color[0] + color[3] - color[1];
		}
		else
		{
			color[1] = color[0] + color[3] - color[2];
		}
	}
	else if (wd1 > wd2)
	{
		color[3] = color[1] + color[2] - color[0];
	}
	
	vec3 result = bilinear(p, q, color[0], color[1], color[2], color[3]);
	float result_luma = get_luma(result);
	
	float score[4] = {
		color_comparison_luma(scd[0], result, luma[0], result_luma),
		color_comparison_luma(scd[1], result, luma[1], result_luma),
		color_comparison_luma(scd[2], result, luma[2], result_luma),
		color_comparison_luma(scd[3], result, luma[3], result_luma)
	};
	
	result = cdr(score, scd);
	
	FragColor = vec4(result, 1.0);
}
