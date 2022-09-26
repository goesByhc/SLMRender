Shader "Scene_Vegetation_Gradient_LoopMap" //GPU Instancer Setup
{
    
    
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _GradientTex("GradientTex", 2D) = "white" {}
//        _NoiseTex("NoiseTex", 2D) = "gray" {}
        [HDR]_TintColor("Tint Color", Color) = (1, 1, 1, 0)
        _Brightness("Brightness", Range(0, 3)) = 1
        _Saturation("Saturation", Range(0, 3)) = 1
        _NoiseIntensity("Noise Intensity", Range(0, 1)) = 1
        _NoiseScale("Noise Scale", Float) = 1
//        _BrightColor("Bright Color", Color) = (1, 1, 1, 0)
//        _ShadowColor("Shadow Color", Color) = (0.745283, 0.745283, 0.745283,0)
//        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1
        
        [Header(SSS)]
        [Toggle]_SSS("Enable SSS", Int) = 0
        _SSSColor("SSS Color", Color) = (1,1,0,1)
        _SSSIntensity("SSS Intensity", Range(0, 10)) = 0
        _SSSPower("SSS Power", Range(0, 1)) = 0.2
        
        [Header(Rim)]
        [Toggle]_RIM("Enable Rim", Int) = 0
        _RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimIntensity("Rim Intensity", Range(0, 1)) = 0
        _RimWidth("Rim Width", Range(0, 1)) = 0.2
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.2
        
        [Header(Wind)]
        
        [Toggle]_WIND("Enable Wind", Int) = 0
        _WindMultiplier("Wind Multiplier", Range(0, 1)) = 1
        
        [Space(5)]
        _BloomFactor("BloomFactor", Range(0, 1)) = 0
        
        [Toggle]_ALPHATEST("AlphaTest", Int) = 1
        
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
            #include "../Noise.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            half4 _TintColor;
            half4 _MainTex_ST;
            // half4 _NoiseTex_ST;
            // half4 _ShadowColor;
            // half4 _BrightColor;
            // half _ShadowIntensity;
            half _Brightness;
            half _Saturation;
            half _NoiseIntensity;
            half _NoiseScale;

            half4 _SSSColor;
            half _SSSPower;
            half _SSSIntensity;

            half4 _RimColor;
            half _RimIntensity;
            half _RimWidth;
            half _RimThreshold;
        
            half _WindMultiplier;
            half _BloomFactor;
            CBUFFER_END
            half3 _LoopMapLength;
            
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
            #pragma multi_compile _ _SSS_ON
            #pragma multi_compile _ _RIM_ON
            #pragma multi_compile _ _WIND_ON

            TEXTURE2D(_GradientTex);            SAMPLER(sampler_GradientTex);
            TEXTURE2D(_NoiseTex);               SAMPLER(sampler_NoiseTex);

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

                half3 localAdditionalLights = AdditionalLightsHalfLambert(positionWS, normalWS);

                // return float4(finalLightShadowColor.rgb, 1);
                
                float2 uv = i.uv.xy;
                float2 uv_MainTex = uv * _MainTex_ST.xy + _MainTex_ST.zw;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
                half3 baseColor = (_Brightness * mainTex ).rgb;
                half luminance = Luminance(baseColor.rgb);
                baseColor = lerp( luminance , baseColor , _Saturation);
                baseColor = _TintColor * baseColor;

                // return baseColor;
                
                half NDotL = dot(normalWS , lightDir );
                half halfLambert = (NDotL + 1) * 0.5; 

                // half2 uv_NoiseTex = uv * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
                // half noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uv_NoiseTex).r;
                // noise = (noise - 0.5) * _NoiseIntensity;
                half3 lengthTemp = half3(max(1, _LoopMapLength.x), max(1, _LoopMapLength.y), max(1, _LoopMapLength.z));
                half3 temp = floor(positionWS / lengthTemp);
                half3 pos = half3(max(positionWS.x - temp.x * _LoopMapLength.x, positionWS.x),
                    max(positionWS.y - temp.y * _LoopMapLength.y, positionWS.y),
                    max(positionWS.z - temp.z * _LoopMapLength.z, positionWS.z));
                
                half noise = (snoise3(pos * _NoiseScale) ) * _NoiseIntensity;

                half uv_x = clamp(halfLambert + noise, 0.01, 0.99);
                // return half4(step(noise, 0).rrr, 1);
                
                half3 shadowColor = SAMPLE_TEXTURE2D(_GradientTex, sampler_GradientTex, half2(uv_x, 0.5)).rgb;


                //SSS
                half3 sssColor = half3(0,0,0);
#ifdef _SSS_ON
                half sss = max(pow(max(dot(-normalize(lightDir + normalWS), viewDir), 0), (1 - _SSSPower) * 10), 0.001);
                sssColor = sss * _SSSIntensity * _SSSColor * baseColor;
#endif

                
                //Rim
                half3 rimColor = half3(0,0,0);
#ifdef _RIM_ON
                half4 screenPos = i.screenPos;
                half4 screenPosNorm = screenPos / screenPos.w;
                half rimOffsetLength = (_RimWidth * 0.01) / i.positionCS.w;
                half3 center = TransformObjectToWorld(half3(0,0,0));
                half2 rimDir = TransformWorldToHClipDir(positionWS - center).xy;
                rimDir.y = -rimDir.y;
                half currentDepth = Linear01Depth(SampleSceneDepth(screenPosNorm.xy), _ZBufferParams);
                half targetDepth = Linear01Depth(SampleSceneDepth(screenPosNorm.xy + rimDir.xy * rimOffsetLength), _ZBufferParams);

                half rim = step(_RimThreshold, targetDepth - currentDepth);
                rimColor = rim * _RimColor * _RimIntensity * baseColor;
#endif
                

                
                // return float4(shadowColor.rgb, 1);
                
                half finalBloom = GetSceneObjectOpaqueFinalBloom(_BloomFactor);

                half3 diffuseColor = baseColor * shadowColor * mainLight.color;
                half3 additionalColor = diffuseColor * localAdditionalLights;
                
                half3 Color = diffuseColor + sssColor + rimColor + additionalColor;

                AlphaClip(mainTex.a);

                return half4(Color, finalBloom );
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

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _WIND_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment CommonShadowPassFragment


            VertexOutputShadowCaster ShadowPassVertex(VertexInputShadowCaster v)
            {
                VertexOutputShadowCaster output;
                UNITY_SETUP_INSTANCE_ID(v);
            
#ifdef _WIND_ON
                 half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                 half3 windScaler = WindScaler(positionWS);
                 half3 wind = windScaler * v.normalOS * _WindPower * _WindMultiplier * v.color.r;
                 half3 positionOS = v.positionOS.xyz + wind;
#else
                half3 positionOS = v.positionOS.xyz;
#endif
                
                output.positionCS = TransformObjectToHClip(positionOS);
                output.uv = v.uv.xy;
                return output;
            }
            
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

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _WIND_ON

            #pragma vertex CustomDepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            VertexOutputDepth CustomDepthOnlyVertex(VertexInputObject v)
            {
                VertexOutputDepth o;
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
                
                o.positionCS = TransformObjectToHClip(positionOS);
                o.uv.xy = v.uv.xy;
                return o;
            }
            
            ENDHLSL
        }
        
        
        
        
        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]
            
            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace 
                Fail Keep
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma target 4.5
            #pragma prefer_hlslcc gles

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing
            
            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _WIND_ON

            #pragma vertex CustomDepthOnlyVertex
            #pragma fragment DepthNormalsFragment

            VertexOutputDepthNormals CustomDepthOnlyVertex(VertexInputObject v)
            {
                VertexOutputDepthNormals o;
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
                
                o.positionCS = TransformObjectToHClip(positionOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv.xy = v.uv.xy;
                return o;
            }

            
            ENDHLSL
        }
        
        
        
        
        Pass
        {
            
            Name "Meta"
            Tags { "LightMode" = "Meta" }

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