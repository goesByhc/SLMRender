Shader "HZBBuild" {

    Properties{
        [HideInInspector] _MainTex("Main Texture", 2D) = "black"
        [HideInInspector] _InvSize("Inv Size", Vector) = (0,0,0,0)
    }
    
    SubShader {
        
        
        
        //Blit Depth Pass
        Pass
        {
            
            Name "Copy Depth"

            HLSLPROGRAM
            #pragma vertex FullscreenVert
            #pragma fragment Fragment
 
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Fullscreen.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl" 

            Texture2D _CameraDepthTexture;
            SamplerState sampler_CameraDepthTexture;

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float camDepth = _CameraDepthTexture.Sample(sampler_CameraDepthTexture, input.uv).r;
                return camDepth;
            }

            ENDHLSL
        }
        
        
        Pass {
            Name "HZBBuild"
            
//            Cull Off ZWrite Off ZTest Always

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex FullscreenVert
            #pragma fragment HZBBuildFrag
            //#pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Fullscreen.hlsl"
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            half4 _InvSize;


            half4 HZBBuildFrag(Varyings input) : Color
            {	   
                half2 invSize = _InvSize.xy;
                half2 inUV = input.uv;

                // float depth = HZBReduce(_MainTex, inUV, invSize);

                // float finalDepth = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, inUV).r;


                half finalDepth;
                half4 depth;
                half2 uv0 = inUV + float2(-0.25f, -0.25f) * invSize;
                half2 uv1 = inUV + float2(0.25f, -0.25f) * invSize;
                half2 uv2 = inUV + float2(-0.25f, 0.25f) * invSize;
                half2 uv3 = inUV + float2(0.25f, 0.25f) * invSize;

                depth.x = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv0).r;
                depth.y = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv1).r;
                depth.z = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv2).r;
                depth.w = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv3).r;
#if UNITY_REVERSED_Z
                finalDepth = min(min(depth.x, depth.y), min(depth.z, depth.w));
#else
                finalDepth = max(max(depth.x, depth.y), max(depth.z, depth.w));
#endif

                return half4(finalDepth, 0, 0, 1.0f);
            }

            
            ENDHLSL
        }
    }
}