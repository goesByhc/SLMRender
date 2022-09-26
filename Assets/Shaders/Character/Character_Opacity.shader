Shader "Character_Opacity"
{
	Properties
	{
		_BaseMap ("Base Map", 2D) = "white" {}
		_TintColor("Tint Color", Color) = (1,1,1,0)
		_Opacity("Opacity", Range( 0 , 1)) = 1
	}
	SubShader
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline" 
			"RenderType"="Transparent" 
			"Queue"="AlphaTest" 
		}

		HLSLINCLUDE

		
		ENDHLSL
		
		
		Pass
		{
			Name "Forward"
			Tags
			{
				"LightMode"="UniversalForward" 
			}

			Cull Off
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// #pragma multi_compile_fwdbase
			// #include "UnityCG.cginc"
			// #include "AutoLight.cginc"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
				float3 normal: NORMAL;
				float4 tangent : TANGENT;
				float4 color: COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normalDir: TEXCOORD1; //法线
				float3 tangentDir: TEXCOORD2; //切线
				float3 binormalDir: TEXCOORD3; //副法线
				float4 posWorld: TEXCOORD4;
				float4 vertexColor: TEXCOORD5;
			};


			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);
				o.normalDir = TransformObjectToWorldNormal(v.normal);
				// o.pos = UnityObjectToClipPos(v.vertex);
				// o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.vertexColor = v.color;
				o.uv = v.texcoord0;
				return o;
			}
			
			CBUFFER_START(UnityPerMaterial)
			float4 _TintColor;
			half _Opacity;
			CBUFFER_END
			
			sampler2D _BaseMap;
			float4 _CharacterLightColor;
			float _CharacterLightIntensity;
			float _SceneLightProbe;
			float4 _CharacterLightDirection;

			float3 RotateAround(float degree, float3 target)
			{
				float rad = degree * PI / 180;
				float2x2 m_rotate = float2x2(cos(rad), -sin(rad),
						sin(rad), cos(rad));
				float2 dir_rotate = mul(m_rotate, target.xz);
				target = float3(dir_rotate.x, target.y, dir_rotate.y);
				return target;
			}

			inline float3 ACESFilm(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
			}
			
			
			half4 frag (v2f i) : SV_Target
			{
				//向量
				half3 normalDir = normalize(i.normalDir);
				// half3 tangentDir = normalize(i.tangentDir);
				// half3 binormalDir = normalize(i.binormalDir);
				half3 lightDir = normalize(_CharacterLightDirection.xyz);
				// half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				// half3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
				// half3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);


				// return frontDotView; 

				// if (frontDotView + _BackClip < 0)
				// {
				// 	discard;
				// }
				
				float3 indirectDiffuse = SampleSH(i.normalDir);
				float3 finalIndirect = lerp(float3(0,0,0), indirectDiffuse, _SceneLightProbe);
				float3 finalLight = _CharacterLightColor * _CharacterLightIntensity + finalIndirect;
				//贴图数据
				half4 baseMap = tex2D(_BaseMap, i.uv).rgba;
				half3 baseColor = baseMap.rgb * _TintColor.rgb;
				half opacity = lerp(1, baseMap.a, _Opacity);

				
				//漫反射
				half NDotL = max(0.0, dot(normalDir, lightDir));
				half half_lamber = (NDotL + 1.0) * 0.5;
				half3 final_diffuse = half_lamber * baseColor * finalLight;

				return float4(final_diffuse, opacity);
			}
			ENDHLSL
		}
		
		
	}
	FallBack "Standard"
}
