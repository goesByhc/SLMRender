Shader "Scene_Cloud"
{
    Properties
    {
        _BaseMap("BaseMap", 2D) = "white" {}
        _SkyColor("SkyColor", Color) = (0,0.9218221,1,0)
        _CloudColor("CloudColor", Color) = (1,1,1,0)
        _Opacity("Opacity", Range( 0 , 1)) = 1
        _Emission("Emission", Float) = 0
        _BloomFactor("BloomFactor", Range( 0 , 1)) = 0.001
    }

    SubShader
    {

        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../Core.hlsl"
            #include "../ForwardPass.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseMap_ST;
            half4 _SkyColor;
            half4 _CloudColor;
            half _BloomFactor;
            half _Opacity;
            half _Emission;
            CBUFFER_END
        
        ENDHLSL


        Pass
        {

            Name "Forward"
            Tags {"LightMode" = "UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            ColorMask RGB

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma prefer_hlslcc gles

            #pragma vertex CommonVertexSimpleFunction
            #pragma fragment frag

            //Texture
            sampler2D _BaseMap;

            half4 frag(VertexOutputSimple i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                half2 uv_BaseMap = i.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
                half4 baseMap = tex2D(_BaseMap, uv_BaseMap);
                half4 baseColor = lerp(_SkyColor, _CloudColor, baseMap.r);

                half opacity = clamp(baseMap.a * _Opacity, 0.0, 1.0);

                half3 color = (baseColor + _Emission).rgb;
                half alpha = saturate((_Emission * opacity));

                return half4(color, alpha);
            }
            ENDHLSL
        }
        
        
        
        
        Pass
        {
            Name "DrawBloomAlpha"
            Tags {"LightMode" = "DrawBloomAlpha"}
            
            Blend One Zero, DstColor Zero
            Cull Off
            ZWrite Off
            ZTest LEqual
            Offset 0 , 0
            ColorMask A
            

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma prefer_hlslcc gles

            #pragma vertex CommonVertexSimpleFunction
            #pragma fragment frag

            //Texture
            sampler2D _BaseMap;

            half4 frag ( VertexOutputSimple i  ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID( IN );
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

                half2 uv_BaseMap = i.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
                half4 tex2DNode1 = tex2D( _BaseMap, uv_BaseMap );
                half opacity = clamp( ( tex2DNode1.a * _Opacity ) , 0.0 , 1.0 );

                return GetSceneObjectTransparentFinalBloom(_BloomFactor, opacity);
            }

            ENDHLSL
        }

        

    }

}