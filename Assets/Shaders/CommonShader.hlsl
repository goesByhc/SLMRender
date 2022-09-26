#ifndef COMMON_SHADER_CUSTOM
#define COMMON_SHADER_CUSTOM


float4 CalcTransparentBloomFactor(float bloomFactor, float originAlpha)
{
    bloomFactor = saturate(bloomFactor);
    return float4(1,1,1,bloomFactor * 0.45 * originAlpha * originAlpha);
}


#endif