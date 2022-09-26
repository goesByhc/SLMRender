Shader "DepthOnly"
{
    Properties
    {
    }

    SubShader
    {
        
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
            #include "../ShadowCasterPass.hlsl"
            #include "../DepthOnlyPass.hlsl"
            #include "../DepthNormalsPass.hlsl"
            #include "../MetaPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

        ENDHLSL

        
        Pass
        {
            
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            AlphaToMask Off
            Cull Off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON
            
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            ENDHLSL
        }
        
        
        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Off

            HLSLPROGRAM
            #pragma target 4.5
            #pragma prefer_hlslcc gles

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            ENDHLSL
        }
    }

}