Shader "Scene_Object_Emission"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        [HDR]_TintColor("Tint Color", Color) = (1, 1, 1, 0)
        _EmissionMap("Emission Map", 2D) = "black" {}
		[HDR]_EmissionColor("Emission Color", Color) = (1,1,1,0)
        _Brightness("Brightness", Range(0, 3)) = 1
        _Saturation("Saturation", Range(0, 3)) = 1
        _BrightColor("Bright Color", Color) = (1, 1, 1, 0)
        _ShadowColor("Shadow Color", Color) = (0.745283, 0.745283, 0.745283,0)
        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1
        _BloomFactor("BloomFactor", Range(0, 1)) = 0
        
        [Toggle]_ALPHATEST("AlphaTest", Int) = 0
        [MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
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
			half4 _EmissionMap_ST;
			half4 _EmissionColor;
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
            ZWrite On
            ZTest LEqual
            Offset 0 , 0
            ColorMask RGBA
            Cull [_Cull]


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
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _HBAO_ON


            //Texture
            sampler2D _EmissionMap;
            
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

                half4 lightShadowColor  = half4(1, 1, 1, 1);
                #ifdef LIGHTMAP_ON

                float2 lightmapUV = i.uv.zw;
                float3 lightmap = SampleLightmap( lightmapUV );
                lightShadowColor = half4(max( lightAtten , 0.5 ) * pow( lightmap , _ShadowIntensity ) , 0.0 );
                // return float4(lightShadowColor.rgb, 1);
                #else
                lightShadowColor = _MainLightColor;
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

                half2 uv_EmissionMap = uv * _EmissionMap_ST.xy + _EmissionMap_ST.zw;
				half4 emissionMap = ( tex2D( _EmissionMap, uv_EmissionMap ) * _EmissionColor );

                // return baseColor;
                
                half NDotL = dot( normalWS , _MainLightPosition.xyz );
                half readlTimeShadow = saturate( NDotL ) * lightAtten;
                #ifdef LIGHTMAP_ON
                half4 finalShadow = lightShadowColor;
                // return half4(finalShadow.rgb, 1);
                #else
                half4 finalShadow = readlTimeShadow.xxxx;
                #endif
                half4 shadowColor = lerp( _ShadowColor , _BrightColor , finalShadow);

                // return float4(shadowColor.rgb, 1);
                
                half finalBloom = GetSceneObjectOpaqueFinalBloom(_BloomFactor);
                
                half3 Color = ( (baseColor * shadowColor + emissionMap) * (lightShadowColor + localAdditionalLights) * ssao ).rgb;
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

            ZWrite On
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

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

            ZWrite On
            ColorMask 0
            AlphaToMask Off
            Cull [_Cull]

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
            Cull[_Cull]

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
        
        
        
        Pass
        {
            
            Name "Meta"
            Tags { "LightMode" = "Meta" }

            Cull [_Cull]

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
            #pragma fragment CustomCommonMetaPassFragment

            //Texture
            sampler2D _EmissionMap;

            
            half4 CustomCommonMetaPassFragment(VertexOutputObjectMeta i  ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( i );
            
                float3 WorldPosition = i.positionWS;
            
                float4 staticSwitch94 = _MainLightColor;
            
                float3 localAdditionalLightsFlat = AdditionalLightsFlat( WorldPosition );
                float4 LightShadowColor = ( staticSwitch94 + float4( localAdditionalLightsFlat , 0.0 ) );
            
                float3 BakedAlbedo = LightShadowColor.rgb;

                float2 uv_EmissionMap = i.uv * _EmissionMap_ST.xy + _EmissionMap_ST.zw;
                float4 emissionMap = ( tex2D( _EmissionMap, uv_EmissionMap ) * _EmissionColor );
                
#ifdef _ALPHATEST_ON
                half alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).a;
                AlphaClip(alpha, 0.5);
#endif
                
                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo = BakedAlbedo;
                metaInput.Emission = emissionMap.rgb;
                
                return MetaFragment(metaInput);
            }

            
            ENDHLSL
        }
        
        
        

    }

}