## Includes

Includes = {

}


## Samplers

PixelShader = 
{
	Samplers = 
	{
		BlurSample = 
		{
			AddressV = "Clamp"
			MagFilter = "Linear"
			Index = 0
			MipFilter = "Linear"
			AddressU = "Clamp"
		}


	}
}


## Vertex Structs

VertexStruct VS_INPUT
{
    float4 vPosition  : POSITION;
    float2 vTexCoord  : TEXCOORD0;
};


VertexStruct VS_OUTPUT
{
    float4  vPosition : PDX_POSITION;
    float2  vTexCoord : TEXCOORD0;
};


## Constant Buffers

ConstantBuffer( 0, 0 )
{
	float4  	vGaussianOffsetsWeights[2];
}

## Shared Code

## Vertex Shaders

VertexShader = 
{
	MainCode VertexShader
	[[
		VS_OUTPUT main(const VS_INPUT In )
		{
		    VS_OUTPUT Out;
		    Out.vPosition  	= In.vPosition;
		    Out.vTexCoord  	= In.vTexCoord;
		    return Out;
		}
	]]

}


## Pixel Shaders

PixelShader = 
{
	MainCode HorizontalPixelShader
	[[
		float4 main( VS_OUTPUT In ) : PDX_COLOR
		{
			// Accumulated color
			float fAccum = 0.0f;
			/*float vOffset[3];
			float vWeight[3];
			vOffset[0] = vGaussianOffsetsWeights[0].x;
			vOffset[1] = vGaussianOffsetsWeights[0].y;
			vOffset[2] = vGaussianOffsetsWeights[0].z;	
			vWeight[0] = vGaussianOffsetsWeights[0].w;
			vWeight[1] = vGaussianOffsetsWeights[1].x;
			vWeight[2] = vGaussianOffsetsWeights[1].y;*/
			
			int sampleCount = 1;
			const int sampleSize = 9;
			float sampleOffset = 0.025f;
			float2 radius[sampleSize * 2 - 1];
			
			float3 sample = tex2D( BlurSample, In.vTexCoord ).rgb;
			sampleOffset /= sample.b * 100.0f;// Decrease blur radius with distance from the camera
			radius[0] = sample.rg;
			float maxRadius = radius[0].g;
			float maxRadiusMultiplier = 4;
			
			for (int i = 1; i < sampleSize; i++) {
				radius[i * 2 - 1] = tex2D( BlurSample, ( In.vTexCoord+float2(i * sampleOffset, 0.0) ) ).rg;
				radius[i * 2] = tex2D( BlurSample, ( In.vTexCoord-float2(i * sampleOffset, 0.0) ) ).rg;
				maxRadius = max(max(maxRadius, radius[i * 2 - 1].g), radius[i * 2].g);
			}
			
			// Thicker shadow
			for (int i = 0; i < sampleSize * 2 - 1; i++) {
				radius[i].r *= radius[i].r;
			}
			
			maxRadius = saturate(maxRadius * maxRadiusMultiplier + 1 / sampleSize) * sampleSize;
			
			fAccum = radius[0].r;
			for (int i = 1; i < maxRadius; i++) {
				fAccum += radius[i * 2 - 1].r + radius[i * 2].r;
				sampleCount += 2;
			}
			fAccum /= float( sampleCount );
			return float4( fAccum, sample.g, sample.b, 1.0f );
		}
	]]

	MainCode VerticalPixelShader
	[[
		float4 main( VS_OUTPUT In ) : PDX_COLOR
		{
			// Accumulated color
			float fAccum = 0.0f;
			/*float vOffset[3];
			float vWeight[3];
			vOffset[0] = vGaussianOffsetsWeights[0].x;
			vOffset[1] = vGaussianOffsetsWeights[0].y;
			vOffset[2] = vGaussianOffsetsWeights[0].z;	
			vWeight[0] = vGaussianOffsetsWeights[0].w;
			vWeight[1] = vGaussianOffsetsWeights[1].x;
			vWeight[2] = vGaussianOffsetsWeights[1].y;*/
			
			int sampleCount = 1;
			const int sampleSize = 9;
			float sampleOffset = 0.025f;
			float2 radius[sampleSize * 2 - 1];
			
			float3 sample = tex2D( BlurSample, In.vTexCoord ).rgb;
			sampleOffset /= sample.b * 100.0f;// Decrease blur radius with distance from the camera
			radius[0] = sample.rg;
			float maxRadius = radius[0].g;
			float maxRadiusMultiplier = 4;
			
			for (int i = 1; i < sampleSize; i++) {
				radius[i * 2 - 1] = tex2D( BlurSample, ( In.vTexCoord+float2(0.0, i * sampleOffset) ) ).rg;
				radius[i * 2] = tex2D( BlurSample, ( In.vTexCoord-float2(0.0, i * sampleOffset) ) ).rg;
				maxRadius = max(max(maxRadius, radius[i * 2 - 1].g), radius[i * 2].g);
			}
			
			maxRadius = saturate(maxRadius * maxRadiusMultiplier + 1 / sampleSize) * sampleSize;
			
			fAccum = radius[0].r;
			for (int i = 1; i < maxRadius; i++) {
				fAccum += radius[i * 2 - 1].r + radius[i * 2].r;
				sampleCount += 2;
			}
			fAccum /= float( sampleCount );
			return float4( fAccum, fAccum, fAccum, 1.0f );	
		}
	]]

}


## Blend States

BlendState BlendState
{
	SourceBlend = "SRC_ALPHA"
	AlphaTest = no
	BlendEnable = no
	DestBlend = "INV_SRC_ALPHA"
}

## Rasterizer States

## Depth Stencil States

## Effects

Effect ShadowBlurHorizontal
{
	VertexShader = "VertexShader"
	PixelShader = "HorizontalPixelShader"
}

Effect ShadowBlurVertical
{
	VertexShader = "VertexShader"
	PixelShader = "VerticalPixelShader"
}