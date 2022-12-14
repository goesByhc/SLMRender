Shader "VFX/UV_Effect_Dynamatic" {
    Properties {
        _SoftHard ("Soft Hard", Range(0, 0.5) ) = 0.5
        [HDR]_MainColor ("Main Color", Color) = (1,1,1,1)
        [HDR]_InColor("Interior Color", COLOR) = (1,1,1,1)
        [MaterialToggle] _DoubleFaceColor ("Double Face Color", Float ) = 0.0
        _MainTex ("Main Tex", 2D) = "white" {}
        _MainTexBrightness ("Main Tex Brightness", Float ) = 1
        _MainTexPower ("Main Tex Power", Float ) = 1
        _TurbulenceTex ("Turbulence Tex", 2D) = "bump" {}
        _TurbulenceTexPannerX ("Turbulence Tex Panner X", Float ) = 0
        _TurbulenceTexPannerY ("Turbulence Tex Panner Y", Float ) = 0
        
        [Header(Mesh Depth Setting)]
        [MaterialToggle] _MeshDepth ("Mesh Depth", Float ) = 0
        _MeshDepthIntensity ("Mesh Depth Intensity", Range(0, 1)) = 0.2068142
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

        
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        [HideInInspector]_SeparateAlpha("SeparateAlpha", Float) = 0
        [HideInInspector]_UIFXClipRange0("", vector) = (-100.0, -100.0, 100.0, 100.0)
    }
    SubShader {
        
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
            Offset  [_OffsetFactor], [_OffsetUnit]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UICLIP_ON
            //SEPARATEALPHA(????????????Alpha????????????????????????)
            //#pragma multi_compile __ SEPARATEALPHA
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex; 
            half4 _MainTex_ST;
            /*#ifdef SEPARATEALPHA
                uniform sampler2D _MainTex_Alpha;
            #endif*/
            sampler2D _MainTex_Alpha;
            half _SeparateAlpha;
            half _MainTexBrightness;
            sampler2D _TurbulenceTex; 
            half4 _TurbulenceTex_ST;
            half _TurbulenceTexPannerX;
            half _TurbulenceTexPannerY;
            half4 _MainColor;
            half4 _InColor;
            half _DoubleFaceColor;
            half _MainTexPower;
            half _MeshDepthIntensity;
            half _MeshDepth;
            half _SoftHard;

            half4 _UIFXClipRange0 = half4(0.0, 0.0, 1.0, 1.0);
            half _BloomFactor;
            CBUFFER_END
            half _VFXBloomAdd;
            
            struct appdata {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                half3 normal : NORMAL;
                half4 vertexColor : COLOR;
            };
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                half3 posWorld : TEXCOORD2;
                half3 normalDir : TEXCOORD3;
                half4 vertexColor : COLOR;
                
            };
            v2f vert (appdata v) {
                v2f o = (v2f)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.vertexColor = v.vertexColor;
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }
            half4 frag(v2f i, half facing : VFACE) : SV_Target {
                half isFrontFace = ( facing >= 0 ? 1 : 0 );
                half3 doubleFaceColor = lerp( _MainColor.rgb, lerp(_InColor.rgb,_MainColor.rgb,isFrontFace), _DoubleFaceColor );

                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half3 normalDirection = i.normalDir;
                half4 time1 = _Time;
                half2 noisePanner = (i.uv0+(half2(_TurbulenceTexPannerX,_TurbulenceTexPannerY)*time1.y));
                half4 _TurbulenceTex_var = tex2D(_TurbulenceTex,TRANSFORM_TEX(noisePanner, _TurbulenceTex));
                //clip((_TurbulenceTex_var.r+(1.0-i.uv1.b)) - 0.5);

                half2 customData = ((_TurbulenceTex_var.r*i.uv1.a)+(i.uv0+half2(i.uv1.r,i.uv1.g)));
                half4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(customData, _MainTex));
                /*#ifdef SEPARATEALPHA
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(customData, _MainTex));
                #endif*/  
                if (_SeparateAlpha)
                {
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(customData, _MainTex));
                }
                half3 emissive = (doubleFaceColor.rgb*(pow((_MainTexBrightness*_MainTex_var.rgb),_MainTexPower)*i.vertexColor.rgb));
                half3 finalColor = emissive;
                half vAlpha = (_MainColor.a*(i.vertexColor.a*_MainTex_var.a));
                #if UICLIP_ON
                // Softness factor
                bool inArea = i.posWorld.x >= _UIFXClipRange0.x && i.posWorld.x <= _UIFXClipRange0.z && i.posWorld.y >= _UIFXClipRange0.y && i.posWorld.y <= _UIFXClipRange0.w;
                if(!inArea){
                vAlpha = 0;
                }
                #endif
                
                half MD =  saturate(lerp( vAlpha, (vAlpha*pow(0.5*dot(normalDirection,viewDirection)+0.5,exp2(lerp(1,11,_MeshDepthIntensity)))), _MeshDepth ));
                half Alpha = saturate(smoothstep( _SoftHard, (1.0 - _SoftHard), saturate( _TurbulenceTex_var.r+(1.0-i.uv1.b)))) * MD;

                clip(Alpha - 0.01);
                
                return half4(finalColor,Alpha);
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
            Offset  [_OffsetFactor], [_OffsetUnit]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UICLIP_ON
            //SEPARATEALPHA(????????????Alpha????????????????????????)
            //#pragma multi_compile __ SEPARATEALPHA
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "../CommonShader.hlsl"

            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex; 
            half4 _MainTex_ST;
            /*#ifdef SEPARATEALPHA
                uniform sampler2D _MainTex_Alpha;
            #endif*/
            sampler2D _MainTex_Alpha;
            half _SeparateAlpha;
            half _MainTexBrightness;
            sampler2D _TurbulenceTex; 
            half4 _TurbulenceTex_ST;
            half _TurbulenceTexPannerX;
            half _TurbulenceTexPannerY;
            half4 _MainColor;
            half4 _InColor;
            half _DoubleFaceColor;
            half _MainTexPower;
            half _MeshDepthIntensity;
            half _MeshDepth;
            half _SoftHard;

            half4 _UIFXClipRange0 = half4(0.0, 0.0, 1.0, 1.0);
            half _BloomFactor;
            CBUFFER_END
            half _VFXBloomAdd;
            
            struct appdata {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                half3 normal : NORMAL;
                half4 vertexColor : COLOR;
            };
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                half3 posWorld : TEXCOORD2;
                half3 normalDir : TEXCOORD3;
                half4 vertexColor : COLOR;
                
            };
            v2f vert (appdata v) {
                v2f o = (v2f)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.vertexColor = v.vertexColor;
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }
            half4 frag(v2f i, half facing : VFACE) : SV_Target {

                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half3 normalDirection = i.normalDir;
                half4 time1 = _Time;
                half2 noisePanner = (i.uv0+(half2(_TurbulenceTexPannerX,_TurbulenceTexPannerY)*time1.y));
                half4 _TurbulenceTex_var = tex2D(_TurbulenceTex,TRANSFORM_TEX(noisePanner, _TurbulenceTex));
                //clip((_TurbulenceTex_var.r+(1.0-i.uv1.b)) - 0.5);

                half2 customData = ((_TurbulenceTex_var.r*i.uv1.a)+(i.uv0+half2(i.uv1.r,i.uv1.g)));
                half4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(customData, _MainTex));
                /*#ifdef SEPARATEALPHA
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(customData, _MainTex));
                #endif*/  
                if (_SeparateAlpha)
                {
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(customData, _MainTex));
                }
                half vAlpha = (_MainColor.a*(i.vertexColor.a*_MainTex_var.a));
                #if UICLIP_ON
                // Softness factor
                bool inArea = i.posWorld.x >= _UIFXClipRange0.x && i.posWorld.x <= _UIFXClipRange0.z && i.posWorld.y >= _UIFXClipRange0.y && i.posWorld.y <= _UIFXClipRange0.w;
                if(!inArea){
                vAlpha = 0;
                }
                #endif
                
                half MD =  saturate(lerp( vAlpha, (vAlpha*pow(0.5*dot(normalDirection,viewDirection)+0.5,exp2(lerp(1,11,_MeshDepthIntensity)))), _MeshDepth ));
                half Alpha = saturate(smoothstep( _SoftHard, (1.0 - _SoftHard), saturate( _TurbulenceTex_var.r+(1.0-i.uv1.b)))) * MD;

                clip(Alpha - 0.01);
                
                return CalcTransparentBloomFactor(_BloomFactor + _VFXBloomAdd, Alpha);
            }
            ENDHLSL
        }
    }
}
