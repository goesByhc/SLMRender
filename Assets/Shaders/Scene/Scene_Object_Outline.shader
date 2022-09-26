Shader "Scene_Object_Outline" //GPU Instancer Setup
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
        _OutlineColor("Outline Color", Color) = (0,0,0,0)
        _OutlineWidth("Outline Width 描边宽度", Range( 0 , 10)) = 0
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
            #include "./../../../Plugins/GPUInstancer/Shaders/Include/GPUInstancerInclude.cginc"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
            #include "../ShadowCasterPass.hlsl"
            #include "../DepthOnlyPass.hlsl"
            #include "../MetaPass.hlsl"
            #include "../OutlinePass.hlsl"
            #include "../DepthNormalsPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            half4 _TintColor;
            half4 _MainTex_ST;
            half4 _ShadowColor;
            half4 _BrightColor;
            half _ShadowIntensity;
            half _Brightness;
            half _Saturation;
            half4 _OutlineColor;
            half _OutlineWidth;
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
                half3 localAdditionalLights = AdditionalLightsHalfLambert( positionWS, normalWS);

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
                #ifdef LIGHTMAP_ON
                half4 finalShadow = lightShadowColor;
                // return half4(finalShadow.rgb, 1);
                #else
                half4 finalShadow = readlTimeShadow.xxxx;
                #endif
                half4 shadowColor = lerp( _ShadowColor , _BrightColor , finalShadow);

                // return float4(shadowColor.rgb, 1);
                
                half finalBloom = GetSceneObjectOpaqueFinalBloom(_BloomFactor);
                
                half3 Color = ( baseColor * (shadowColor * lightShadowColor + localAdditionalLights) * ssao ).rgb;
                half Alpha = finalBloom;
                
#ifdef _ALPHATEST_ON
                half opacityMask = step(0.5 , mainTex.a);
                half finalClip = 1.0 - saturate( ( opacityMask - finalBloom ) ) ;
                AlphaClip(Alpha , finalClip);
#endif

                return half4(Color , Alpha );
            }

            ENDHLSL
        }
        
        
        
        Pass
        {
            Name "Outline"
            Tags {"LightMode" = "Outline"}
            
            Cull Front

            HLSLPROGRAM

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            #pragma vertex OutlineVertFunction
            #pragma fragment OutlineFragFunction
            
            // Textures

            VertexOutputOutline OutlineVertFunction( VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                VertexOutputOutline o;

                o.positionCS = GetOutlinePositionHClip(v, _OutlineWidth, 0);
                o.uv = v.uv;
                return o;
            }

            half4 OutlineFragFunction (VertexOutputOutline i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                return float4(_OutlineColor.rgb, 1.0);
            }

            ENDHLSL
        }
        
        
        
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull Off

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
            Tags {"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            AlphaToMask Off
            Cull [_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing
            
            #pragma vertex CustomDepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            VertexOutputDepth CustomDepthOnlyVertex(VertexInput input)
            {
                VertexOutputDepth output = (VertexOutputDepth)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
                output.positionCS = GetOutlinePositionHClip(input, _OutlineWidth, 0);
                return output;
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

            HLSLPROGRAM
            #pragma target 4.5
            #pragma prefer_hlslcc gles
            
            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            VertexOutputDepthNormals CustomDepthNormalsVertex(VertexInput input)
            {
                VertexOutputDepthNormals output = (VertexOutputDepthNormals)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
                output.positionCS = GetOutlinePositionHClip(input, _OutlineWidth, 0);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);

                output.uv = input.uv;
                return output;
            }
            
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