## Constant Buffers



## Shared Code

Code
[[
#ifndef CONSTANTS_H_
#define CONSTANTS_H_

#define AD_LUCEM

// --------------------------------------------------------------
// A collection of constants that can be used to tweak the shaders
// To update: run "reloadfx all"
// --------------------------------------------------------------

// --------------------------------------------------------------
// ------------------    Light          -------------------------
// --------------------------------------------------------------


static const float3 LIGHT_DIFFUSE				= float3( 1.0f, 1.0f, 1.0f );
static const float  LIGHT_INTENSITY   			= 1.2f;
static const float  AMBIENT						= 0.2f;
static const float3 MAP_LIGHT_DIFFUSE			= float3( 1.0f, 1.0f, 1.0f );
static const float  MAP_LIGHT_INTENSITY   		= 1.5f;
static const float  MAP_AMBIENT					= 0.0f;
static const float	LIGHT_HDR_RANGE 			= 0.8f;

// LIGHT_DIRECTION_X = -1.0						defines.lua   (reload defines)
// LIGHT_DIRECTION_Y = -1.0						defines.lua   (reload defines)
// LIGHT_DIRECTION_Z = 0.5						defines.lua   (reload defines)

// --------------------------------------------------------------
// ------------------    TERRAIN        -------------------------
// --------------------------------------------------------------

static const float 	TERRAIN_TILE_FREQ 			= 128.0f;

// MILD_WINTER_VALUE = ###,						defines.lua   (reload defines)
// NORMAL_WINTER_VALUE = ##,					defines.lua   (reload defines)
// SEVERE_WINTER_VALUE = ###,					defines.lua   (reload defines)


static const float 	BORDER_TILE					= 0.4f;
// BORDER_WIDTH		= ###						defines.lua   (reload defines)



// Snow color									standardfuncsgfx.fxh   
// const static float3 SNOW_COLOR = float3( 0.8f, 0.8f, 0.8f );
// Snow fade									standardfuncsgfx.fxh   
// 	float vSnow = saturate( saturate( vNoise - ( 1.0f - vIsSnow ) ) * 5.0f );

static const float 	TREE_SEASON_MIN 			= 0.5f;
static const float 	TREE_SEASON_FADE_TWEAK 		= 2.5f;

static const bool   PARALLAX					= true;
static const float  PARALLAX_SCALE				= 0.0625f;
static const bool   FALSE_COLORS				= false;
static const float  TERRAIN_COLOR_SATURATION	= 0.75f;
static const float  TERRAIN_COLOR_MULTIPLIER	= 1.0f;
static const float  TERRAIN_COLOR_OPACITY_NEAR	= 1.0f;
static const float  TERRAIN_COLOR_OPACITY_FAR	= 1.0f;
static const float  TERRAIN_COLOR_MIN_HEIGHT	= 60.0f;
static const float  TERRAIN_COLOR_MAX_HEIGHT	= 300.0f;
static const float3 SELECTION_DASH_COLOR_1		= float3( 0.1f, 0.1f, 0.1f );
static const float3 SELECTION_DASH_COLOR_2		= float3( 1.0f, 1.0f, 1.0f );
static const float4 MAP_NAME_COLOR				= float4( 0.0f, 0.0f, 0.0f, 0.75f );
static const float4 MAP_NAME_GLOW				= float4( 0.566f, 0.566f, 0.566f, 0.75f );


// --------------------------------------------------------------
// ------------------    WATER          -------------------------
// --------------------------------------------------------------


static const float 	WATER_TILE					= 1.0f;
static const float 	WATER_TIME_SCALE			= 12.0f;

static const bool   REPLACE_WATER_TEXTURE		= true;
static const float  WATER_CONTRAST				= 1.0f;
static const float  WATER_COLOR_MULTIPLIER		= 1.0f;
static const int	WATER_RAMP_STOP				= 8;
#ifndef PDX_OPENGL
static const float4 WATER_RAMP[WATER_RAMP_STOP] =
{
	float4(0.0f, 0.0f, 0.0f, 0.0f),
	float4(0.0f, 0.004f, 0.055f, 0.01f),
	float4(0.0f, 0.07f, 0.18f, 0.15f),
	float4(0.008f, 0.129f, 0.271f, 0.25f),
	float4(0.016f, 0.184f, 0.357f, 0.29f),
	float4(0.031f, 0.282f, 0.482f, 0.345f),
	float4(0.051f, 0.553f, 0.58f, 0.37f),
	float4(0.059f, 0.388f, 0.502f, 0.38f)
};
#endif
static const float  UNDERWATER_COLOR_MULTIPLIER	= 1.0f;
static const bool   WAVES						= true;
static const float4 WAVE_COLOR					= float4( 0.75f, 0.82f, 0.88f, 1.0f );
static const float  WAVE_DISTANCE				= 5.7f;


// --------------------------------------------------------------
// ------------------    BUILDINGS      -------------------------
// --------------------------------------------------------------

//	PORT_SHIP_OFFSET = 2.0,					defines.lua   (reload defines)
//	SHIP_IN_PORT_SCALE = 0.25,				
//  BUILDING SIZE?



// --------------------------------------------------------------
// ------------------    FOG            -------------------------
// --------------------------------------------------------------

static const float 	FOG_BEGIN					= 80.0f;
static const float 	FOG_END 					= 150.0f;
static const float 	FOG_MAX 					= 0.7f;
static const float3 FOG_COLOR 					= float3( 0.5f, 0.5f, 0.6f );


// --------------------------------------------------------------
// ------------------    BUILDINGS      -------------------------
// --------------------------------------------------------------


static const float  SHADOW_WEIGHT_TERRAIN    	= 1.0f;
static const float  SHADOW_WEIGHT_MAP    		= 1.0f;
static const float  SHADOW_WEIGHT_BORDER   		= 1.0f;
static const float  SHADOW_WEIGHT_WATER   		= 0.8f;
static const float  SHADOW_WEIGHT_RIVER   		= 1.0f;
static const float  SHADOW_WEIGHT_TREE   		= 1.0f;

// LIGHT_SHADOW_DIRECTION_X = -8.0				defines.lua   (reload defines)
// LIGHT_SHADOW_DIRECTION_Y = -8.0				defines.lua   (reload defines)
// LIGHT_SHADOW_DIRECTION_Z = 5.0				defines.lua   (reload defines)


// --------------------------------------------------------------
// ------------------    CAMERA         -------------------------
// --------------------------------------------------------------



// CAMERA_MIN_HEIGHT = 50.0,					defines.lua   (reload defines)
// CAMERA_MAX_HEIGHT = 3000.0,					defines.lua   (reload defines)



// --------------------------------------------------------------
// ------------------    FOW            -------------------------
// --------------------------------------------------------------

static const float3	FOW_COLOR 					= float3( 1.0f, 1.0f, 1.0f );
static const float 	FOW_SCALE 					= 512.0f;
static const float 	FOW_TIME_SCALE 				= 0.005f;
static const bool   FOW_FLAT 					= false;
static const float 	FOW_CONTRAST 				= 0.5f;
static const float 	FOW_OPACITY 				= 0.875f;
static const float 	FOW_WEIGHT_BORDER			= 1.0f;
static const float 	FOW_WEIGHT_MAP_NAME			= 0.5f;


#endif //CONSTANTS_H_
]]
