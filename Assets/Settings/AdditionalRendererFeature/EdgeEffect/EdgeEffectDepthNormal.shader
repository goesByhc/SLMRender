
Shader "PostProcess/EdgeEffectDepthNormal"
{

    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };
    
    struct v2f
    {
        float2 uv[5] : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };
    
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    sampler2D _CameraDepthNormalsTexture;
    float4 _EdgeColor;
 
    float _SampleRange;
    float _NormalDiffThreshold;
    float _DepthDiffThreshold;


    inline float DecodeFloatRG(float2 rg) {
        return dot(rg, float2(1.0, 1 / 255.0));
    }
    
    float CheckEdge(float4 s1, float4 s2)
    {
        float2 normalDiff = abs(s1.xy - s2.xy);
        float normalEdgeVal = (normalDiff.x + normalDiff.y) < _NormalDiffThreshold;

        float s1Depth = s1.z;
        float s2Depth = s2.z;
        
        // float s1Depth = DecodeFloatRG(s1.zw);
        // float s2Depth = DecodeFloatRG(s2.zw);
        float depthEdgeVal = abs(s1Depth - s2Depth) < 0.1 * s1Depth * _DepthDiffThreshold;
        return depthEdgeVal * normalEdgeVal;
    }

    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = mul (UNITY_MATRIX_MVP, v.vertex);
        o.uv[0] = v.uv + float2(-1, -1) * _MainTex_TexelSize * _SampleRange;
        o.uv[1] = v.uv + float2( 1, -1) * _MainTex_TexelSize * _SampleRange;
        o.uv[2] = v.uv + float2(-1,  1) * _MainTex_TexelSize * _SampleRange;
        o.uv[3] = v.uv + float2( 1,  1) * _MainTex_TexelSize * _SampleRange;
        o.uv[4] = v.uv;
        return o;
    }
    
    float4 frag (v2f i) : SV_Target
    {
        float4 mainTex = tex2D(_MainTex, i.uv[4]);
        float a = mainTex.a;

        float4 s1 = SAMPLE_TEXTURE2D_X(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[0]);
        float4 s2 = SAMPLE_TEXTURE2D_X(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[1]);
        float4 s3 = SAMPLE_TEXTURE2D_X(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[2]);
        float4 s4 = SAMPLE_TEXTURE2D_X(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[3]);

        float depth1 = Linear01Depth(SampleSceneDepth(i.uv[0]), _ZBufferParams);
        s1.z = depth1;
        float depth2 = Linear01Depth(SampleSceneDepth(i.uv[1]), _ZBufferParams);
        s2.z = depth2;
        float depth3 = Linear01Depth(SampleSceneDepth(i.uv[2]), _ZBufferParams);
        s3.z = depth3;
        float depth4 = Linear01Depth(SampleSceneDepth(i.uv[3]), _ZBufferParams);
        s4.z = depth4;

        
        // float4 s1 = tex2D(_CameraNormalsTexture, i.uv[0]);
        // float4 s2 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
        // float4 s3 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
        // float4 s4 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
        
        float result = 1.0;
        result *= CheckEdge(s1, s4);
        result *= CheckEdge(s2, s3);
        mainTex *= lerp(_EdgeColor, float4(1,1,1,1), result);
        return float4(mainTex.rgb, a);
    } 
    
    ENDHLSL
    
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        
        ColorMask RGB
        
        Stencil
        {
            Ref 50
            Comp NotEqual
        }
        
        //Pass 0 Roberts Operator
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
        
        
    }
}
