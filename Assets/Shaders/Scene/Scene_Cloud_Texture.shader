Shader "Scene_Cloud_Texture" //GPU Instancer Setup
{
    Properties
    {
        _BaseMap("BaseMap", 2D) = "white" {}
        _FlowUV("FlowUV", Vector) = (0, 0, 0, 0)
        _Opacity("Opacity", Range(0, 1)) = 1
        _Emission("Emission", Float) = 0
        [HDR]_TintColor("TintColor", Color) = (1, 1, 1, 0)
        _BloomFactor("BloomFactor", Range(0, 1)) = 0.001
    }

    SubShader
    {
        
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        
        Cull Off
        AlphaToMask Off
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../../../Plugins/GPUInstancer/Shaders/Include/GPUInstancerInclude.cginc"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _TintColor;
            half4 _BaseMap_ST;
            half2 _FlowUV;
            half _Emission;
            half _BloomFactor;
            half _Opacity;
            CBUFFER_END
        
        ENDHLSL

        Pass
        {
            
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Offset 0 , 0
            ColorMask RGB
            

            HLSLPROGRAM
            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            #pragma vertex CommonVertexSimpleFunction
            #pragma fragment frag

            //Texture
            sampler2D _BaseMap;

            half4 frag (VertexOutputSimple i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                half mulTime = _TimeParameters.x * 0.01;
                half2 uv_BaseMap = i.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
                half2 panner = frac( mulTime ) * _FlowUV + uv_BaseMap;
                half4 baseMap = tex2D( _BaseMap, panner );
                half4 baseColor = _TintColor * baseMap + _Emission;
                
                float opacity = saturate( ( baseMap.a * _Opacity ) );
                return half4( baseColor.rgb, opacity );
            }

            ENDHLSL
        }

        
        
        Pass
        {
            Name "DrawBloomAlpha"
            Tags { "LightMode"="DrawBloomAlpha" }
            
            Blend DstColor Zero
            Cull Off
            ZWrite Off
            ZTest LEqual
            Offset 0 , 0
            ColorMask A
            

            HLSLPROGRAM
            // -------------------------------------
            // GPU Instancing
            #pragma instancing_options procedural:setupGPUI
            #pragma multi_compile_instancing

            #pragma vertex CommonVertexSimpleFunction
            #pragma fragment frag

            //Texture
            sampler2D _BaseMap;

            half4 frag (VertexOutputSimple i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                half mulTime36 = _TimeParameters.x * 0.01;
                half2 uv_BaseMap = i.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
                half2 panner = frac(mulTime36) * _FlowUV + uv_BaseMap;
                half4 baseMap = tex2D(_BaseMap, panner);
                
                float opacity = saturate(baseMap.a * _Opacity);
                
                half4 finalBloom = GetSceneObjectTransparentFinalBloom(_BloomFactor, opacity);
                return finalBloom;

            }

            ENDHLSL
        }

    
    }

    
}
