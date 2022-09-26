Shader "Character_Eyebrow"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BackClip("BackClip", Range(-0.5, 0.5)) = 0.15
        
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Header(Stencil)]
        _Stencil("Stencil ID", Float) = 50
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        
        
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

            CBUFFER_START(UnityPerMaterial)
            float _BackClip;
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
                Fail Replace
            }
            
            ZTest [_ZTest]
            ZWrite [_ZWrite]
            
            Cull Back

            HLSLPROGRAM
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _DISSOLVE_ON

            #pragma multi_compile_instancing
            
            #pragma vertex CommonVertexFunction
            #pragma fragment frag


            //Texture
            sampler2D _BaseMap;
            TEXTURE2D(_DissolveMap);            SAMPLER(sampler_DissolveMap);

            half4 frag(VertexOutput i) : SV_Target
            {
                //向量
                half3 normalWS = normalize(i.normalWS);
                half3 tangentDir = normalize(i.tangentWS);
                half3 binormalDir = normalize(i.bitangentWS);
                half3 lightDir = normalize(_CharacterLightDirection.xyz);
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS.xyz);
                half3 frontDir = TransformObjectToWorldDir(half3(0, 1, 0), true); //因为模型默认朝下的，X转了一个-90
                half frontDotView = dot(frontDir.xyz, viewDir);

                // half atten = MainLightRealtimeShadow(TransformWorldToShadowCoord(i.positionWS));
                // half3 characterShadowColor = lerp(_CharacterShadowColor, half4(1,1,1,1), atten).rgb;
                half3 characterShadowColor = half3(1,1,1);

                
                // return frontDotView;
                clip(frontDotView + _BackClip);

                float3 indirectDiffuse = normalWS;
                float3 finalIndirect = lerp(float3(0, 0, 0), indirectDiffuse, _SceneLightProbe);
                float3 finalLight = _CharacterLightColor * _CharacterLightIntensity + finalIndirect;

                float2 uv = i.uv;
                //贴图数据
                half3 base_color = tex2D(_BaseMap, uv).rgb;

                // return half4(base_color, 1);
                
                //漫反射
                half NDotL = max(0.0, dot(normalWS, lightDir));
                half half_lamber = (NDotL + 1.0) * 0.5;
                half3 final_diffuse = base_color * characterShadowColor * finalLight;

                //Additional Light
                half3 localAdditionalLights = AdditionalLightsLambert(i.positionWS, normalWS);
                half3 additionalColor = localAdditionalLights * base_color;

                half3 finalColor = final_diffuse + additionalColor;


#ifdef _DISSOLVE_ON
                half2 dissolveUV = i.screenPos.xy / i.screenPos.w * _DissolveMap_ST.xy;
                dissolveUV.x *= _ScreenParams.x / _ScreenParams.y;
                half dissolveValue = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, dissolveUV).r + 0.001;

                // half diss = step(dissolveValue, _DissolveRange);
                clip(dissolveValue - _DissolveRange);
#endif
                
                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }

        UsePass "Character_Eye/DepthOnly"

    }
}