#ifndef XGJOY_META_PASS_INCLUDED
#define XGJOY_META_PASS_INCLUDED

#include "./Core.hlsl"
#include "./Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"


VertexOutputObjectMeta CommonMetaPassVertex( VertexInputObjectMeta v  )
{
    VertexOutputObjectMeta o = (VertexOutputObjectMeta)0;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.uv = v.uv.xy;

    o.positionWS = TransformObjectToWorld( v.positionOS.xyz );
    o.positionCS = MetaVertexPosition( v.positionOS, v.uv2.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST );
    
    return o;
}

half4 CommonMetaPassFragment(VertexOutputObjectMeta i  ) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( i );

    float3 WorldPosition = i.positionWS;

    float4 staticSwitch94 = _MainLightColor;

    float3 localAdditionalLightsFlat = AdditionalLightsFlat( WorldPosition );
    float4 LightShadowColor = ( staticSwitch94 + float4( localAdditionalLightsFlat , 0.0 ) );

    float3 BakedAlbedo = LightShadowColor.rgb;
    
#ifdef _ALPHATEST_ON
    half alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).a;
    AlphaClip(alpha, 0.5);
#endif
    
    MetaInput metaInput = (MetaInput)0;
    metaInput.Albedo = BakedAlbedo;
    metaInput.Emission = 0;
    
    return MetaFragment(metaInput);
}

#endif