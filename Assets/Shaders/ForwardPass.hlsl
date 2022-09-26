#ifndef XGJOY_FORWARD_PASS
#define XGJOY_FORWARD_PASS

#include "./Input.hlsl"

VertexOutput CommonVertexFunction (VertexInput v)
{
    VertexOutput o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
    o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
    o.screenPos = ComputeScreenPos(o.positionCS);

    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
    o.bitangentWS = vertexNormalInput.bitangentWS;
    o.tangentWS = vertexNormalInput.tangentWS;
    o.normalWS = vertexNormalInput.normalWS;
    
    o.color = v.color;
    o.uv.xy = v.uv;
    o.uv.zw = v.uv1;
    return o;
}


VertexOutputSimple CommonVertexSimpleFunction(VertexInputSimple v)
{
    VertexOutputSimple o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
    o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
    o.normalWS = TransformObjectToWorldNormal(v.normalOS);
    
    o.color = v.color;
    o.uv = v.uv.xy;
    return o;
}

VertexOutputObject CommonVertexObjectFunction(VertexInputObject v)
{
    VertexOutputObject o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
    o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
    o.positionCS = TransformWorldToHClip(o.positionWS);

    // VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
    // o.normalWS = vertexNormalInput.normalWS;

    o.normalWS = TransformObjectToWorldNormal(v.normalOS);
    o.screenPos = ComputeScreenPos(o.positionCS);

   
    o.color = v.color;
    o.uv.xy = v.uv.xy;

    float2 uv2 = v.uv2.xy * float2(1, 1);
    float2 lightmapUV = uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
    o.uv.zw = lightmapUV;
    return o;
}


#endif