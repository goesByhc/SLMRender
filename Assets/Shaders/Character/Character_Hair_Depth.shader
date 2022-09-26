Shader "Character_Hair_Depth"
{
    Properties
    {
    }


    SubShader
    {

        HLSLINCLUDE
            #include "../Core.hlsl"
            #include "../DepthOnlyPass.hlsl"
        ENDHLSL
        
        Pass
        {
            
            Name "DepthHairOnly"
            Tags
            {
                "LightMode" = "DepthHairOnly" 
            }

            ZWrite On
            AlphaToMask Off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            
            #pragma vertex CustomDepthOnlyVertex
            #pragma fragment CustomDepthOnlyFragment

            //DepthPrePass
            struct VertexInputHairDepth
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct VertexOutputHairDepth
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            VertexOutputHairDepth CustomDepthOnlyVertex(VertexInputHairDepth input)
            {
                VertexOutputHairDepth output = (VertexOutputHairDepth)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                
                return output;
            }
            
            half4 CustomDepthOnlyFragment(VertexOutputHairDepth input): SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                //如果Rt.ColorFormat == Depth，则这里返回啥都无所谓
                //如果Rt.ColorFormat是RGB，则会写入返回值
                float depth = input.positionCS.z / input.positionCS.w;
                return half4(depth.rrr, 1);
            }

            ENDHLSL
        }
    }
}