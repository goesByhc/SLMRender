#ifndef XGJOY_OUTLINE_PASS
#define XGJOY_OUTLINE_PASS

#include "./Core.hlsl"


float RemapOutline(float oldLow, float oldHigh, float newLow, float newHigh, float invalue)
{
    return newLow + (invalue - oldLow) * (newHigh - newLow) / (oldHigh - oldLow);
}

half GetOutLineFade(half dis)
{
    float outlineFade = 1.0;

    if (dis > 80)
    {
        outlineFade = Remap(dis, 80, 120, 0.2, 0);
    }
    else if (dis > 50)
    {
        outlineFade = Remap(dis, 50, 80, 0.4, 0.2);
    }
    else if (dis > 15)
    {
        outlineFade = Remap(dis, 10, 50, 0.8, 0.4);
    }
    else
    {
        outlineFade = Remap(dis, 0, 15, 1, 0.8);
    }

    
    outlineFade = saturate(outlineFade);
    
    return outlineFade;
}
    

float4 GetCharacterOutlinePositionHClip(VertexInput v, half outlineWidth, half outlineBias)
{

    
    float4 clipPos = TransformObjectToHClip(v.positionOS);

    half3 bitangentOS = cross( v.normalOS, v.tangentOS.xyz ) * v.tangentOS.w * unity_WorldTransformParams.w;
    float3x3 TtoO = float3x3(v.tangentOS.xyz.x , bitangentOS.x , v.normalOS.x,
                             v.tangentOS.xyz.y , bitangentOS.y , v.normalOS.y,
                             v.tangentOS.xyz.z , bitangentOS.z , v.normalOS.z);

    //取出顶点色法线
    half3 vertexNormal = v.color.rgb * 2 - 1;
    half3 normalOffsetOS = mul(TtoO, vertexNormal);
    
    float3 worldNormal = TransformObjectToWorldNormal(normalOffsetOS);
    float3 ndcNormal = normalize(mul(UNITY_MATRIX_VP, worldNormal)) * clipPos.w; //NDC空间外扩，保证宽度

    float dist = distance(unity_ObjectToWorld._m03_m13_m23, _WorldSpaceCameraPos);

    float distFade = GetOutLineFade(dist); //随距离变细

    ndcNormal.x *= _ScreenParams.y / _ScreenParams.x; //解决屏幕长宽比
    clipPos.xy += 0.002 * outlineWidth * ndcNormal.xy * distFade;

    clipPos.z -= outlineBias * (1 - v.color.a) * clipPos.w; //向外挤出
    
    return clipPos;
    

}



float4 GetOutlinePositionHClip(VertexInput v, half outlineWidth, half outlineBias)
{

    //取出顶点色法线
    half3 vertexNormal = v.color.rgb * 2 - 1;

    //构建TtoO矩阵，转化法线方向
    half3 bitangentOS = cross( v.normalOS, v.tangentOS.xyz ) * v.tangentOS.w * unity_WorldTransformParams.w;
    float3x3 TtoO = float3x3(v.tangentOS.xyz.x , bitangentOS.x , v.normalOS.x,
                             v.tangentOS.xyz.y , bitangentOS.y , v.normalOS.y,
                             v.tangentOS.xyz.z , bitangentOS.z , v.normalOS.z);
                
    half3 normalOffsetOS = mul(TtoO, vertexNormal);

    //向法线方向偏移
    half3 positionOS = normalOffsetOS * outlineWidth * 0.001 + v.positionOS.xyz;
    half3 positionWS = TransformObjectToWorld(positionOS);

    //向视线方向偏移
    half3 viewDir = normalize(positionWS - _WorldSpaceCameraPos);
    positionWS += viewDir * outlineBias * (1 - v.color.a);
                
    float4 positionCS = TransformWorldToHClip(positionWS);

    return positionCS;
}

float4 GetNoBakedOutlinePositionHCip(VertexInput v, half outlineWidth, half outlineBias)
{
    half3 normalOffset = v.normalOS;

    //向法线方向偏移
    half3 positionOS = normalOffset * outlineWidth * 0.001 + v.positionOS.xyz;
    float4 positionCS = TransformObjectToHClip(positionOS);

    return positionCS;
}


half3 GetOutlineColor(half3 baseColor, half3 outlineColor, float4 positionCS)
{
    return baseColor * outlineColor;
}

#endif