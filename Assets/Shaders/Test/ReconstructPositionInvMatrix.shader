//puppet_master
//https://blog.csdn.net/puppet_master  
//2018.6.10  
//通过逆矩阵的方式从深度图构建世界坐标
Shader "DepthTexture/ReconstructPositionInvMatrix"
{

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos: TEXCOORD1;
            };


            sampler2D _CameraDepthTexture;
    	    float4x4 _InverseVPMatrix;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                float4 screenPos = ComputeScreenPos( o.vertex );

                screenPos = screenPos / screenPos.w;
				screenPos.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPos.z : screenPos.z* 0.5 + 0.5;
                o.screenPos = screenPos;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {


                
                // return half4(i.screenPos.xy,0, 1);
                
                float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy);
                //自己操作深度的时候，需要注意Reverse_Z的情况
                #if defined(UNITY_REVERSED_Z)
                depthTextureValue = 1 - depthTextureValue;
                #endif

                // return depthTextureValue.rrrr;
                
                float4 ndc = float4(i.screenPos.x * 2 - 1, i.screenPos.y * 2 - 1, depthTextureValue * 2 - 1, 1);
                
                float4 worldPos = mul(_InverseVPMatrix, ndc);
                worldPos /= worldPos.w;

                // return worldPos.yyyy;
                return worldPos;
            }
            ENDCG
        }

    }



    //	CGINCLUDE
    //	#include "UnityCG.cginc"
    //	sampler2D _CameraDepthTexture;
    //	float4x4 _InverseVPMatrix;

    //	fixed4 frag_depth(v2f_img i) : SV_Target
    //	{
    //		float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
    //		//自己操作深度的时候，需要注意Reverse_Z的情况
    //		#if defined(UNITY_REVERSED_Z)
    //		depthTextureValue = 1 - depthTextureValue;
    //		#endif
    //		float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue * 2 - 1, 1);
    //		
    //		float4 worldPos = mul(_InverseVPMatrix, ndc);
    //		worldPos /= worldPos.w;
    //		return worldPos;
    //	}
    //	ENDCG
    // 
    //	SubShader
    //	{
    //		Pass
    //		{
    //			ZTest Off
    //			Cull Off
    //			ZWrite Off
    //			Fog{ Mode Off }
    // 
    //			CGPROGRAM
    //			#pragma vertex vert_img
    //			#pragma fragment frag_depth
    //			ENDCG
    //		}
    //	}
}