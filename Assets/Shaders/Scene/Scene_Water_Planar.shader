// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Scene_Water_Planar"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_DeepColor("Deep Color 深水颜色", Color) = (0,0,0,0)
		_DeepRange("Deep Range 深水范围", Range( 0 , 10)) = 1
		_ShallowColor("Shallow Color 潜水颜色", Color) = (0,0,0,0)
		_FresnelColor("Fresnel Color 菲涅尔颜色", Color) = (0,0,0,0)
		_FresnelPower("Fresnel Power 菲涅尔范围", Range( 0.001 , 100)) = 0
		_NormalMap("Normal Map 法线贴图", 2D) = "bump" {}
		_NormalTiling("Normal Tiling 法线密度", Float) = 1
		_NormalSpeed("Normal Speed 法线速度", Vector) = (0,0,0,0)
		_NormalScale("Normal Scale 法线强度", Float) = 0
		_ReflectDistort("Reflect Distort 反射扰动", Range( 0 , 1)) = 0
		_ReflectPower("Reflect Power 反射范围", Float) = 5
		_ReflectIntensity("Reflect Intensity 反射强度", Float) = 20
		_ReflectionRoughness("Reflection Roughness", Range( 0 , 1)) = 0
		_WaveA("WaveA 波浪(x方向,y方向,z方向,波长)", Vector) = (1,1,2,50)
		_WaveB("WaveB", Vector) = (1,1,2,50)
		_WaveC("WaveC", Vector) = (1,1,2,50)
		_WaveColor("Wave Color 波浪颜色", Color) = (0,0,0,0)
		_UnderWaterDistort("Under Water Distort 水下扰动", Float) = 1
		_CausticsMap("Caustics Map 焦散贴图", 2D) = "white" {}
		_CausticsScale("Caustics Scale 焦散大小", Float) = 0
		_CausticsIntensity("Caustics Intensity 焦散强度", Float) = 3
		_CausticsSpeed("Caustics Speed 焦散速度", Vector) = (0,0,0,0)
		_CausticsRange("Caustics Range 焦散范围", Float) = 1
		_ShoreColor("Shore Color 岸边颜色", Color) = (1,1,1,0)
		_ShoreRange("Shore Range 岸边范围", Range( 0 , 30)) = 0
		_ShoreEdgeWidth("Shore Edge Width 岸边过渡", Range( 0 , 1)) = 0
		_ShoreEdgeIntensity("Shore Edge Intensity 岸边强度", Range( 0 , 1)) = 0
		_FoamColor("Foam Color 泡沫颜色", Color) = (1,1,1,1)
		_FoamRange("Foam Range 泡沫范围", Range( 0 , 2)) = 1
		_FoamSpeed("Foam Speed 泡沫速度", Float) = 0.01
		_FoamFrequency("Foam Frequency 泡沫频率", Float) = 0
		_FoamBlend("Foam Blend 泡沫混合强度", Range( 0 , 1)) = 0
		_FoamNoiseSize("Foam Noise Size 泡沫噪点大小", Vector) = (0,0,0,0)
		_FoamDissolve("Foam Dissolve 泡沫溶解", Float) = 0
		_BloomFactor("BloomFactor", Range( 0.001 , 1)) = 0.011
		[ASEEnd][KeywordEnum(Default,WaterColor,UnderWaterColor,ReflectionColor,ShoreColor,FoemColor)] _DebugChannel("DebugChannel", Float) = 0

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="AlphaTest+500" }
		
		Cull Off
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS

		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="MobileSSPR" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999
			#define REQUIRE_DEPTH_TEXTURE 1
			#define REQUIRE_OPAQUE_TEXTURE 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _DEBUGCHANNEL_DEFAULT _DEBUGCHANNEL_WATERCOLOR _DEBUGCHANNEL_UNDERWATERCOLOR _DEBUGCHANNEL_REFLECTIONCOLOR _DEBUGCHANNEL_SHORECOLOR _DEBUGCHANNEL_FOEMCOLOR
			#include "../MobileSSPRInclude.hlsl"
			#pragma multi_compile _ _MobileSSPR


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaveA;
			float4 _WaveB;
			float4 _WaveC;
			float4 _WaveColor;
			float4 _DeepColor;
			float4 _ShallowColor;
			float4 _ShoreColor;
			float4 _FresnelColor;
			float4 _FoamColor;
			float2 _CausticsSpeed;
			float2 _FoamNoiseSize;
			float2 _NormalSpeed;
			float _ShoreRange;
			float _FoamBlend;
			float _FoamDissolve;
			float _FoamFrequency;
			float _FoamSpeed;
			float _ShoreEdgeWidth;
			float _FoamRange;
			float _CausticsRange;
			float _UnderWaterDistort;
			float _CausticsScale;
			float _ShoreEdgeIntensity;
			float _ReflectPower;
			float _ReflectIntensity;
			float _ReflectionRoughness;
			float _ReflectDistort;
			float _NormalScale;
			float _NormalTiling;
			float _FresnelPower;
			float _DeepRange;
			float _CausticsIntensity;
			float _BloomFactor;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			uniform float4 _CameraDepthTexture_TexelSize;
			sampler2D _NormalMap;
			sampler2D _CausticsMap;


			float3 GerstnerWave188( float3 position, inout float3 tangent, inout float3 binormal, float4 wave )
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = 2 * PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, position.xz) - c * _Time.y);
				float a = steepness / k;
							
				tangent += float3(
				-d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				-d.y * d.y * (steepness * sin(f))
				);
				return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
			}
			
			float3 GerstnerWave196( float3 position, inout float3 tangent, inout float3 binormal, float4 wave )
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = 2 * PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, position.xz) - c * _Time.y);
				float a = steepness / k;
							
				tangent += float3(
				-d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				-d.y * d.y * (steepness * sin(f))
				);
				return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
			}
			
			float3 GerstnerWave203( float3 position, inout float3 tangent, inout float3 binormal, float4 wave )
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = 2 * PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, position.xz) - c * _Time.y);
				float a = steepness / k;
							
				tangent += float3(
				-d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				-d.y * d.y * (steepness * sin(f))
				);
				return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
			}
			
			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			float3 InvertDepthDirURP75_g16( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301 || ASE_SRP_VERSION == 70503 || ASE_SRP_VERSION >= 80301 
				result *= float3(1,1,-1);
				#endif
				return result;
			}
			
			float3 SSPR24_g15( float3 posWS, float4 screenPos, float2 screenPosNoise, float roughness, float ssrpUsage )
			{
				ReflectionInput reflectionData;
				reflectionData.posWS = posWS;
				reflectionData.screenPos = screenPos;
				reflectionData.screenSpaceNoise = screenPosNoise;
				reflectionData.roughness = roughness;
				reflectionData.SSPR_Usage = ssrpUsage;
				half3 resultReflection = GetResultReflection(reflectionData);
				return resultReflection;
			}
			
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			
			//https://www.shadertoy.com/view/XdXGW8
			float2 GradientNoiseDir( float2 x )
			{
				const float2 k = float2( 0.3183099, 0.3678794 );
				x = x * k + k.yx;
				return -1.0 + 2.0 * frac( 16.0 * k * frac( x.x * x.y * ( x.x + x.y ) ) );
			}
			
			float GradientNoise( float2 UV, float Scale )
			{
				float2 p = UV * Scale;
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = f * f * ( 3.0 - 2.0 * f );
				return lerp( lerp( dot( GradientNoiseDir( i + float2( 0.0, 0.0 ) ), f - float2( 0.0, 0.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 0.0 ) ), f - float2( 1.0, 0.0 ) ), u.x ),
						lerp( dot( GradientNoiseDir( i + float2( 0.0, 1.0 ) ), f - float2( 0.0, 1.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 1.0 ) ), f - float2( 1.0, 1.0 ) ), u.x ), u.y );
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				
				o.ase_texcoord5.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float3 position188 = WorldPosition;
				float3 tangent188 = float3( 1,0,0 );
				float3 binormal188 = float3( 0,0,1 );
				float4 wave188 = _WaveA;
				float3 localGerstnerWave188 = GerstnerWave188( position188 , tangent188 , binormal188 , wave188 );
				float3 position196 = WorldPosition;
				float3 tangent196 = tangent188;
				float3 binormal196 = binormal188;
				float4 wave196 = _WaveB;
				float3 localGerstnerWave196 = GerstnerWave196( position196 , tangent196 , binormal196 , wave196 );
				float3 position203 = WorldPosition;
				float3 tangent203 = tangent196;
				float3 binormal203 = binormal196;
				float4 wave203 = _WaveC;
				float3 localGerstnerWave203 = GerstnerWave203( position203 , tangent203 , binormal203 , wave203 );
				float3 temp_output_191_0 = ( WorldPosition + localGerstnerWave188 + localGerstnerWave196 + localGerstnerWave203 );
				float clampResult209 = clamp( (( temp_output_191_0 - WorldPosition )).y , 0.0 , 1.0 );
				float4 WaveColor212 = ( clampResult209 * _WaveColor );
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 UV22_g17 = ase_screenPosNorm.xy;
				float2 localUnStereo22_g17 = UnStereo( UV22_g17 );
				float2 break64_g16 = localUnStereo22_g17;
				float clampDepth69_g16 = SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy );
				#if UNITY_REVERSED_Z
				float staticSwitch38_g16 = ( 1.0 - clampDepth69_g16 );
				#else
				float staticSwitch38_g16 = clampDepth69_g16;
				#endif
				float3 appendResult39_g16 = (float3(break64_g16.x , break64_g16.y , staticSwitch38_g16));
				float4 appendResult42_g16 = (float4((appendResult39_g16*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g16 = mul( unity_CameraInvProjection, appendResult42_g16 );
				float3 temp_output_46_0_g16 = ( (temp_output_43_0_g16).xyz / (temp_output_43_0_g16).w );
				float3 In75_g16 = temp_output_46_0_g16;
				float3 localInvertDepthDirURP75_g16 = InvertDepthDirURP75_g16( In75_g16 );
				float4 appendResult49_g16 = (float4(localInvertDepthDirURP75_g16 , 1.0));
				float3 PositionFromDepth220 = (mul( unity_CameraToWorld, appendResult49_g16 )).xyz;
				float WaterDepth226 = ( WorldPosition.y - (PositionFromDepth220).y );
				float clampResult237 = clamp( exp( ( -WaterDepth226 / _DeepRange ) ) , 0.0 , 1.0 );
				float4 lerpResult230 = lerp( _DeepColor , _ShallowColor , clampResult237);
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float fresnelNdotV242 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode242 = ( 0.0 + 1.0 * pow( max( 1.0 - fresnelNdotV242 , 0.0001 ), _FresnelPower ) );
				float4 lerpResult239 = lerp( lerpResult230 , _FresnelColor , fresnelNode242);
				float4 WaterColor244 = lerpResult239;
				float3 posWS24_g15 = WorldPosition;
				float4 screenPos24_g15 = ase_screenPosNorm;
				float2 temp_output_255_0 = ( ( (WorldPosition).xz * _NormalTiling ) / _NormalScale );
				float mulTime261 = _TimeParameters.x * 0.1;
				float2 temp_output_259_0 = ( _NormalSpeed * mulTime261 );
				float3 SurfaceNormal264 = BlendNormal( UnpackNormalScale( tex2D( _NormalMap, ( temp_output_255_0 + temp_output_259_0 ) ), 1.0f ) , UnpackNormalScale( tex2D( _NormalMap, ( ( temp_output_255_0 * 2.0 ) + ( temp_output_259_0 * -0.5 ) ) ), 1.0f ) );
				float2 screenPosNoise24_g15 = ( (SurfaceNormal264).xy * ( _ReflectDistort * 0.01 ) );
				float clampResult34_g15 = clamp( _ReflectionRoughness , 0.0 , 1.0 );
				float roughness24_g15 = clampResult34_g15;
				float clampResult37_g15 = clamp( 1.0 , 0.0 , 1.0 );
				float ssrpUsage24_g15 = clampResult37_g15;
				float3 localSSPR24_g15 = SSPR24_g15( posWS24_g15 , screenPos24_g15 , screenPosNoise24_g15 , roughness24_g15 , ssrpUsage24_g15 );
				float3 temp_output_451_0 = localSSPR24_g15;
				float fresnelNdotV408 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode408 = ( 0.0 + _ReflectIntensity * pow( max( 1.0 - fresnelNdotV408 , 0.0001 ), _ReflectPower ) );
				float clampResult413 = clamp( fresnelNode408 , 0.0 , 1.0 );
				float3 ReflectionColor415 = ( temp_output_451_0 * clampResult413 );
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float4 fetchOpaqueVal288 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ( ase_grabScreenPosNorm + float4( ( SurfaceNormal264 * _UnderWaterDistort * 0.01 ) , 0.0 ) ).xy ), 1.0 );
				float4 SceneColor337 = fetchOpaqueVal288;
				float2 temp_output_308_0 = ( (PositionFromDepth220).xz / _CausticsScale );
				float2 temp_output_311_0 = ( _CausticsSpeed * _TimeParameters.x * 0.01 );
				float clampResult329 = clamp( exp( ( -WaterDepth226 / _CausticsRange ) ) , 0.0 , 1.0 );
				float4 CausticsColor356 = ( ( min( tex2D( _CausticsMap, ( temp_output_308_0 + temp_output_311_0 ) ) , tex2D( _CausticsMap, ( -temp_output_308_0 + temp_output_311_0 ) ) ) * _CausticsIntensity ) * clampResult329 );
				float4 UnderWaterColor295 = ( SceneColor337 + CausticsColor356 );
				float WaterOpacity246 = ( 1.0 - (lerpResult239).a );
				float4 lerpResult299 = lerp( ( WaveColor212 + WaterColor244 + float4( ReflectionColor415 , 0.0 ) ) , UnderWaterColor295 , WaterOpacity246);
				float3 ShoreColor352 = (( SceneColor337 * _ShoreColor )).rgb;
				float clampResult344 = clamp( exp( ( -WaterDepth226 / _ShoreRange ) ) , 0.0 , 1.0 );
				float WaterShore345 = clampResult344;
				float4 lerpResult354 = lerp( lerpResult299 , float4( ShoreColor352 , 0.0 ) , WaterShore345);
				float clampResult372 = clamp( ( WaterDepth226 / _FoamRange ) , 0.0 , 1.0 );
				float smoothstepResult378 = smoothstep( _FoamBlend , 1.0 , ( 0.1 + clampResult372 ));
				float temp_output_373_0 = ( 1.0 - clampResult372 );
				float2 texCoord387 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				float gradientNoise386 = GradientNoise(( texCoord387 * _FoamNoiseSize ),1.0);
				gradientNoise386 = gradientNoise386*0.5 + 0.5;
				float4 FoemColor395 = ( ( ( 1.0 - smoothstepResult378 ) * step( temp_output_373_0 , ( ( sin( ( ( temp_output_373_0 * _FoamFrequency ) + ( _TimeParameters.x * -_FoamSpeed ) ) ) + gradientNoise386 ) - _FoamDissolve ) ) ) * _FoamColor );
				float4 lerpResult402 = lerp( lerpResult354 , ( lerpResult354 + FoemColor395 ) , (FoemColor395).a);
				float smoothstepResult357 = smoothstep( ( 1.0 - _ShoreEdgeWidth ) , 1.1 , WaterShore345);
				float ShoreEdge363 = ( smoothstepResult357 * _ShoreEdgeIntensity );
				float4 FinalColor453 = max( ( lerpResult402 + ShoreEdge363 ) , float4( 0,0,0,0 ) );
				#if defined(_DEBUGCHANNEL_DEFAULT)
				float4 staticSwitch452 = FinalColor453;
				#elif defined(_DEBUGCHANNEL_WATERCOLOR)
				float4 staticSwitch452 = WaterColor244;
				#elif defined(_DEBUGCHANNEL_UNDERWATERCOLOR)
				float4 staticSwitch452 = UnderWaterColor295;
				#elif defined(_DEBUGCHANNEL_REFLECTIONCOLOR)
				float4 staticSwitch452 = float4( ReflectionColor415 , 0.0 );
				#elif defined(_DEBUGCHANNEL_SHORECOLOR)
				float4 staticSwitch452 = float4( ShoreColor352 , 0.0 );
				#elif defined(_DEBUGCHANNEL_FOEMCOLOR)
				float4 staticSwitch452 = FoemColor395;
				#else
				float4 staticSwitch452 = FinalColor453;
				#endif
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = staticSwitch452.rgb;
				float Alpha = ( 1.0 - ( IN.ase_color.a * _BloomFactor ) );
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

	
	}
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Standard"
	
}
/*ASEBEGIN
Version=18900
329.6;193.6;1658.4;704.6;-2568.31;-2053.512;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;215;-419.4103,-22.04184;Inherit;False;1410.807;493.4987;Water Depth;7;226;221;223;219;220;218;216;Water Depth;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;251;-464.2594,1692.332;Inherit;False;1878.128;681.7974;Comment;19;256;264;271;263;265;257;270;266;268;255;269;267;259;261;286;258;254;287;252;Surface Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;216;-374.149,319.5296;Inherit;False;Reconstruct World Position From Depth;-1;;16;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldPosInputsNode;252;-449.1333,1740.872;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SwizzleNode;218;-23.79654,319.1741;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;287;-279.3602,1905.57;Inherit;False;Property;_NormalTiling;Normal Tiling 法线密度;6;0;Create;False;0;0;0;False;0;False;1;0.55;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;254;-171.7432,1802.19;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;262;-470.2101,2257.339;Inherit;False;Constant;_TimeScale;TimeScale;11;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;258;-223.6723,2079.468;Inherit;False;Property;_NormalSpeed;Normal Speed 法线速度;7;0;Create;False;0;0;0;False;0;False;0,0;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;220;169.5031,309.7738;Inherit;False;PositionFromDepth;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;261;-213.2101,2234.339;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;286;-21.52051,1811.696;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;256;-126.6723,1976.468;Inherit;False;Property;_NormalScale;Normal Scale 法线强度;8;0;Create;False;0;0;0;False;0;False;0;2.68;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;255;140.3277,1884.468;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;269;30.78993,2280.339;Inherit;False;Constant;_Float1;Float 1;12;0;Create;True;0;0;0;False;0;False;-0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;267;196.7899,2112.339;Inherit;False;Constant;_Float0;Float 0;12;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;219;68.90329,115.5728;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;321;-491.6512,4113.591;Inherit;False;2063.507;827.7651;Caustics Color;24;356;330;329;318;335;328;319;317;331;327;308;306;309;307;313;315;314;316;311;333;323;334;325;326;Caustics Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;259;15.3277,2096.468;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;223;408.603,309.7736;Inherit;False;FLOAT;1;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;221;540.6048,172.8743;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;266;353.7899,2081.339;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;306;-441.651,4163.589;Inherit;False;220;PositionFromDepth;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;268;234.7899,2225.339;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;307;-202.6673,4167.163;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;270;414.7899,2255.339;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;257;341.3277,1928.468;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;226;702.7978,206.0892;Inherit;False;WaterDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;309;-439.6673,4271.163;Inherit;False;Property;_CausticsScale;Caustics Scale 焦散大小;20;0;Create;False;0;0;0;False;0;False;0;5.13;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;396;1963.823,4515.657;Inherit;False;2903.974;1125.955;Foam Color;25;395;399;385;398;393;391;392;390;394;384;386;383;389;376;388;387;382;375;374;373;377;372;369;370;368;Foam Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;193;-869.1297,5883.583;Inherit;False;2805.586;721.6816;Wave Vertex Animation ;23;212;209;194;200;207;208;206;211;210;199;192;191;198;197;203;196;204;202;188;189;190;424;423;Wave Vertex Animation ;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;368;2023.276,4743.321;Inherit;False;226;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;313;-374.8674,4374.764;Inherit;False;Property;_CausticsSpeed;Caustics Speed 焦散速度;22;0;Create;False;0;0;0;False;0;False;0,0;5,5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;263;549.7899,1881.339;Inherit;True;Property;_NormalMap;Normal Map 法线贴图;5;0;Create;False;0;0;0;False;0;False;-1;None;f409486a995492b488229a4ca82d0c6d;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;308;20.33266,4191.163;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;315;-331.3674,4636.964;Inherit;False;Constant;_Float4;Float 4;18;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;370;2013.823,4877.306;Inherit;False;Property;_FoamRange;Foam Range 泡沫范围;29;0;Create;False;0;0;0;False;0;False;1;0.47;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;189;-748.707,5965.309;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;314;-349.3674,4533.964;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;190;-789.7069,6263.31;Inherit;False;Property;_WaveA;WaveA 波浪(x方向,y方向,z方向,波长);14;0;Create;False;0;0;0;False;0;False;1,1,2,50;1,1,0,10;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;238;-473.8445,615.4764;Inherit;False;1925.816;950.8893;Comment;17;246;244;239;230;242;241;229;228;237;243;236;234;235;233;231;248;249;Water Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;265;564.7899,2101.339;Inherit;True;Property;_TextureSample0;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Instance;263;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;369;2337.473,4799.325;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;-457.6445,1074.063;Inherit;False;226;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;311;-116.9673,4428.265;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;333;65.52279,4348.134;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BlendNormalsNode;271;913.0898,2002.139;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector4Node;202;-377.4781,6335.732;Inherit;False;Property;_WaveB;WaveB;15;0;Create;True;0;0;0;False;0;False;1,1,2,50;-0.5,-0.5,0,10;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;323;63.81529,4731.555;Inherit;False;226;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;188;-389.5331,6162.037;Inherit;False;float steepness = wave.z * 0.01@$float wavelength = wave.w@$float k = 2 * PI / wavelength@$float c = sqrt(9.8 / k)@$float2 d = normalize(wave.xy)@$float f = k * (dot(d, position.xz) - c * _Time.y)@$float a = steepness / k@$			$$tangent += float3($-d.x * d.x * (steepness * sin(f)),$d.x * (steepness * cos(f)),$-d.x * d.y * (steepness * sin(f))$)@$$binormal += float3($-d.x * d.y * (steepness * sin(f)),$d.y * (steepness * cos(f)),$-d.y * d.y * (steepness * sin(f))$)@$$return float3($d.x * (a * cos(f)),$a * sin(f),$d.y * (a * cos(f))$)@;3;False;4;True;position;FLOAT3;0,0,0;In;;Inherit;False;True;tangent;FLOAT3;1,0,0;InOut;;Inherit;False;True;binormal;FLOAT3;0,0,1;InOut;;Inherit;False;True;wave;FLOAT4;0,0,0,0;In;;Inherit;False;GerstnerWave;True;False;0;4;0;FLOAT3;0,0,0;False;1;FLOAT3;1,0,0;False;2;FLOAT3;0,0,1;False;3;FLOAT4;0,0,0,0;False;3;FLOAT3;0;FLOAT3;2;FLOAT3;3
Node;AmplifyShaderEditor.NegateNode;325;277.8153,4734.555;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;235;-232.7444,1256.062;Inherit;False;Property;_DeepRange;Deep Range 深水范围;1;0;Create;False;0;0;0;False;0;False;1;6.47;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;297;-464.2769,3388.14;Inherit;False;1490.318;573.1279;Under Water Color;11;337;295;336;288;293;292;289;291;294;290;338;Under Water Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;326;134.8782,4837.93;Inherit;False;Property;_CausticsRange;Caustics Range 焦散范围;23;0;Create;False;0;0;0;False;0;False;1;0.98;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;316;240.7326,4325.963;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;204;41.32908,6352.521;Inherit;False;Property;_WaveC;WaveC;16;0;Create;True;0;0;0;False;0;False;1,1,2,50;1,0.5,0,10;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;375;2122.184,5306.156;Inherit;False;Property;_FoamSpeed;Foam Speed 泡沫速度;30;0;Create;False;0;0;0;False;0;False;0.01;2.7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;264;1161.59,1996.439;Inherit;False;SurfaceNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;372;2533.823,4773.306;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;334;195.5228,4508.134;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;233;-183.3444,1071.462;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;196;-53.55096,6162.125;Inherit;False;float steepness = wave.z * 0.01@$float wavelength = wave.w@$float k = 2 * PI / wavelength@$float c = sqrt(9.8 / k)@$float2 d = normalize(wave.xy)@$float f = k * (dot(d, position.xz) - c * _Time.y)@$float a = steepness / k@$			$$tangent += float3($-d.x * d.x * (steepness * sin(f)),$d.x * (steepness * cos(f)),$-d.x * d.y * (steepness * sin(f))$)@$$binormal += float3($-d.x * d.y * (steepness * sin(f)),$d.y * (steepness * cos(f)),$-d.y * d.y * (steepness * sin(f))$)@$$return float3($d.x * (a * cos(f)),$a * sin(f),$d.y * (a * cos(f))$)@;3;False;4;True;position;FLOAT3;0,0,0;In;;Inherit;False;True;tangent;FLOAT3;1,0,0;InOut;;Inherit;False;True;binormal;FLOAT3;0,0,1;InOut;;Inherit;False;True;wave;FLOAT4;0,0,0,0;In;;Inherit;False;GerstnerWave;True;False;0;4;0;FLOAT3;0,0,0;False;1;FLOAT3;1,0,0;False;2;FLOAT3;0,0,1;False;3;FLOAT4;0,0,0,0;False;3;FLOAT3;0;FLOAT3;2;FLOAT3;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;234;-26.04453,1053.262;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;405;-676.2725,2444.54;Inherit;False;1870.171;781.6881;URP不支持Probe 的BoxProject模式 ，所以这种方法有问题;17;415;413;412;411;410;408;407;406;430;432;433;437;431;445;446;450;451;Reflection Color;0.2122642,0.5199389,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;373;2689.284,4950.257;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;203;286.7812,6137.314;Inherit;False;float steepness = wave.z * 0.01@$float wavelength = wave.w@$float k = 2 * PI / wavelength@$float c = sqrt(9.8 / k)@$float2 d = normalize(wave.xy)@$float f = k * (dot(d, position.xz) - c * _Time.y)@$float a = steepness / k@$			$$tangent += float3($-d.x * d.x * (steepness * sin(f)),$d.x * (steepness * cos(f)),$-d.x * d.y * (steepness * sin(f))$)@$$binormal += float3($-d.x * d.y * (steepness * sin(f)),$d.y * (steepness * cos(f)),$-d.y * d.y * (steepness * sin(f))$)@$$return float3($d.x * (a * cos(f)),$a * sin(f),$d.y * (a * cos(f))$)@;3;False;4;True;position;FLOAT3;0,0,0;In;;Inherit;False;True;tangent;FLOAT3;1,0,0;InOut;;Inherit;False;True;binormal;FLOAT3;0,0,1;InOut;;Inherit;False;True;wave;FLOAT4;0,0,0,0;In;;Inherit;False;GerstnerWave;True;False;0;4;0;FLOAT3;0,0,0;False;1;FLOAT3;1,0,0;False;2;FLOAT3;0,0,1;False;3;FLOAT4;0,0,0,0;False;3;FLOAT3;0;FLOAT3;2;FLOAT3;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;327;449.8153,4738.555;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;294;-407.0062,3876.802;Inherit;False;Constant;_Float3;Float 3;14;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;374;2178.184,5181.156;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;377;2432.484,5058.058;Inherit;False;Property;_FoamFrequency;Foam Frequency 泡沫频率;31;0;Create;False;0;0;0;False;0;False;0;16.41;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;331;386.5228,4467.134;Inherit;True;Property;_TextureSample1;Texture Sample 1;19;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;317;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;403;2396.273,5347.944;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;317;381.7141,4252.579;Inherit;True;Property;_CausticsMap;Caustics Map 焦散贴图;19;0;Create;False;0;0;0;False;0;False;-1;None;baf4559687c4fde4087db6db10fa95c6;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;291;-414.2769,3761.684;Inherit;False;Property;_UnderWaterDistort;Under Water Distort 水下扰动;18;0;Create;False;0;0;0;False;0;False;1;1.42;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;290;-408.218,3645.353;Inherit;False;264;SurfaceNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;292;-136.7795,3713.212;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMinOpNode;335;709.0556,4454.255;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;191;541.6678,5954.543;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;387;2719.904,5332.807;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;410;-616.7509,2692.271;Inherit;False;Property;_ReflectDistort;Reflect Distort 反射扰动;9;0;Create;False;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;318;614.1139,4654.377;Inherit;False;Property;_CausticsIntensity;Caustics Intensity 焦散强度;21;0;Create;False;0;0;0;False;0;False;3;1.61;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;388;2717.904,5494.807;Inherit;False;Property;_FoamNoiseSize;Foam Noise Size 泡沫噪点大小;33;0;Create;False;0;0;0;False;0;False;0,0;800,400;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ExpOpNode;236;153.3556,1088.362;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;411;-594.3432,2562.159;Inherit;False;264;SurfaceNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ExpOpNode;328;620.8151,4744.555;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;376;2611.483,5216.756;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;289;-408.218,3438.14;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;207;552.4608,6236.05;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;430;-581.9907,2792.669;Inherit;False;Constant;_ReflectDistortScale;Reflect Distort Scale;35;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;382;2853.689,5068.184;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;237;300.2554,1023.362;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;206;789.4608,6166.05;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;431;-288.9907,2729.669;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;293;-24.08397,3509.634;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;407;-302.1852,2945.469;Inherit;False;Property;_ReflectIntensity;Reflect Intensity 反射强度;11;0;Create;False;0;0;0;False;0;False;20;3.56;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;243;116.2255,1428.027;Inherit;False;Property;_FresnelPower;Fresnel Power 菲涅尔范围;4;0;Create;False;0;0;0;False;0;False;0;31.2;0.001;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;228;-207.3094,664.1764;Inherit;False;Property;_DeepColor;Deep Color 深水颜色;0;0;Create;False;0;0;0;False;0;False;0,0,0,0;0.1425418,0.4150943,0.2547693,0.2980392;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;319;954.6137,4429.278;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;329;766.8151,4731.555;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;229;-218.4443,875.1624;Inherit;False;Property;_ShallowColor;Shallow Color 潜水颜色;2;0;Create;False;0;0;0;False;0;False;0,0,0,0;0,0,0,0.3686275;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;406;-248.1852,3037.469;Inherit;False;Property;_ReflectPower;Reflect Power 反射范围;10;0;Create;False;0;0;0;False;0;False;5;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;389;2988.904,5406.807;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;383;3020.089,5199.483;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;346;-522.5415,5184.867;Inherit;False;2206.7;518.334;Water Shore;18;360;357;359;358;352;353;351;345;344;343;342;347;350;340;341;339;362;363;Water Shore;1,1,1,1;0;0
Node;AmplifyShaderEditor.SwizzleNode;432;-346.9907,2588.669;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;433;-117.9907,2572.669;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;339;-472.5418,5234.867;Inherit;False;226;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;288;145.9764,3490.925;Inherit;False;Global;_GrabScreen0;Grab Screen 0;14;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;241;134.6035,1200.33;Inherit;False;Property;_FresnelColor;Fresnel Color 菲涅尔颜色;3;0;Create;False;0;0;0;False;0;False;0,0,0,0;0.1928266,0.5914478,0.6509434,0.4901961;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;230;399.0557,801.0622;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SwizzleNode;208;961.4608,6174.05;Inherit;False;FLOAT;1;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;242;449.4031,1296.729;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;394;2722.584,4565.657;Inherit;False;855.5996;364.5007;Foam Mask;4;381;380;378;379;;1,1,1,1;0;0
Node;AmplifyShaderEditor.FresnelNode;408;34.45109,2901.407;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;446;16.55835,2791.765;Inherit;False;Constant;_Float2;Float 2;37;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;386;3225.201,5367.508;Inherit;False;Gradient;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;330;1134.269,4452.468;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;445;-116.4417,2699.765;Inherit;False;Property;_ReflectionRoughness;Reflection Roughness;13;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;384;3267.089,5216.383;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;356;1347.729,4464.01;Inherit;False;CausticsColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;381;2772.584,4615.657;Inherit;False;2;2;0;FLOAT;0.1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;341;-362.571,5375.051;Inherit;False;Property;_ShoreRange;Shore Range 岸边范围;25;0;Create;False;0;0;0;False;0;False;0;1.5;0;30;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;392;3496.904,5454.807;Inherit;False;Property;_FoamDissolve;Foam Dissolve 泡沫溶解;34;0;Create;False;0;0;0;False;0;False;0;0.74;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;209;1139.752,6115.498;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;211;1001.523,6258.166;Inherit;False;Property;_WaveColor;Wave Color 波浪颜色;17;0;Create;False;0;0;0;False;0;False;0,0,0,0;0.5921568,0.8784314,0.7266805,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;340;-248.9748,5252.995;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;337;379.0281,3561.414;Inherit;False;SceneColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;239;690.8029,1011.73;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;390;3552.904,5314.807;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;413;351.1852,2892.188;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;451;260.801,2576.795;Inherit;False;SSPR;-1;;15;f1ad8a953c3673443bd6ffa1a93fa525;0;3;30;FLOAT2;0,0;False;33;FLOAT;0;False;36;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;380;2931.384,4814.158;Inherit;False;Property;_FoamBlend;Foam Blend 泡沫混合强度;32;0;Create;False;0;0;0;False;0;False;0;0.089;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;437;604.6855,2717.592;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;350;-104.4176,5530.399;Inherit;False;Property;_ShoreColor;Shore Color 岸边颜色;24;0;Create;False;0;0;0;False;0;False;1,1,1,0;0.7215686,1,0.8306493,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;391;3748.905,5373.807;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;342;-76.16375,5285.623;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;336;314.7462,3699.68;Inherit;False;356;CausticsColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SwizzleNode;248;857.2491,1198.481;Inherit;False;FLOAT;3;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;210;1343.753,6184.498;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;378;3184.484,4641.857;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;347;-103.2092,5430.095;Inherit;False;337;SceneColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;393;3956.501,5090.608;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;338;561.8412,3636.813;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;244;963.1144,954.5736;Inherit;False;WaterColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;415;853.3359,2717.973;Inherit;False;ReflectionColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;249;1063.249,1196.481;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;212;1748.662,6183.037;Inherit;False;WaveColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;351;152.8723,5517.724;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ExpOpNode;343;115.9829,5302.542;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;379;3399.184,4719.658;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;353;343.2271,5525.529;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;295;785.6157,3600.62;Inherit;False;UnderWaterColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;246;1230.503,1299.837;Inherit;False;WaterOpacity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;245;1637.364,1399.27;Inherit;False;244;WaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;344;298.4617,5306.167;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;398;4140.828,5175.604;Inherit;False;Property;_FoamColor;Foam Color 泡沫颜色;28;0;Create;False;0;0;0;False;0;False;1,1,1,1;0.4334817,0.4622641,0.4622641,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;285;1628.203,1521.236;Inherit;False;415;ReflectionColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;385;4249.877,4901.063;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;358;452.1469,5394.376;Inherit;False;Property;_ShoreEdgeWidth;Shore Edge Width 岸边过渡;26;0;Create;False;0;0;0;False;0;False;0;0.096;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;214;1651.426,1286.772;Inherit;False;212;WaveColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;359;762.147,5396.376;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;300;1898.091,1479.557;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;399;4423.121,5138.016;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;345;518.4031,5286.832;Inherit;False;WaterShore;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;352;551.3218,5516.271;Inherit;False;ShoreColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;250;1708.339,1729.917;Inherit;False;246;WaterOpacity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;298;1694.742,1635.449;Inherit;False;295;UnderWaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;299;2029.193,1561.274;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;395;4614.664,5096.506;Inherit;False;FoemColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;355;2016.616,1829.593;Inherit;False;345;WaterShore;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;362;894.147,5480.376;Inherit;False;Property;_ShoreEdgeIntensity;Shore Edge Intensity 岸边强度;27;0;Create;False;0;0;0;False;0;False;0;0.164;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;322;1997.502,1731.294;Inherit;False;352;ShoreColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;357;973.147,5305.376;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;354;2273.616,1584.592;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;360;1190.147,5379.376;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;397;2228.09,1867.565;Inherit;False;395;FoemColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;401;2471.392,1738.48;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;363;1428.147,5330.376;Inherit;False;ShoreEdge;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;400;2475.85,1868.585;Inherit;False;FLOAT;3;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;402;2682.392,1714.48;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;365;2681.728,1880.52;Inherit;False;363;ShoreEdge;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;364;2911.071,1731.714;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;367;3090.915,1742.073;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;453;3265.305,1732.586;Inherit;False;FinalColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;417;2435.935,2396.698;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;440;2479.423,2606.033;Inherit;False;Property;_BloomFactor;BloomFactor;35;0;Create;True;0;0;0;False;0;False;0.011;0.001;0.001;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;441;2813.423,2505.033;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;459;3274.721,1960.541;Inherit;False;453;FinalColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;458;3256.721,2364.541;Inherit;False;395;FoemColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;455;3010.692,2123.228;Inherit;False;295;UnderWaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;456;3040.692,2020.227;Inherit;False;244;WaterColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;454;3054.692,2225.228;Inherit;False;415;ReflectionColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;457;3060.819,2304.703;Inherit;False;352;ShoreColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;452;3511.006,2118.04;Inherit;False;Property;_DebugChannel;DebugChannel;36;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;6;Default;WaterColor;UnderWaterColor;ReflectionColor;ShoreColor;FoemColor;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;195;3065.608,2552.709;Inherit;False;194;WaveVertexPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;461;3520.772,2315.433;Inherit;False;226;WaterDepth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;423;1108.313,5964.57;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RegisterLocalVarNode;450;802.251,2546.501;Inherit;False;SSPR;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;201;3071.513,2634.766;Inherit;False;200;WaveVertexNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;424;1307.313,5964.57;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;200;1270.991,6438.915;Inherit;False;WaveVertexNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;442;3104.423,2416.032;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;460;3576.881,2462.674;Inherit;False;450;SSPR;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;194;1514.824,5966.914;Inherit;False;WaveVertexPos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;197;621.9908,6409.914;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;198;820.9908,6443.915;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;199;993.991,6435.914;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;192;774.3447,5954.836;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;412;-53.00481,3144.863;Inherit;False;Property;_ReflectSmoothness;Reflect Smoothness 反射平滑度;12;0;Create;False;0;0;0;False;0;False;0.95;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;422;3321.171,1701.601;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;419;3890.512,2320.84;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;Scene_Water_Planar;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=AlphaTest=Queue=500;True;0;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=MobileSSPR;False;3;Include;;False;;Native;Include;../MobileSSPRInclude.hlsl;False;;Custom;Pragma;multi_compile _ _MobileSSPR;False;;Custom;Standard;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;0;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;False;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;418;3321.171,1701.601;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;421;3321.171,1701.601;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;420;3321.171,1701.601;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;218;0;216;0
WireConnection;254;0;252;0
WireConnection;220;0;218;0
WireConnection;261;0;262;0
WireConnection;286;0;254;0
WireConnection;286;1;287;0
WireConnection;255;0;286;0
WireConnection;255;1;256;0
WireConnection;259;0;258;0
WireConnection;259;1;261;0
WireConnection;223;0;220;0
WireConnection;221;0;219;2
WireConnection;221;1;223;0
WireConnection;266;0;255;0
WireConnection;266;1;267;0
WireConnection;268;0;259;0
WireConnection;268;1;269;0
WireConnection;307;0;306;0
WireConnection;270;0;266;0
WireConnection;270;1;268;0
WireConnection;257;0;255;0
WireConnection;257;1;259;0
WireConnection;226;0;221;0
WireConnection;263;1;257;0
WireConnection;308;0;307;0
WireConnection;308;1;309;0
WireConnection;265;1;270;0
WireConnection;369;0;368;0
WireConnection;369;1;370;0
WireConnection;311;0;313;0
WireConnection;311;1;314;0
WireConnection;311;2;315;0
WireConnection;333;0;308;0
WireConnection;271;0;263;0
WireConnection;271;1;265;0
WireConnection;188;0;189;0
WireConnection;188;3;190;0
WireConnection;325;0;323;0
WireConnection;316;0;308;0
WireConnection;316;1;311;0
WireConnection;264;0;271;0
WireConnection;372;0;369;0
WireConnection;334;0;333;0
WireConnection;334;1;311;0
WireConnection;233;0;231;0
WireConnection;196;0;189;0
WireConnection;196;1;188;2
WireConnection;196;2;188;3
WireConnection;196;3;202;0
WireConnection;234;0;233;0
WireConnection;234;1;235;0
WireConnection;373;0;372;0
WireConnection;203;0;189;0
WireConnection;203;1;196;2
WireConnection;203;2;196;3
WireConnection;203;3;204;0
WireConnection;327;0;325;0
WireConnection;327;1;326;0
WireConnection;331;1;334;0
WireConnection;403;0;375;0
WireConnection;317;1;316;0
WireConnection;292;0;290;0
WireConnection;292;1;291;0
WireConnection;292;2;294;0
WireConnection;335;0;317;0
WireConnection;335;1;331;0
WireConnection;191;0;189;0
WireConnection;191;1;188;0
WireConnection;191;2;196;0
WireConnection;191;3;203;0
WireConnection;236;0;234;0
WireConnection;328;0;327;0
WireConnection;376;0;374;0
WireConnection;376;1;403;0
WireConnection;382;0;373;0
WireConnection;382;1;377;0
WireConnection;237;0;236;0
WireConnection;206;0;191;0
WireConnection;206;1;207;0
WireConnection;431;0;410;0
WireConnection;431;1;430;0
WireConnection;293;0;289;0
WireConnection;293;1;292;0
WireConnection;319;0;335;0
WireConnection;319;1;318;0
WireConnection;329;0;328;0
WireConnection;389;0;387;0
WireConnection;389;1;388;0
WireConnection;383;0;382;0
WireConnection;383;1;376;0
WireConnection;432;0;411;0
WireConnection;433;0;432;0
WireConnection;433;1;431;0
WireConnection;288;0;293;0
WireConnection;230;0;228;0
WireConnection;230;1;229;0
WireConnection;230;2;237;0
WireConnection;208;0;206;0
WireConnection;242;3;243;0
WireConnection;408;2;407;0
WireConnection;408;3;406;0
WireConnection;386;0;389;0
WireConnection;330;0;319;0
WireConnection;330;1;329;0
WireConnection;384;0;383;0
WireConnection;356;0;330;0
WireConnection;381;1;372;0
WireConnection;209;0;208;0
WireConnection;340;0;339;0
WireConnection;337;0;288;0
WireConnection;239;0;230;0
WireConnection;239;1;241;0
WireConnection;239;2;242;0
WireConnection;390;0;384;0
WireConnection;390;1;386;0
WireConnection;413;0;408;0
WireConnection;451;30;433;0
WireConnection;451;33;445;0
WireConnection;451;36;446;0
WireConnection;437;0;451;0
WireConnection;437;1;413;0
WireConnection;391;0;390;0
WireConnection;391;1;392;0
WireConnection;342;0;340;0
WireConnection;342;1;341;0
WireConnection;248;0;239;0
WireConnection;210;0;209;0
WireConnection;210;1;211;0
WireConnection;378;0;381;0
WireConnection;378;1;380;0
WireConnection;393;0;373;0
WireConnection;393;1;391;0
WireConnection;338;0;337;0
WireConnection;338;1;336;0
WireConnection;244;0;239;0
WireConnection;415;0;437;0
WireConnection;249;0;248;0
WireConnection;212;0;210;0
WireConnection;351;0;347;0
WireConnection;351;1;350;0
WireConnection;343;0;342;0
WireConnection;379;0;378;0
WireConnection;353;0;351;0
WireConnection;295;0;338;0
WireConnection;246;0;249;0
WireConnection;344;0;343;0
WireConnection;385;0;379;0
WireConnection;385;1;393;0
WireConnection;359;0;358;0
WireConnection;300;0;214;0
WireConnection;300;1;245;0
WireConnection;300;2;285;0
WireConnection;399;0;385;0
WireConnection;399;1;398;0
WireConnection;345;0;344;0
WireConnection;352;0;353;0
WireConnection;299;0;300;0
WireConnection;299;1;298;0
WireConnection;299;2;250;0
WireConnection;395;0;399;0
WireConnection;357;0;345;0
WireConnection;357;1;359;0
WireConnection;354;0;299;0
WireConnection;354;1;322;0
WireConnection;354;2;355;0
WireConnection;360;0;357;0
WireConnection;360;1;362;0
WireConnection;401;0;354;0
WireConnection;401;1;397;0
WireConnection;363;0;360;0
WireConnection;400;0;397;0
WireConnection;402;0;354;0
WireConnection;402;1;401;0
WireConnection;402;2;400;0
WireConnection;364;0;402;0
WireConnection;364;1;365;0
WireConnection;367;0;364;0
WireConnection;453;0;367;0
WireConnection;441;0;417;4
WireConnection;441;1;440;0
WireConnection;452;1;459;0
WireConnection;452;0;456;0
WireConnection;452;2;455;0
WireConnection;452;3;454;0
WireConnection;452;4;457;0
WireConnection;452;5;458;0
WireConnection;423;0;192;0
WireConnection;450;0;451;0
WireConnection;424;1;423;1
WireConnection;200;0;199;0
WireConnection;442;0;441;0
WireConnection;194;0;424;0
WireConnection;197;0;203;3
WireConnection;197;1;203;2
WireConnection;198;0;197;0
WireConnection;199;0;198;0
WireConnection;192;0;191;0
WireConnection;419;2;452;0
WireConnection;419;3;442;0
ASEEND*/
//CHKSM=0E1F653CAEDF07A8B8828B8CCEC09B479AE6529D