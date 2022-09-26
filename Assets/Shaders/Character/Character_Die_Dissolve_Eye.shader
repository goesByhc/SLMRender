Shader "Character_Die_Dissolve_Eye"
{
	Properties
	{
		_BaseMap ("Base Map", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_EyeCenter("Eye Center", Vector) = (0.5, 0.5, 0.5, 0.5)
		_EnvMap("Env Map", Cube) = "white" {}
		_EnvRotate("Env Rotate", Range(0, 360)) = 0
		_Roughness("Roughness", Range(0, 1)) = 1
		_EnvIntensity("Env Intensity", float) = 0.5
		_Parallax ("Parallax", Range(-0.5, 0)) = -0.1
		_EyeShadowIntensity("Eye Shadow Intnsity", Range(0, 3)) = 1
		_DissolveTexture("DissolveTexture", 2D) = "white" {}
		_DissolveTiling("DissolveTiling", Range( 0 , 1000)) = 1
		_DissolveProgress("DissolveProgress", Range( -0.001 , 1)) = -0.001
		}
	SubShader
	{
		
		Tags
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}


		Pass
		{
			Name "Forward"
			Tags
			{
				"LightMode"="UniversalForward" 
			}

			
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
				float4 screenPos : TEXCOORD6;
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
				o.screenPos = ComputeScreenPos(o.pos);
				o.vertexColor = v.color;
				o.uv = v.texcoord0;
				return o;
			}

			CBUFFER_START(UnityPerMaterial)
			sampler2D _BaseMap;
			float _Parallax;
			sampler2D _NormalMap;
			
			
			samplerCUBE _EnvMap;
			float _EnvRotate;
			float4 _EnvMap_HDR;
			float _Roughness;
			float _FresnelMin;
			float _FresnelMax;
			float _EnvIntensity;
			float _EyeShadowIntensity;
			float4 _EyeCenter;
			float _DissolveProgress;
			float _DissolveTiling;
			CBUFFER_END
			sampler2D _DissolveTexture;
			float4 _CharacterLightColor;
			float4 _CharacterLightDirection;
			float _CharacterLightIntensity;
			float _SceneLightProbe;


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

				float4 screenPos = i.screenPos;
				float4 screenPosNorm = screenPos / screenPos.w;
				screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
				float2 screenUV = (float2(( ( _ScreenParams.x / _ScreenParams.y ) * screenPosNorm.x ) , screenPosNorm.y));
				float dissolveAlpha = step( _DissolveProgress , tex2D( _DissolveTexture, frac( ( screenUV * _DissolveTiling ) ) ).r );
				
				clip( dissolveAlpha - 0.5 );

				// return half4(1,0,0,1);
				//向量
				half3 normalDir = normalize(i.normalDir);
				half3 tangentDir = normalize(i.tangentDir);
				half3 binormalDir = normalize(i.binormalDir);
				half3 lightDir = normalize(_CharacterLightDirection.xyz);
				// half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);


				//法线贴图
				half4 normal_map = tex2D(_NormalMap, i.uv);
				half3 normal_data = UnpackNormal(normal_map);
				float3x3 TBN = float3x3(tangentDir, binormalDir, normalDir);
				normalDir = normalize(mul(normal_data, TBN));
				normal_data.xy = -normal_data.xy;
				float3 normalDir_Iris = normalize(mul(normal_data, TBN));


				//视差偏移
				float2 parallax_depth = smoothstep(1.0, 0.5, (distance(i.uv, float2(_EyeCenter.x, _EyeCenter.y)) / float2(_EyeCenter.z, _EyeCenter.w)));

				float3 tanViewDir = normalize(mul(TBN, viewDir));
				float2 parallax_offset = parallax_depth * (tanViewDir.xy / (tanViewDir.z + 0.42f)) * _Parallax;
				// return float4(parallax_offset.xy, 1, 1);

				//贴图数据
				half4 base_color = tex2D(_BaseMap, i.uv + parallax_offset).rgba;
				half alpha = base_color.a;
				
				//漫反射
				half NDotL = dot(normalDir_Iris.xz, lightDir.xz);
				half half_lamber = (NDotL + 1.0) * 0.5;
				half3 final_diffuse = half_lamber * base_color * base_color;

				// return 

				//环境反射/边缘光
				half3 reflectDir = reflect(-viewDir, normalDir);
				reflectDir = RotateAround(_EnvRotate, reflectDir);
				float roughness = lerp(0.0, 0.95, saturate(_Roughness));
				roughness = roughness * (1.7 - 0.7 * roughness);
				float mip_level = roughness * 6.0;
				half4 color_cubemap = texCUBElod(_EnvMap, float4(reflectDir, mip_level));
				half3 env_color = DecodeHDREnvironment(color_cubemap, _EnvMap_HDR);
				// half3 env_color = half3(0.0, 0.0, 0.0);
				half3 final_env = env_color * _EnvIntensity;
				half env_lumin = dot(final_env, float3(0.299f, 0.587f, 0.114f));
				final_env = final_env * env_lumin;

				// return float4(lightDir, 1);

				float3 indirectDiffuse = SampleSH(i.normalDir);
				float3 finalIndirect = lerp(float3(0,0,0), indirectDiffuse, _SceneLightProbe);
				float3 finalLight = _CharacterLightColor * _CharacterLightIntensity + finalIndirect;
				
				half3 final_color = final_diffuse + final_diffuse * final_env;

				final_color *= finalLight;

				// half3 final_color = NDotL.xxx;
				half3 encode_color = sqrt(ACESFilm(final_color));
				encode_color = encode_color * saturate(pow(alpha, _EyeShadowIntensity));
				return half4(encode_color, 1.0);
			}
			ENDHLSL
		}
		
		
	}
	FallBack "Standard"
}
