Shader "VFX/Particle_Base_UI" {
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
                half Alpha = saturate(lerp( vAlpha, (vAlpha*pow(0.5*dot(normalDirection,viewDirection)+0.5,exp2(lerp(1,11,_MeshDepthIntensity)))), _MeshDepth ));


                #ifdef UNITY_UI_CLIP_RECT
                Alpha *= UnityGet2DClipping(i.posWorldUI.xy, _ClipRect);
                #endif

                
                return half4(emissive, Alpha);
            }
            ENDHLSL
        }
        
    }
}
