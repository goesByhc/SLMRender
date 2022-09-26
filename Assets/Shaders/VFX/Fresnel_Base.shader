Shader "VFX/Fresnel_Base" {
    Properties {
        [HDR]_MainColor ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Brightness ("Brightness", Float ) = 1
        _Contrast ("Contrast", Float ) = 1
        _MainTexPannerX ("Main Tex Panner X", Float ) = 0
        _MainTexPannerY ("Main Tex Panner Y", Float ) = 0
        _FrenselColor ("Frensel Color", Color) = (1,1,1,1)
        _FrenselValue ("Frensel Value", Float ) = 1
        _FresnelBrightness ("Fresnel Brightness", Float ) = 1
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

        
        
        [MaterialToggle] _FresnelMultiplyAlpha ("Fresnel Multiply Alpha", Float ) = 0
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        [HideInInspector]_SeparateAlpha("SeparateAlpha",Float) = 0
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
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //SEPARATEALPHA(分离Alpha通道为单张图)
            //#pragma multi_compile __ SEPARATEALPHA

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex; 
            half4 _MainTex_ST;
            sampler2D _MainTex_Alpha;
            half _SeparateAlpha;
            /*#ifdef SEPARATEALPHA
                uniform sampler2D _MainTex_Alpha;
            #endif*/
            half _MainTexPannerX;
            half _MainTexPannerY;
            half _FresnelBrightness;
            half _FrenselValue;
            half _Brightness;
            half _FresnelMultiplyAlpha;
            half4 _MainColor;
            half _Contrast;
            half4 _FrenselColor;
            half _BloomFactor;
            CBUFFER_END
            half _VFXBloomAdd;
            
            struct appdata {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                half3 normal : NORMAL;
                half4 vertexColor : COLOR;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                half3 posWorld : TEXCOORD1;
                half3 normalDir : TEXCOORD2;
                half4 vertexColor : COLOR;
            };
            
            v2f vert (appdata v) {
                v2f o;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }
            
            half4 frag(v2f i) : SV_Target {

                // return half4(1,1,0,1);
                
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half3 normalDirection = i.normalDir;
                half4 time = _Time;
                half2 panner = (i.uv0+(half2(_MainTexPannerX,_MainTexPannerY)*time.g));
                half4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(panner, _MainTex));
                /*#ifdef SEPARATEALPHA
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(panner, _MainTex));
                #endif */  
                if(_SeparateAlpha)
                {
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(panner, _MainTex));
                }
                half power = pow(1.0-max(0,dot(normalDirection, viewDirection)),_FrenselValue);
                half3 emissive = (_MainColor.rgb*(pow((_Brightness*(_MainTex_var.rgb+((_FresnelBrightness*power)*_FrenselColor.rgb))),_Contrast)*i.vertexColor.rgb));
                half alpha = saturate((_MainColor.a*(i.vertexColor.a*lerp(_MainTex_var.a, (_MainTex_var.a*power), _FresnelMultiplyAlpha))));
                //DoubleHDR
                return half4(0.5 * emissive, alpha);
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
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //SEPARATEALPHA(分离Alpha通道为单张图)
            //#pragma multi_compile __ SEPARATEALPHA

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "../CommonShader.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex; 
            half4 _MainTex_ST;
            sampler2D _MainTex_Alpha;
            half _SeparateAlpha;
            /*#ifdef SEPARATEALPHA
                uniform sampler2D _MainTex_Alpha;
            #endif*/
            half _MainTexPannerX;
            half _MainTexPannerY;
            half _FresnelBrightness;
            half _FrenselValue;
            half _Brightness;
            half _FresnelMultiplyAlpha;
            half4 _MainColor;
            half _Contrast;
            half4 _FrenselColor;
            half _BloomFactor;
            CBUFFER_END
            half _VFXBloomAdd;
            
            struct appdata {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                half3 normal : NORMAL;
                half4 vertexColor : COLOR;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                half3 posWorld : TEXCOORD1;
                half3 normalDir : TEXCOORD2;
                half4 vertexColor : COLOR;
            };
            
            v2f vert (appdata v) {
                v2f o;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.normalDir = TransformObjectToWorldNormal(v.normal);
                o.posWorld = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }
            
            half4 frag(v2f i) : SV_Target {

                // return half4(1,1,0,1);
                
                half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                half3 normalDirection = i.normalDir;
                half4 time = _Time;
                half2 panner = (i.uv0+(half2(_MainTexPannerX,_MainTexPannerY)*time.g));
                half4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(panner, _MainTex));
                /*#ifdef SEPARATEALPHA
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(panner, _MainTex));
                #endif */  
                if(_SeparateAlpha)
                {
                    _MainTex_var.a = tex2D(_MainTex_Alpha, TRANSFORM_TEX(panner, _MainTex));
                }
                half power = pow(1.0-max(0,dot(normalDirection, viewDirection)),_FrenselValue);
                half alpha = saturate((_MainColor.a*(i.vertexColor.a*lerp(_MainTex_var.a, (_MainTex_var.a*power), _FresnelMultiplyAlpha))));
                //DoubleHDR

                return CalcTransparentBloomFactor(_BloomFactor + _VFXBloomAdd, alpha);
            }
            ENDHLSL
        }
    }
}
