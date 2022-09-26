#ifndef XGJOY_SHADOW_CASTER_PASS_INCLUDED
#define XGJOY_SHADOW_CASTER_PASS_INCLUDED

#include "./Core.hlsl"
#include "./Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;

float4 GetShadowPositionHClip(VertexInputShadowCaster input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

    #if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return positionCS;
}

VertexOutputShadowCaster CommonShadowPassVertex(VertexInputShadowCaster input)
{
    VertexOutputShadowCaster output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.positionCS = GetShadowPositionHClip(input);
    output.uv = input.uv.xy;
    return output;
}

half4 CommonShadowPassFragment(VertexOutputShadowCaster input) : SV_TARGET
{
    // #if defined(_ALPHATEST_ON)
    half alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;
    AlphaClip(alpha, 0.5);
    // #endif
    return 0;
}

#endif
