Shader "Character_Face"
{
    Properties
    {
        _BrightMap("BrightMap", 2D) = "white" {}
        _DarkMap("DarkMap", 2D) = "white" {}
        _RampMap("RampMap", 2D) = "white" {}
        _ShadowColor("ShadowColor", Color) = (1, 1, 1, 0)
        _HairShadowXWidth("HairShadowXWidth", Range(0, 10)) = 5
        _HairShadowYWidth("HairShadowYWidth", Range(0, 10)) = 5
        _ShadowThreshold("ShadowThreshold", Range(0, 1)) = 0.5
        _ShadowSmoothStep("ShadowSmoothStep", Range(0, 1)) = 0.5
        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 0)
        _OutlineWidth("Outline Width 描边宽度", Range(0, 10)) = 0
        _OutlineBias("Outline Bias 描边偏移", Range(0, 10)) = 10
        _BloomFactor("BloomFactor", Range(0, 1)) = 0
        [Toggle(_FaceRamp_ON)] _FaceRamp("是否使用过渡图", Float) = 0
        
        [Header(Stencil)]
        _Stencil("Stencil ID", Float) = 50

        
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
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
            #include "../OutlinePass.hlsl"
            #include "../DepthOnlyPass.hlsl"
            #include "../DepthNormalsPass.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _OutlineColor;
            float4 _ShadowColor;
            half _OutlineWidth;
            half _OutlineBias;
            half _ShadowIntensity;
            half _ShadowThreshold;
            half _ShadowSmoothStep;
            half _HairShadowXWidth;
            half _HairShadowYWidth;
            half _BloomFactor;
            half4 _DissolveMap_ST;
            half _DissolveRange;
            CBUFFER_END
        
        ENDHLSL
        
        Pass
        {
            Name "Forward"
            Tags{"LightMode" = "UniversalForward"}

            
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
            #pragma multi_compile _ _DISSOLVE_ON

            
            #pragma multi_compile_local _ _FaceRamp_ON
            #pragma multi_compile _ _Character_Hair_Depth_Enable
            
            #pragma vertex CommonVertexFunction
            #pragma fragment frag
            
            // Textures
            sampler2D _BrightMap;
            sampler2D _DarkMap;
            sampler2D _RampMap;

            TEXTURE2D(_DissolveMap);            SAMPLER(sampler_DissolveMap);
            
            // Env params
            
            half4 frag (VertexOutput i) : SV_Target
            {
                //向量
                half3 normalWS = normalize(i.normalWS);
                half3 tangentWS = normalize(i.tangentWS);
                half3 bitangentWS = normalize(i.bitangentWS);
                half3 lightDir = normalize(_CharacterLightDirection.xyz);
                half2 lightDirXZ = normalize(lightDir.xz);
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);

                float2 uv = i.uv.xy;
                
                half rampShadowRange = 0;
#ifdef _FaceRamp_ON
                //向量
                half3 upDir = half3(0, 1, 0);

                half3 frontDir = TransformObjectToWorldDir(half3(0, 1, 0), true); //因为模型默认朝下的，X转了一个-90

                half2 rightDir = normalize(cross(upDir, frontDir).xz);
                half2 frontDirXZ = frontDir.xz;
                half frontHalfLambert = (dot(frontDirXZ, lightDirXZ) + 1) * 0.5;
                half isRight = step(dot(rightDir, lightDirXZ), 0);

                // return half4(frontHalfLambert.rrr, 1);
                
                //采样过渡图
                half rampLeft = frontHalfLambert - tex2D(_RampMap, uv).r;
                half rampRight = frontHalfLambert - tex2D(_RampMap, float2(1 - uv.x, uv.y)).r;
                rampShadowRange = lerp(saturate(rampLeft / fwidth(rampLeft)), saturate(rampRight / fwidth(rampRight)), isRight);

                // return half4(rampShadowRange.rrr, 1);
#else
                //自然光照
                half halfLambert = dot(_CharacterLightDirection, normalWS) * 0.5 + 0.5;
                rampShadowRange = smoothstep(_ShadowThreshold - _ShadowSmoothStep, _ShadowThreshold + _ShadowSmoothStep, halfLambert);
#endif
                

                // return half4(rampShadowRange.rrr, 1);
                
                //贴图数据
                half4 darkMap = tex2D(_DarkMap, uv);
                half4 brightMap = tex2D(_BrightMap, uv);

                // half atten = MainLightRealtimeShadow(TransformWorldToShadowCoord(i.positionWS));
                // half3 characterShadowColor = lerp(_CharacterShadowColor, half4(1,1,1,1), atten).rgb;
                half3 characterShadowColor = half3(1,1,1);

                half hairShadowRange = 1;

#ifdef _Character_Hair_Depth_Enable
                    //头发投影
                half4 screenPos = i.screenPos;
                half4 screenPosNorm = screenPos / screenPos.w;
                // screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;

                //添加灯光偏移
                half hairOffsetX = _HairShadowXWidth * 0.01 / i.positionCS.w;
                half hairOffsetY = _HairShadowYWidth * 0.01 / i.positionCS.w;
                // half3 lightDirCameraSpace = mul(unity_WorldToCamera, half4(_CharacterLightDirection.xyz, 0)).xyz;
                half3 lightDirCameraSpace = mul(UNITY_MATRIX_V, half4(_CharacterLightDirection.xyz, 0)).xyz;

                half2 targetHairScreenPos = half2(screenPosNorm.x + (lightDirCameraSpace.x * hairOffsetX) , screenPosNorm.y + lightDirCameraSpace.y * hairOffsetY);
                
                half hairDepth = SAMPLE_TEXTURE2D(_HairShadowDepth, sampler_HairShadowDepth, targetHairScreenPos).r;
                //Demo1 Use Color Buffer
                // half depth = (i.positionCS.xyz / i.positionCS.w).z;
                // hairShadowRange = step(depth, hairDepth);

                //Demo2 Use DepthBuffer
                hairShadowRange = step(i.positionCS.z, hairDepth);

                // return half4(hairShadowRange.rrr, 1);

#endif
                
                half finalShadowRange = saturate(hairShadowRange * rampShadowRange);
                
                half3 finalColor = lerp(darkMap, brightMap, finalShadowRange).rgb;

                //Additional Light
                half3 localAdditionalLights = AdditionalLightsLambert(i.positionWS, normalWS);
                half3 additionalColor = localAdditionalLights * finalColor;
                
                half3 lightColor = GetFinalLightColor(normalWS);
                finalColor = finalColor * lightColor * characterShadowColor;// + additionalColor;

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
                o.uv = v.uv;
                return o;
            }

            half4 OutlineFragFunction (VertexOutputOutline i) : SV_Target
            {
                float3 baseColor = tex2D(_BrightMap, i.uv.xy).rgb;
                half3 outlineColor = GetOutlineColor(baseColor, _OutlineColor.rgb, i.positionCS);

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
        
        
        UsePass "Character_Standard/ShadowCaster"

        
    }
}