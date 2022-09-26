Shader "Scene_Object_Blinn_Outline" //GPU Instancer Setup
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap("NormalMap",2D) = "bump"{}
        _NormalIntensity("Normal Intensity",Range(0.0, 5.0)) = 1.0
        
        [Header(BaseColor)][Space(5)]
        [HDR]_TintColor("Tint Color", Color) = (1, 1, 1, 0)
        _Brightness("Brightness", Range(0, 3)) = 1
        _Saturation("Saturation", Range(0, 3)) = 1
        _ShadowColor("Shadow Color", Color) = (0.098, 0.219, 0.239, 0)
//        _AmbientColor("Ambient Color", Color) = (0.172, 0.466, 0.5490, 0)

//        _AOMap("AO Map",2D) = "white"{}
//        _SpecMask("Spec Mask",2D) = "white"{}
        [Header(Spec)][Space(5)]
        _SpecColor("Spec Color", Color) = (1, 1, 1, 1)
        _Roughness("Roughness", Range(0.001, 1)) = 1
//        _Shininess("Shininess",Range(0.01,100)) = 10.0
        _SpecIntensity("SpecIntensity", Range(0.00, 5)) = 1.0
        
//        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1.0
//		_ParallaxMap("ParallaxMap",2D) = "black"{}
//		_Parallax("_Parallax",float) = 2
        //_AmbientColor("Ambient Color",Color) = (0,0,0,0)
        
//        _Fresnel("Fresnel", Range(0, 1)) = 0.1

        [Header(Rim)][Space(5)]
        _RimColor("Rim Color", Color) = (0.352, 0.705, 0.988, 0)
        _RimPower("Rim Power", Float) = 80
        _RimIntensity("Rim Intensity", Range(0, 1)) = 0.1
//        _RimBias("Rim Bias", Range(0, 1)) = 0

        [Header(Outline)][Space(5)]
        _OutlineColor("Outline Color", Color) = (0,0,0,0)
        _OutlineWidth("Outline Width 描边宽度", Float) = 0
        
        [Header(Bloom)][Space(5)]
        _BloomFactor("BloomFactor", Range(0, 1)) = 0

        [Header(Setting)][Space(5)]
        [Toggle]_ALPHATEST("AlphaTest", Int) = 0
        [MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Cull", Int) = 2
        
        [Header(Blend Setting)][Space(5)]
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        
    	[Header(Stencil)][Space(5)]
        [IntRange]_Stencil ("Stencil ID", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass ("Stencil Pass", Float) = 2
        
//        
//        custom_SHAr("Custom SHAr", Vector) = (0, 0, 0, 0)
//		custom_SHAg("Custom SHAg", Vector) = (0, 0, 0, 0)
//		custom_SHAb("Custom SHAb", Vector) = (0, 0, 0, 0)
//		custom_SHBr("Custom SHBr", Vector) = (0, 0, 0, 0)
//		custom_SHBg("Custom SHBg", Vector) = (0, 0, 0, 0)
//		custom_SHBb("Custom SHBb", Vector) = (0, 0, 0, 0)
//		custom_SHC("Custom SHC", Vector) = (0, 0, 0, 1)
        
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
            #include "../DepthNormalsPass.hlsl"
            #include "../OutlinePass.hlsl"
            #include "../MetaPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
                half4 _MainTex_ST;
                half4 _NormalMap_ST;
                half _NormalIntensity;
            
                half4 _TintColor;
                half _Brightness;
                half _Saturation;
                // half4 _AmbientColor;
                half4 _ShadowColor;
    
                half4 _SpecColor;
                half _Roughness;
                half _SpecIntensity;
            
                half4 _RimColor;
                half _RimPower;
                half _RimIntensity;

                half4 _OutlineColor;
                half _OutlineWidth;
        
                half _BloomFactor;
            CBUFFER_END

            
        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
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
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
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
            
            
            // sampler2D _AOMap;
            // sampler2D _SpecMask;


            struct VertexOutputObjectBlinn
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                half3 positionWS: TEXCOORD1;
                half3 tangent: TEXCOORD2;
                half3 bitangentWS: TEXCOORD3;
                half3 normalWS : TEXCOORD4;
                half4 screenPos : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };





            VertexOutputObjectBlinn vert(VertexInputObject v)
            {
                VertexOutputObjectBlinn o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
            
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = vertexNormalInput.normalWS;
                o.bitangentWS = vertexNormalInput.bitangentWS;
                o.tangent = vertexNormalInput.tangentWS;
            
                o.uv.xy = v.uv.xy;
                o.screenPos = ComputeScreenPos(o.positionCS);
            
                float2 uv2 = v.uv2.xy * float2(1, 1);
                float2 lightmapUV = uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
                o.uv.zw = lightmapUV;
                return o;
            }
            
            
            half4 frag (VertexOutputObjectBlinn i) : SV_Target
            {
                half2 uv = i.uv.xy;

                //Sample
                float2 uv_MainTex = uv * _MainTex_ST.xy + _MainTex_ST.zw;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);

                AlphaClip(mainTex.a, 0.5);
                
                //Dir
                half3 positionWS = i.positionWS;
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);
                
                float2 uv_NormalMap = uv * _NormalMap_ST.xy + _NormalMap_ST.zw;
                half4 normalmap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv_NormalMap);
                half3 normal_data = UnpackNormalScale(normalmap, _NormalIntensity);
                normal_data.z = lerp(1, normal_data.z, saturate(_NormalIntensity));
                half3 normalWS = normalize(TransformTangentToWorld(normal_data, half3x3(i.tangent, i.bitangentWS,normalize(i.normalWS))));
                half NDotV = saturate(dot(normalWS, viewDir));

                //Shadow Light
                half4 shadowCoords = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(shadowCoords );
                half lightAtten = max(mainLight.shadowAttenuation, 0.0001);
                
                half3 lightDir = mainLight.direction;

                half3 localAdditionalLights = AdditionalLightsLambert(positionWS, normalWS);


                //BaseColor
                half3 baseColor = mainTex.rgb;
                baseColor = _Brightness * baseColor;
                half luminance = Luminance(baseColor);
                baseColor = lerp(luminance , baseColor, _Saturation);
                baseColor = _TintColor.rgb * baseColor;
                // baseColor = pow(max(baseColor, 0), 2.2);
                


                // return half4(lightAtten.rrr * _RimPower, 1);
                //SSAO
                half3 ssao = half3(1,1,1);
#ifdef _HBAO_ON
                ssao = SAMPLE_TEXTURE2D(_SSAOTex, sampler_SSAOTex, i.screenPos.xy / i.screenPos.w).rgb;
#endif
                
                half diffTerm = min(lightAtten, max(0.0,dot(normalWS, lightDir)));
                half3 diffTermColor = lerp(_ShadowColor.rgb, mainLight.color, diffTerm);
            	half halfLambert = (diffTerm + 1.0) * 0.5;

                //Diffuse
                half3 diffuseColor = diffTermColor * mainLight.color * baseColor;

                //Spec
                half specular = LightingFuncGGX_OPT1(normalWS, viewDir, lightDir, _Roughness, _SpecIntensity);
                half3 specColor = specular * diffTerm * mainLight.color * _SpecColor.rgb;

                //Rim
                half3 rimColor = max(half3(0,0,0), pow(1 - NDotV, _RimPower) * _RimIntensity) * _RimColor.rgb;

                //Additional
                half3 additionalColor = localAdditionalLights * baseColor;

                //Ambient
                // half3 ambientColor = _AmbientColor.rgb * baseColor;
                half3 ambientColor = customSH(normalWS) * baseColor * halfLambert;

                //Bloom
                half finalBloom = GetSceneObjectOpaqueFinalBloom(_BloomFactor);

                //Final
                half3 finalColor = (diffuseColor + specColor + ambientColor + additionalColor + rimColor) * ssao;
                //half3 toneColor = ACESFilm(finalColor);
                 half3 toneColor = finalColor;
                // toneColor = pow(toneColor, 1.0 / 2.2);
                return half4(toneColor, finalBloom);
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

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing
            
            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

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
