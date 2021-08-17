## Constant Buffers

ConstantBuffer( 0, 0 )
{
	float4x4 ViewProjectionMatrix;
	float4x4 ViewMatrix;
	float4x4 InvViewMatrix;
	float4x4 InvViewProjMatrix;
	float4 vMapSize;
	float3 vLightDir;
	float3 vCamPos;
	float3 vCamRightDir;
	float3 vCamLookAtDir;
	float3 vCamUpDir;
	float3 vFoWOpacity_Time;
}

## Shared Code

Code
[[
#ifndef STANDARDFUNCS_H_
#define STANDARDFUNCS_H_




// Photoshop filters, kinda...
float3 Hue( float H )
{
	float X = 1.0 - abs( ( mod( H, 2.0 ) ) - 1.0 );
	if ( H < 1.0f )			return float3( 1.0f,    X, 0.0f );
	else if ( H < 2.0f )	return float3(   X, 1.0f, 0.0f );
	else if ( H < 3.0f )	return float3( 0.0f, 1.0f,    X );
	else if ( H < 4.0f )	return float3( 0.0f,    X, 1.0f );
	else if ( H < 5.0f )	return float3(   X, 0.0f, 1.0f );
	else					return float3( 1.0f, 0.0f,    X );
}

float3 HSVtoRGB( in float3 HSV )
{
	if ( HSV.y != 0.0f )
	{
		float C = HSV.y * HSV.z;
		return clamp( Hue( HSV.x ) * C + ( HSV.z - C ), 0.0f, 1.0f );
	}
	return saturate( HSV.zzz );
}

float3 RGBtoHSV( in float3 RGB )
{
    float3 HSV = float3( 0, 0, 0 );
    HSV.z = max( RGB.r, max( RGB.g, RGB.b ) );
    float M = min( RGB.r, min( RGB.g, RGB.b ) );
    float C = HSV.z - M;
    
	if ( C != 0.0f )
    {
        HSV.y = C / HSV.z;

		float3 vDiff = ( RGB.gbr - RGB.brg ) / C;
		// vDiff.x %= 6.0f; // We make this operation after tweaking the value
		vDiff.yz += float2( 2.0f, 4.0f );

        if ( RGB.r == HSV.z )		HSV.x = vDiff.x;
        else if ( RGB.g == HSV.z )	HSV.x = vDiff.y;
        else						HSV.x = vDiff.z;
    }
    return HSV;
}

float3 GetOverlay( float3 vColor, float3 vOverlay, float vOverlayPercent )
{
	float3 res;
	res.r = vOverlay.r < .5 ? ( 2.0 * vOverlay.r * vColor.r ) : ( 1.0 - 2.0 * ( 1.0 - vOverlay.r ) * ( 1.0 - vColor.r ) );
	res.g = vOverlay.g < .5 ? ( 2.0 * vOverlay.g * vColor.g ) : ( 1.0 - 2.0 * ( 1.0 - vOverlay.g ) * ( 1.0 - vColor.g ) );
	res.b = vOverlay.b < .5 ? ( 2.0 * vOverlay.b * vColor.b ) : ( 1.0 - 2.0 * ( 1.0 - vOverlay.b ) * ( 1.0 - vColor.b ) );

	return lerp( vColor, res, vOverlayPercent );
}

float GetOverlay( float vColor, float vOverlay, float vOverlayPercent )
{
	float res;
	res = vOverlay < .5 ? ( 2.0 * vOverlay * vColor ) : ( 1.0 - 2.0 * ( 1.0 - vOverlay ) * ( 1.0 - vColor ) );

	return lerp( vColor, res, vOverlayPercent );
}

float3 GetLinearLight( float3 vColor, float3 vLinearLight, float vLinearLightPercent )
{
	float3 res = 2.0 * vLinearLight + vColor - 1.0;
	res = max( float3( 0, 0, 0 ), res );

	return lerp( vColor, res, vLinearLightPercent );
}

float4 ComposeOver( float4 vColor, float4 vOverlay ) {
	return float4( vOverlay.rgb * vOverlay.a + vColor.rgb * vColor.a * ( 1.0f - vOverlay.a ), vOverlay.a + vColor.a * ( 1.0f - vOverlay.a ) );
}

float3 Levels( float3 vInColor, float vMinInput, float vMaxInput )
{
	float3 vRet = vInColor - vMinInput;
	vRet /= vMaxInput - vMinInput;
	return saturate( vRet );
}

float3 UnpackNormal( in sampler2D NormalTex, float2 uv )
{
	float3 vNormalSample = normalize( tex2D( NormalTex, uv ).rgb - 0.5f );
	vNormalSample.g = -vNormalSample.g;
	return vNormalSample;
}

// Source: http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
float3 sRGBtoRGB( in float3 sRGB )// pow( sRGB, 2.2f )
{
	float3 RGB = sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
	return RGB;
}

float3 RGBtosRGB( in float3 RGB )// pow( RGB, 2.2f / 1.0f )
{
	float3 S1 = sqrt(RGB);
	float3 S2 = sqrt(S1);
	float3 S3 = sqrt(S2);
	float3 sRGB = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * RGB;
	return sRGB;
}

// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/
float3 ToneMap( float3 vColor )
{
	float srcLum = max(vColor.r, max(vColor.g, vColor.b));// Luminance : dot(vColor,float3(1,1,1)/3.0);
	float dstLum = srcLum / (srcLum + 1.0f);
	return vColor * (dstLum/srcLum);
}

float3 FalseColors( float3 vColor )
{
	return lerp( vColor, float3( 0.7f, 0.7f, 0.7f ), -2.0f );
}

float3 CalculateLighting( float3 vColor, float3 vNormal, float3 vLightDirection, float3 vAmbient, float3 vLightDiffuse, float vLightIntensity )
{
	float NdotL = dot( vNormal, -vLightDirection );
	float3 vLambert = saturate( NdotL ) * vLightDiffuse;
	vNormal.g = ( vNormal.g + 1.0f ) / 2.0f;
	vLambert += float3( 1, 1, 1 ) * ( vNormal.g * vAmbient + pow( ( 1.0f - vNormal.g ) / 1.5f, 2.2f ) );// vLambert = vAmbient + ( 1.0f - vAmbient ) * vLambert;
	vLambert *= vLightIntensity * sRGBtoRGB( vColor );
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float3 CalculateLighting( float3 vColor, float3 vNormal )
{
	return CalculateLighting( vColor, vNormal, vLightDir, AMBIENT, LIGHT_DIFFUSE, LIGHT_INTENSITY );
}

float3 CalculateLighting( float3 vColor, float3 vNormal, float fShadowTerm )// Static mesh
{
	float NdotL = dot( vNormal, -vLightDir );
	float3 vLambert = float3( 1, 1, 1 ) * saturate( NdotL ) * fShadowTerm;
	vNormal.g = ( vNormal.g + 1.0f ) / 2.0f;
	vLambert += float3( 1, 1, 1 ) * ( vNormal.g * AMBIENT + pow( ( 1.0f - vNormal.g ) / 1.5f, 2.2f ) );// vLambert = AMBIENT + ( 1.0f - AMBIENT ) * vLambert;
	vLambert *= LIGHT_INTENSITY * sRGBtoRGB( vColor );
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float3 CalculateTreeLighting( float3 vColor, float3 vNormal, float3 vNormalSmooth, float3 vSeasonColorMap, float fShadowTerm, float vSnowMask )
{
	vSeasonColorMap *= vSeasonColorMap * ( 1.0f - vSnowMask );// vSeasonColorMap = sRGBtoRGB( vSeasonColorMap ) * ( 1.0f - vSnowMask );
	float NdotL = dot( vNormal, -vLightDir );
	float NdotLSmooth = dot( vNormalSmooth, -vLightDir );
	float3 vLambert = float3( 1, 1, 1 ) * saturate( NdotL ) * fShadowTerm;
	float3 vLambertSmooth = float3( 1, 1, 1 ) * saturate( NdotLSmooth ) * fShadowTerm;
	vNormal.g = ( vNormal.g + 1.0f ) / 2.0f;
	vNormalSmooth.g = ( vNormalSmooth.g + 1.0f ) / 2.0f;
	vLambert += float3( 1, 1, 1 ) * ( vNormal.g * AMBIENT + pow( ( 1.0f - vNormalSmooth.g ) / 1.5f, 2.2f ) );// vLambert = AMBIENT + ( 1.0f - AMBIENT ) * vLambert;
	vLambertSmooth = vSeasonColorMap + ( 1.0f - vSeasonColorMap ) * vLambertSmooth;
	vLambert = vLambertSmooth + ( 1.0f - vLambertSmooth ) * vLambert;
	vLambert *= LIGHT_INTENSITY * sRGBtoRGB( vColor );
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float3 CalculateShadowLighting( float3 vColor, float fShadowTerm )
{
	float3 vLambert = float3( 1, 1, 1 ) * fShadowTerm;
	vLambert = MAP_AMBIENT + ( 1.0f - MAP_AMBIENT ) * vLambert;
	vLambert *= MAP_LIGHT_INTENSITY * sRGBtoRGB( vColor );
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float3 CalculateMapLighting( float3 vColor, float3 vNormal )
{
	return CalculateLighting( vColor, vNormal, vLightDir, MAP_AMBIENT, MAP_LIGHT_DIFFUSE, MAP_LIGHT_INTENSITY );
}

float3 CalculateMapLighting( float3 vColor, float3 vNormal, float fShadowTerm )
{
	float NdotL = dot( vNormal, -vLightDir );
	float3 vLambert = float3( 1, 1, 1 ) * saturate( NdotL ) * fShadowTerm;
	vNormal.g = ( vNormal.g + 1.0f ) / 2.0f;
	vLambert += float3( 1, 1, 1 ) * ( vNormal.g * MAP_AMBIENT + pow( ( 1.0f - vNormal.g ) / 1.5f, 2.2f ) * fShadowTerm );// vLambert = MAP_AMBIENT + ( 1.0f - MAP_AMBIENT ) * vLambert;
	vLambert *= MAP_LIGHT_INTENSITY * sRGBtoRGB( vColor );
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float3 CalculateMapLighting( float3 vColor, float3 vNormal, float fShadowTerm, float ao )
{
	float NdotL = dot( vNormal, -vLightDir );
	float3 vLambert = float3( 1, 1, 1 ) * saturate( NdotL ) * fShadowTerm;
	ao = 1.0f - ( 1.0f - ao) * ( 1.0f - vLambert.r);// Screen blend mode
	vNormal.g = ( vNormal.g + 1.0f ) / 2.0f;
	vLambert += float3( 1, 1, 1 ) * ( vNormal.g * MAP_AMBIENT + pow( ( 1.0f - vNormal.g ) / 1.5f, 2.2f ) * fShadowTerm );// vLambert = MAP_AMBIENT + ( 1.0f - MAP_AMBIENT ) * vLambert;
	vLambert *= ao;
	vLambert *= MAP_LIGHT_INTENSITY * sRGBtoRGB( vColor );
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float3 CalculateFogLighting( float3 vNormal )
{
	float NdotL = dot( vNormal, -vLightDir );
	float3 vLambert = FOW_COLOR * saturate( NdotL );
	vNormal.g = ( vNormal.g + 1.0f ) / 2.0f;
	vLambert += float3( 1, 1, 1 ) * ( vNormal.g * MAP_AMBIENT + pow( ( 1.0f - vNormal.g ) / 1.5f, 2.2f ) );// vLambert = MAP_AMBIENT * 2 + ( 1.0f - MAP_AMBIENT * 2 ) * vLambert;
	vLambert *= MAP_LIGHT_INTENSITY;
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float3 CalculateMapLighting( float3 vColor )
{
	float3 vLambert = MAP_AMBIENT + ( 1.0f - MAP_AMBIENT );
	vLambert *= MAP_LIGHT_INTENSITY * sRGBtoRGB( vColor );
	vLambert = ToneMap ( vLambert );
	return RGBtosRGB( vLambert );
}

float CalculateSpecular( float3 vPos, float3 vNormal, float vInIntensity )
{
	float3 H = normalize( -normalize( vPos - vCamPos ) + -vLightDir );
	float vSpecWidth = 10.0f;
	float vSpecMultiplier = 2.0f;
	return ( pow( saturate( dot( H, vNormal ) ), vSpecWidth ) * vSpecMultiplier ) * vInIntensity;
}

float3 CalculateSpecular( float3 vPos, float3 vNormal, float3 vInIntensity )
{
	float3 H = normalize( -normalize( vPos - vCamPos ) + -vLightDir );
	float vSpecWidth = 10.0f;
	float vSpecMultiplier = 2.0f;
	return ( pow( saturate( dot( H, vNormal ) ), vSpecWidth ) * vSpecMultiplier ) * vInIntensity;
}

float3 ComposeSpecular( float3 vColor, float vSpecular ) 
{
	return vColor + vSpecular;
}

float3 ComposeSpecular( float3 vColor, float3 vSpecular ) 
{
	return vColor + vSpecular;
}

float4 sample_terrain_copy( float IndexU, float IndexV, float2 vTileRepeat, float vMipTexels, float lod )
{
	const float NUM_TILES = 4.0f;
	
	vTileRepeat = frac( vTileRepeat );

#ifdef NO_SHADER_TEXTURE_LOD
	vTileRepeat *= 0.98;
	vTileRepeat += 0.01;
#endif
	
	float vTexelsPerTile = vMipTexels / NUM_TILES;

	vTileRepeat *= ( vTexelsPerTile - 1.0f ) / vTexelsPerTile;
	return float4( ( float2( IndexU, IndexV ) + vTileRepeat ) / NUM_TILES + 0.5f / vMipTexels, 0.0f, lod );
}

// http://sunandblackcat.com/tipFullView.php?topicid=28
float3 parallaxOcclusionMapping( float3 V, float IndexU, float IndexV, sampler2D TerrainNormal, float2 vTileRepeat, float vMipTexels, float lod, float parallaxMultiplier )
{
	float parallaxScale = 0.0625 * parallaxMultiplier;
	
	// determine optimal number of layers
	const float minLayers = 2.0;
	const float maxLayers = 8.0;
	float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), V))) * parallaxMultiplier;

	// height of each layer
	float layerHeight = 1.0 / numLayers;
	// current depth of the layer
	float curLayerHeight = 0.0;
	// shift of texture coordinates for each layer
	float2 dtex = parallaxScale * V.xy / V.z / numLayers;

	// current texture coordinates
	float2 currentTextureCoords = float2(IndexU, IndexV);

	// depth from heightmap
	float heightFromTexture = tex2Dlod( TerrainNormal, sample_terrain_copy( currentTextureCoords.x, currentTextureCoords.y, vTileRepeat, vMipTexels, lod ) ).a;
	heightFromTexture = 1.0f - heightFromTexture;

	// while point is above the surface
	while(heightFromTexture > curLayerHeight)
	{
		// to the next layer
		curLayerHeight += layerHeight;
		// shift of texture coordinates
		currentTextureCoords -= dtex;
		// new depth from heightmap
		heightFromTexture = tex2Dlod( TerrainNormal, sample_terrain_copy( currentTextureCoords.x, currentTextureCoords.y, vTileRepeat, vMipTexels, lod ) ).a;
	heightFromTexture = 1.0f - heightFromTexture;
	}

	///////////////////////////////////////////////////////////
	
	// previous texture coordinates
	float2 prevTCoords = currentTextureCoords + dtex;

	// heights for linear interpolation
	float nextH = heightFromTexture - curLayerHeight;
	float prevH = tex2Dlod( TerrainNormal, sample_terrain_copy( prevTCoords.x, prevTCoords.y, vTileRepeat, vMipTexels, lod ) ).a - curLayerHeight + layerHeight;

	// proportions for linear interpolation
	float weight = nextH / (nextH - prevH);

	// interpolation of texture coordinates
	float2 finalTexCoords = prevTCoords * weight + currentTextureCoords * (1.0-weight);

	// interpolation of depth values
	float parallaxHeight = curLayerHeight + prevH * weight + nextH * (1.0 - weight);

	// return result
	return float3(IndexU - finalTexCoords.x, IndexV - finalTexCoords.y, parallaxHeight);
} 

float3 reliefMapping( float3 V, float IndexU, float IndexV, sampler2D TerrainNormal, float2 vTileRepeat, float vMipTexels, float lod, float parallaxMultiplier )
{
	float parallaxScale = PARALLAX_SCALE * parallaxMultiplier;
	
	// determine required number of layers
	const float minLayers = 2.0;
	const float maxLayers = 8.0;
	float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), V))) * parallaxMultiplier;

	// height of each layer
	float layerHeight = 1.0 / numLayers;
	// depth of current layer
	float currentLayerHeight = 0.0;
	// shift of texture coordinates for each iteration
	float2 dtex = parallaxScale * V.xy / V.z / numLayers;

	// current texture coordinates
	float2 currentTextureCoords = float2(0, 0);

	// depth from heightmap
	float heightFromTexture = tex2Dlod( TerrainNormal, sample_terrain_copy( IndexU, IndexV, vTileRepeat, vMipTexels, lod ) ).a;
	heightFromTexture = 1.0f - heightFromTexture;

	// while point is above surface
	while(heightFromTexture > currentLayerHeight)
	{
		// go to the next layer
		currentLayerHeight += layerHeight;
		// shift texture coordinates along V
		currentTextureCoords -= dtex;
		// new depth from heightmap
		heightFromTexture = tex2Dlod( TerrainNormal, sample_terrain_copy( IndexU, IndexV, vTileRepeat + currentTextureCoords, vMipTexels, lod ) ).a;
	  heightFromTexture = 1.0f - heightFromTexture;
	}

	///////////////////////////////////////////////////////////
	// Start of Relief Parallax Mapping

	// decrease shift and height of layer by half
	float2 deltaTexCoord = dtex / 2.0;
	float deltaHeight = layerHeight / 2.0;

	// return to the mid point of previous layer
	currentTextureCoords += deltaTexCoord;
	currentLayerHeight -= deltaHeight;

	// binary search to increase precision of Steep Paralax Mapping
	const int numSearches = 5;
	for(int i=0; i<numSearches; i++)
	{
		// decrease shift and height of layer by half
		deltaTexCoord /= 2.0;
		deltaHeight /= 2.0;

		// new depth from heightmap
		heightFromTexture = tex2Dlod( TerrainNormal, sample_terrain_copy( IndexU, IndexV, vTileRepeat + currentTextureCoords, vMipTexels, lod ) ).a;
	  heightFromTexture = 1.0f - heightFromTexture;

		// shift along or agains vector V
		if(heightFromTexture > currentLayerHeight) // below the surface
		{
			currentTextureCoords -= deltaTexCoord;
			currentLayerHeight += deltaHeight;
		}
		else // above the surface
		{
			currentTextureCoords += deltaTexCoord;
			currentLayerHeight -= deltaHeight;
		}
	}

	return float3(float2(IndexU, IndexV) - currentTextureCoords, currentLayerHeight);
} 

float parallaxSoftShadowMultiplier(float3 L, float IndexU, float IndexV, float initialHeight, sampler2D TerrainNormal, float2 vTileRepeat, float vMipTexels, float lod, float parallaxMultiplier )
{
	float parallaxScale = PARALLAX_SCALE * parallaxMultiplier;

	float shadowMultiplier = 1.0;

	const float minLayers = 8.0;
	const float maxLayers = 32.0;

	// current texture coordinates
	float2 currentTextureCoords = float2(0, 0);

	// calculate lighting only for surface oriented to the light source
	if(dot( float3(0, 0, 1), L ) > 0.0)
	{
		// calculate initial parameters
		float numSamplesUnderSurface = 0.0;
		shadowMultiplier = 0.0;
		float numLayers = lerp(maxLayers, minLayers, abs(dot( float3(0, 0, 1), L ))) * parallaxMultiplier;
		float layerHeight = initialHeight / numLayers;
		float2 texStep = parallaxScale * L.xy / L.z / numLayers;

		// current parameters
		float currentLayerHeight = initialHeight - layerHeight;
		currentTextureCoords += texStep;
		float heightFromTexture = tex2Dlod( TerrainNormal, sample_terrain_copy( IndexU, IndexV, vTileRepeat + currentTextureCoords, vMipTexels, lod ) ).a;
		heightFromTexture = 1.0f - heightFromTexture;
		int stepIndex = 1;

		// while point is below depth 0.0 )
		while(currentLayerHeight > 0.0)
		{
			// if point is under the surface
			if(heightFromTexture < currentLayerHeight)
			{
				// calculate partial shadowing factor
				numSamplesUnderSurface += 1;
				float newShadowMultiplier = (currentLayerHeight - heightFromTexture) *
															(1.0 - float( stepIndex ) / numLayers);
				shadowMultiplier = max(shadowMultiplier, newShadowMultiplier);
			}

			// offset to the next layer
			stepIndex += 1;
			currentLayerHeight -= layerHeight;
			currentTextureCoords += texStep;
			heightFromTexture = tex2Dlod( TerrainNormal, sample_terrain_copy( IndexU, IndexV, vTileRepeat + currentTextureCoords, vMipTexels, lod ) ).a;
			heightFromTexture = 1.0f - heightFromTexture;
		}

		// Shadowing factor should be 1 if there were no points under the surface
		if(numSamplesUnderSurface < 1.0)
		{
			shadowMultiplier = 1.0;
		}
		else
		{
			shadowMultiplier = 1.0 - shadowMultiplier;
		}
	}
	
	shadowMultiplier = saturate( shadowMultiplier * 8.0 - 7.0 );
	
	return shadowMultiplier;
} 

// http://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch25.html
float filterwidth(float2 v)
{
	#ifdef PDX_OPENGL
		#ifdef PIXEL_SHADER
			return (abs(fwidth(v.x)) + abs(fwidth(v.y))) / 2.0f;
		#else
			return 0.002f;
		#endif //PIXEL_SHADER
	#else
		float2 fw = max(abs(ddx(v)), abs(ddy(v)));
		return (fw.x + fw.y) / 2.0f;// return max(fw.x, fw.y);
	#endif //PDX_OPENGL
}

float3 ApplyWaterRamp( float value )
{
	#ifdef PDX_OPENGL
	float4 WATER_RAMP[WATER_RAMP_STOP];
	WATER_RAMP[0] = float4(0.0f, 0.0f, 0.0f, 0.0f);
	WATER_RAMP[1] = float4(0.0f, 0.004f, 0.055f, 0.01f);
	WATER_RAMP[2] = float4(0.0f, 0.07f, 0.18f, 0.15f);
	WATER_RAMP[3] = float4(0.008f, 0.129f, 0.271f, 0.25f);
	WATER_RAMP[4] = float4(0.016f, 0.184f, 0.357f, 0.29f);
	WATER_RAMP[5] = float4(0.031f, 0.282f, 0.482f, 0.345f);
	WATER_RAMP[6] = float4(0.051f, 0.553f, 0.58f, 0.37f);
	WATER_RAMP[7] = float4(0.059f, 0.388f, 0.502f, 0.38f);
	#endif
	
	float3 color = WATER_RAMP[0].rgb;
	for ( int i = 1; i < WATER_RAMP_STOP; i++ ) {
		if ( value < WATER_RAMP[i].a )
		{
			color = lerp( WATER_RAMP[i-1].rgb, WATER_RAMP[i].rgb, ( value - WATER_RAMP[i-1].a ) / ( WATER_RAMP[i].a - WATER_RAMP[i-1].a ) );
			break;
		}
		else if (i == WATER_RAMP_STOP - 1)
		{
			color = WATER_RAMP[WATER_RAMP_STOP - 1].rgb;
		}
	}
	return color * WATER_COLOR_MULTIPLIER;
}

float4 GetProvinceColor( float2 Coord, in sampler2D IndirectionMap, in sampler2D ColorMap, float2 ColorMapSize )
{
	float2 ColorIndex = tex2D( IndirectionMap, Coord ).xy;
	return tex2D( ColorMap, float2( ColorIndex.x, ( ( ColorIndex.y * 255.0 ) / ( ColorMapSize.y - 1 ) ) ) ); // Assume ColorMapSize.x is 256
}

float4 GetProvinceColorSampled( float2 Coord, in sampler2D IndirectionMap, float2 IndirectionMapSize, in sampler2D ColorMap, float2 ColorMapSize )
{
	float2 Pixel = Coord * IndirectionMapSize + 0.5;
	float2 InvTextureSize = 1.0 / IndirectionMapSize;

	float2 FracCoord = frac( Pixel );
	Pixel = floor( Pixel ) / IndirectionMapSize - InvTextureSize / 2.0;

	float4 C11 = GetProvinceColor( Pixel, IndirectionMap, ColorMap, ColorMapSize );
	float4 C21 = GetProvinceColor( Pixel + float2( InvTextureSize.x, 0.0 ), IndirectionMap, ColorMap, ColorMapSize );
	float4 C12 = GetProvinceColor( Pixel + float2( 0.0, InvTextureSize.y ), IndirectionMap, ColorMap, ColorMapSize );
	float4 C22 = GetProvinceColor( Pixel + InvTextureSize, IndirectionMap, ColorMap, ColorMapSize );

	float4 x1 = lerp( C11, C21, FracCoord.x );
	float4 x2 = lerp( C12, C22, FracCoord.x );
	return lerp( x1, x2, FracCoord.y );
}

float3 ApplyDistanceFog( float3 vColor, float3 vPos )
{
	float3 vDiff = vCamPos - vPos;
	float vFogFactor = 1.0f - abs( normalize( vDiff ).y ); // abs b/c of reflections
	float vSqDistance = dot( vDiff, vDiff );

	float vBegin = FOG_BEGIN;
	float vEnd = FOG_END;
	vBegin *= vBegin;
	vEnd *= vEnd;
	
	float vMaxFog = FOG_MAX;
	
	float vMin = min( ( vSqDistance - vBegin ) / ( vEnd - vBegin ), vMaxFog );

	return lerp( vColor, FOG_COLOR, saturate( vMin ) * vFogFactor );
}

float4 GetProvinceColor( float2 Coord, in sampler2D IndirectionMap, in sampler2D ColorMap, float2 ColorMapSize, float TextureIndex )
{
	float2 ColorIndex = tex2D( IndirectionMap, Coord ).xy;
	ColorIndex.y = ( ColorIndex.y * 255.0 ) / ( ( ColorMapSize.y * 2 ) - 1 ) + ( TextureIndex * 0.5 );
	return tex2D( ColorMap, ColorIndex );
}

float4 GetProvinceColorSampled( float2 Coord, in sampler2D IndirectionMap, float2 IndirectionMapSize, in sampler2D ColorMap, float2 ColorMapSize, float TextureIndex )
{
	float2 Pixel = Coord * IndirectionMapSize + 0.5;
	float2 InvTextureSize = 1.0 / IndirectionMapSize;

	float2 FracCoord = frac( Pixel );
	Pixel = floor( Pixel ) / IndirectionMapSize - InvTextureSize / 2.0;

	float4 C11 = GetProvinceColor( Pixel, IndirectionMap, ColorMap, ColorMapSize, TextureIndex );
	float4 C21 = GetProvinceColor( Pixel + float2( InvTextureSize.x, 0.0 ), IndirectionMap, ColorMap, ColorMapSize, TextureIndex );
	float4 C12 = GetProvinceColor( Pixel + float2( 0.0, InvTextureSize.y ), IndirectionMap, ColorMap, ColorMapSize, TextureIndex );
	float4 C22 = GetProvinceColor( Pixel + InvTextureSize, IndirectionMap, ColorMap, ColorMapSize, TextureIndex );

	float4 x1 = lerp( C11, C21, FracCoord.x );
	float4 x2 = lerp( C12, C22, FracCoord.x );
	return lerp( x1, x2, FracCoord.y );
}

float4 GetFoWColor( float3 vPos, in sampler2D FoWTexture )
{
	return tex2D( FoWTexture, float2( ( ( vPos.x + 0.5f ) / MAP_SIZE_X ) * FOW_POW2_X, ( ( vPos.z + 0.5f ) / MAP_SIZE_Y ) * FOW_POW2_Y ) );
}

float GetTI( float4 vFoWColor )
{
	return vFoWColor.r;
}

float4 GetTIColor( float3 vPos, in sampler2D TITexture )
{
	return tex2D( TITexture, ( vPos.xz + 0.5f ) / float2( 1876.0f, 2048.0f ) );
}

float4 GetFoW( float3 vPos, float4 vFoWColor, in sampler2D FoWDiffuse, float localOpacity )
{
	if ( FOW_OPACITY * localOpacity > 0.0f )
	{
		float vIsFow = 1.0f - vFoWColor.a;
		if ( FOW_FLAT && FOW_CONTRAST == 0.0f )
		{
			return float4( FOW_COLOR, vIsFow * FOW_OPACITY * localOpacity * vFoWOpacity_Time.x );
		}
		else
		{
			
			float offset = vFoWOpacity_Time.y * FOW_TIME_SCALE;
			
			float4 vFoWDiffuse1 = tex2D( FoWDiffuse, ( vPos.xz ) / FOW_SCALE + offset );
			float4 vFoWDiffuse2 = tex2D( FoWDiffuse, float2( ( vPos.x + FOW_SCALE * 0.875f ) / FOW_SCALE + offset, ( vPos.z + FOW_SCALE * 0.75f ) / FOW_SCALE - offset ) );
			float4 vFoWDiffuse3 = tex2D( FoWDiffuse, float2( ( vPos.x + FOW_SCALE * 0.625f ) / FOW_SCALE - offset, ( vPos.z + FOW_SCALE * 0.5f ) / FOW_SCALE - offset ) );
			float4 vFoWDiffuse4 = tex2D( FoWDiffuse, float2( ( vPos.x + FOW_SCALE * 0.375f ) / FOW_SCALE - offset, ( vPos.z + FOW_SCALE * 0.25f ) / FOW_SCALE + offset ) );

			float4 vFoWDiffuse = ( lerp(vFoWDiffuse1, vFoWDiffuse3, ( vFoWDiffuse2.a + vFoWDiffuse4.a ) / 2.0f ) + lerp(vFoWDiffuse2, vFoWDiffuse4, ( vFoWDiffuse1.a + vFoWDiffuse2.a ) / 2.0f ) ) / 2.0f;
			
			vFoWDiffuse.a = GetOverlay(vFoWDiffuse.a, vFoWDiffuse.a, 2.0f);
			vFoWDiffuse.a = saturate( ( vFoWDiffuse.a - 0.5f ) * FOW_CONTRAST + 0.5f );
			vFoWDiffuse.a *= vIsFow * FOW_OPACITY * localOpacity * vFoWOpacity_Time.x;
			if ( FOW_FLAT )
			{
				//return lerp( float4( 0, 0, 0, 0 ), float4( 0, 0, 0, vFoWDiffuse.a ), vFoWOpacity_Time.x );
				return float4( FOW_COLOR, vFoWDiffuse.a );
			}
			else
			{
				vFoWDiffuse.rgb = CalculateFogLighting( normalize( vFoWDiffuse.rbg - 0.5f ) );
				return vFoWDiffuse;
				//return lerp( float4(0, 0, 0, vFoWDiffuse.a), float4( vFoWDiffuse.rgb, 1.0f ), vFoWDiffuse.a );
			}
		}
	}
	else
	{
		return float4( 0, 0, 0, 0 );
	}
}

float4 GetFoW( float3 vPos, float4 vFoWColor, in sampler2D FoWDiffuse )
{
	return GetFoW( vPos, vFoWColor, FoWDiffuse, 1.0f );
}

float3 ApplyFoW( float3 vColor, float4 vFOW )
{
	return lerp( lerp( vColor, float3( 0, 0, 0 ), vFOW.a ), vFOW.rgb, vFOW.a );
}

float3 ApplyDistanceFog( float3 vColor, float3 vPos, float4 vFoWColor, in sampler2D FoWDiffuse, float localOpacity )
{
	float4 vFOW = GetFoW( vPos, vFoWColor, FoWDiffuse, localOpacity );
	return ApplyFoW( ApplyDistanceFog( vColor, vPos ), vFOW );
}

float3 ApplyDistanceFog( float3 vColor, float3 vPos, float4 vFoWColor, in sampler2D FoWDiffuse )
{
	return ApplyDistanceFog( vColor, vPos, vFoWColor, FoWDiffuse, 1.0f );
}

const static float SNOW_START_HEIGHT 	= 18.0f;
const static float SNOW_RIDGE_START_HEIGHT 	= 22.0f;// No longer used
const static float SNOW_NORMAL_START 	= 0.7f;// No longer used
const static float3 SNOW_COLOR = float3( 0.7f, 0.7f, 0.7f );
const static float3 SNOW_WATER_COLOR = float3( 0.05f, 0.15f, 0.15f );

float GetSnow( float4 vFoWColor )
{
	return lerp( vFoWColor.b, vFoWColor.g, vFoWOpacity_Time.z );
}

float3 ApplySnow( float4 vColor, float3 vPos, inout float3 vNormal, float4 vFoWColor, in sampler2D FoWDiffuse, float3 vSnowColor )
{
	float vSnowFade = saturate( vPos.y - SNOW_START_HEIGHT );

	float vNoise = tex2D( FoWDiffuse, ( vPos.xz + 0.5f ) / 200.0f ).a;
	
	float vSnowTexture = tex2D( FoWDiffuse, ( vPos.xz + 0.5f ) / 100.0f ).a;
	float vSnowTexture2 = tex2D( FoWDiffuse, ( -vPos.xz + 0.5f ) / 50.0f ).a;
	float vSnowTexture3 = tex2D( FoWDiffuse, ( vPos.xz + 0.5f ) / 25.0f ).a;
	float vSnowTexture4 = tex2D( FoWDiffuse, ( -vPos.xz + 0.5f ) / 12.5f ).a;
	
	float vIsSnow = GetSnow( vFoWColor );
	float vAltitude = ( vPos.y - SNOW_START_HEIGHT ) / ( 48.0f - SNOW_START_HEIGHT );

	vSnowFade = GetOverlay( GetOverlay( GetOverlay( GetOverlay( GetOverlay( vIsSnow, vSnowTexture4, 0.05f ), vSnowTexture3, 0.05f ), vSnowTexture2, 0.05f ), vSnowTexture, 0.05f ), vNoise, 0.05f );
	float vNormalFade = saturate( ( ( 1.0f - vColor.a ) * ( vIsSnow - 0.25f ) ) * 16.0f + vNormal.y * ( vSnowFade * 0.875f + 0.125f ) );
	vNormalFade = saturate( GetOverlay( vNormalFade, vNormalFade, 4.0f ) );
	
	vColor.rgb = lerp( vColor.rgb, vSnowColor, vNormalFade );
	
	if ( FALSE_COLORS )
	{
		vColor.rgb = FalseColors( vColor.rgb );
	}
	return vColor.rgb;
}

float3 ApplySnow( float4 vColor, float3 vPos, inout float3 vNormal, float4 vFoWColor, in sampler2D FoWDiffuse )
{
	return ApplySnow( vColor, vPos, vNormal, vFoWColor, FoWDiffuse, SNOW_COLOR );
}

float3 ApplyWaterSnow( float3 vColor, float3 vPos, inout float3 vNormal, float4 vFoWColor, in sampler2D FoWDiffuse )
{
	return ApplySnow( float4( vColor, 1.0f ), vPos, vNormal, vFoWColor, FoWDiffuse, SNOW_WATER_COLOR );
}

#endif // STANDARDFUNCS_H_
]]
