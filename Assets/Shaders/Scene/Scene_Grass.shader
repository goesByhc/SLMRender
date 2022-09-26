Shader "Scene_Grass" //GPU Instancer Setup
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
        
        [Header(Wind)]
        [Toggle]_WIND("Enable Wind", Int) = 0
        _WindMultiplier("Wind Multiplier", Range(0, 1)) = 1
        
        [Space(5)]
        [Toggle]_ALPHATEST("AlphaTest", Int) = 0
        _BloomFactor("BloomFactor", Range(0, 1)) = 0
        
        [MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 0
        
        [Header(Stencil)]
        _Stencil("Stencil ID", Float) = 90
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
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
        
            half _WindMultiplier;
            half _BloomFactor;
            CBUFFER_END

            
        ENDHLSL

        
        Pass
        {
            
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            Blend One Zero
            
            ZWrite On
            ZTest LEqual
            Offset 0 , 0
            ColorMask RGBA
            Cull [_Cull]
            
            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace 
                Fail Keep
                ZFail Keep
            }


            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex VertexObjectFunction
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
            #pragma multi_compile _ _WIND_ON

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            VertexOutputObject VertexObjectFunction(VertexInputObject v)
            {
                VertexOutputObject o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

#ifdef _WIND_ON
                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                half3 windScaler = WindScaler(positionWS);
                half3 wind = windScaler * v.normalOS * _WindPower * _WindMultiplier * v.color.r;

                half3 positionOS = v.positionOS.xyz + wind;

#else
                half3 positionOS = v.positionOS.xyz;
#endif
                
                
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(positionOS);
                o.positionCS = TransformObjectToHClip(positionOS);
                o.screenPos = ComputeScreenPos(o.positionCS);
                o.color = v.color;
                o.uv.xy = v.uv.xy;
            
                float2 uv2 = v.uv2.xy * float2(1, 1);
                float2 lightmapUV = uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
                o.uv.zw = lightmapUV;
                return o;
            }
            
            half4 frag (VertexOutputObject i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                //Dir
                half3 positionWS = i.positionWS;
                half3 normalWS = normalize(i.normalWS);

                //SSAO
                // half ssao = SAMPLE_TEXTURE2D(_SSAOTex, sampler_SSAOTex, i.screenPos.xy / i.screenPos.w).r;

                //shadows
                half4 shadowCoords = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight( shadowCoords );
                half3 lightDir = mainLight.direction;
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS.xyz);
                half lightAtten = max(mainLight.shadowAttenuation, 0.0001);
                lightAtten = lerp(1, lightAtten, _ShadowIntensity);

                half4 lightShadowColor  = half4(1, 1, 1, 1);
                #ifdef LIGHTMAP_ON

                float2 lightmapUV = i.uv.zw;
                float3 lightmap = SampleLightmap( lightmapUV );
                lightShadowColor = half4(max( lightAtten , 0.5 ) * pow( lightmap , _ShadowIntensity ) , 0.0 );
                // return float4(lightShadowColor.rgb, 1);
                #else
                lightShadowColor = half4(mainLight.color, 1);
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
                
                half NDotL = dot( normalWS , mainLight.direction );
                half halfLambert = (NDotL + 1) * 0.5; 
                half readlTimeShadow = saturate( halfLambert ) * lightAtten;
                #ifdef LIGHTMAP_ON
                half4 finalShadow = lightShadowColor;
                // return half4(finalShadow.rgb, 1);
                #else
                half4 finalShadow = readlTimeShadow.xxxx;
                #endif
                half4 shadowColor = lerp( _ShadowColor , _BrightColor , finalShadow);

                half finalBloom = GetSceneObjectOpaqueFinalBloom(_BloomFactor);

                
                half3 Color = ( (baseColor) * (shadowColor * lightShadowColor + localAdditionalLights)).rgb;

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

//        
//        Pass
//        {
//            Name "DrawBloomAlpha"
//            Tags {"LightMode" = "DrawBloomAlpha"}
//            
//    		Blend [SrcBlendBloom] [DstBlendBloom]
//            Cull Off
//            ZWrite Off
//            ZTest LEqual
//            Offset 0 , 0
//            ColorMask A
//            Cull [_Cull]
//
//            HLSLPROGRAM
//            #pragma multi_compile_instancing
//            #pragma prefer_hlslcc gles
//
//            #pragma vertex VertexGrassFunction
//            #pragma fragment frag
//
//            // -------------------------------------
//            // Material Keywords
//            #pragma multi_compile _ _ALPHATEST_ON
//            #pragma multi_compile _ _WIND_ON
//            
//            VertexOutputSimple VertexGrassFunction(VertexInputSimple v)
//            {
//                VertexOutputSimple o;
//                UNITY_SETUP_INSTANCE_ID(v);
//                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
//
//#ifdef _WIND_ON
//                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
//                half2 uvPanner = _Time.y * _WindSpeed + positionWS;
//                half noisePerlin = snoise(uvPanner);
//                half3 windScaler = clamp(sin(_WindFrequency * (positionWS + noisePerlin)), half3(-1, -1, -1), half3(1, 1, 1));
//                half3 wind = windScaler * v.normalOS * _WindPower * _WindMultiplier * v.color.r;
//
//                half3 positionOS = v.positionOS + wind;
//
//#else
//                half3 positionOS = v.positionOS;
//#endif
//                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
//                o.positionWS = TransformObjectToWorld(positionOS);
//                o.positionCS = TransformObjectToHClip(positionOS);
//                o.color = v.color;
//                o.uv.xy = v.uv.xy;
//                
//                return o;
//            }
//            
//            half4 frag ( VertexOutputSimple i  ) : SV_Target
//            {
//                UNITY_SETUP_INSTANCE_ID( IN );
//                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
//
//                half2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
//                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
//                half opacity = step(0.5, mainTex.a);
//
//#ifdef _ALPHATEST_ON
//                AlphaClip(mainTex.a, 0.5);
//#endif
//                
//                return GetSceneObjectTransparentFinalBloom(_BloomFactor, opacity);
//            }
//
//            ENDHLSL
//        }
//        
    }

}