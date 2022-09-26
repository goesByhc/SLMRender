Shader "Character_Standard"
{
    Properties
    {
        _BrightMap("Bright Map 明部贴图", 2D) = "white" {}
        _DarkMap("Dark Map 暗部贴图", 2D) = "white" {}
        [Gamma]_LightMap("Light Map 光照贴图", 2D) = "gray" {}
        _TintColor("Tint Color 整体颜色", Color) = (1, 1, 1, 1)
        _CustomShadowWeight("Custom Shadow Weight 贴图阴影权重", Range(0, 2)) = 1
        _AOIntensity("AO Intensity AO强度", Range(0, 1)) = 1
        
        [Space(10)]
        [Header(Shadow)]
        [Space(10)]
        _ShadowThreshold("Shadow Threshold 阴影阈值", Range(0, 1)) = 0.001
        _DarkColor("Dark Color 暗部颜色", Color) = (0.5, 0.5, 0.5 ,1)
        _DarkThreshold("Dark Threshold 暗部阈值", Range(-0.1, 1)) = 0.001
        _DarkSmoothStep("Dark Smooth Step 暗部阴影过渡", Range(0, 1)) = 0.5
        
        [Space(10)]
        [Header(Specular)]
        [Space(10)]
        _SpecTintColor("SpecTintColor 高光颜色", Color) = (1,1,1,1)
        _SpecIntensity("Spec Intensity 高光强度", Range(0, 100)) = 30
        _SpecSize("Spec Size 高光范围大小", Range(0, 100)) = 30
        _SpecSizeScale("Spec Size Weight 贴图高光权重", Range(0, 0.5)) = 0.1
        _SpecGradient("Spec Gradient 高光随角度减弱", Range(0, 1)) = 0.1
        _SpecThreshold("Spec Threshold 高光阈值", Range(0, 1)) = 0
        _SpecSmoothStep("Spec Smooth Step 高光过渡", Range(0, 1)) = 0
        
        [Space(10)]
        [Header(Rim)]
        [Space(10)]
        _RimColor("Rim Color 边缘光颜色", Color) = (0,1,0.8758622,1)
        _RimWidth("Rim Width 边缘光宽度", Range(0, 0.5)) = 0.2
        _RimThreshold("Rim Threshold 边缘阈值", Range(0.1, 10)) = 2
        _RimIntensity("Rim Intensity 边缘光强度", Range(0, 100)) = 80
        _RimThresholdShallow("Rim Threshold Shallow 浅边缘阈值", Range(0.01, 1)) = 0.02
        _RimIntensityShallow("Rim Intensity Shallow 浅边缘光强度", Range(0, 100)) = 50
        _RimPow("Rim Pow 随角度衰减", Range(0, 10)) = 4

        
        [Space(10)]
        [Header(Outline)]
        [Space(10)]
        _InnerLineColor("Innerline Color 内描边颜色", Color) = (0, 0, 0, 0)
        _OutlineColor("Outline Color 描边颜色", Color) = (0, 0, 0, 0)
        _OutlineWidth("Outline Width 描边宽度", Range(0, 10)) = 0
        _OutlineBias("Outline Bias 描边偏移", Range(0, 10)) = 10
        
        [Space(10)]
        [Header(Bloom)]
        [Space(10)]
        _BloomFactor("BloomFactor", Range(0, 1)) = 0
        
        [Header(Stencil)]
        _Stencil("Stencil ID", Float) = 50
        
        
        [Space(10)]
        [Toggle]_ADDITIONAL_LIGHT("Enable Additional Light", Int) = 1
        
        [Space(10)]
        [Toggle]_DISSOLVE("Dissolve", Int) = 0
        _DissolveMap("Dissolve Map", 2D) = "white" {}
        _DissolveRange("Dissolve Range", Range(0, 1)) = 0

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
            #include "../Core.hlsl"
            #include "../OutlinePass.hlsl"
            #include "../ForwardPass.hlsl"
            #include "../ShadowCasterPass.hlsl"
            #include "../DepthOnlyPass.hlsl"
            #include "../DepthNormalsPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            half4 _TintColor;
            half4 _DarkColor;
            half4 _SpecTintColor;
            half4 _RimColor;
            half4 _InnerLineColor;
            half4 _OutlineColor;
            half _CustomShadowWeight;
            half _AOIntensity;
            half _ShadowThreshold;
            half _DarkThreshold;
            half _DarkSmoothStep;
            half _SpecThreshold;
            half _SpecIntensity;
            half _SpecGradient;
            half _SpecSize;
            half _SpecSizeScale;
            half _SpecSmoothStep;
            half _RimThreshold;
            half _RimWidth;
            half _RimIntensity;
            half _RimThresholdShallow;
            half _RimIntensityShallow;
            half _RimPow;
            half _OutlineWidth;
            half _OutlineBias;
            half _BloomFactor;
            half4 _DissolveMap_ST;
            half _DissolveRange;
            CBUFFER_END

        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags {"LightMode" = "UniversalForward"}

            //写深度用
            ZTest LEqual
            ZWrite True
            ColorMask 0

            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace 
                Fail Keep
                ZFail Keep
            }
            

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_ON
            #pragma multi_compile _ _DISSOLVE_ON

            #pragma multi_compile_instancing
            #pragma prefer_hlslcc gles
            
            TEXTURE2D(_DissolveMap);            SAMPLER(sampler_DissolveMap);
            
            #pragma vertex CommonVertexFunction
            #pragma fragment frag
            
            half4 frag (VertexOutput i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);


#ifdef _DISSOLVE_ON
                half2 dissolveUV = i.screenPos.xy / i.screenPos.w * _DissolveMap_ST.xy;
                dissolveUV.x *= _ScreenParams.x / _ScreenParams.y;
                half dissolveValue = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, dissolveUV).r + 0.001;

                // half diss = step(dissolveValue, _DissolveRange);
                clip(dissolveValue - _DissolveRange);
#endif

                return half4(0,0,0,0);
            }
            ENDHLSL
        }
        
        
        Pass
        {
            Name "Character"
            Tags {"LightMode" = "Character"}

            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace 
                Fail Keep
                ZFail Keep
            }
            
            ZWrite False
            ZTest Equal
            
            
            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _DISSOLVE_ON
            
            #pragma multi_compile_instancing
            #pragma prefer_hlslcc gles
            

            #pragma vertex CommonVertexFunction
            #pragma fragment frag

            // Textures
            TEXTURE2D(_BrightMap);              SAMPLER(sampler_BrightMap);
            TEXTURE2D(_DarkMap);                SAMPLER(sampler_DarkMap);
            TEXTURE2D(_LightMap);               SAMPLER(sampler_LightMap);
            TEXTURE2D(_DissolveMap);            SAMPLER(sampler_DissolveMap);

            
            half4 frag (VertexOutput i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                //向量 
                half3 normalWS = normalize(i.normalWS);
                half3 tangentWS = normalize(i.tangentWS);
                half3 bitangentWS = normalize(i.bitangentWS);
                half3 lightDir = normalize(_CharacterLightDirection.xyz);
                half2 lightDirXZ = normalize(lightDir.xz);
                half3 positionWS = i.positionWS;
                half3 viewDir = normalize(_WorldSpaceCameraPos - positionWS);
                half lambertF = dot(normalWS, lightDir);

                
                float2 uv0 = i.uv.xy;
                float2 uv1 = i.uv.zw;
                
                //贴图数据
                half4 brightMap = SAMPLE_TEXTURE2D(_BrightMap, sampler_BrightMap, uv0);
                half4 darkMap = SAMPLE_TEXTURE2D(_DarkMap, sampler_DarkMap, uv0);
                half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, uv0);
                half diffuseControl = lightMap.r;
                half specSize = lightMap.g;
                half specIntensity = lightMap.b;
                half ao = lerp(1, lightMap.a, _AOIntensity);

                half innerLine2 = SAMPLE_TEXTURE2D(_DarkMap, sampler_DarkMap, uv1).a;
                
                //DecodeColor
                half3 brightColor = brightMap.rgb;
                half3 darkBaseColor = darkMap.rgb;
                half3 shadowColor = darkBaseColor;
                half3 darkColor = darkBaseColor * _DarkColor;

                half innerLine = brightMap.a * innerLine2;
                half3 innerLineColor = GetOutlineColor(brightColor, _InnerLineColor, i.positionCS);

                //Diffuse
                half3 characterShadowColor = half3(1,1,1);
                half halfLambert = lambertF * 0.5 + 0.5;
                half lambertTerm = saturate(halfLambert + (diffuseControl * 2 - 1) * _CustomShadowWeight);
                
                const half deepShadowRange = 0.1;
                half forceShadowRange = StepAntialiasing(deepShadowRange, diffuseControl);
                half finalShadowValue = min(lambertTerm, forceShadowRange) * ao;

                half shadowRange = StepAntialiasing(_ShadowThreshold, finalShadowValue);
                half darkRange = saturate(smoothstep(_DarkThreshold - _DarkSmoothStep, _DarkThreshold + _DarkSmoothStep, finalShadowValue));
                half3 finalShadowColor = lerp(darkColor, shadowColor, darkRange);
                half3 diffuseColor = lerp(finalShadowColor, brightColor, shadowRange);
                half3 baseColor = diffuseColor;
                diffuseColor = diffuseColor * _TintColor * characterShadowColor;


                //Specular
                half NDotH = max(dot(normalize(lightDir + viewDir), normalWS), 0.0001);
                half specSizeNDotH = pow(NDotH, 50 / _SpecSize);
                half specSizeTerm = (_SpecSizeScale + specSizeNDotH) * specSize;
                half NDotVHalf = dot(normalWS, viewDir) * 0.5 + 0.5;
                half specGradient = sqrt(max(halfLambert / NDotVHalf, 0)) * _SpecGradient;
                half specValue = specSizeTerm - specGradient;
                specValue = smoothstep(_SpecThreshold - _SpecSmoothStep, _SpecThreshold + _SpecSmoothStep, specValue);
                half3 specColor = diffuseColor * _SpecTintColor * ao * specValue * specIntensity * _SpecIntensity;


                //Rim
                half lambertFPositive = max(0, lambertF);
                half rim = 1 - saturate(dot(viewDir, normalWS));
                half rimDot = pow(rim, _RimPow);

                half4 screenPos = i.screenPos;
                half4 screenPosNorm = screenPos / screenPos.w;
                half rimOffsetLength = (_RimWidth * 0.1) / i.positionCS.w;
                half2 rimOffsetDir = normalize(mul(UNITY_MATRIX_VP, normalWS).xy); 
                half currentDepth = LinearEyeDepth(i.positionCS.z, _ZBufferParams);

                half2 targetRimPosCS = screenPosNorm + rimOffsetDir * rimOffsetLength;
                half targetDepth = LinearEyeDepth(SampleSceneDepth(targetRimPosCS), _ZBufferParams);

                half rimValueDeep = step(_RimThreshold, targetDepth - currentDepth) * _RimIntensity;
                half rimValueShallow = step(_RimThresholdShallow, targetDepth - currentDepth) * _RimIntensityShallow;
                half rimValue = max(rimValueDeep, rimValueShallow);
                rimValue = max(0, rimValue * rimDot);
                half3 rimColor = rimValue * _RimColor * diffuseColor * lambertFPositive;

                // return half4(rimColor.rrr, 1);

                //Additional Light

                #ifdef _ADDITIONAL_LIGHT_ON
                half3 localAdditionalLights = AdditionalLightsLambert(positionWS, normalWS);
                #else
                half3 localAdditionalLights = half3(0,0,0);
                #endif
                
                half3 additionalColor = localAdditionalLights * baseColor;
                
                half3 finalColor = diffuseColor + specColor + rimColor;
                // finalColor = pow(finalColor, 1.0 / 2.2);
                half3 lightColor = GetFinalLightColor(normalWS);
                finalColor *= lightColor;
                finalColor += additionalColor;
                finalColor = lerp(innerLineColor, finalColor, innerLine);

                half finalBloom = GetCharacterFinalBloom(_BloomFactor);

#ifdef _DISSOLVE_ON
                half2 dissolveUV = i.screenPos.xy / i.screenPos.w * _DissolveMap_ST.xy;
                dissolveUV.x *= _ScreenParams.x / _ScreenParams.y;
                half dissolveValue = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, dissolveUV).r + 0.001;

                // half diss = step(dissolveValue, _DissolveRange);
                clip(dissolveValue - _DissolveRange);
#endif



                
                return half4(finalColor, finalBloom);
            }
            ENDHLSL
        }
        
        
        Pass
        {
            Name "Outline"
            Tags{"LightMode" = "Outline"}
            
            Cull Front
            
            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace 
                Fail Keep
                ZFail Keep
            }
            

            HLSLPROGRAM

            #pragma multi_compile _ _DISSOLVE_ON

            
            #pragma vertex OutlineVertFunction
            #pragma fragment OutlineFragFunction
            
            // Textures
            sampler2D _BrightMap;
            TEXTURE2D(_DissolveMap);            SAMPLER(sampler_DissolveMap);

            VertexOutputOutline OutlineVertFunction( VertexInput v)
            {

                VertexOutputOutline o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.positionCS = GetCharacterOutlinePositionHClip(v, _OutlineWidth, _OutlineBias);
                o.screenPos = ComputeScreenPos(o.positionCS);
                o.uv = v.uv;
                return o;
            }

            half4 OutlineFragFunction (VertexOutputOutline i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                half3 baseColor = tex2D(_BrightMap, i.uv.xy).rgb;
                half3 outlineColor = GetOutlineColor(baseColor, _OutlineColor, i.positionCS);

#ifdef _DISSOLVE_ON
                half2 dissolveUV = i.screenPos.xy / i.screenPos.w * _DissolveMap_ST.xy;
                dissolveUV.x *= _ScreenParams.x / _ScreenParams.y;
                half dissolveValue = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, dissolveUV).r + 0.001;

                // half diss = step(dissolveValue, _DissolveRange);
                clip(dissolveValue - _DissolveRange);
#endif
                
                return float4(outlineColor, 1.0);
            }

            ENDHLSL
        }
        
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual

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

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            
            #pragma vertex CustomDepthOnlyVertex
            #pragma fragment DepthOnlyFragment


            VertexOutputDepth CustomDepthOnlyVertex(VertexInput input)
            {
                VertexOutputDepth output = (VertexOutputDepth)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
                output.positionCS = GetOutlinePositionHClip(input, _OutlineWidth, _OutlineBias);
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
            Cull Back
            
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
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

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