#ifndef XGJOY_DEPTH_ONLY_PASS
#define XGJOY_DEPTH_ONLY_PASS

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "./Input.hlsl"


VertexOutputDepth DepthOnlyVertex(VertexInputDepth input)
{
    VertexOutputDepth output = (VertexOutputDepth)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = input.uv.xy;
    return output;
}

half4 DepthOnlyFragment(VertexOutputDepth input) : SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    half alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;
    AlphaClip(alpha);
    
    return 0;
}



#endif