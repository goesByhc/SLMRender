Shader "Scene_Object_Opacity_Custom_Light"
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
        _Opacity("Opacity", Range( 0 , 1)) = 1
        _BloomFactor("BloomFactor", Range(0, 1)) = 0
        
        [MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
    }

    SubShader
    {
        
        Tags
        { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "AlphaTest"
        }


        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
            #include "../ShadowCasterPass.hlsl"
            #include "../DepthOnlyPass.hlsl"
            #include "../MetaPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            half4 _TintColor;
            half4 _MainTex_ST;
            half4 _ShadowColor;
            half4 _BrightColor;
            half _ShadowIntensity;
            half _Brightness;
            half _Saturation;
        	half _Opacity;
            half _BloomFactor;
            CBUFFER_END

            
        ENDHLSL

        
        Pass
        {
            
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGB
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

            
            half4 frag (VertexOutputObject i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                //Dir
                half3 positionWS = i.positionWS;
                half3 normalWS = normalize(i.normalWS);

                //shadows
                half4 shadowCoords = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight( shadowCoords );
                half lightAtten = max(mainLight.shadowAttenuation, 0.0001);
                lightAtten = lerp(1, lightAtten, _ShadowIntensity);

                half3 localAdditionalLights = AdditionalLightsHalfLambert(positionWS, normalWS);
                float3 finalLightShadowColor = ( ( (( _CharacterLightColor * _CharacterLightIntensity )).rgb * pow( lightAtten , _ShadowIntensity ) ) + localAdditionalLights );


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
                half readlTimeShadow = saturate( NDotL ) * lightAtten;
                half4 finalShadow = readlTimeShadow.xxxx;
                half4 shadowColor = lerp( _ShadowColor , _BrightColor , finalShadow);

                // return float4(shadowColor.rgb, 1);
                
                half3 Color = ( baseColor * shadowColor * finalLightShadowColor ).rgb;
                half Alpha = mainTex.a * _Opacity;
                

                return half4( Color, Alpha );
            }

            ENDHLSL
        }
        
        Pass
        {
            Name "DrawBloomAlpha"
            Tags {"LightMode" = "DrawBloomAlpha"}
            
            Blend One Zero, DstColor Zero
            Cull Off
            ZWrite Off
            ZTest LEqual
            Offset 0 , 0
            ColorMask A
            Cull [_Cull]

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma prefer_hlslcc gles

            #pragma vertex CommonVertexSimpleFunction
            #pragma fragment frag

            half4 frag ( VertexOutputSimple i  ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID( IN );
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

                half2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
                half opacity = clamp( ( mainTex.a * _Opacity ) , 0.0 , 1.0 );

                return GetSceneObjectTransparentFinalBloom(_BloomFactor, opacity);
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

            
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
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
            #pragma fragment CommonMetaPassFragment

            ENDHLSL
        }
        
        
        

    }

}