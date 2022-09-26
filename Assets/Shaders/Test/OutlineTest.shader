Shader "Unlit/OutlineTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineWidth("_OutlineWidth", float) = 1
        _OutlineColor("_OutlineColor", Color) = (1,1,1,1)
    }
    SubShader
    {
		Name "Outline"
		Tags { "LightMode"="Outline" }
        LOD 100

        
        
        Pass
        {
		    Name "Outline"
            Tags { "LightMode"="Outline" }
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 vertexColor : COLOR0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            half4 _OutlineColor;
            half _OutlineWidth;

            v2f vert(a2v v)
            {
                v2f o;
                //从顶点颜色中读取法线信息，并将其值范围从0~1还原为-1~1
                float3 vertNormal = v.vertexColor.rgb * 2 - 1;
                //使用法线与切线叉乘计算副切线用于构建切线→模型空间转换矩阵
                float3 bitangent = cross(v.normal, v.tangent.xyz) * v.tangent.w * unity_WorldTransformParams.w;
                //构建切线→模型空间转换矩阵
                float3x3 TtoO = float3x3(v.tangent.x, bitangent.x, v.normal.x,
                                         v.tangent.y, bitangent.y, v.normal.y,
                                         v.tangent.z, bitangent.z, v.normal.z);
                //将法线转换到模型空间下
                vertNormal = mul(TtoO, vertNormal);
                //模型坐标 + 法线 * 自定义粗细值 * 顶点颜色A通道 = 轮廓线模型					
                o.vertex = TransformObjectToHClip(v.vertex + vertNormal * _OutlineWidth * v.vertexColor.a);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // apply fog
                return _OutlineColor;
            }
            ENDHLSL
        }
        
        
                // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"
            ENDHLSL
        }
        
    }
}