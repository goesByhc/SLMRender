Shader "Terrain_Blinn"
{
    Properties
    {
        _BlendMap ("Texture", 2D) = "white" {}
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
        
        [Space(20)]
        _Layer2("Layer2", 2D) = "black" {}
        [HDR]_Layer2_Color("Tint Color", Color) = (1, 1, 1, 0)
        _Layer2_Brightness("Brightness", Range(0, 3)) = 1
        _Layer2_Saturation("Saturation", Range(0, 3)) = 1
        
        [Space(10)]
        _Layer2_SpecColor("Spec Color", Color) = (1, 1, 1, 1)
        _Layer2_Roughness("Roughness", Range(0.001, 1)) = 1
        _Layer2_SpecIntensity("SpecIntensity", Range(0.00, 5)) = 0
        
        [Space(10)]
        _Layer2_RimColor("Rim Color", Color) = (0.352, 0.705, 0.988, 0)
        _Layer2_RimPower("Rim Power", Float) = 80
        _Layer2_RimIntensity("Rim Intensity", Range(0, 1)) = 0
        
        [Space(20)]
        _Layer3("Layer3", 2D) = "black" {}
        [HDR]_Layer3_Color("Tint Color", Color) = (1, 1, 1, 0)
        _Layer3_Brightness("Brightness", Range(0, 3)) = 1
        _Layer3_Saturation("Saturation", Range(0, 3)) = 1
        
        [Space(10)]
        _Layer3_SpecColor("Spec Color", Color) = (1, 1, 1, 1)
        _Layer3_Roughness("Roughness", Range(0.001, 1)) = 1
        _Layer3_SpecIntensity("SpecIntensity", Range(0.00, 5)) = 0
        
        [Space(10)]
        _Layer3_RimColor("Rim Color", Color) = (0.352, 0.705, 0.988, 0)
        _Layer3_RimPower("Rim Power", Float) = 80
        _Layer3_RimIntensity("Rim Intensity", Range(0, 1)) = 0
        
        
        [Space(20)]
        _Layer4("Layer4", 2D) = "black" {}
        [HDR]_Layer4_Color("Tint Color", Color) = (1, 1, 1, 0)
        _Layer4_Brightness("Brightness", Range(0, 3)) = 1
        _Layer4_Saturation("Saturation", Range(0, 3)) = 1
        
        [Space(10)]
        _Layer4_SpecColor("Spec Color", Color) = (1, 1, 1, 1)
        _Layer4_Roughness("Roughness", Range(0.001, 1)) = 1
        _Layer4_SpecIntensity("SpecIntensity", Range(0.00, 5)) = 0
        
        [Space(10)]
        _Layer4_RimColor("Rim Color", Color) = (0.352, 0.705, 0.988, 0)
        _Layer4_RimPower("Rim Power", Float) = 80
        _Layer4_RimIntensity("Rim Intensity", Range(0, 1)) = 0
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
                half4 _BlendMap_ST;
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


                //2
                half4 _Layer2_ST;
                half4 _Layer2_Color;
                half _Layer2_Brightness;
                half _Layer2_Saturation;
    
                half4 _Layer2_SpecColor;
                half _Layer2_Roughness;
                half _Layer2_SpecIntensity;
            
                half4 _Layer2_RimColor;
                half _Layer2_RimPower;
                half _Layer2_RimIntensity;


                //3
                half4 _Layer3_ST;
                half4 _Layer3_Color;
                half _Layer3_Brightness;
                half _Layer3_Saturation;
    
                half4 _Layer3_SpecColor;
                half _Layer3_Roughness;
                half _Layer3_SpecIntensity;
            
                half4 _Layer3_RimColor;
                half _Layer3_RimPower;
                half _Layer3_RimIntensity;


                //4
                half4 _Layer4_ST;
                half4 _Layer4_Color;
                half _Layer4_Brightness;
                half _Layer4_Saturation;
                half4 _Layer4_ShadowColor;
    
                half4 _Layer4_SpecColor;
                half _Layer4_Roughness;
                half _Layer4_SpecIntensity;
            
                half4 _Layer4_RimColor;
                half _Layer4_RimPower;
                half _Layer4_RimIntensity;
        

                half _BloomFactor;
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


            TEXTURE2D(_BlendMap);          SAMPLER(sampler_BlendMap);
            TEXTURE2D(_Layer1);            SAMPLER(sampler_Layer1);
            TEXTURE2D(_Layer2);            SAMPLER(sampler_Layer2);
            TEXTURE2D(_Layer3);            SAMPLER(sampler_Layer3);
            TEXTURE2D(_Layer4);            SAMPLER(sampler_Layer4);



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


            half Blend(half4 blendFactor, half p1, half p2, half p3, half p4)
            {
                return blendFactor.r * p1 + blendFactor.g * p2 + blendFactor.b * p3 + blendFactor.a * p4;
            }

            half4 Blend(half4 blendFactor, half4 p1, half4 p2, half4 p3, half4 p4)
            {
                return blendFactor.r * p1 + blendFactor.g * p2 + blendFactor.b * p3 + blendFactor.a * p4;
            }


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
                float2 uv_BlendMap = uv * _BlendMap_ST.xy + _BlendMap_ST.zw;
                half4 blendMap = SAMPLE_TEXTURE2D(_BlendMap, sampler_BlendMap, uv_BlendMap);

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
                float2 uv_Layer2 = uv_blend * _Layer2_ST.xy + _Layer2_ST.zw;
                half4 layer2 = SAMPLE_TEXTURE2D(_Layer2, sampler_Layer2, uv_Layer2);
                float2 uv_Layer3 = uv_blend * _Layer3_ST.xy + _Layer3_ST.zw;
                half4 layer3 = SAMPLE_TEXTURE2D(_Layer3, sampler_Layer3, uv_Layer3);
                float2 uv_Layer4 = uv_blend * _Layer4_ST.xy + _Layer4_ST.zw;
                half4 layer4 = SAMPLE_TEXTURE2D(_Layer4, sampler_Layer4, uv_Layer4);
                
                //Blend
                half3 baseColor = Blend(blendMap, layer1, layer2, layer3, layer4).rgb;
                half4 _Color = Blend(blendMap, _Layer1_Color, _Layer2_Color, _Layer3_Color, _Layer4_Color);
                half _Brightness = Blend(blendMap, _Layer1_Brightness, _Layer2_Brightness, _Layer3_Brightness, _Layer4_Brightness);
                half _Saturation = Blend(blendMap, _Layer1_Saturation, _Layer2_Saturation, _Layer3_Saturation, _Layer4_Saturation);
                half4 _SpecColor = Blend(blendMap, _Layer1_SpecColor, _Layer2_SpecColor, _Layer3_SpecColor, _Layer4_SpecColor);
                half _Roughness = Blend(blendMap, _Layer1_Roughness, _Layer2_Roughness, _Layer3_Roughness, _Layer4_Roughness);
                half _SpecIntensity = Blend(blendMap, _Layer1_SpecIntensity, _Layer2_SpecIntensity, _Layer3_SpecIntensity, _Layer4_SpecIntensity);
                half4 _RimColor = Blend(blendMap, _Layer1_RimColor, _Layer2_RimColor, _Layer3_RimColor, _Layer4_RimColor);
                half4 _RimPower = Blend(blendMap, _Layer1_RimPower, _Layer2_RimPower, _Layer3_RimPower, _Layer4_RimPower);
                half4 _RimIntensity = Blend(blendMap, _Layer1_RimIntensity, _Layer2_RimIntensity, _Layer3_RimIntensity, _Layer4_RimIntensity);

                

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
