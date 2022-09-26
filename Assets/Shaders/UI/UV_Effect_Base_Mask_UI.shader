Shader "VFX/UV_Effect_Base_Mask_UI" {
    Properties {
        _SoftHard ("Soft Hard", Range(0, 0.5) ) = 0.5
        [HDR]_MainColor ("Main Color", Color) = (1,1,1,1)
        [HDR]_InColor("Interior Color", COLOR) = (1,1,1,1)
        [MaterialToggle] _DoubleFaceColor ("Double Face Color", Float ) = 0.0
        _MainTex ("Main Tex", 2D) = "white" {}
        _MainTexBrightness ("Main Tex Brightness", Float ) = 1
        _MainTexPannerX ("Main Tex Panner X", Float ) = 0
        _MainTexPannerY ("Main Tex Panner Y", Float ) = 0
        _MainTexContrast ("Main Tex Contrast", Float ) = 1
        _MaskTex ("Mask Tex", 2D) = "white" {}
        _MaskTexPannerX ("Mask Tex Panner X", Float ) = 0
        _MaskTexPannerY ("Mask Tex Panner Y", Float ) = 0
        _TurbulenceTex ("Turbulence Tex", 2D) = "bump" {}
        _UVEffectPower ("UV Effect Power", Float ) = 0
        _NormalTexPannerX ("Normal Tex Panner X", Float ) = 0
        _NormalTexPannerY ("Normal Tex Panner Y", Float ) = 0
        _Dis ("Dis", Float ) = 1

        [Header(Mesh Depth Setting)]
        [MaterialToggle] _MeshDepth ("Mesh Depth", Float ) = 0
        _MeshDepthIntensity ("Mesh Depth Intensity", Range(0, 1)) = 0

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

        _ColorMask ("Color Mask", Float) = 14
        
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        [HideInInspector]_SeparateAlpha("SeparateAlpha",Float) = 0
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
            Name "Forward"
            Tags {"LightMode" = "UniversalForward"}
            
            ColorMask [_ColorMask]
            Blend [SrcBlend] [DstBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UICLIP_ON
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT

            //SEPARATEALPHA(����Alphaͨ��Ϊ����ͼ)
            //#pragma multi_compile __ SEPARATEALPHA
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex; 
            half4 _MainTex_ST;
            /*#ifdef SEPARATEALPHA
                uniform sampler2D _MainTex_Alpha;
            #endif*/
            sampler2D _MainTex_Alpha;
            half _SeparateAlpha;
            half _MainTexPannerX;
            half _MainTexPannerY;
            sampler2D _MaskTex; 
            half4 _MaskTex_ST;
            half _MainTexBrightness;
            half _MainTexContrast;
            sampler2D _TurbulenceTex; 
            half4 _TurbulenceTex_ST;
            half _UVEffectPower;
            half _NormalTexPannerX;
            half _NormalTexPannerY;
            half _MaskTexPannerX;
            half _MaskTexPannerY;
            half4 _MainColor;
            half4 _InColor;
            half _DoubleFaceColor;
            half _Dis;
            half _MeshDepthIntensity;
            half _MeshDepth;
            half _SoftHard;
            half4 _UIFXClipRange0 = half4(0.0, 0.0, 1.0, 1.0); // minx maxx miny maxy
            CBUFFER_END
            float4 _ClipRect;

            struct appdata {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
                half2 texcoord0 : TEXCOORD0;
                half4 vertexColor : COLOR;
            };
            struct v2f {
                half4 pos : SV_POSITION;
                half2 uv0 : TEXCOORD0;
                half4 posWorld : TEXCOORD1;
                half3 normalDir : TEXCOORD2;
                half2 posWorldUI : TEXCOORD3;
                half4 vertexColor : COLOR;
            };
            
            inline float UnityGet2DClipping (in float2 position, in float4 clipRect)
            {
                float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
                return inside.x * inside.y;
            }
            
            v2f vert (appdata v) {
                v2f o = (v2f)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = TransformObjectToHClip( v.vertex );
                o.posWorldUI = v.vertex.xy;
                return o;
            }
            
            half4 frag(v2f i, half facing : VFACE) : SV_Target {
                half isFrontFace = ( facing >= 0 ? 1 : 0 );
                half3 doubleFaceColor = lerp( _MainColor.rgb, lerp(_InColor.rgb,_MainColor.rgb,isFrontFace), _DoubleFaceColor );
 
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half3 normalDirection = i.normalDir;
                half4 time1 = _Time;
                half2 noisePanner = (i.uv0+(half2(_NormalTexPannerX,_NormalTexPannerY)*time1.y));
                half4 _TurbulenceTex_var = tex2D(_TurbulenceTex,TRANSFORM_TEX(noisePanner, _TurbulenceTex));
                //clip((_TurbulenceTex_var.r+_Dis) - 0.5);

                half4 time2 = _Time;
                half2 col = ((_TurbulenceTex_var.r*_UVEffectPower)+(i.uv0+(half2(_MainTexPannerX,_MainTexPannerY)*time2.y)));
                half4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(col, _MainTex));
                /*#ifdef SEPARATEALPHA
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(col, _MainTex));
                #endif*/  
                if (_SeparateAlpha)
                {
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(col, _MainTex));
                }
                half3 emissive = (doubleFaceColor.rgb*(pow((_MainTexBrightness*_MainTex_var.rgb),_MainTexContrast)*i.vertexColor.rgb));
                half3 finalColor = emissive;
                half4 time3 = _Time;
                half2 maskPanner = (i.uv0+(half2(_MaskTexPannerX,_MaskTexPannerY)*time3.y));
                half4 _MaskTex_var = tex2D(_MaskTex,TRANSFORM_TEX(maskPanner, _MaskTex));
                half vAlpha = (_MainColor.a*(i.vertexColor.a*(_MainTex_var.a*_MaskTex_var.r)));
                #if UICLIP_ON
                // Softness factor
                bool inArea = i.posWorld.x >= _UIFXClipRange0.x && i.posWorld.x <= _UIFXClipRange0.z && i.posWorld.y >= _UIFXClipRange0.y && i.posWorld.y <= _UIFXClipRange0.w;
                if(!inArea){
                vAlpha = 0;
                }
                #endif
                half MD = saturate(lerp( vAlpha, (vAlpha*pow(0.5*dot(normalDirection,viewDirection)+0.5,exp2(lerp(1,11,_MeshDepthIntensity)))), _MeshDepth ));
                half Alpha = saturate(smoothstep( _SoftHard, (1.0 - _SoftHard), saturate( _TurbulenceTex_var.r+_Dis))) * MD;

                #ifdef UNITY_UI_CLIP_RECT
                Alpha *= UnityGet2DClipping(i.posWorldUI.xy, _ClipRect);
                #endif
                
                clip(Alpha - 0.01);
                
                return half4(finalColor, Alpha);
            }
            ENDHLSL
        }
        
    }
}
