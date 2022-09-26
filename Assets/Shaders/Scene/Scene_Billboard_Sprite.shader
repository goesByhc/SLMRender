Shader "Scene_Billboard_Sprite" //GPU Instancer Setup
{
    Properties
    {
        _MainTex ("Texture Image", 2D) = "white" {}
        [Toggle]_ALPHATEST("AlphaTest", Int) = 0
        [HDR]_Color("Color", Color) = (1,1,1,1)
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
        #include "../MetaPass.hlsl"
        #include "../DepthNormalsPass.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _Color;
        CBUFFER_END
        
        ENDHLSL

        Pass
        {

            Name "Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }


//            ColorMask RGB

//            Blend SrcAlpha OneMinusSrcAlpha

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing
            
            #pragma multi_compile _ _ALPHATEST_ON

            #pragma vertex vert
            #pragma fragment frag

            VertexOutputDepth vert(VertexInputDepth v)
            {
                VertexOutputDepth output;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float4 positionCS = GetBillboardPositionCS(v.positionOS);
                // TransformWorldToObject()

                output.positionCS = positionCS;

                // output.positionCS = GetBillboardHClip(v.positionOS);
                output.uv = v.uv.xy;
                return output;
            }

            float4 frag(VertexOutputDepth input) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                mainTex.rgb *= _Color.rgb;

                #if _ALPHATEST_ON
                clip(mainTex.a - 0.5);
                #endif
                return half4(mainTex.rgb * mainTex.a, 1);
            }
            ENDHLSL
        }


        Pass
        {

            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            AlphaToMask Off
            Cull Off


            //            Stencil
            //            {
            //                Ref [_Stencil]
            //                Comp [_StencilComp]
            //                Pass [_StencilPass]
            //                Fail Keep
            //                ZFail Keep
            //            }


            HLSLPROGRAM
            #pragma prefer_hlslcc gles

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

            #pragma vertex vert
            #pragma fragment frag

            VertexOutputDepth vert(VertexInputDepth input)
            {
                VertexOutputDepth output = (VertexOutputDepth)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = GetBillboardPositionCS(input.positionOS);
                output.uv = input.uv.xy;
                return output;
            }

            half4 frag(VertexOutputDepth input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #ifdef _ALPHATEST_ON
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);\
                clip(mainTex.a - 0.5);
                #endif
                return 0;
            }
            ENDHLSL
        }


        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            AlphaToMask Off
            Cull Off


//            Stencil
//            {
//                Ref [_Stencil]
//                Comp [_StencilComp]
//                Pass [_StencilPass]
//                Fail Keep
//                ZFail Keep
//            } 

            HLSLPROGRAM
            #pragma prefer_hlslcc gles

            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma multi_compile _ _ALPHATEST_ON

            #pragma vertex vert
            #pragma fragment frag

            VertexOutputDepthNormals vert(VertexInputDepthNormals input)
            {
                VertexOutputDepthNormals output = (VertexOutputDepthNormals)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv = input.uv.xy;
                output.positionCS = GetBillboardPositionCS(input.positionOS);

                float3 worldCenter = TransformObjectToWorld(half3(0, 0, 0));

                float3 normalWS = normalize(_WorldSpaceCameraPos - worldCenter); //视线方向为法线

                output.normalWS = normalWS;

                return output;
            }

            half4 frag(VertexOutputDepthNormals input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_ALPHATEST_ON)
                half alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;
                AlphaClip(alpha, 0.5);
                #endif

                return half4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS, true)), 0.0, 0.0);
            }
            ENDHLSL
        }





/*

        //            Pass {
        //                
        //                    Name "ShadowCaster"
        //                
        //                    // ShadowCaster
        //                    Tags { "LightMode" = "ShadowCaster" "RenderType" = "AlphaTest" "Queue" = "AlphaTest" }
        //
        //                    ZWrite On ZTest LEqual Cull Off
        //
        //                    HLSLPROGRAM
        //                    #pragma vertex vert
        //                    #pragma fragment frag
        //                    #pragma target 2.0
        //                    #pragma multi_compile_shadowcaster
        //                    #pragma multi_compile_instancing
        //                    #include "UnityCG.cginc"
        //
        //                    struct appdata {
        //                        float4 vertex : POSITION;
        //                        float2 uv : TEXCOORD0;
        //// #if INSTANCING_ON
        ////                         UNITY_VERTEX_INPUT_INSTANCE_ID
        //// #endif
        //                    };
        //
        //                    struct v2f {
        //                        V2F_SHADOW_CASTER;
        //                        float2 uv : TEXCOORD1;
        //                        UNITY_VERTEX_OUTPUT_STEREO
        //                    };
        //
        //                    sampler2D _MainTex;
        //                    float4 _MainTex_ST;
        //                    float4 _BBSizePos;
        //                    fixed _Cutoff;
        //                    float _NormalYLockToCam;
        //                    float3 _AnchorPos;
        //
        //                    v2f vert(appdata_base v)
        //                    {
        //                        v2f o;
        //// #if INSTANCING_ON
        ////                         UNITY_SETUP_INSTANCE_ID(v);
        //// #endif
        //                        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        //
        //                        // jave.lin : 这里使用的是 灯光方向来处理
        //                        float3 wpos = mul(unity_WorldToObject, v.vertex).xyz;
        //                        float3 camPos = UnityWorldSpaceLightDir(wpos);
        //                        float3 normal = camPos - _AnchorPos;
        //                        normal.y *= _NormalYLockToCam;
        //                        normal = normalize(normal);
        //
        //                        float3 up = abs(normal.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
        //                        float3 right = normalize(cross(normal, up));// * -1;
        //                        up = normalize(cross(right, normal));// * -1;
        //
        //                        float3 offsetPos = v.vertex.xyz - _AnchorPos;
        //                        float3x3 newLocalMatrix = { /*col0*/right, /*col1*/up, /*col2*/normal };
        //                        float3 newLocalPos = mul(offsetPos, newLocalMatrix);
        //                        newLocalPos += _AnchorPos;
        //
        //                        newLocalPos.xyz += right * v.vertex.x * _BBSizePos.x + up * v.vertex.y * _BBSizePos.y;
        //                        newLocalPos.xy += _BBSizePos.zw;
        //
        //                        v.vertex.xyz = newLocalPos;
        //
        //                        TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
        //                        o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
        //                        return o;
        //                    }
        //
        //                    float4 frag(v2f i) : SV_Target
        //                    {
        //                        fixed4 texcol = tex2D(_MainTex, i.uv);
        //                        clip(texcol.a - _Cutoff);
        //
        //                        return 0;
        //                        // SHADOW_CASTER_FRAGMENT(i)
        //                    }
        //                    ENDHLSL
        //
        //                }
        
        */
    }
}