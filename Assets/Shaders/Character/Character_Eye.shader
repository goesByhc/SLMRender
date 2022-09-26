Shader "Character_Eye"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
//        _NormalMap("Normal Map", 2D) = "bump" {}
//        _EyeCenter("Eye Center", Vector) = (0.5, 0.5, 0.5, 0.5)
        _EnvMap("Env Map", Cube) = "white" {}
        _EnvRotate("Env Rotate", Range(0, 360)) = 0
        _Roughness("Roughness", Range(0, 1)) = 1
        _EnvIntensity("Env Intensity", float) = 0.5
//        _Parallax("Parallax", Range(-0.5, 0)) = -0.1
        _EyeShadowIntensity("Eye Shadow Intensity", Range(0, 3)) = 1
        
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
            #include "../DepthOnlyPass.hlsl"
            #include "../DepthNormalsPass.hlsl"
            #include "../ForwardPass.hlsl"
            
        
            CBUFFER_START(UnityPerMaterial)
            // half4 _EyeCenter;
            half _EnvRotate;
            half _Roughness;
            half _EnvIntensity;
            // half _Parallax;
            half _EyeShadowIntensity;
            half4 _EnvMap_HDR;
            half4 _DissolveMap_ST;
            half _DissolveRange;
            CBUFFER_END
        
        ENDHLSL
        

        Pass
        {
            Name "Forward"
            Tags{"LightMode" = "UniversalForward"}

            
            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _DISSOLVE_ON

            #pragma multi_compile_instancing

            #pragma vertex CommonVertexFunction
            #pragma fragment frag
            
            // Textures
            sampler2D _BaseMap;
            // samplerCUBE _EnvMap;

            TEXTURECUBE(_EnvMap);               SAMPLER(sampler_EnvMap);
            TEXTURE2D(_DissolveMap);            SAMPLER(sampler_DissolveMap);
            

            half4 frag (VertexOutput i) : SV_Target
            {
                //向量
                half3 normalWS = normalize(i.normalWS);
                half3 tangentWS = normalize(i.tangentWS);
                half3 bitangentWS = normalize(i.bitangentWS);
                half3 lightDir = normalize(_CharacterLightDirection.xyz);
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);

                float2 uv = i.uv.xy;
                
                //法线贴图
                //half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                //half3 normalData = UnpackNormal(normalMap);
                //float3x3 TBN = float3x3(tangentWS, bitangentWS, normalWS);
                //normalWS = normalize(mul(normalData, TBN));
                //normalData.xy = -normalData.xy;
                //float3 normalDirIris = normalize(mul(normalData, TBN));

                // half atten = MainLightRealtimeShadow(TransformWorldToShadowCoord(i.positionWS));
                // half3 characterShadowColor = lerp(_CharacterShadowColor, half4(1,1,1,1), atten).rgb;
                half3 characterShadowColor = half3(1,1,1);

                
                //视差偏移
                // float2 parallaxDepth = smoothstep(1.0, 0.5, distance(uv, float2(_EyeCenter.x, _EyeCenter.y)) / float2(_EyeCenter.z, _EyeCenter.w));
                // float3 tanViewDir = normalize(mul(TBN, viewDir));
                // float2 parallax_offset = parallaxDepth * (tanViewDir.xy / (tanViewDir.z + 0.42f)) * _Parallax;
                // return float4(parallax_offset.xy, 1, 1);

                //贴图数据
                half4 baseColor = tex2D(_BaseMap, uv).rgba;
                half alpha = baseColor.a;
                
                //漫反射
                half NDotL = dot(normalWS.xz, lightDir.xz);
                half halfLambert = (NDotL + 1.0) * 0.5;
                half3 finalDiffuse = halfLambert * baseColor * baseColor * characterShadowColor;


                //环境反射/边缘光
                half3 reflectDir = reflect(-viewDir, normalWS);
                reflectDir = RotateAround(_EnvRotate, reflectDir);
                float roughness = lerp(0.0, 0.95, saturate(_Roughness));
                roughness = roughness * (1.7 - 0.7 * roughness);
                float mip_level = roughness * 6.0;
                half4 color_cubemap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, reflectDir, mip_level);
                half3 env_color = DecodeHDREnvironment(color_cubemap, _EnvMap_HDR);
                half3 final_env = env_color * _EnvIntensity;
                half env_lumin = dot(final_env, float3(0.299f, 0.587f, 0.114f));
                final_env = final_env * env_lumin;

                //light probe
                float3 indirectDiffuse = SampleSH(normalWS);
                float3 finalIndirect = lerp(float3(0,0,0), indirectDiffuse, _SceneLightProbe);
                float3 finalLight = _CharacterLightColor * _CharacterLightIntensity + finalIndirect;

                half3 finalColor = finalDiffuse;
                finalColor *= finalLight;

                //tonemapping
                half3 encodeColor = sqrt(ACESFilm(finalColor));
                encodeColor = encodeColor * saturate(pow(alpha, _EyeShadowIntensity));

#ifdef _DISSOLVE_ON
                half2 dissolveUV = i.screenPos.xy / i.screenPos.w * _DissolveMap_ST.xy;
                dissolveUV.x *= _ScreenParams.x / _ScreenParams.y;
                half dissolveValue = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, dissolveUV).r + 0.001;

                // half diss = step(dissolveValue, _DissolveRange);
                clip(dissolveValue - _DissolveRange);
#endif
                
                return half4(encodeColor, 1.0);
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
        
        
        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 4.5
            #pragma prefer_hlslcc gles

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
