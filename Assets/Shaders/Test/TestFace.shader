Shader "TestFace"
{
    Properties
    {
        [MainTexture]_BaseMap ("Base Map (Albedo)", 2D) = "white" { }
        _FacePow("FacePow", Range(0, 3)) = 1 
        _FaceAdd("FaceAdd", Range(-1, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { 
                "LightMode" = "UniversalForward" 
            }
            HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                half3 normalOS: NORMAL;
                half4 tangentOS: TANGENT;
                half4 color: COLOR;
                half2 texcoord0: TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : POSITION;
                float4 color: COLOR0;
                float2 uv : TEXCOORD0;
                float3 positionWS: TEXCOORD1;
                float3 positionVS: TEXCOORD2;
                float3 normalWS: TEXCOORD3;
                float3 tangentWS: TEXCOORD4; //切线
                float3 bitangentWS: TEXCOORD5; //副法线
                float4 shadowCoord: TEXCOORD6;
            };

            //Base 
            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _FacePow;
            float _FaceAdd;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.texcoord0;
                o.color = v.color;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS = TransformWorldToView(o.positionWS);

                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                o.bitangentWS = vertexNormalInput.bitangentWS;
                o.tangentWS = vertexNormalInput.tangentWS;
                o.normalWS = vertexNormalInput.normalWS;
                
                o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                
                return o;
            }
            
            half4 frag (v2f i) : COLOR
            {
                float3 UP = float3(0,1,0); // cs脚本里动态修改
                float3 Front = float3(0,0,-1);
                float3 Left = cross(UP, Front);
                float3 Right = -cross(UP, Front);

				half3 lightDir = normalize(_MainLightPosition.xyz);

                half lambert = dot(_MainLightPosition.xz, Front.xz);
                half halfLambert = (lambert * 0.5 + 0.5);


                // half4 col = tex2D(_BaseMap, i.uv);
                // // 左右翻转
                // float2 flipUV = float2(1 - i.uv.x, i.uv.y);
                // half4 lightMap = half4(0,0,0,0);
                // half4 lightMapL = tex2D(_BaseMap, i.uv);
                // half4 lightMapR = tex2D(_BaseMap, flipUV);
                //
                // lightMap = LR > 0 ? lightMapL : lightMapR;
                // lightMap = lightMap.a > lambert ? 1 - _ShadowColor.a : 1;
                //
                // col.rgb = lerp(_ShadowColor.rgb, col.rgb, lightMap.rgb);

                // float3 Up = float3(0.0,1.0,0.0);
                // float3 Front = unity_ObjectToWorld._12_22_32;
                // float3 Right = cross(Up,Front);


                // float switchShadowTex = dot(lightDir.x,Front.x);
                // float4 var_FaceShadow;
                //  if (switchShadowTex < 0.0)
                // {
                //     var_FaceShadow = tex2D(_BaseMap,i.uv);
                // }
                // else
                // {
                //     var_FaceShadow = tex2D(_BaseMap,float2(-i.uv.x,i.uv.y));
                // }
                //
                // float switchShadow  = dot(normalize(Right.xz), normalize(lightDir.xz))*0.5+0.5 < 0.5;
                // float FaceShadow = lerp(var_FaceShadow.r,1 - var_FaceShadow,switchShadow.r);
                // float FaceShadowRange = dot(normalize(Front.xz), normalize(lightDir.xz));
                // float lightAttenuation = 1 - smoothstep(FaceShadowRange - 0.0,FaceShadowRange + 0.0,FaceShadow);
                // return lightAttenuation.rrrr ;

                half lightmapL = tex2D(_BaseMap, i.uv).r;
                half lightmapR = tex2D(_BaseMap, float2(-i.uv.x, i.uv.y)).r;

                // float FrontL = dot(normalize(Front.xz), normalize(lightDir.xz));
                float LeftL = dot(normalize(Left.xz), normalize(lightDir.xz));
                // float RightL = dot(normalize(Right.xz), normalize(lightDir.xz));

                // return halfLambert.rrrr;
                
                // return step(lightmapL, 0.5).rrrr;

                return lerp(step(lightmapL, halfLambert) , step(lightmapR, halfLambert), step(0, LeftL));
                
                

                    
                // return step(lightmap, halfLambert);
                
                // float atten = pow(lightmap.r, _FacePow);
                // atten = halfLambert;
                
                // float lightAttenuation = (FrontL > 0) * min(
                //     (halfLambert > LeftL),
                //     1-(1 - halfLambert < RightL)
                // );
                //
                // return lightAttenuation.rrrr;
            }
            ENDHLSL
        }
    }
}