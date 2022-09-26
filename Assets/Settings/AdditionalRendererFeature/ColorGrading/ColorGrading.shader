Shader "PostProcess/ColorGrading"
{
    
    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    
    uniform float4 _MainTex_TexelSize;

    float4 _Vignette_Params1;
    float4 _Vignette_Params2;

    
    TEXTURE2D(_InternalLut);
    float4 _Lut_Params;
    float4 _UserLut_Params;
    TEXTURE2D(_UserLut);

    struct appdata_img
    {
        float4 vertex : POSITION;
        half2 texcoord : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct v2f_img
    {
        float4 pos : SV_POSITION;
        half2 uv : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    v2f_img vert_img( appdata_img v )
    {
        v2f_img o;
        o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
        o.uv = v.texcoord;
        return o;
    }

    // Symmetric Nearest Neighbor
    half4 frag(in v2f_img i): SV_Target {

        // return half4(half3(1,0,0), 1);

        // half2 src_size = iResolution.xy;
        // half2 inv_src_size = 1.0f / src_size;
        // half2 uv = fragCoord * inv_src_size;
        half2 uv = i.uv;
        
        half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
        half3 color = mainTex.rgb;
        half a = mainTex.a;

        half3 VignetteColor = _Vignette_Params1.xyz;
        half2 VignetteCenter = _Vignette_Params2.xy;
        half VignetteIntensity = _Vignette_Params2.z;
        half VignetteSmoothness = _Vignette_Params2.w;
        half VignetteRoundness = _Vignette_Params1.w;

        if (VignetteIntensity > 0)
        {
            color = ApplyVignette(color, uv, VignetteCenter, VignetteIntensity, VignetteRoundness, VignetteSmoothness, VignetteColor);
        }

        
        half PostExposure = _Lut_Params.w;
        half3 LutParams = _Lut_Params.xyz;
        half3 UserLutParams = _UserLut_Params.xyz;
        half UserLutContribution = _UserLut_Params.w;
        
        color = ApplyColorGrading(color, PostExposure, TEXTURE2D_ARGS(_InternalLut, sampler_LinearClamp), LutParams, TEXTURE2D_ARGS(_UserLut, sampler_LinearClamp), UserLutParams, UserLutContribution);
        
        return half4(color.rgb, a);
    }
        
    
    ENDHLSL
    
    Properties
    {
//        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        
//        ColorMask RGB

        Stencil
        {
            Ref 50
            Comp NotEqual
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            ENDHLSL
        }
    }
}
