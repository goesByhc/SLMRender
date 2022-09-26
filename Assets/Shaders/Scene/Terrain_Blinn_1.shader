Shader "Terrain_Blinn_1"
{
    Properties
    {
        _TintColorAll("Tint Color All", Color) = (1, 1, 1, 0)
        _ShadowColorAll("Shadow Color All", Color) = (0.098, 0.219, 0.239, 0)

        [Space(20)]
		_Layer1("Layer1", 2D) = "black" {}
        [HDR]_Layer1_Color("Tint Color", Color) = (1, 1, 1, 0)
        _Layer1_Brightness("Brightness", Range(0, 3)) = 1
        _Layer1_Saturation("Saturation", Range(0, 3)) = 1
        
        [Space(10)]
        _Layer1_SpecColor("Spec Color", Color) = (1, 1, 1, 1)
        _Layer1_Roughness("Roughness", Range(0.001, 1)) = 1
        _Layer1_SpecIntensity("SpecIntensity", Range(0.00, 5)) = 0
        
        [Space(10)]
        _Layer1_RimColor("Rim Color", Color) = (0.352, 0.705, 0.988, 0)
        _Layer1_RimPower("Rim Power", Float) = 80
        _Layer1_RimIntensity("Rim Intensity", Range(0, 1)) = 0
        
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
            #include "../OutlinePass.hlsl"
            #include "../MetaPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
                half4 _TintColorAll;
                half4 _ShadowColorAll;

                //1
                half4 _Layer1_ST;
                half4 _Layer1_Color;
                half _Layer1_Brightness;
                half _Layer1_Saturation;
    
                half4 _Layer1_SpecColor;
                half _Layer1_Roughness;
                half _Layer1_SpecIntensity;
            
                half4 _Layer1_RimColor;
                half _Layer1_RimPower;
                half _Layer1_RimIntensity;

            CBUFFER_END

            
        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
            Stencil
            {
                Ref 100
                Comp GEqual
                Pass Replace
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
            // Material Keywords
            #pragma multi_compile _ _HBAO_ON
            
            
            // sampler2D _AOMap;
            // sampler2D _SpecMask;

            TEXTURE2D(_Layer1);            SAMPLER(sampler_Layer1);

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
                //Dir
                half3 positionWS = i.positionWS;
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);
                half3 normalWS = normalize(i.normalWS);
                half NDotV = saturate(dot(normalWS, viewDir));

                //Shadow Light
                half4 shadowCoords = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(shadowCoords );
                half lightAtten = max(mainLight.shadowAttenuation, 0.0001);
                
                half3 lightDir = mainLight.direction;

                half3 localAdditionalLights = AdditionalLightsLambert(positionWS, normalWS);

                //BaseMap
                float2 uv_blend = float2(positionWS.x , positionWS.z) * 0.1;
                float2 uv_Layer1 = uv_blend * _Layer1_ST.xy + _Layer1_ST.zw;
                half4 layer1 = SAMPLE_TEXTURE2D(_Layer1, sampler_Layer1, uv_Layer1);

                //Blend
                half3 baseColor = layer1.rgb;
                half4 _Color = _Layer1_Color;
                half _Brightness = _Layer1_Brightness;
                half _Saturation = _Layer1_Saturation;
                half4 _SpecColor = _Layer1_SpecColor;
                half _Roughness = _Layer1_Roughness;
                half _SpecIntensity = _Layer1_SpecIntensity;
                half4 _RimColor = _Layer1_RimColor;
                half4 _RimPower = _Layer1_RimPower;
                half4 _RimIntensity = _Layer1_RimIntensity;

                

                //BaseColor
                baseColor = _Brightness * baseColor;
                half luminance = Luminance(baseColor);
                baseColor = lerp(luminance , baseColor, _Saturation);
                baseColor = _Color.rgb * baseColor * _TintColorAll.rgb;
                //
                // return half4(baseColor, 1);

                //SSAO
                half3 ssao = half3(1,1,1);
#ifdef _HBAO_ON
                ssao = SAMPLE_TEXTURE2D(_SSAOTex, sampler_SSAOTex, i.screenPos.xy / i.screenPos.w).rgb;
#endif
                
                half diffTerm = min(lightAtten, max(0.0,dot(normalWS, lightDir)));
                half3 diffTermColor = lerp(_ShadowColorAll.rgb, mainLight.color, diffTerm);
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
                half finalBloom = 1;

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
            
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ColorMask 0
            AlphaToMask Off
            
            Stencil
            {
                Ref 100
                Comp GEqual
                Pass Replace
                Fail Keep
                ZFail Keep
            }
            

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
            
            Stencil
            {
                Ref 100
                Comp GEqual
                Pass Replace
                Fail Keep
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            ENDHLSL
        }
        
        
        Pass
        {
            
            Name "Meta"
            Tags { "LightMode" = "Meta" }
            
            Stencil
            {
                Ref 100
                Comp GEqual
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
