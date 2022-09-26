Shader "TextureDebug"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        [KeywordEnum(None, R, G, B, A, UV, UV2, Normal ,VertexColor, VertexR, VertexG, VertexB, VertexA)] _TestMode("_TestMode",Int) = 0
    }
    SubShader
    {
    	Tags
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"Queue"="Transparent"
		}

        Pass
        {
			Name "Forward"
            Tags {
            	"LightMode"="SRPDefaultUnlit" 
            }
            
            HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// #pragma multi_compile_fwdbase			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // #include "UnityCG.cginc"
            // #include "AutoLight.cginc"
            //
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord0: TEXCOORD0;
                float2 texcoord1: TEXCOORD1;
                float3 normal: NORMAL;
                float4 tangent : TANGENT;
                float4 color: COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 pos_world: TEXCOORD1;
                float4 vertex_color: TEXCOORD2;
                float3 normal_dir: TEXCOORD3; //法线
				float3 tangent_dir: TEXCOORD4; //切线
				float3 binormal_dir: TEXCOORD5; //副法线
            };

            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            sampler2D _NormalMap;
            int _TestMode;

            
            v2f vert (appdata v)
            {
                v2f o;

                o.normal_dir = TransformObjectToWorldNormal(v.normal);
				o.tangent_dir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormal_dir = normalize(cross(o.normal_dir, o.tangent_dir) * v.tangent.w);
                o.pos = TransformObjectToHClip(v.vertex);
                // o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                // o.normal_world = TransformObjectToWorldNormal(v.normal);
                o.uv = float4(v.texcoord0, v.texcoord1);
                o.vertex_color = v.color;
                // TRANSFER_SHADOW(o)
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {

                half4 base_color = tex2D(_BaseMap, i.uv);

				//法线贴图
                				//向量
				half3 normalDir = normalize(i.normal_dir);
				half3 tangentDir = normalize(i.tangent_dir);
				half3 binormalDir = normalize(i.binormal_dir);
				half4 normal_map = tex2D(_NormalMap, i.uv);
				half3 normal_data = UnpackNormal(normal_map);
				float3x3 TBN = float3x3(tangentDir, binormalDir, normalDir);
				normal_data.xy = normal_data.xy * 1;
				normalDir = normalize(mul(normal_data.xyz, TBN));

                // return BaseColor.xyzz;
                int mode = 0;
                if(_TestMode == mode++)
                    return base_color;
                if(_TestMode == mode++)
                    return base_color.r;
                if(_TestMode == mode++)
                    return base_color.g;
                if(_TestMode == mode++)
                    return base_color.b;
                if(_TestMode == mode++)
                    return base_color.a;
                if(_TestMode == mode++)
                    return float4(i.uv.xy,0,0); //uv
                if(_TestMode == mode++)
                    return float4(i.uv.zw,0,0); //uv2
                if(_TestMode == mode++)
                    return float4(normalDir, 1);
                if(_TestMode == mode++)
                    return i.vertex_color.rgba; //vertexColor
                if(_TestMode == mode++)
                    return i.vertex_color.r; //vertexColor
                if(_TestMode == mode++)
                    return i.vertex_color.g; //vertexColor
                if(_TestMode == mode++)
                    return i.vertex_color.b; //vertexColor
                if(_TestMode == mode++)
                    return i.vertex_color.a; //vertexColor
                return base_color;
            }
            ENDHLSL
        }
    }
}