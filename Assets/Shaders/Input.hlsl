#ifndef XGJOY_INPUT
#define XGJOY_INPUT

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

float4 _CharacterLightDirection; //角色光照方向
float4 _CharacterLightColor; //角色光照颜色
float4 _CharacterShadowColor;
float _CharacterLightIntensity; //角色光照强度
float _SceneLightProbe; //场景是否开启了LightProbe

float _CharacterBloomAdd; //角色Bloom叠加
float _SceneBloomAdd; //场景Bloom叠加

float4x4 _InverseVPMatrix; //InverseVP矩阵

//Wind
float _WindPower;
float _WindSpeed;
float _WindFrequency;
float4 _WindDirection;


//SceneObject
TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
TEXTURE2D(_SSAOTex);            SAMPLER(sampler_SSAOTex);
TEXTURE2D(_NormalMap);          SAMPLER(sampler_NormalMap);

//HairShadowDepth
TEXTURE2D(_HairShadowDepth);    SAMPLER(sampler_HairShadowDepth); //头发深度图


//SH
float4 custom_SHAr;
float4 custom_SHAg;
float4 custom_SHAb;
float4 custom_SHBr;
float4 custom_SHBg;
float4 custom_SHBb;
float4 custom_SHC;
float custom_SH_Intensity;


#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
struct GPUItemStruct
{
    float3 Position;
    float4x4 Matrix;
};

StructuredBuffer<GPUItemStruct> posVisibleBuffer;
#endif


//ForwardPass
struct VertexInput
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    half4 screenPos : TEXCOORD1;
    half3 positionWS: TEXCOORD2;
    half3 normalWS : TEXCOORD3; 
    half3 tangentWS : TEXCOORD4; 
    half3 bitangentWS : TEXCOORD5; 
    half4 color : TEXCOORD6;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

//Simple
struct VertexInputSimple
{
    float4 positionOS : POSITION;
    float4 uv : TEXCOORD0;
    half3 normalOS : NORMAL;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutputSimple
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    half3 positionWS: TEXCOORD1;
    half3 normalWS : TEXCOORD2;
    half4 color : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

//Object
struct VertexInputObject
{
    float4 positionOS : POSITION;
    float4 uv : TEXCOORD0;
    float4 uv2 : TEXCOORD1;
    float3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutputObject
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    half3 positionWS: TEXCOORD1;
    half3 normalWS : TEXCOORD5;
    half4 color : TEXCOORD3;
    half4 screenPos : TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


//Outline
struct VertexOutputOutline
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 screenPos: TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


//Meta
struct VertexInputObjectMeta
{
    float4 positionOS : POSITION;
    float4 uv : TEXCOORD0;
    float4 uv2 : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutputObjectMeta
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    half3 positionWS: TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};



//DepthPrePass
struct VertexInputDepth
{
    float4 positionOS : POSITION;
    float4 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutputDepth
{
    float4 positionCS : SV_POSITION;
    float2 uv: TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


//DepthNormalsPrePass
struct VertexInputDepthNormals
{
    float4 positionOS : POSITION;
    float4 uv : TEXCOORD0;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutputDepthNormals
{
    float4 positionCS : SV_POSITION;
    float2 uv: TEXCOORD0;
    half3 normalWS : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


//ShadowCaster
struct VertexInputShadowCaster
{
    float4 positionOS   : POSITION;
    float4 uv: TEXCOORD0;
    float4 color: COLOR;
    float3 normalOS     : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutputShadowCaster
{
    float4 positionCS   : SV_POSITION;
    float2 uv: TEXCOORD0;
};





#endif