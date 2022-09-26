Shader "VFX/Particle_Base" {
    Properties {
        [HDR]_FixColor("FixColor", COLOR) = (1,1,1,1)
        [HDR]_InColor("Interior Color", COLOR) = (1,1,1,1)
        [MaterialToggle] _DoubleFaceColor ("Double Face Color", Float ) = 0.0
        _MainTex ("Main Tex", 2D) = "white" {}
        _Brightness ("Brightness", Float ) = 1
        _Contrast ("Contrast", Float ) = 1
        _MainTexPannerX ("Main Tex Panner X", Float ) = 0
        _MainTexPannerY ("Main Tex Panner Y", Float ) = 0

        [Header(Mesh Depth Setting)]
        [MaterialToggle] _MeshDepth ("Mesh Depth", Float ) = 0
        _MeshDepthIntensity ("Mesh Depth Intensity", Range(0, 1)) = 0
        _BloomFactor("Bloom Factor", Range(0,1)) = 0

        [Header(Stencil)]
        [IntRange]_Stencil ("Stencil ID", Range(0,255)) = 0
        [IntRange]_StencilReadMask ("Stencil Read Mask", Range(0,255)) = 255
        [IntRange]_StencilWriteMask ("Stencil Write Mask", Range(0,255)) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass ("Stencil Pass", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilFail ("Stencil Fail", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilZFail ("Stencil ZFail", Float) = 0
        
        [Header(Blend Setting)]
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.BlendMode)] SrcBlend ("SrcBlend", Float) = 5    //SrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)] DstBlend ("DstBlend", Float) = 10   //OneMinusSrcAlpha
        
        [Enum(UnityEngine.Rendering.BlendMode)] SrcBlendBloom ("SrcBlendBloom", Float) = 5    //SrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)] DstBlendBloom ("DstBlendBloom", Float) = 10   //OneMinusSrcAlpha
        _ColorMask ("Color Mask", Float) = 14
        
        
        [HideInInspector]_SeparateAlpha("SeparateAlpha", Float) = 0
        [HideInInspector]_UIFXClipRange0("", vector) = (-100.0, -100.0, 100.0, 100.0)
    }
    SubShader {
//        Tags {
//            "IgnoreProjector"="True"
//            "Queue"="Transparent"
//            "RenderType"="Transparent"
//        }
        
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        
        
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Pass [_StencilPass]
            Fail [_StencilFail]
            ZFail [_StencilZFail]
        }
        
        Pass {
            Name "VFX"
            Tags {
                "LightMode" = "VFX" 
            }
            ColorMask [_ColorMask]
            Blend [SrcBlend] [DstBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UICLIP_ON
            //SEPARATEALPHA(分离Alpha通道为单张图)
            //#pragma multi_compile __ SEPARATEALPHA
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _FixColor;
            half4 _InColor;
            half _DoubleFaceColor;

            sampler2D _MainTex; 
            half4 _MainTex_ST;
            /*#ifdef SEPARATEALPHA
                uniform sampler2D _MainTex_Alpha;
            #endif*/
            sampler2D _MainTex_Alpha;

            half _Brightness;
            half _Contrast;
            half _MainTexPannerX;
            half _MainTexPannerY;

            half _MeshDepth;
            half _MeshDepthIntensity;

            half _SeparateAlpha;
            half _ZWrite;
            half SrcBlend;
            half DstBlend;
            half4 _UIFXClipRange0 = half4(-100.0, -100.0, 100.0, 100.0); // minx maxx miny maxy
            half _BloomFactor;
            CBUFFER_END
            half _VFXBloomAdd;

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                half3 normal : NORMAL;
                half4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                half3 posWorld : TEXCOORD1;
                half3 normalDir : TEXCOORD2;
                half4 vertexColor : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = (TRANSFORM_TEX(v.texcoord0,_MainTex) + half2(_MainTexPannerX,_MainTexPannerY) * _Time.y);
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformObjectToHClip(v.vertex.xyz );
                o.vertexColor = v.vertexColor;
                return o;
            }
            half4 frag(VertexOutput i, half facing : VFACE) : SV_Target {
                half isFrontFace = ( facing >= 0 ? 1 : 0 );
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half3 normalDirection = i.normalDir;
                half4 _MainTex_var = tex2D(_MainTex,i.uv0);
                /*#ifdef SEPARATEALPHA
                    _MainTex_var.a = tex2D(_MainTex_Alpha, i.uv0);
                #endif*/ 
                if (_SeparateAlpha)
                {
                    _MainTex_var.a = tex2D(_MainTex_Alpha, i.uv0);
                }
                half3 doubleFaceColor = lerp( _FixColor.rgb, lerp(_InColor.rgb,_FixColor.rgb,isFrontFace), _DoubleFaceColor );
                half3 emissive = pow((_Brightness * _MainTex_var.rgb * i.vertexColor.rgb * doubleFaceColor.rgb),_Contrast);
                half vAlpha = (_FixColor.a*(i.vertexColor.a*_MainTex_var.a));
                #if UICLIP_ON
                // Softness factor
                bool inArea = i.posWorld.x >= _UIFXClipRange0.x && i.posWorld.x <= _UIFXClipRange0.z && i.posWorld.y >= _UIFXClipRange0.y && i.posWorld.y <= _UIFXClipRange0.w;
                if(!inArea){
                    vAlpha = 0;
                }
                #endif
                half MD = saturate(lerp( vAlpha, (vAlpha*pow(0.5*dot(normalDirection,viewDirection)+0.5,exp2(lerp(1,11,_MeshDepthIntensity)))), _MeshDepth ));
                return half4(emissive, MD);
            }
            ENDHLSL
        }
        
        Pass {
            Name "DrawBloomAlpha"
            Tags {
                "LightMode"="DrawBloomAlpha"
            }
            ColorMask A
            Blend [SrcBlendBloom] [DstBlendBloom]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UICLIP_ON
            //SEPARATEALPHA(分离Alpha通道为单张图)
            //#pragma multi_compile __ SEPARATEALPHA
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "../CommonShader.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _FixColor;
            half4 _InColor;
            half _DoubleFaceColor;

            sampler2D _MainTex; 
            half4 _MainTex_ST;
            /*#ifdef SEPARATEALPHA
                uniform sampler2D _MainTex_Alpha;
            #endif*/
            sampler2D _MainTex_Alpha;

            half _Brightness;
            half _Contrast;
            half _MainTexPannerX;
            half _MainTexPannerY;

            half _MeshDepth;
            half _MeshDepthIntensity;

            half _SeparateAlpha;
            half _ZWrite;
            half SrcBlend;
            half DstBlend;
            half4 _UIFXClipRange0 = half4(-100.0, -100.0, 100.0, 100.0); // minx maxx miny maxy
            half _BloomFactor;
            CBUFFER_END
            half _VFXBloomAdd;

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                half3 normal : NORMAL;
                half4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                half3 posWorld : TEXCOORD1;
                half3 normalDir : TEXCOORD2;
                half4 vertexColor : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = (TRANSFORM_TEX(v.texcoord0,_MainTex) + half2(_MainTexPannerX,_MainTexPannerY) * _Time.y);
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.vertexColor = v.vertexColor;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }
            half4 frag(VertexOutput i, half facing : VFACE) : SV_Target {
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half3 normalDirection = i.normalDir;
                half4 _MainTex_var = tex2D(_MainTex,i.uv0);
                /*#ifdef SEPARATEALPHA
                    _MainTex_var.a = tex2D(_MainTex_Alpha, i.uv0);
                #endif*/ 
                if (_SeparateAlpha)
                {
                    _MainTex_var.a = tex2D(_MainTex_Alpha, i.uv0);
                }
                half vAlpha = (_FixColor.a*(i.vertexColor.a*_MainTex_var.a));
                #if UICLIP_ON
                // Softness factor
                bool inArea = i.posWorld.x >= _UIFXClipRange0.x && i.posWorld.x <= _UIFXClipRange0.z && i.posWorld.y >= _UIFXClipRange0.y && i.posWorld.y <= _UIFXClipRange0.w;
                if(!inArea){
                    vAlpha = 0;
                }
                #endif
                half Alpha = saturate(lerp( vAlpha, (vAlpha*pow(0.5*dot(normalDirection,viewDirection)+0.5,exp2(lerp(1,11,_MeshDepthIntensity)))), _MeshDepth ));
                return CalcTransparentBloomFactor(_BloomFactor + _VFXBloomAdd, Alpha);
            }
            ENDHLSL
        }

    }
}
