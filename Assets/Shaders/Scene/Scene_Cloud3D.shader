Shader"Scene_Cloud3D"
{
    Properties
    {
        _Noise3D("Noise3D",3D) = ""{}
        _NoiseScale("NoiseScale",Range(0.0,1000.0)) = 200
        _Speed("Speed",Range(0.0,20.0)) = 1
        [HDR]_Color("Color",Color) = (0.9,0.9,0.9,0.9)
        _LargeWaves("LargeCloud",Range(0.0,1.0)) = 0.5
        _MiddleWaves("MiddleCloud",Range(0.0,1.0)) = 0.3
        _SmallWaves("SmallCloud",Range(0.0,1.0)) = 0.1

        _SSSColor("SSS Color", Color) = (1,1,1,1)
        _SSSIntensity("SSS Intensity", Range(0, 1)) = 0
        _SSSPower("SSS Power", Range(0.001, 20)) = 1
        
        _ShadowIntensity("ShadowIntensity", Range(0,1)) = 1

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }
        
        HLSLINCLUDE
        
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
    
            //Define variable
            UNITY_INSTANCING_BUFFER_START(pro)
                UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
            UNITY_INSTANCING_BUFFER_END(pro)
    
    
            CBUFFER_START(UnityPerMaterial)
                half4 _MainTex_ST;
                half4 _Noise_ST;
                half _NoiseScale;
                half _Speed;
                half4 _Color;
                half _LargeWaves;
                half _MiddleWaves;
                half _SmallWaves;
                half alpha;
                half _ShadowIntensity;
                half4 _BaseColor;
                half4 _SSSColor;
                half _SSSPower;
                half _SSSIntensity;
            CBUFFER_END
        ENDHLSL


        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            Blend SrcAlpha OneMinusSrcAlpha
            Zwrite Off
            Cull Off
            ColorMask RGB
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            //GPU instance
            #pragma multi_compile_instancing
            //#pragma instancing_options procedural:setup

            //SHADOW
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma multi_compile _ _SHADOWS_SOFT//
            

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float3 normalOS:NORMAL;
                float2 uv : TEXCOORD0;
                half4 color:COLOR;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS:TEXCOORD1;
                float3 viewDirWS:TEXCOORD2;
                float3 normalWS:TEXCOORD3;
                float3 uvw:TEXCOORD4;
                half4 color:COLOR;
                float4 positionOS:TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID

                float4 shadowcoord:TEXCOORD5;
            };

            sampler3D _Noise3D;
            
            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;

                //uint instanceID = IN.instanceID;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);


                o.positionOS = i.positionOS;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                //#ifdef SHADOWS_SHADOWMASK
                o.shadowcoord = TransformWorldToShadowCoord(o.positionWS);
                // #endif

                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.viewDirWS = GetCameraPositionWS() - o.positionWS;
                o.uvw = o.positionWS.xyz;
                o.uv = i.uv.xy;


                return o;
            }


            float remap(float original_value, float original_min, float original_max, float new_min, float new_max)
            {
                return new_min + (((original_value - original_min) / (original_max - original_min)) * (new_max -new_min));
            }


            half4 frag(VertexOutput i) :SV_Target
            {
                //Sampler 3D noise and flow UV
                UNITY_SETUP_INSTANCE_ID(i);
                
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS.xyz);
                
                float3 FlowUVW = i.uvw / _NoiseScale + (_Time.xyz / 3) * _Speed * 0.01 * half3(1, 1, 1);

                float4 samplerColor = tex3D(_Noise3D, FlowUVW);

                //梯度clip
                ///float4 weatherMap = tex3D(_Noise3D, IN.uvw);
                // float heightPercent = (rayPos.y - _boundsMin.y) / size.y;//计算一个梯度值
                // float heightGradient = saturate(remap(heightPercent, 0.0, weatherMap.r, 1, 0));
                //return heightGradient;

                // float alpahtest = samplerColor.a;

                //Add noise to the uv
                // samplerColor = tex3D(_Noise3D, IN.uvw + samplerColor.b * 0.2 * _NoiseOffset);

                //Alpha test and blend
                float AlphaTint = (_LargeWaves * samplerColor.r + _MiddleWaves * samplerColor.b + _SmallWaves * samplerColor.g); ///MaxGB*1.5;
                AlphaTint = clamp(AlphaTint, 0.0, 1.0);

                float clipValue = AlphaTint - UNITY_ACCESS_INSTANCED_PROP(pro, _Cutoff);


                //Fade edags
                // float Boundsize = max(0, max(IN.positionOS.x, IN.positionOS.z));
                float distanceRP = min(2, sqrt(pow(i.positionOS.z, 2) + pow(i.positionOS.x, 2)));
                float edgeWeight = distanceRP / 2;
                clipValue *= 1 - edgeWeight;

                clip(clipValue);
                //ambient
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;


                //mix RGB R for the main ,b for the middle waves , c for the small Waves
                // Smooth the cloud
                samplerColor.a = saturate(samplerColor.r + _MiddleWaves * samplerColor.b + _SmallWaves * samplerColor.g);
                // float SmoothedA = smoothstep(0, 1 - UNITY_ACCESS_INSTANCED_PROP(pro, _Cutoff), samplerColor.a);


                //shadow the cloud
                //Compute the light
                Light mainLight = GetMainLight(i.shadowcoord);

                float3 offsetUV = float3((i.uvw.xz + 0 * mainLight.direction.xz) / _NoiseScale, i.uvw.y) + (_Time.xyz/ 3) * _Speed * 0.01 * half3(1, 1, 1);;

                float4 samplerColorB = tex3D(_Noise3D, offsetUV);
                float AlphaTintB = (_LargeWaves * samplerColorB.r + _MiddleWaves * samplerColorB.b + _SmallWaves *
                    samplerColorB.g); ///MaxGB*1.5;
                AlphaTintB = clamp(AlphaTintB, 0.0, 1.0);
                
                float shadow = 1 - clamp(samplerColor.a - AlphaTintB, 0.0, 1) * _ShadowIntensity * mainLight.shadowAttenuation;
                
                // half NdotL = max(0, dot(i.normalWS, mainLight.direction));
                // half smoothNdotL = saturate(pow(NdotL, 2 - UNITY_ACCESS_INSTANCED_PROP(pro, _Cutoff)));


                //SSS
                half sss = dot(mainLight.direction, - viewDir);
                half3 sssColor = mainLight.color.rgb * pow(max(0, sss), _SSSPower * 20) * _SSSIntensity;

                half3 diffuse = samplerColor.a * _Color * mainLight.color;


                half3 color = (diffuse + ambient + sssColor) * shadow;


                //

                return float4(color, clipValue); //* UNITY_ACCESS_INSTANCED_PROP(pro, _BaseColor)* _ColorTint;
            }
            ENDHLSL
        }

        //
        //        Pass
        //        {
        //
        //            Name"ShadowCaster"
        //
        //            Tags
        //            {
        //                "LightMode" = "ShadowCaster"
        //            }
        //            Cull off
        //            Zwrite On
        //            ZTest LEqual
        //
        //            HLSLPROGRAM
        //            #pragma vertex vertshadow
        //            #pragma fragment fragshadow
        //
        //
        //            struct Attributes
        //            {
        //                float4 positionOS : POSITION;
        //                float3 normalOS:NORMAL;
        //                float2 uv : TEXCOORD;
        //                half4 color:COLOR;
        //            };
        //
        //
        //            struct Varings
        //            {
        //                float4 positionCS : SV_POSITION;
        //                float2 uv : TEXCOORD;
        //                float3 positionWS:TEXCOORD1;
        //                float3 viewDirWS:TEXCOORD2;
        //                float3 normalWS:TEXCOORD3;
        //                //#ifdef SHADOWS_SHADOWMASK
        //                float4 shadowcoord:TEXCOORD4;
        //                // #endif
        //            };
        //
        //
        //            Varings vertshadow(Attributes IN)
        //            {
        //                Varings Out;
        //                Out.uv = TRANSFORM_TEX(IN.uv, _MainTex);
        //                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
        //                Light MainLight = GetMainLight(Out.shadowcoord);
        //                float normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz);
        //
        //                Out.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, MainLight.direction));
        //
        //                return Out;
        //            }
        //
        //
        //            float fragshadow(Varings IN) :SV_TARGET
        //            {
        //                float alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).b;
        //
        //                clip(alpha - _Cutoff);
        //                return 0;
        //            }
        //            ENDHLSL
        //
        //
        //
        //
        //        }
    }
}