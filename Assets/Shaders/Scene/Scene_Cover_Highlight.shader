Shader "Scene_Cover_Highlight"
{
    Properties
    {

        _TintColor("Tint Color", Color) = (0.352, 0.705, 0.988, 0)
        _RimPower("Rim Power", Float) = 1
        _RimIntensity("Rim Intensity", Range(0, 1)) = 1

        [Header(Blend Setting)][Space(5)]
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        
    	[Header(Stencil)][Space(5)]
        [IntRange]_Stencil ("Stencil ID", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass ("Stencil Pass", Float) = 2

        
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
            #include "../ShadowCasterPass.hlsl"
            #include "../DepthOnlyPass.hlsl"
            #include "../DepthNormalsPass.hlsl"
            #include "../OutlinePass.hlsl"
            #include "../MetaPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
                half4 _TintColor;
                half _RimPower;
                half _RimIntensity;
            CBUFFER_END

            
        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull [_Cull]
            
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB

            Stencil
            {
                Ref [_Stencil]
                Comp [_StencilComp]
                Pass [_StencilPass]
                Fail Keep
                ZFail Keep
            }
            
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex CommonVertexObjectFunction
            #pragma fragment frag

            
            half4 frag (VertexOutputObject i) : SV_Target
            {

                //Dir
                half3 positionWS = i.positionWS;
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);
                half3 normalWS = normalize(i.normalWS);
                half NDotV = abs(dot(normalWS, viewDir));

                half rim = max(0.01, pow(1 - NDotV, _RimPower) * _RimIntensity);
                
                half3 rimColor = rim * _TintColor * _RimIntensity;

                return half4(rimColor, rim);
            }
            ENDHLSL
        }
        
        
    }
}
