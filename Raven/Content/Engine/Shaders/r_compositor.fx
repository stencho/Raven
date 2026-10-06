#include "lib/general.fx"

Texture2D Diffuse;
Texture2D Lighting;
Texture2D Depth;
Texture2D Normal;
Texture2D Composed;
Texture2D Overlay;
Texture2D Output;

SamplerState DiffuseSampler = sampler_state { texture = <Diffuse>; };
SamplerState LightingSampler = sampler_state { texture = <Lighting>; };
SamplerState DepthSampler = sampler_state { texture = <Depth>; };
SamplerState NormalSampler = sampler_state { texture = <Normal>; };
SamplerState ComposedSampler = sampler_state { texture = <Composed>; };
SamplerState OverlaySampler = sampler_state { texture = <Overlay>; };
SamplerState OutputSampler = sampler_state { texture = <Output>; };

struct VSI {
	float4 Position : POSITION0;
	float2 UV : TEXCOORD0;
};

struct VSO {
	float4 Position : POSITION0;
	float2 UV : TEXCOORD0;
};

struct ClearPSO {
    float4 Diffuse :  SV_TARGET0;
    float4 Normal :   SV_TARGET1;
    float Depth :     SV_DEPTH;
    float4 Lighting : SV_TARGET2;
};

// SCREEN DRAW VARS
float2 screen_resolution;
float2 screen_draw_position;
float2 screen_draw_size;

// VERTEX SHADERS
VSO FullscreenVS(VSI input) {
	VSO output = (VSO)0;
    output.Position = input.Position;    
	output.UV = input.UV;
	return output;
}

VSO ScreenVS(VSI input) {
    VSO output = (VSO)0;
        
    float2 float_per_screen_pixel = 1.0 / screen_resolution;
    float2 screen_offset = float_per_screen_pixel * screen_draw_position;    
    float2 screen_size = float_per_screen_pixel * screen_draw_size;
    
    output.Position = float4(input.Position + float3(screen_offset, 0), 1);
    output.Position.xy *= screen_size;
        
    output.UV = input.UV;
    return output;    
}

// PIXEL SHADERS
ClearPSO ClearPS() {
	ClearPSO output;
    output.Diffuse = 0.0;
	output.Normal = 0.0;
	output.Depth = 1.0;
    output.Lighting = 0.0;
	return output;
}

int buffer = -1; //debug buffer selection variable
 
float4 Compose(VSO input) : SV_TARGET {
    float4 rgba = sample2D(Diffuse, input.UV);           
    float4 l =    sample2D(Lighting, input.UV);            
    float4 d =    sample2D(Depth, input.UV);
    float4 n =    sample2D(Normal, input.UV);
	
    if (buffer == 0) return rgba;
    else if (buffer == 1) return n; //normals
    else if (buffer == 2) return float4(d.x,d.y,d.z, 1) ; //depth
    else if (buffer == 3) return l; //lighting
	else return float4(saturate(rgba.rgb * l.rgb), 1);       
}

float4 Finalize(VSO input) : SV_TARGET {
    float4 composed = sample2D(Composed, input.UV);
    float4 overlay =  sample2D(Overlay, input.UV);
    
    float3 rgb = lerp(composed.rgb, overlay.rgb, overlay.a);
    
    return float4(rgb, 1);
}

float4 ToScreen(VSO input) : SV_TARGET {
    float4 composed = sample2D(Output, input.UV);     
    return float4((composed.rgb), 1);
}

// TECHNIQUES IN ORDER OF USE
technique clear {
	pass P0	{
		VertexShader = compile VS_SHADERMODEL FullscreenVS();
		PixelShader = compile PS_SHADERMODEL ClearPS();
	}
}

technique compose {
	pass P0	{
		VertexShader = compile VS_SHADERMODEL FullscreenVS();
		PixelShader = compile PS_SHADERMODEL Compose();
	}
};

technique finalize {
	pass P0	{
		VertexShader = compile VS_SHADERMODEL FullscreenVS();
		PixelShader = compile PS_SHADERMODEL Finalize();
	}
};

technique draw_to_screen {
	pass P0 {
		VertexShader = compile VS_SHADERMODEL ScreenVS();
		PixelShader = compile PS_SHADERMODEL ToScreen();
	}
};

technique draw_fullscreen {
	pass P0 {
		VertexShader = compile VS_SHADERMODEL FullscreenVS();
		PixelShader = compile PS_SHADERMODEL ToScreen();
	}
};