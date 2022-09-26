Shader "Scene_Object" //GPU Instancer Setup
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        [HDR]_TintColor("Tint Color", Color) = (1, 1, 1, 0)
        _Brightness("Brightness", Range(0, 3)) = 1
        _Saturation("Saturation", Range(0, 3)) = 1
        _BrightColor("Bright Color", Color) = (1, 1, 1, 0)
        _ShadowColor("Shadow Color", Color) = (0.745283, 0.745283, 0.745283,0)
        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1
        _BloomFactor("BloomFactor", Range(0, 1)) = 0
        
        [Toggle]_ALPHATEST("AlphaTest", Int) = 0
        [MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
        
        
        [Header(Blend Setting)]
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        
    	[Header(Stencil)]
        [IntRange]_Stencil ("Stencil ID", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass ("Stencil Pass", Float) = 2
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
            #include "./../../../Plugins/GPUInstancer/Shaders/Include/GPUInstancerInclude.cginc"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
            #include "../ShadowCasterPass.hlsl"
            #include "../DepthOnlyPass.hlsl"
            #include "../MetaPass.hlsl"
            #include "../DepthNormalsPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            half4 _TintColor;
            half4 _MainTex_ST;
            half4 _ShadowColor;
            half4 _BrightColor;
            half _ShadowIntensity;
            half _Brightness;
            half _Saturation;
            half _BloomFactor;
            CBUFFER_END

            
        ENDHLSL

        
        Pass
        {
            
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend One Zero, One Zero
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Offset 0 , 0
            ColorMask RGBA
            Cull [_Cull]
            
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
            
            #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing
            
            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _HBAO_ON
            


            half4 frag (VertexOutputObject i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                //Dir
                half3 positionWS = i.positionWS;
                half3 normalWS = normalize(i.normalWS);

                //SSAO
                half3 ssao = half3(1,1,1);
#ifdef _HBAO_ON
                ssao = SAMPLE_TEXTURE2D(_SSAOTex, sampler_SSAOTex, i.screenPos.xy / i.screenPos.w).rgb;
#endif

                //shadows
                half4 shadowCoords = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight( shadowCoords );
                half lightAtten = max(mainLight.shadowAttenuation, 0.0001);
                lightAtten = lerp(1, lightAtten, _ShadowIntensity);

                half4 lightMapColor  = half4(1, 1, 1, 1);
                #ifdef LIGHTMAP_ON

                float2 lightmapUV = i.uv.zw;
                float3 lightmap = SampleLightmap( lightmapUV );
                lightMapColor = half4(max( lightAtten , 0.5 ) * pow( lightmap , _ShadowIntensity ) , 0.0 );
                // return float4(lightShadowColor.rgb, 1);
                #else
                lightMapColor = half4(mainLight.color, 1);
                // return float4(0,1,0, 1);

                #endif
                half3 localAdditionalLights = AdditionalLightsHalfLambert(positionWS, normalWS);
                // return float4(finalLightShadowColor.rgb, 1);
                
                float2 uv = i.uv.xy;
                float2 uv_MainTex = uv * _MainTex_ST.xy + _MainTex_ST.zw;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
                half4 baseColor = ( _Brightness * mainTex );
                half luminance = Luminance(baseColor.rgb);
                baseColor = lerp( luminance , baseColor , _Saturation);
                baseColor = ( _TintColor * baseColor );

                // return baseColor;
                
                half NDotL = dot( normalWS , _MainLightPosition.xyz );

                // return half4(normalWS.xyz, 1);
                
                half readlTimeShadow = saturate( NDotL ) * lightAtten;
                #ifdef LIGHTMAP_ON
                half4 finalShadow = lightMapColor;
                // return half4(finalShadow.rgb, 1);
                #else
                half4 finalShadow = readlTimeShadow.xxxx;
                #endif
                half4 shadowColor = lerp( _ShadowColor , _BrightColor , finalShadow);

                // return float4(shadowColor.rgb, 1);
                 
                half finalBloom = GetSceneObjectOpaqueFinalBloom(_BloomFactor);
                
                half3 Color = ( baseColor * (shadowColor * lightMapColor + localAdditionalLights) * ssao).rgb;
                
                half Alpha = finalBloom;
                
                
#ifdef _ALPHATEST_ON
                half opacityMask = step(0.5 , mainTex.a);
                half finalClip = 1.0 - saturate( ( opacityMask - finalBloom ) ) ;
                AlphaClip(Alpha , finalClip);
#endif

                return half4( Color, Alpha );
            }

            ENDHLSL
        }
        
        
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull [_Cull]
            
            
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

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

            #pragma vertex CommonShadowPassVertex
            #pragma fragment CommonShadowPassFragment

            ENDHLSL
        }
        
        
        
        Pass
        {
            
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite [_ZWrite]
            ZTest [_ZTest]
            ColorMask 0
            AlphaToMask Off
            Cull [_Cull]
            
            
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

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

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

            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull[_Cull]
            
            
            Stencil
            {
                Ref [_Stencil]
                Comp [_StencilComp]
                Pass [_StencilPass]
                Fail Keep
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            ENDHLSL
        }
        
        
        Pass
        {
            
            Name "Meta"
            Tags { "LightMode" = "Meta" }

            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            
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

            #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON


            #pragma vertex CommonMetaPassVertex
            #pragma fragment CommonMetaPassFragment

            ENDHLSL
        }
        
        
        
        

    }

}