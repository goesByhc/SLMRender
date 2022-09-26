#ifndef XGJOY_CORE
#define XGJOY_CORE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
#include "./Noise.hlsl"

#include "./optimized-ggx.hlsl"
#include "./Input.hlsl"

//Utils

half3 GetFinalLightColor(float3 normalWS)
{
    half3 sh = SampleSH(normalWS);
    half3 indirectDiffuse = lerp(half3(0,0,0), sh, _SceneLightProbe);
    half3 lightColor = _CharacterLightColor.rgb * _CharacterLightIntensity + indirectDiffuse;

    //TODO:叠加点光源
    return lightColor;
}

half GetCharacterFinalBloom(half bloomFactor)
{
    return clamp(1.0 - (bloomFactor + _CharacterBloomAdd), 0.0, 0.999);
}

half GetSceneObjectOpaqueFinalBloom(float bloomFactor)
{
    return clamp(1.0 - bloomFactor  - _SceneBloomAdd, 0.0 , 0.999 );
}

half4 GetSceneObjectTransparentFinalBloom(float bloomFactor, float originAlpha)
{
    bloomFactor = bloomFactor + _SceneBloomAdd;
    half finalBloom = clamp(1.0 - bloomFactor * 0.45 * originAlpha * originAlpha, 0.0, 0.999);
    return half4(1, 1, 1, finalBloom);
}

float3 RotateAround(float degree, float3 target)
{
    float rad = degree * PI / 180;
    float2x2 m_rotate = float2x2(cos(rad), -sin(rad),
            sin(rad), cos(rad));
    float2 dir_rotate = mul(m_rotate, target.xz);
    target = float3(dir_rotate.x, target.y, dir_rotate.y);
    return target;
}

inline float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

half3 Saturation(half3 color, half saturation )
{
    half grayColor = dot(float3(0.2125, 0.7154, 0.0721), color);
    half3 grayedColor = half3(grayColor, grayColor, grayColor);
    return lerp(grayedColor, color, saturation);
}

half StepAntialiasing(half a, half b)
{
    half c = b - a;
    return saturate(c / fwidth(c));
}

half Remap(half x, half minOld, half maxOld, half minNew, half maxNew)
{
    return (x - minOld) / (maxOld - minOld) * (maxNew - minNew) + minNew;
}


float3 WorldPosFromScreenDepth(float2 screenPos, float depth)
{
    #if UNITY_REVERSED_Z
    depth = 1 - depth;
    #endif
    float4 ndc = float4(screenPos.x * 2 - 1, screenPos.y * 2 - 1, depth * 2 - 1, 1);
    float4 worldPos = mul(_InverseVPMatrix, ndc);
    worldPos /= worldPos.w;
    return worldPos.xyz;
}

float4 URPDecodeInstruction()
{
    return float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0, 0);
}

float3 SampleLightmap(float2 uv)
{
    float4 lightMap = SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, uv);
    float4 decode_instructions = URPDecodeInstruction();
    float3 decodeLightMap = DecodeLightmap(lightMap, decode_instructions);
    return max(decodeLightMap, 0.0001);
}


float3 AdditionalLightsFlat( float3 WorldPosition )
{
    float3 Color = 0;
    #ifdef _ADDITIONAL_LIGHTS
    int numLights = GetAdditionalLightsCount();
    for(int i = 0; i<numLights;i++)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        Color += light.color * (light.distanceAttenuation * light.shadowAttenuation);
    }
    #endif
    return Color;
}

float3 AdditionalLightsHalfLambert( float3 WorldPosition, float3 WorldNormal )
{
    float3 Color = 0;
    #ifdef _ADDITIONAL_LIGHTS
    int numLights = GetAdditionalLightsCount();
    for(int i = 0; i<numLights;i++)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        half3 AttLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        Color += (dot(light.direction, WorldNormal)*0.5+0.5 )* AttLightColor;
    }
    #endif
    return Color;
}

float3 AdditionalLightsLambert( float3 WorldPosition, float3 WorldNormal )
{
    float3 Color = 0;
    #ifdef _ADDITIONAL_LIGHTS
    int numLights = GetAdditionalLightsCount();
    for(int i = 0; i<numLights;i++)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        half3 AttLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        Color += LightingLambert(AttLightColor, light.direction, WorldNormal);
    }
    #endif
    return Color;
}

float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
{
    original -= center;
    float C = cos( angle );
    float S = sin( angle );
    float t = 1 - C;
    float m00 = t * u.x * u.x + C;
    float m01 = t * u.x * u.y - S * u.z;
    float m02 = t * u.x * u.z + S * u.y;
    float m10 = t * u.x * u.y + S * u.z;
    float m11 = t * u.y * u.y + C;
    float m12 = t * u.y * u.z - S * u.x;
    float m20 = t * u.x * u.z - S * u.y;
    float m21 = t * u.y * u.z + S * u.x;
    float m22 = t * u.z * u.z + C;
    float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
    return mul( finalMatrix, original ) + center;
}


half3 mod2D289( half3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
half2 mod2D289( half2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
half3 permute( half3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

//在安卓上有问题，原因待查
half snoise( half2 v )
{
    const half4 C = half4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
    half2 i = floor( v + dot( v, C.yy ) );
    half2 x0 = v - i + dot( i, C.xx );
    half2 i1;
    i1 = ( x0.x > x0.y ) ? half2( 1.0, 0.0 ) : half2( 0.0, 1.0 );
    half4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod2D289( i );
    half3 p = permute( permute( i.y + half3( 0.0, i1.y, 1.0 ) ) + i.x + half3( 0.0, i1.x, 1.0 ) );
    half3 m = max( 0.5 - half3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
    m = m * m;
    m = m * m;
    half3 x = 2.0 * frac( p * C.www ) - 1.0;
    half3 h = abs( x ) - 0.5;
    half3 ox = floor( x + 0.5 );
    half3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
    half3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return (130.0 * dot( m, g )) * 0.5 + 0.5;
}



half AlphaClip(half alpha, half cutoff)
{
#ifdef _ALPHATEST_ON
    clip(alpha - cutoff);
#endif

    return alpha;
}

void AlphaClip(half alpha)
{
#ifdef _ALPHATEST_ON
    clip(alpha - 0.5);
#endif
}



half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
{
    const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    half4 r = Roughness * c0 + c1;
    half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
    half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;
    return SpecularColor * AB.x + AB.y;
}

float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

inline half4 Pow5 (half4 x)
{
    return x*x * x*x * x;
}

inline half3 FresnelTerm (half3 F0, half cosA)
{
    half t = Pow5 (1 - cosA).x;   // ala Schlick interpoliation
    return F0 + (1-F0) * t;
}


inline half3 GetWorldScale()
{
    half3 worldScale =
         float3(
       length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
       length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
       length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))  // scale z axis
       );

    return worldScale;
}

float4 GetBillboardPositionCS(float4 positionOS)
{
    float3 worldScale = GetWorldScale();

    return mul(UNITY_MATRIX_P,
            mul(UNITY_MATRIX_MV, float4(0.0, 0.0, 0.0, 1.0)) + float4(positionOS.x, positionOS.y, 0.0, 0.0) * float4(worldScale.x, worldScale.y, 1.0, 1.0)
        ); 
}

void Unity_SampleGradient_float(Gradient Gradient, float Time, out float4 Out)
{
    float3 color = Gradient.colors[0].rgb;
    [unroll]
    for (int c = 1; c < 8; c++)
    {
        float colorPos = saturate((Time - Gradient.colors[c-1].w) / (Gradient.colors[c].w - Gradient.colors[c-1].w)) * step(c, Gradient.colorsLength-1);
        color = lerp(color, Gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), Gradient.type));
    }
    #ifndef UNITY_COLORSPACE_GAMMA
    color = SRGBToLinear(color);
    #endif
    float alpha = Gradient.alphas[0].x;
    [unroll]
    for (int a = 1; a < 8; a++)
    {
        float alphaPos = saturate((Time - Gradient.alphas[a-1].y) / (Gradient.alphas[a].y - Gradient.alphas[a-1].y)) * step(a, Gradient.alphasLength-1);
        alpha = lerp(alpha, Gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), Gradient.type));
    }
    Out = float4(color, alpha);
}

void Unity_Blend_SoftLight_float4(float4 Base, float4 Blend, float Opacity, out float4 Out)
{
    float4 result1 = 2.0 * Base * Blend + Base * Base * (1.0 - 2.0 * Blend);
    float4 result2 = sqrt(Base) * (2.0 * Blend - 1.0) + 2.0 * Base * (1.0 - Blend);
    float4 zeroOrOne = step(0.5, Blend);
    Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
    Out = lerp(Base, Out, Opacity);
}

void Unity_Blend_Screen_float4(float4 Base, float4 Blend, float Opacity, out float4 Out)
{
    Out = 1.0 - (1.0 - Blend) * (1.0 - Base);
    Out = lerp(Base, Out, Opacity);
}

void Unity_Blend_Multiply_float4(float4 Base, float4 Blend, float Opacity, out float4 Out)
{
    Out = Base * Blend;
    Out = lerp(Base, Out, Opacity);
}


void Unity_SampleGradientTexture(UnityTexture2D GradientTexture, float Time, out float4 Color)
{
    float2 uv = float2(Time, 0.5);
    float4 gradientColor = SAMPLE_TEXTURE2D(GradientTexture.tex, GradientTexture.samplerstate, uv);
    Color = gradientColor;
}



float3 customSH(float3 normal_dir)
{
    float4 normalForSH = float4(normal_dir, 1.0);
    //SHEvalLinearL0L1
    half3 x;
    x.r = dot(custom_SHAr, normalForSH);
    x.g = dot(custom_SHAg, normalForSH);
    x.b = dot(custom_SHAb, normalForSH);

    //SHEvalLinearL2
    half3 x1, x2;
    // 4 of the quadratic (L2) polynomials
    half4 vB = normalForSH.xyzz * normalForSH.yzzx;
    x1.r = dot(custom_SHBr, vB);
    x1.g = dot(custom_SHBg, vB);
    x1.b = dot(custom_SHBb, vB);

    // Final (5th) quadratic (L2) polynomial
    half vC = normalForSH.x*normalForSH.x - normalForSH.y*normalForSH.y;
    x2 = custom_SHC.rgb * vC;

    float3 sh = max(float3(0.0, 0.0, 0.0), (x + x1 + x2));
    sh = pow(sh, 1.0 / 2.2);

    // half3 env_color = sh;
    // half3 final_color = env_color * _Expose;
    return sh * custom_SH_Intensity;
}

half3 WindScaler(float3 positionWS)
{
    half3 uvPanner = _Time.y * _WindSpeed + positionWS;
    half noisePerlin = snoise3(uvPanner);
    // half noisePerlin = 1;
    half3 windScaler = clamp(sin(_WindFrequency * (positionWS + noisePerlin)), half3(-1, -1, -1), half3(1, 1, 1));
    return windScaler;
}





#endif
