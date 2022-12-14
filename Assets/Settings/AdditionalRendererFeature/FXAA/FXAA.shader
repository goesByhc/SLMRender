Shader "PostProcess/FXAA"
{
    HLSLINCLUDE
        #pragma exclude_renderers gles
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

        TEXTURE2D_X(_SourceTex);

        float4 _SourceSize;

        #define FXAA_SPAN_MAX           (8.0)
        #define FXAA_REDUCE_MUL         (1.0 / 8.0)
        #define FXAA_REDUCE_MIN         (1.0 / 128.0)

        half3 Fetch(float2 coords, float2 offset)
        {
            float2 uv = coords + offset;
            return SAMPLE_TEXTURE2D_X(_SourceTex, sampler_LinearClamp, uv).xyz;
        }

        half3 Load(int2 icoords, int idx, int idy)
        {
            #if SHADER_API_GLES
                float2 uv = (icoords + int2(idx, idy)) * _SourceSize.zw;
                return SAMPLE_TEXTURE2D_X(_SourceTex, sampler_LinearClamp, uv).xyz;
            #else
                return LOAD_TEXTURE2D_X(_SourceTex, clamp(icoords + int2(idx, idy), 0, _SourceSize.xy - 1.0)).xyz;
            #endif
        }

        half4 Frag(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float2 uv = UnityStereoTransformScreenSpaceTex(input.uv);
            int2 positionSS = uv * _SourceSize.xy;
            float2 positionNDC = uv;
            half3 color = Load(positionSS, 0, 0).xyz;

            // Edge detection
            half3 rgbNW = Load(positionSS, -1, -1);
            half3 rgbNE = Load(positionSS, 1, -1);
            half3 rgbSW = Load(positionSS, -1, 1);
            half3 rgbSE = Load(positionSS, 1, 1);

            rgbNW = saturate(rgbNW);
            rgbNE = saturate(rgbNE);
            rgbSW = saturate(rgbSW);
            rgbSE = saturate(rgbSE);
            color = saturate(color);

            half lumaNW = Luminance(rgbNW);
            half lumaNE = Luminance(rgbNE);
            half lumaSW = Luminance(rgbSW);
            half lumaSE = Luminance(rgbSE);
            half lumaM = Luminance(color);

            float2 dir;
            dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
            dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));

            half lumaSum = lumaNW + lumaNE + lumaSW + lumaSE;
            float dirReduce = max(lumaSum * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
            float rcpDirMin = rcp(min(abs(dir.x), abs(dir.y)) + dirReduce);

            dir = min((FXAA_SPAN_MAX).xx, max((-FXAA_SPAN_MAX).xx, dir * rcpDirMin)) * _SourceSize.zw;

            // Blur
            half3 rgb03 = Fetch(positionNDC, dir * (0.0 / 3.0 - 0.5));
            half3 rgb13 = Fetch(positionNDC, dir * (1.0 / 3.0 - 0.5));
            half3 rgb23 = Fetch(positionNDC, dir * (2.0 / 3.0 - 0.5));
            half3 rgb33 = Fetch(positionNDC, dir * (3.0 / 3.0 - 0.5));

            rgb03 = saturate(rgb03);
            rgb13 = saturate(rgb13);
            rgb23 = saturate(rgb23);
            rgb33 = saturate(rgb33);

            half3 rgbA = 0.5 * (rgb13 + rgb23);
            half3 rgbB = rgbA * 0.5 + 0.25 * (rgb03 + rgb33);

            half lumaB = Luminance(rgbB);

            half lumaMin = Min3(lumaM, lumaNW, Min3(lumaNE, lumaSW, lumaSE));
            half lumaMax = Max3(lumaM, lumaNW, Max3(lumaNE, lumaSW, lumaSE));

            color = ((lumaB < lumaMin) || (lumaB > lumaMax)) ? rgbA : rgbB;
            return half4(color, 1.0);
        }
    ENDHLSL
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "FinalPost"

            HLSLPROGRAM
            #pragma vertex FullscreenVert
            #pragma fragment Frag
            ENDHLSL
        }
    }
}