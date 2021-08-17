## Includes

Includes = {
	"constants.fxh"
	"standardfuncsgfx.fxh"
	"pdxmap.fxh"
	"shadow.fxh"
}


## Samplers

PixelShader = 
{
	Samplers = 
	{
		HeightTexture = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 0
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		WaterNormal = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 1
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		ReflectionCubeMap = 
		{
			AddressV = "Mirror"
			MagFilter = "Linear"
			Type = "Cube"
			AddressU = "Mirror"
			Index = 2
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		WaterColor = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 3
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		WaterNoise = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 4
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		WaterRefraction = 
		{
			AddressV = "Clamp"
			MagFilter = "Linear"
			AddressU = "Clamp"
			Index = 5
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		IceDiffuse = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 6
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		IceNormal = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 7
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		FoWTexture = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 8
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		FoWDiffuse = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 9
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		ShadowMap = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 10
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		TITexture = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 11
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		ProvinceColorMap = 
		{
			AddressV = "Clamp"
			MagFilter = "Point"
			AddressU = "Clamp"
			Index = 12
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		IndirectionMap =
		{
			AddressV = "Clamp"
			MagFilter = "Point"
			AddressU = "Clamp"
			Index = 13
			MipFilter = "Linear"
			MinFilter = "Linear"
		}
	}
}


## Vertex Structs

VertexStruct VS_INPUT_WATER
{
    float2 position			: POSITION;
};


VertexStruct VS_OUTPUT_WATER
{
    float4 position			: PDX_POSITION;
	float3 pos				: TEXCOORD0; 
	float2 uv				: TEXCOORD1;
	float4 screen_pos		: TEXCOORD2; 
	float3 cubeRotation     : TEXCOORD3;
	float4 vShadowProj     : TEXCOORD4;	
	float4 vScreenCoord		: TEXCOORD5;
	float2 uv_ice			: TEXCOORD6;	
};

VertexStruct VS_INPUT_LAKE
{
    float4 position			: POSITION;
};

## Constant Buffers

ConstantBuffer( 2, 48 )
{
	float3 vTime_HalfPixelOffset;
}

## Shared Code

## Vertex Shaders

VertexShader = 
{
	MainCode VertexShader
	[[
		VS_OUTPUT_WATER main( const VS_INPUT_WATER VertexIn )
		{
			VS_OUTPUT_WATER VertexOut;
			VertexOut.pos = float3( VertexIn.position.x, WATER_HEIGHT, VertexIn.position.y );
			VertexOut.position = mul( ViewProjectionMatrix, float4( VertexOut.pos.x, VertexOut.pos.y, VertexOut.pos.z, 1.0f ) );
			VertexOut.screen_pos = VertexOut.position;
			VertexOut.screen_pos.y = FLIP_SCREEN_POS( VertexOut.screen_pos.y );
			VertexOut.uv = float2( ( VertexIn.position.x + 0.5f ) / MAP_SIZE_X,  ( VertexIn.position.y + 0.5f - MAP_SIZE_Y ) / -MAP_SIZE_Y );
			VertexOut.uv *= float2( MAP_POW2_X, MAP_POW2_Y ); //POW2
			VertexOut.uv_ice = VertexOut.uv * float2( MAP_SIZE_X, MAP_SIZE_Y ) * 0.1f;
			VertexOut.uv_ice *= float2( FOW_POW2_X, FOW_POW2_Y ); //POW2
			float vAnimTime = vTime_HalfPixelOffset.x * 0.01f;
			VertexOut.cubeRotation = normalize( float3( sin( vAnimTime ) * 0.5f, sin( vAnimTime ), cos( vAnimTime ) * 0.3f ) );
			
			VertexOut.vShadowProj = mul( ShadowMapTextureMatrix, float4( VertexOut.pos, 1.0f ) );	
			
			// Output the screen-space texture coordinates
			VertexOut.vScreenCoord.x = ( VertexOut.position.x * 0.5 + VertexOut.position.w * 0.5 );
			VertexOut.vScreenCoord.y = ( VertexOut.position.w * 0.5 - VertexOut.position.y * 0.5 );
		#ifdef PDX_OPENGL
			VertexOut.vScreenCoord.y = -VertexOut.vScreenCoord.y;
		#endif			
			VertexOut.vScreenCoord.z = VertexOut.position.w;
			VertexOut.vScreenCoord.w = VertexOut.position.w;	
			
			return VertexOut;
		}
	]]
	
	MainCode VertexShaderLake
	[[
		VS_OUTPUT_WATER main( const VS_INPUT_LAKE VertexIn )
		{
			VS_OUTPUT_WATER VertexOut;
			VertexOut.pos = float3( VertexIn.position.x, VertexIn.position.z, VertexIn.position.y );
			VertexOut.position = mul( ViewProjectionMatrix, float4( VertexOut.pos.x, VertexOut.pos.y, VertexOut.pos.z, 1.0f ) );
			VertexOut.screen_pos = VertexOut.position;
			VertexOut.screen_pos.y = FLIP_SCREEN_POS( VertexOut.screen_pos.y );
			VertexOut.uv = float2( ( VertexIn.position.x + 0.5f ) / MAP_SIZE_X,  ( VertexIn.position.y + 0.5f - MAP_SIZE_Y ) / -MAP_SIZE_Y );
			VertexOut.uv *= float2( MAP_POW2_X, MAP_POW2_Y ); //POW2
			VertexOut.uv_ice = VertexOut.uv * float2( MAP_SIZE_X, MAP_SIZE_Y ) * 0.1f;
			VertexOut.uv_ice *= float2( FOW_POW2_X, FOW_POW2_Y ); //POW2
			float vAnimTime = vTime_HalfPixelOffset.x * 0.01f;
			VertexOut.cubeRotation = normalize( float3( sin( vAnimTime ) * 0.5f, sin( vAnimTime ), cos( vAnimTime ) * 0.3f ) );
			
			VertexOut.vShadowProj = mul( ShadowMapTextureMatrix, float4( VertexOut.pos, 1.0f ) );	
			
			// Output the screen-space texture coordinates
			VertexOut.vScreenCoord.x = ( VertexOut.position.x * 0.5 + VertexOut.position.w * 0.5 );
			VertexOut.vScreenCoord.y = ( VertexOut.position.w * 0.5 - VertexOut.position.y * 0.5 );
		#ifdef PDX_OPENGL
			VertexOut.vScreenCoord.y = -VertexOut.vScreenCoord.y;
		#endif			
			VertexOut.vScreenCoord.z = VertexOut.position.w;
			VertexOut.vScreenCoord.w = VertexOut.position.w;	
			
			return VertexOut;
		}
	]]
}


## Pixel Shaders

PixelShader = 
{
	MainCode PixelShader
	[[
		float3 CalcWaterNormal( float2 uv, float vTimeSpeed )
		{
			float vScaledTime = vTime_HalfPixelOffset.x * vTimeSpeed;
			float vScaleUV =25.0f;
			float2 time1 = vScaledTime * float2( 0.3f, 0.7f );
			float2 time2 = -vScaledTime * 0.75f * float2( 0.8f, 0.2f );
			float2 uv1 = vScaleUV * uv;
			float2 uv2 = vScaleUV * uv * 1.3;
			float noiseScale = 12.0f;
			float3 noiseNormal1 = tex2D( WaterNoise, uv1 * noiseScale + time1 * 3.0f ).rgb - 0.5f;
			float3 noiseNormal2 = tex2D( WaterNoise, uv2 * noiseScale + time2 * 3.0f ).rgb - 0.5f;
			float3 normalNoise = noiseNormal1 + noiseNormal2 + float3( 0.0f, 0.0f, 15.0f );
			return normalize( normalNoise ).xzy;
		}

		float4 ApplyIce( float4 vColor, float2 vPos, inout float3 vNormal, float4 vFoWColor, float2 vIceUV, out float vIceFade )
		{
			float vSnow = saturate( GetSnow(vFoWColor) - 0.2f ); 
			vIceFade = vSnow*8.0f;
			float4 vIceNormal = tex2D( IceNormal, vIceUV * 2.0f );
			float vIceNoise = tex2D( FoWDiffuse, ( vPos + 0.5f ) / 16.0f  ).a;
			vIceFade *= vIceNoise * 1.5f + 0.25f;
			vIceFade *= vIceNormal.a;
			float vMapLimitFade = saturate( saturate( (vPos.y/MAP_SIZE_Y) - 0.74f )*800.0f );
			vIceFade *= vMapLimitFade;
			vIceFade = saturate( ( vIceFade-0.5f ) * 2.0f );
			//vNormal = lerp( vNormal, tex2D( IceNormal, vIceUV ).rgb, vIceFade );
			vNormal = normalize( lerp( vNormal, normalize( vIceNormal.rbg - 0.5f ), vIceFade ) );
			//float4 vIceColor = tex2D( IceDiffuse, vIceUV );
			float3 vIceColor = lerp( float3(0.5f, 0.7f, 0.9f), float3(0.75f, 0.8f, 0.85f), saturate( vSnow * 2.0f ) );
			vColor.rgb /= vSnow * 4.0f + 1.0f;
			vColor.rgb = lerp( vColor.rgb, float3(0.75f, 0.8f, 0.85f), vIceFade * 0.875f );
			return vColor;
		}

		float4 main( VS_OUTPUT_WATER Input ) : PDX_COLOR
		{
		#ifdef MAP_IGNORE_HEIGHT
			float waterHeight = 0.0f;
		#else
			float waterHeight = tex2D( HeightTexture, Input.uv ).x;
		#endif
			
			float4 waterColor = float4( float3( 1, 1, 1 ) * waterHeight, 1.0f );
			
			waterHeight /= ( 93.7f / 255.0f );
			waterHeight = saturate( ( waterHeight - 0.995f ) * 50.0f );

			float4 vFoWColor = GetFoWColor( Input.pos, FoWTexture);	
			float TI = GetTI( vFoWColor );	
			float4 vTIColor = GetTIColor( Input.pos, TITexture );

			if( ( TI - 0.99f ) * 1000.0f > 0.0f )
			{
				return float4( vTIColor.rgb, 1.0f - waterHeight );
			}

			float3 normal = CalcWaterNormal( Input.uv * WATER_TILE, vTimeScale * WATER_TIME_SCALE );

			//Ice effect
			
			if ( REPLACE_WATER_TEXTURE )
			{
				waterColor.rgb = ApplyWaterRamp( ( waterColor.x - 93.7f / 255.0f ) * WATER_CONTRAST + 93.7f / 255.0f );
			}
			else
			{
				waterColor = tex2D( WaterColor, Input.uv );
			}
			
			// Region colors (provinces)
			float2 flippedUV = Input.uv;
			flippedUV.y = 1.0f - flippedUV.y;
			float4 vSample = GetProvinceColorSampled( flippedUV, IndirectionMap, ProvinceIndirectionMapSize, ProvinceColorMap, ProvinceColorMapSize, 1 );
			waterColor.rgb = lerp( waterColor.rgb, vSample.rgb, saturate( vSample.a ) );

			float vIceFade = 0.0f;
			waterColor = ApplyIce( waterColor, Input.pos.xz, normal, vFoWColor, Input.uv_ice, vIceFade );
			
			float3 vEyeDir = normalize( Input.pos - vCamPos.xyz );
			float3 reflection = reflect( vEyeDir, normal );

		#ifdef PDX_OPENGLES
			reflection.y *= -1.0f;
		#endif 

			float3 reflectiveColor = texCUBE( ReflectionCubeMap, reflection ).rgb;

		#ifdef PDX_OPENGLES
			float3 refractiveColor = float3(0.1, 0.3, 0.5);
			float vRefractionScale = saturate( 5.0f - ( Input.screen_pos.z / Input.screen_pos.w ) * 5.0f );
		#else
			float2 refractiveUV = ( Input.screen_pos.xy / Input.screen_pos.w ) * 0.5f + 0.5f;
			refractiveUV.y = 1.0f - refractiveUV.y;
			refractiveUV += vTime_HalfPixelOffset.gb;
			float vRefractionScale = saturate( 5.0f - ( Input.screen_pos.z / Input.screen_pos.w ) * 5.0f );
			float3 refractiveColor = tex2D( WaterRefraction, (refractiveUV.xy - normal.xz * vRefractionScale * 0.15f) ).rgb;
		#endif

			float fresnelBias = 0.0625f;
			float fresnel = saturate( dot( -vEyeDir, normal ) ) * 0.5f;
			fresnel = fresnelBias + ( 1.0f - fresnelBias ) * pow( 1.0f - fresnel, 10.0f );
			fresnel *= (1.0f-vIceFade); //No fresnel when we have snow
			
			float3 H = normalize( -vLightDir + -vEyeDir );
			float vSpecWidth = MAP_SIZE_X*0.9f;
			
			float vSpecMultiplier = 3.0f;
			float specular = pow( saturate( dot( H, normal ) ), vSpecWidth ) * vSpecMultiplier;
			
			refractiveColor = lerp( refractiveColor, waterColor.rgb, 0.3f+(0.7f*vIceFade) );
			float3 outColor = refractiveColor * ( 1.0f - fresnel ) + reflectiveColor * fresnel;
			
			if ( WAVES )
			{
				float waveFrequency = 2.0f;
				float waveStart = 93.7f - WAVE_DISTANCE;
				float waveBase = tex2D( HeightTexture, Input.uv ).r - waveStart / 255.0f;
				waveBase /= 93.7f / 255.0f - waveStart / 255.0f;
				waveBase = saturate( waveBase );
				float waveTime = vTime_HalfPixelOffset.x * vTimeScale * WATER_TIME_SCALE * 10.0f;
				float waveNoise = tex2D( FoWDiffuse, Input.pos.xz / 256.0f ).a * 4.0f + tex2D( FoWDiffuse, ( Input.pos.xz - float2( 0.0f, waveTime ) )/ 2.0f ).a / 16.0f;
				float waveNoise2 = saturate( ( tex2D( FoWDiffuse, ( Input.pos.xz + float2( waveTime, 0.0f ) ) / 32.0f ).a + 1.0f - tex2D( FoWDiffuse, ( Input.pos.xz - float2( waveTime, 0.5f ) ) / 32.0f ).a ) * 2.0f - 2.0f );
				//wave = saturate( ( frac( wave * waveFrequency - waveTime + waveNoise ) - ( 1.0f - frac( wave ) ) ) * 1.25f) * waveNoise2;
				float wave = waveBase * waveFrequency - waveTime;
				//waveNoise = ( waveNoise - 0.5f ) * ( frac( wave + waveNoise ) < 0.5f ? -1.0f : 1.0f ) + 0.5f;
				wave += waveNoise;
				waveNoise2 = frac( wave / 2.0f ) < 0.5f ? waveNoise2 : 1.0f - waveNoise2;
				wave = frac( wave );
				wave -= 1.0f - frac( waveBase );
				wave *= 1.25f;
				wave = saturate( wave ) * waveNoise2;
				wave = wave * ( tex2D( FoWDiffuse, Input.pos.xz / 2.0f ).a / 2.0f + 0.5f );
				// outColor = lerp( outColor, float3( 0.19f, 0.2f, 0.22f ) * MAP_LIGHT_INTENSITY, wave );
				outColor = lerp( outColor, WAVE_COLOR.rgb, wave * WAVE_COLOR.a );
			}
			
			//outColor = ApplySnow( float4( outColor, 1.0f ), Input.pos, normal, vFoWColor, FoWDiffuse );		
			
			float4 vFoW = GetFoW( Input.pos, vFoWColor, FoWDiffuse );
	
			// Grab the shadow term
			float4 vShadowCoord = Input.vScreenCoord;
			vShadowCoord.xz = vShadowCoord.xz + normal.xz * vRefractionScale * 0.06f;
			float fShadowTerm = GetShadowScaled( SHADOW_WEIGHT_WATER, vShadowCoord, ShadowMap );
			outColor = ComposeSpecular( outColor, specular * ( 1.0f - vFoW.a ) );
			outColor = CalculateShadowLighting( outColor, fShadowTerm );

			outColor = ApplyFoW( ApplyDistanceFog( outColor, Input.pos ), vFoW );
			return float4( lerp( outColor, vTIColor.rgb, TI ), 1.0f - waterHeight );
		}
	]]
	
	MainCode PixelShaderLake
	[[
		float3 CalcWaterNormal( float2 uv, float vTimeSpeed )
		{
			float vScaledTime = vTime_HalfPixelOffset.x * vTimeSpeed;
			float vScaleUV =25.0f;
			float2 time1 = vScaledTime * float2( 0.3f, 0.7f );
			float2 time2 = -vScaledTime * 0.75f * float2( 0.8f, 0.2f );
			float2 uv1 = vScaleUV * uv;
			float2 uv2 = vScaleUV * uv * 1.3;
			float noiseScale = 12.0f;
			float3 noiseNormal1 = tex2D( WaterNoise, uv1 * noiseScale + time1 * 3.0f ).rgb - 0.5f;
			float3 noiseNormal2 = tex2D( WaterNoise, uv2 * noiseScale + time2 * 3.0f ).rgb - 0.5f;
			float3 normalNoise = noiseNormal1 + noiseNormal2 + float3( 0.0f, 0.0f, 15.0f );
			return normalize( /*normalWaves +*/ normalNoise ).xzy;
		}

		float4 ApplyIce( float4 vColor, float2 vPos, inout float3 vNormal, float4 vFoWColor, float2 vIceUV, out float vIceFade )
		{
			float vSnow = saturate( GetSnow(vFoWColor) - 0.2f ); 
			vIceFade = vSnow*8.0f;
			float4 vIceNormal = tex2D( IceNormal, vIceUV * 2.0f );
			float vIceNoise = tex2D( FoWDiffuse, ( vPos + 0.5f ) / 16.0f  ).a;
			vIceFade *= vIceNoise * 1.5f + 0.25f;
			vIceFade *= vIceNormal.a;
			float vMapLimitFade = saturate( saturate( (vPos.y/MAP_SIZE_Y) - 0.74f )*800.0f );
			vIceFade *= vMapLimitFade;
			vIceFade = saturate( ( vIceFade-0.5f ) * 2.0f );
			//vNormal = lerp( vNormal, tex2D( IceNormal, vIceUV ).rgb, vIceFade );
			vNormal = normalize( lerp( vNormal, normalize( vIceNormal.rbg - 0.5f ), vIceFade ) );
			//float4 vIceColor = tex2D( IceDiffuse, vIceUV );
			float3 vIceColor = lerp( float3(0.5f, 0.7f, 0.9f), float3(0.75f, 0.8f, 0.85f), saturate( vSnow * 2.0f ) );
			vColor.rgb /= vSnow * 4.0f + 1.0f;
			vColor.rgb = lerp( vColor.rgb, float3(0.75f, 0.8f, 0.85f), vIceFade * 0.875f );
			return vColor;
		}

		float4 main( VS_OUTPUT_WATER Input ) : PDX_COLOR
		{
			float waterHeight = Input.pos.y - ( tex2D( HeightTexture, Input.uv ).x * 51.0 );
			waterHeight = ( 0.9f - waterHeight ) * 1.2f;
			
			//if ( waterHeight > 0.99f )
			//	return float4( 0.0f, 1.0f, 0.0f, 1.0f );
			//else if ( waterHeight > 0.0f )
			//	return float4( 1.0f, 0.0f, 0.0f, 1.0f );
			//else
			//	return float4( 0.0f, 0.0f, 1.0f, 1.0f );
			
			//waterHeight = 0.5f - waterHeight;
			//waterHeight -= Input.pos.y;
			//waterHeight /= ( 93.7f / 255.0f );
			//waterHeight = saturate( ( waterHeight - 0.995f ) * 50.0f );
		
			float4 vFoWColor = GetFoWColor( Input.pos, FoWTexture);	
			float TI = GetTI( vFoWColor );	
			float4 vTIColor = GetTIColor( Input.pos, TITexture );

			if( ( TI - 0.99f ) * 1000.0f > 0.0f )
			{
				return float4( vTIColor.rgb, 1.0f - waterHeight );
			}

			float3 normal = CalcWaterNormal( Input.uv * WATER_TILE, vTimeScale * WATER_TIME_SCALE );

			//Ice effect
			float4 waterColor;
			
			if ( REPLACE_WATER_TEXTURE )
			{
				waterColor.rgb = ApplyWaterRamp( ( tex2D( HeightTexture, Input.uv ).x - 93.7f / 255.0f ) * WATER_CONTRAST + 93.7f / 255.0f );
			}
			else
			{
				waterColor = tex2D( WaterColor, Input.uv );
			}
			float vIceFade = 0.0f;
			waterColor = ApplyIce( waterColor, Input.pos.xz, normal, vFoWColor, Input.uv_ice, vIceFade );
			
			float3 vEyeDir = normalize( Input.pos - vCamPos.xyz );
			float3 reflection = reflect( vEyeDir, normal );

		#ifdef PDX_OPENGLES
			reflection.y *= -1.0f;
		#endif 
		
			float3 reflectiveColor = texCUBE( ReflectionCubeMap, reflection ).rgb;

		#ifdef PDX_OPENGLES
			float3 refractiveColor = float3(0.1, 0.3, 0.5);
			float vRefractionScale = saturate( 5.0f - ( Input.screen_pos.z / Input.screen_pos.w ) * 5.0f );
		#else
			float2 refractiveUV = ( Input.screen_pos.xy / Input.screen_pos.w ) * 0.5f + 0.5f;
			refractiveUV.y = 1.0f - refractiveUV.y;
			refractiveUV += vTime_HalfPixelOffset.gb;
			float vRefractionScale = saturate( 5.0f - ( Input.screen_pos.z / Input.screen_pos.w ) * 5.0f );
			float3 refractiveColor = tex2D( WaterRefraction, (refractiveUV.xy - normal.xz * vRefractionScale * 0.15f) ).rgb;
		#endif

			float fresnelBias = 0.0625f;
			float fresnel = saturate( dot( -vEyeDir, normal ) ) * 0.5f;
			fresnel = saturate( fresnelBias + ( 1.0f - fresnelBias ) * pow( 1.0f - fresnel, 10.0f ) );
			fresnel *= (1.0f-vIceFade); //No fresnel when we have snow
			
			float3 H = normalize( -vLightDir + -vEyeDir );
			float vSpecWidth = MAP_SIZE_X*0.9f;
			
			float vSpecMultiplier = 3.0f;
			float specular = saturate( pow( saturate( dot( H, normal ) ), vSpecWidth ) * vSpecMultiplier );
			
			refractiveColor = lerp( refractiveColor, waterColor.rgb, 0.3f+(0.7f*vIceFade) );
			float3 outColor = refractiveColor * ( 1.0f - fresnel ) + reflectiveColor * fresnel;
			
			outColor = ApplySnow( float4( outColor, 1.0f ), Input.pos, normal, vFoWColor, FoWDiffuse );		
			
			float4 vFoW = GetFoW( Input.pos, vFoWColor, FoWDiffuse );

			// Grab the shadow term
			float4 vShadowCoord = Input.vScreenCoord;
			vShadowCoord.xz = vShadowCoord.xz + normal.xz * vRefractionScale * 0.06f;
			float fShadowTerm = GetShadowScaled( SHADOW_WEIGHT_WATER, vShadowCoord, ShadowMap );
			outColor = CalculateShadowLighting( outColor, fShadowTerm );
			outColor = ComposeSpecular( outColor, specular * ( 1.0f - vFoW.a ) );

			outColor = ApplyFoW( ApplyDistanceFog( outColor, Input.pos ), vFoW );
			//return float4( waterHeight, 0.0f, 0.0f, 1.0f );
			return float4( lerp( outColor, vTIColor.rgb, TI ), 1.0f - waterHeight );
		}
	]]
	
	MainCode PixelShaderUnlit
	[[
		float4 main( VS_OUTPUT_WATER Input ) : PDX_COLOR
		{
			// Grab the shadow term
			float3 fShadowTerm = CalculateShadow( Input.vShadowProj, ShadowMap, (distance(vCamPos, Input.pos) + 1.0f) / 100.0f );		
			return float4( fShadowTerm.x, fShadowTerm.y, fShadowTerm.z, 1.0f );
		}
	]]

}


## Blend States

BlendState BlendState
{
	AlphaTest = no
	WriteMask = "RED|GREEN|BLUE"
	SourceBlend = "src_alpha"
	BlendEnable = yes
	DestBlend = "inv_src_alpha"
}

## Rasterizer States

## Depth Stencil States

## Effects

Effect water
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect waterunlit
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderUnlit"
}

Effect PdxLake
{
	VertexShader = "VertexShaderLake"
	PixelShader = "PixelShaderLake"
}