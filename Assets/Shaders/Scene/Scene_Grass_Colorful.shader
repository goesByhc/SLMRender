Shader "Scene_Grass_Colorful" //GPU Instancer Setup
{
    Properties
    {
        _BrightColor("Bright Color", Color) = (1,1,1,1)
        _DarkColor("Shadow Color", Color) = (0.04245281,1,0.08771499,1)
        _FlowerColor("Flower Color", Color) = (1,0,0,1)
        _ShadowColor("Shadow Color", Color) = (0,0,0,1)
        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1
        _SSSColor("SSS Color", Color) = (1,1,1,1)
        _SSSIntensity("SSS Intensity", Range(0, 1)) = 0 
        _SSSPower("SSS Power", Range(0, 20)) = 1
        _SSSRotation("SSS Rotation", Float) = 0
        
        _WindMultiplier("Wind Multiplier", Float) = 1
    }

    SubShader
    {
        
        
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent-100"
//            "RenderType" = "Opaque"
//            "Queue" = "Geometry"
        }
            
        
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "./../../../Plugins/GPUInstancer/Shaders/Include/GPUInstancerInclude.cginc"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
    
            CBUFFER_START(UnityPerMaterial)
            half4 _BrightColor;
            half4 _DarkColor;
            half4 _FlowerColor;
            half4 _ShadowColor;
            half4 _SSSColor;
            half _ShadowIntensity;
            half _SSSPower;
            half _SSSIntensity;
            half _SSSRotation;
            half _WindMultiplier;
            // half4 _WindNoiseTex_ST;
            // half _BloomFactor;
            CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" } //这个Pass只写深度，避免混合错误
                        
            ZTest LEqual
            ZWrite On
            Cull Off
            
            ColorMask 0
            
            HLSLPROGRAM
            #pragma target 4.5
            #pragma prefer_hlslcc gles
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            
            

            #pragma vertex vert
            #pragma fragment frag

            // sampler2D _WindNoiseTex;


            // VertexOutputSimple vert(VertexInputSimple v, uint instanceID: SV_InstanceID)
            VertexOutputSimple vert(VertexInputSimple v)
            {
                VertexOutputSimple o = (VertexOutputSimple)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                half3 windScaler = WindScaler(positionWS);
                half3 wind = windScaler * v.positionOS.y * v.positionOS.y * _WindMultiplier * _WindDirection.xyz;
                //
                half3 positionOS = v.positionOS.xyz + wind;
                positionWS = TransformObjectToWorld(positionOS);

                // ===== wind ========
                // half fix = step(0.05, v.positionOS.y);
                // //
                // float2 samplePos = positionWS.xz;
                // TODO: 采样Noise贴图后，无法正确获取LightMapAtten，待查
                // float waveSample = tex2Dlod(_WindNoiseTex, float4(samplePos * _WindNoiseTex_ST.xy * 0.01 + _Time.x * _WindFrequency , 0, 0)).r;
                // positionWS.xy += waveSample * v.color.b * _WindMultiplier * _WindDirection; //顶点色控制
                // positionWS.xz += waveSample * fix * v.positionOS.y * v.positionOS.y * _WindMultiplier * _WindDirection * _WindSpeed; //根据高度计算 //

                o.positionWS = positionWS;
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.color = v.color;

                return o;
            }

            
            half4 frag(VertexOutputSimple i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);


                return 0;
            }
            ENDHLSL

        }
        
        Pass
        {
            Name "CommonTransparent"
            Tags { "LightMode" = "CommonTransparent" }

            
            ZTest Equal
            ZWrite Off
            Cull Off
            
            ColorMask RGB
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma target 4.5
            #pragma prefer_hlslcc gles

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing
            
            #pragma vertex vert
            #pragma fragment frag

            // sampler2D _WindNoiseTex;


            // VertexOutputSimple vert(VertexInputSimple v, uint instanceID: SV_InstanceID)
            VertexOutputSimple vert(VertexInputSimple v)
            {
                VertexOutputSimple o = (VertexOutputSimple)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                half3 windScaler = WindScaler(positionWS);
                half3 wind = windScaler * v.positionOS.y * v.positionOS.y * _WindMultiplier * _WindDirection.xyz;
                //
                half3 positionOS = v.positionOS.xyz + wind;
                positionWS = TransformObjectToWorld(positionOS);

                // ===== wind ========
                // half fix = step(0.05, v.positionOS.y);
                // //
                // float2 samplePos = positionWS.xz;
                // TODO: 采样Noise贴图后，无法正确获取LightMapAtten，待查
                // float waveSample = tex2Dlod(_WindNoiseTex, float4(samplePos * _WindNoiseTex_ST.xy * 0.01 + _Time.x * _WindFrequency , 0, 0)).r;
                // positionWS.xy += waveSample * v.color.b * _WindMultiplier * _WindDirection; //顶点色控制
                // positionWS.xz += waveSample * fix * v.positionOS.y * v.positionOS.y * _WindMultiplier * _WindDirection * _WindSpeed; //根据高度计算 //

                o.positionWS = positionWS;
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.color = v.color;

                return o;
            }

            
            half4 frag(VertexOutputSimple i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);


                half4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                half atten = lerp(1, mainLight.shadowAttenuation, _ShadowIntensity);

                //Dir
                half3 lightDir = mainLight.direction;
                half3 normalWS = half3(0, 1, 0);
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS.xyz);

                //Diffuse
                half3 grassColor = lerp(_DarkColor, _BrightColor, i.color.r).rgb;
                half3 baseColor = lerp(_FlowerColor.rgb, grassColor, i.color.g);

                half3 lightColor = mainLight.color;
                half minDotLN = 0.2;

                half3 shadowColor = lerp(_ShadowColor.rgb, half3(1,1,1), atten);
                
                half halfLambert = max(minDotLN, (dot(lightDir, normalWS) + 1) * 0.5);
                baseColor.rgb = halfLambert * baseColor.rgb;

                half3 rotatedLight = RotateAround(_SSSRotation, mainLight.direction);

                half3 halfNV = normalize(rotatedLight + viewDir);
                //SSS
                half sss = dot(normalWS, halfNV);
                half3 sssColor = mainLight.color.rgb * pow(max(0, sss), _SSSPower * 20) * _SSSIntensity;
                sssColor = sssColor * i.color.g;
                
                half3 finalColor = (baseColor + sssColor) * lightColor * shadowColor;
                // half finalBloom = GetSceneObjectOpaqueFinalBloom(_BloomFactor);

                
                return half4(finalColor, i.color.a);
            }
            ENDHLSL

        }
    }
}