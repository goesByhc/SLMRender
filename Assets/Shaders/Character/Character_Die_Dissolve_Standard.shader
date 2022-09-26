// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Character_Die_Dissolve_Standard"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_BrightMap("Bright Map 明部贴图", 2D) = "white" {}
		_DarkMap("Dark Map 暗部贴图", 2D) = "white" {}
		_Saturation("Saturation 饱和度", Range( 0 , 5)) = 1
		[Gamma]_LightMap("Light Map 光照贴图", 2D) = "gray" {}
		_CustomShadowWeight("Custom Shadow Weight 贴图阴影权重", Range( 0 , 2)) = 1
		_LambertGradient("Lambert Gradient 光照阴影过渡", Range( 0 , 1)) = 1
		_AOIntensity("AO Intensity AO强度", Range( -1 , 1)) = 0
		_TintColor("Tint Color 整体颜色", Color) = (1,1,1,0)
		[Space(10)][Header(Shadow)][Space(10)]_ShadowColor("Shadow Color 阴影颜色", Color) = (0.5849056,0.5849056,0.5849056,0)
		_ShadowThreshold("Shadow Threshold 阴影阈值", Range( 0 , 1)) = 0.001
		_DarkColor("Dark Color 暗部颜色", Color) = (0.5849056,0.5849056,0.5849056,0)
		_DarkThreshold("Dark Threshold 暗部阈值", Range( -0.1 , 1)) = 0.001
		_DarkSmoothStep("Dark Smooth Step 暗部阴影过渡", Range( 0 , 1)) = 0.5
		[Space(10)][Header(Specular)][Space(10)]_SpecTintColor("SpecTintColor 高光颜色", Color) = (1,1,1,0)
		_SpecIntensity("Spec Intensity 高光强度", Range( 0 , 100)) = 30
		_SpecSize("Spec Size 高光范围大小", Range( 0 , 100)) = 30
		_SpecSizeScale("Spec Size Weight 贴图高光权重", Range( 0 , 0.5)) = 0.1
		_SpecGradient("Spec Gradient 高光随角度减弱", Range( 0 , 1)) = 0.1
		_SpecThreshold("Spec Threshold 高光阈值", Range( 0 , 1)) = 0
		_SpecSmoothStep("Spec Smooth Step 高光过渡", Range( 0 , 1)) = 0
		_DissolveTexture("DissolveTexture", 2D) = "white" {}
		_DissolveTiling("DissolveTiling", Range( 0 , 1000)) = 1
		_DissolveProgress("DissolveProgress", Range( -0.001 , 1)) = 0
		_StencilNo("StencilNo 程序用不要改", Float) = 1
		[KeywordEnum(Default,Diffuse,Specular,Rim)] _DebugChannel("DebugChannel 调试频道", Float) = 0
		[ASEEnd][Toggle(_ADDITIONAL_LIGHT_ON)] _ADDITIONAL_LIGHT("_ADDITIONAL_LIGHT", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}

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

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
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
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Stencil
			{
				Ref [_StencilNo]
				Comp NotEqual
				Pass Keep
				Fail Keep
				ZFail Keep
			}

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 999999

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

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_TEXTURE_COORDINATES1
			#pragma shader_feature_local _DEBUGCHANNEL_DEFAULT _DEBUGCHANNEL_DIFFUSE _DEBUGCHANNEL_SPECULAR _DEBUGCHANNEL_RIM
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile __ _ADDITIONAL_LIGHT_ON
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
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
				float4 lightmapUVOrVertexSH : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BrightMap_ST;
			float4 _TintColor;
			float4 _DarkColor;
			float4 _DarkMap_ST;
			float4 _ShadowColor;
			float4 _LightMap_ST;
			float4 _SpecTintColor;
			float _SpecIntensity;
			float _SpecGradient;
			float _SpecSize;
			float _SpecSizeScale;
			float _SpecSmoothStep;
			float _SpecThreshold;
			float _StencilNo;
			float _ShadowThreshold;
			float _DissolveProgress;
			float _AOIntensity;
			float _CustomShadowWeight;
			float _DarkSmoothStep;
			float _DarkThreshold;
			float _Saturation;
			float _LambertGradient;
			float _DissolveTiling;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _DarkMap;
			float4 _CharacterLightDirection;
			sampler2D _LightMap;
			sampler2D _BrightMap;
			float4 _CharacterLightColor;
			float _CharacterLightIntensity;
			float _SceneLightProbe;
			sampler2D _DissolveTexture;


			float3 ASEIndirectDiffuse( float2 uvStaticLightmap, float3 normalWS )
			{
			#ifdef LIGHTMAP_ON
				return SampleLightmap( uvStaticLightmap, normalWS );
			#else
				return SampleSH(normalWS);
			#endif
			}
			
			float3 AdditionalLightsHalfLambert( float3 WorldPosition, float3 WorldNormal )
			{
				float3 Color = 0;
				#ifdef _ADDITIONAL_LIGHTS
				int numLights = GetAdditionalLightsCount();
				for(int i = 0; i<numLights;i++)
				{
					Light light = GetAdditionalLight(i, WorldPosition);
					half3 AttLightColor = light.color *(light.distanceAttenuation * light.shadowAttenuation);
					Color +=(dot(light.direction, WorldNormal)*0.5+0.5 )* AttLightColor;
					
				}
				#endif
				return Color;
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				OUTPUT_LIGHTMAP_UV( v.ase_texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( ase_worldNormal, o.lightmapUVOrVertexSH.xyz );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord6 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord3.zw = v.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;
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
				float4 ase_texcoord1 : TEXCOORD1;

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
				o.ase_texcoord1 = v.ase_texcoord1;
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
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
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
				float4 TintColor124 = _TintColor;
				float2 uv_DarkMap = IN.ase_texcoord3.xy * _DarkMap_ST.xy + _DarkMap_ST.zw;
				float3 temp_output_2_0_g340 = tex2D( _DarkMap, uv_DarkMap ).rgb;
				float dotResult5_g340 = dot( float3(0.2125,0.7154,0.0721) , temp_output_2_0_g340 );
				float3 appendResult7_g340 = (float3(dotResult5_g340 , dotResult5_g340 , dotResult5_g340));
				float3 lerpResult8_g340 = lerp( appendResult7_g340 , temp_output_2_0_g340 , _Saturation);
				float3 saferPower368 = max( lerpResult8_g340 , 0.0001 );
				float3 DarkBaseColor178 = pow( saferPower368 , 2.2 );
				float4 DarkColor310 = ( _DarkColor * float4( DarkBaseColor178 , 0.0 ) );
				float4 ShadowColor125 = ( _ShadowColor * float4( DarkBaseColor178 , 0.0 ) );
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 normalizedWorldNormal = normalize( ase_worldNormal );
				float3 WorldNormalData200 = normalizedWorldNormal;
				float3 CharacterLightDirection692 = (_CharacterLightDirection).xyz;
				float dotResult51 = dot( WorldNormalData200 , CharacterLightDirection692 );
				float NDotL52 = dotResult51;
				float HalfLambert55 = ( ( NDotL52 + 1.0 ) * 0.5 );
				float2 uv_LightMap = IN.ase_texcoord3.xy * _LightMap_ST.xy + _LightMap_ST.zw;
				float4 tex2DNode3 = tex2D( _LightMap, uv_LightMap );
				float DiffuseControl35 = tex2DNode3.r;
				float LambertTerm196 = saturate( ( HalfLambert55 + ( ( ( DiffuseControl35 * 2.0 ) - 1.0 ) * _CustomShadowWeight ) ) );
				float temp_output_3_0_g342 = ( DiffuseControl35 - 0.1 );
				float ForceShadowRange519 = saturate( ( temp_output_3_0_g342 / fwidth( temp_output_3_0_g342 ) ) );
				float AO209 = saturate( ( tex2DNode3.a + _AOIntensity ) );
				float FinalShadowValue533 = ( min( LambertTerm196 , ForceShadowRange519 ) * AO209 );
				float smoothstepResult554 = smoothstep( ( _DarkThreshold - _DarkSmoothStep ) , ( _DarkThreshold + _DarkSmoothStep ) , FinalShadowValue533);
				float4 lerpResult307 = lerp( DarkColor310 , ShadowColor125 , saturate( smoothstepResult554 ));
				float2 uv_BrightMap = IN.ase_texcoord3.xy * _BrightMap_ST.xy + _BrightMap_ST.zw;
				float4 tex2DNode1 = tex2D( _BrightMap, uv_BrightMap );
				float3 temp_output_2_0_g337 = tex2DNode1.rgb;
				float dotResult5_g337 = dot( float3(0.2125,0.7154,0.0721) , temp_output_2_0_g337 );
				float3 appendResult7_g337 = (float3(dotResult5_g337 , dotResult5_g337 , dotResult5_g337));
				float3 lerpResult8_g337 = lerp( appendResult7_g337 , temp_output_2_0_g337 , _Saturation);
				float3 saferPower367 = max( lerpResult8_g337 , 0.0001 );
				float3 BaseColor24 = pow( saferPower367 , 2.2 );
				float temp_output_3_0_g343 = ( FinalShadowValue533 - _ShadowThreshold );
				float ShadowRange267 = saturate( saturate( ( temp_output_3_0_g343 / fwidth( temp_output_3_0_g343 ) ) ) );
				float4 lerpResult122 = lerp( lerpResult307 , float4( BaseColor24 , 0.0 ) , ShadowRange267);
				float LambertGradient319 = saturate( (_LambertGradient + (HalfLambert55 - 0.0) * (1.0 - _LambertGradient) / (1.0 - 0.0)) );
				float4 DiffuseColor132 = ( TintColor124 * lerpResult122 * LambertGradient319 );
				float SpecSize4 = tex2DNode3.g;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult172 = normalize( ( CharacterLightDirection692 + ase_worldViewDir ) );
				float dotResult173 = dot( normalizeResult172 , WorldNormalData200 );
				float NDotH101 = max( dotResult173 , 0.0 );
				float saferPower88 = max( NDotH101 , 0.0001 );
				float dotResult38 = dot( WorldNormalData200 , ase_worldViewDir );
				float NDotV39 = ( ( dotResult38 + 1.0 ) * 0.5 );
				float smoothstepResult108 = smoothstep( ( _SpecThreshold - _SpecSmoothStep ) , ( _SpecThreshold + _SpecSmoothStep ) , ( ( ( _SpecSizeScale * SpecSize4 ) + ( SpecSize4 * pow( saferPower88 , ( 50.0 / _SpecSize ) ) ) ) - ( sqrt( max( ( HalfLambert55 / NDotV39 ) , 0.0 ) ) * _SpecGradient ) ));
				float SpecIntensity294 = tex2DNode3.b;
				float4 SpecColor97 = ( ( float4( BaseColor24 , 0.0 ) * ( _SpecTintColor * ( smoothstepResult108 * _SpecIntensity * ShadowRange267 * SpecIntensity294 ) ) ) * AO209 );
				#if defined(_DEBUGCHANNEL_DEFAULT)
				float4 staticSwitch417 = ( DiffuseColor132 + SpecColor97 );
				#elif defined(_DEBUGCHANNEL_DIFFUSE)
				float4 staticSwitch417 = DiffuseColor132;
				#elif defined(_DEBUGCHANNEL_SPECULAR)
				float4 staticSwitch417 = SpecColor97;
				#elif defined(_DEBUGCHANNEL_RIM)
				float4 staticSwitch417 = float4( 0,0,0,0 );
				#else
				float4 staticSwitch417 = ( DiffuseColor132 + SpecColor97 );
				#endif
				float4 saferPower485 = max( staticSwitch417 , 0.0001 );
				float2 uv2_DarkMap = IN.ase_texcoord3.zw * _DarkMap_ST.xy + _DarkMap_ST.zw;
				float InnerLine536 = ( tex2DNode1.a * tex2D( _DarkMap, uv2_DarkMap ).a );
				float4 color588 = IsGammaSpace() ? float4(0,0,0,0) : float4(0,0,0,0);
				float3 bakedGI387 = ASEIndirectDiffuse( IN.lightmapUVOrVertexSH.xy, WorldNormalData200);
				float3 lerpResult663 = lerp( (color588).rgb , bakedGI387 , _SceneLightProbe);
				float3 WorldPosition22_g339 = WorldPosition;
				float3 WorldNormal22_g339 = WorldNormalData200;
				float3 localAdditionalLightsHalfLambert22_g339 = AdditionalLightsHalfLambert( WorldPosition22_g339 , WorldNormal22_g339 );
				#ifdef _ADDITIONAL_LIGHT_ON
				float3 staticSwitch701 = localAdditionalLightsHalfLambert22_g339;
				#else
				float3 staticSwitch701 = float3(0,0,0);
				#endif
				float3 LightColor389 = ( (( _CharacterLightColor * _CharacterLightIntensity )).rgb + lerpResult663 + staticSwitch701 );
				
				float4 screenPos = IN.ase_texcoord6;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 appendResult678 = (float2(( ( _ScreenParams.x / _ScreenParams.y ) * ase_screenPosNorm.x ) , ase_screenPosNorm.y));
				float DissolveAlpha684 = step( _DissolveProgress , tex2D( _DissolveTexture, frac( ( appendResult678 * _DissolveTiling ) ) ).r );
				
				float DissolveClip688 = 0.5;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( pow( saferPower485 , 0.4545454 ) * InnerLine536 * float4( LightColor389 , 0.0 ) ).rgb;
				float Alpha = DissolveAlpha684;
				float AlphaClipThreshold = DissolveClip688;
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

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BrightMap_ST;
			float4 _TintColor;
			float4 _DarkColor;
			float4 _DarkMap_ST;
			float4 _ShadowColor;
			float4 _LightMap_ST;
			float4 _SpecTintColor;
			float _SpecIntensity;
			float _SpecGradient;
			float _SpecSize;
			float _SpecSizeScale;
			float _SpecSmoothStep;
			float _SpecThreshold;
			float _StencilNo;
			float _ShadowThreshold;
			float _DissolveProgress;
			float _AOIntensity;
			float _CustomShadowWeight;
			float _DarkSmoothStep;
			float _DarkThreshold;
			float _Saturation;
			float _LambertGradient;
			float _DissolveTiling;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _DissolveTexture;


			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;

				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
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

			half4 frag(VertexOutput IN  ) : SV_TARGET
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

				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 appendResult678 = (float2(( ( _ScreenParams.x / _ScreenParams.y ) * ase_screenPosNorm.x ) , ase_screenPosNorm.y));
				float DissolveAlpha684 = step( _DissolveProgress , tex2D( _DissolveTexture, frac( ( appendResult678 * _DissolveTiling ) ) ).r );
				
				float DissolveClip688 = 0.5;
				
				float Alpha = DissolveAlpha684;
				float AlphaClipThreshold = DissolveClip688;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BrightMap_ST;
			float4 _TintColor;
			float4 _DarkColor;
			float4 _DarkMap_ST;
			float4 _ShadowColor;
			float4 _LightMap_ST;
			float4 _SpecTintColor;
			float _SpecIntensity;
			float _SpecGradient;
			float _SpecSize;
			float _SpecSizeScale;
			float _SpecSmoothStep;
			float _SpecThreshold;
			float _StencilNo;
			float _ShadowThreshold;
			float _DissolveProgress;
			float _AOIntensity;
			float _CustomShadowWeight;
			float _DarkSmoothStep;
			float _DarkThreshold;
			float _Saturation;
			float _LambertGradient;
			float _DissolveTiling;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _DissolveTexture;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
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

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
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

				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 appendResult678 = (float2(( ( _ScreenParams.x / _ScreenParams.y ) * ase_screenPosNorm.x ) , ase_screenPosNorm.y));
				float DissolveAlpha684 = step( _DissolveProgress , tex2D( _DissolveTexture, frac( ( appendResult678 * _DissolveTiling ) ) ).r );
				
				float DissolveClip688 = 0.5;
				
				float Alpha = DissolveAlpha684;
				float AlphaClipThreshold = DissolveClip688;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18900
216.8;166.4;1865.6;819;7097.717;2252.461;1.195941;True;True
Node;AmplifyShaderEditor.CommentaryNode;672;2531.881,3243.258;Inherit;False;2838.764;722.043;Comment;14;684;683;682;681;680;679;678;677;676;675;674;673;687;688;Dissolve;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenParams;673;2626.353,3396.501;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;675;3010.741,3422.691;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;674;2754.109,3614.137;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;676;3108.52,3589.971;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;677;3400.25,3769.866;Inherit;False;Property;_DissolveTiling;DissolveTiling;32;0;Create;False;0;0;0;False;0;False;1;1;0;1000;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;678;3377.252,3635.786;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;679;3650.569,3591.419;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FractNode;680;3883.64,3606.021;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;682;4161.214,3548.95;Inherit;True;Property;_DissolveTexture;DissolveTexture;31;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;681;4092.353,3452.767;Inherit;False;Property;_DissolveProgress;DissolveProgress;33;0;Create;True;0;0;0;False;0;False;0;0;-0.001;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;687;4557.054,3761.775;Inherit;False;Constant;_DissolveClip;DissolveClip;36;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;683;4591.472,3531.884;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;691;-7989.211,875.3192;Inherit;False;926.7637;259;Comment;1;692;CharacterLightDirection;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;605;-1451.601,4035.63;Inherit;False;1168.7;317.4543;Comment;6;611;610;609;608;635;636;Bloom;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;201;-6756.437,8.573598;Inherit;False;797.3242;233;Comment;2;199;200;WorldNormal;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;40;-6781.378,911.0248;Inherit;False;1611.816;401.735;Comment;6;39;43;42;38;36;203;N . V;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;151;-877.8394,866.0618;Inherit;False;4946.01;1455.375;保存后要在Shader的描边pass里添加，o.Alpha = 1.0f  不然角色展示会有问题;53;640;545;659;637;626;613;631;625;632;614;547;633;627;617;628;616;634;630;660;655;651;658;657;656;654;653;652;650;649;648;647;646;645;644;643;642;641;639;638;341;340;333;339;332;426;338;336;337;330;544;334;331;146;Outline;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;390;-7030.78,3751.611;Inherit;False;1821.334;695.7583;Comment;14;387;551;389;550;588;663;664;666;667;668;669;671;701;702;LightColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;205;-6692.721,-2340.6;Inherit;False;1492.666;2028.394;Comment;20;209;24;215;1;216;213;178;177;4;35;3;294;367;368;373;375;376;536;553;703;TexInfo;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;259;-4632.581,3615.819;Inherit;False;2343.961;1047.829;Comment;10;262;409;415;410;290;414;288;293;255;416;IndirectSpecular;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;168;-6774.811,422.7754;Inherit;False;1546.859;407.1945;Comment;8;174;173;172;171;170;101;202;695;N . H;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;684;4874.453,3531.803;Inherit;False;DissolveAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;48;-6803.431,1391.325;Inherit;False;1890.306;430.7943;g;7;54;55;53;52;51;204;696;N . L;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;152;-4997.41,-187.3413;Inherit;False;3564.564;1435.903;Comment;34;132;130;210;131;395;122;321;184;307;314;424;313;301;267;302;181;117;223;207;220;345;517;518;519;526;527;531;520;533;534;554;556;557;558;DiffuseColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;688;4865.054,3749.775;Inherit;False;DissolveClip;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;197;-6815.707,1969.907;Inherit;False;1712.93;724.5529;Comment;9;140;298;299;300;196;194;191;364;365;LambertTerm;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;206;-4476.373,-1249.115;Inherit;False;928.8521;902.5425;Comment;10;310;309;183;125;182;121;124;123;308;311;Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;516;-1363.434,2551.959;Inherit;False;3096.65;1054.393;Comment;30;483;481;486;482;478;484;480;498;491;460;493;459;465;458;469;466;467;487;589;528;591;593;594;595;597;598;599;601;603;697;RimColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;320;-6764.984,2779.838;Inherit;False;1109.84;443.083;Comment;5;315;319;317;316;323;LambertGradient;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;85;-4710.137,1491.047;Inherit;False;3103.409;979.4595;Comment;31;93;92;96;90;109;108;97;95;99;110;105;102;106;88;107;103;98;87;86;211;228;229;263;264;265;295;326;327;328;329;394;SpecColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.PowerNode;368;-5768.285,-1878.212;Inherit;False;True;2;0;FLOAT3;0,0,0;False;1;FLOAT;2.2;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;267;-2922.773,291.0253;Inherit;False;ShadowRange;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;263;-3895.492,1822.928;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;3;-6577.428,-1482.054;Inherit;True;Property;_LightMap;Light Map 光照贴图;3;1;[Gamma];Create;False;0;0;0;False;0;False;-1;None;26c0491208f21f24987a27f692060169;True;0;False;gray;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;534;-3873.173,444.3367;Inherit;False;533;FinalShadowValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;301;-4347.424,668.6057;Inherit;False;533;FinalShadowValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;636;-1378.425,4211.824;Inherit;False;Global;_CharacterBloomAdd;_CharacterBloomAdd;33;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;610;-1394.601,4101.627;Inherit;False;Property;_BloomFactor;BloomFactor;30;0;Create;True;0;0;0;False;3;Space(10);Header(Bloom);Space(10);False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SqrtOpNode;329;-4073.505,2221.021;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;203;-6577.542,1002.29;Inherit;False;200;WorldNormalData;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;196;-5314.947,2161.831;Inherit;False;LambertTerm;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;36;-6407.378,1121.025;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;319;-5981.144,2864.921;Inherit;False;LambertGradient;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;611;-967.5581,4131.627;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;609;-506.9007,4085.63;Inherit;False;FinalBloom;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;52;-5894.532,1534.096;Inherit;False;NDotL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;204;-6608.917,1473.876;Inherit;False;200;WorldNormalData;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;604;-199.689,2798.685;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;518;-4686.563,-25.41945;Inherit;False;Step Antialiasing;-1;;342;2a825e80dfb3290468194f83380797bd;0;2;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;387;-6686.581,4133.436;Inherit;False;World;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;107;-4207.582,2358.506;Inherit;False;Property;_SpecGradient;Spec Gradient 高光随角度减弱;17;0;Create;False;0;0;0;False;0;False;0.1;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;200;-6195.112,80.09708;Inherit;False;WorldNormalData;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;480;464.8104,3233.075;Inherit;False;267;ShadowRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;264;-4386.891,1728.807;Inherit;False;Property;_SpecSizeScale;Spec Size Weight 贴图高光权重;16;0;Create;False;0;0;0;False;0;False;0.1;0.2;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-3017.48,1939.445;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;595;-845.266,3297.029;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;593;-1236.544,3391.667;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;608;-751.8214,4120.524;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.999;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;294;-6014.159,-1252.369;Inherit;False;SpecIntensity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;528;817.0369,2726.52;Inherit;False;Step Antialiasing;-1;;341;2a825e80dfb3290468194f83380797bd;0;2;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;216;-6063.314,-1146.532;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;51;-6120.656,1517.777;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;394;-2591.166,1863.452;Inherit;False;389;LightColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;493;-740.2735,2890.492;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;300;-6257.304,2546.42;Inherit;False;Property;_CustomShadowWeight;Custom Shadow Weight 贴图阴影权重;4;0;Create;False;1;Shadow;0;0;False;0;False;1;1;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;544;1712.106,1314.468;Inherit;False;OutlineColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NegateNode;487;664.8343,2820.361;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;255;-4473.171,4073.079;Inherit;False;-1;;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-3875.58,340.8919;Inherit;False;Property;_ShadowThreshold;Shadow Threshold 阴影阈值;9;0;Create;False;0;0;0;False;0;False;0.001;0.14;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;635;-1107.425,4163.824;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;170;-6691.002,629.2872;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;602;203.0524,2984.335;Inherit;False;594;RimOffsetLength;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-6544.248,-2256.428;Inherit;True;Property;_BrightMap;Bright Map 明部贴图;0;0;Create;False;0;0;0;False;0;False;-1;None;cb2376b2fa234584ba1920a1bd3cfe91;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;103;-4355.553,1830.511;Inherit;False;4;SpecSize;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;309;-4054.231,-633.3371;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;641;2954.794,1653.63;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;486;873.5867,3490.352;Inherit;False;24;BaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;556;-4424.73,984.0693;Inherit;False;Property;_DarkSmoothStep;Dark Smooth Step 暗部阴影过渡;12;0;Create;False;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;265;-4078.891,1778.807;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;545;3664.768,1700.816;Inherit;False;OutlineOffset;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StepOpNode;337;506.9384,1016.847;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;55;-5256.716,1542.473;Inherit;False;HalfLambert;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;87;-4414.478,2101.487;Inherit;False;2;0;FLOAT;50;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;330;-809.3398,1109.387;Inherit;False;24;BaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;416;-3662.634,4440.638;Inherit;False;294;SpecIntensity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;308;-4426.154,-662.5461;Inherit;False;Property;_DarkColor;Dark Color 暗部颜色;10;0;Create;False;0;0;0;False;0;False;0.5849056,0.5849056,0.5849056,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;594;-495.0701,3432.461;Inherit;False;RimOffsetLength;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;125;-3801.712,-974.6003;Inherit;False;ShadowColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;338;687.999,1065.224;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;331;-469.9798,1028.733;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;299;-5905.135,2304.797;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;182;-4054.45,-969.706;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;365;-6178.832,2334.34;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;121;-4426.373,-998.915;Inherit;False;Property;_ShadowColor;Shadow Color 阴影颜色;8;0;Create;False;1;Shadow;0;0;False;3;Space(10);Header(Shadow);Space(10);False;0.5849056,0.5849056,0.5849056,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;645;2027.067,1739.571;Inherit;False;Property;_OutlineWidth;Outline Width 描边宽度;25;0;Create;False;0;0;0;False;0;False;0;5.14;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;262;-3014.759,4095.204;Inherit;False;IndirectSpecular;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;465;-2.725872,2852.606;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;588;-6987.151,4032.418;Inherit;False;Constant;_Color0;Color 0;35;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;110;-3852.364,2341.003;Inherit;False;Property;_SpecSmoothStep;Spec Smooth Step 高光过渡;19;0;Create;False;0;0;0;False;0;False;0;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;589;-660.3878,3420.097;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;417;-749.4456,7.449249;Inherit;False;Property;_DebugChannel;DebugChannel 调试频道;35;0;Create;False;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;4;Default;Diffuse;Specular;Rim;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;483;665.7534,2975.513;Float;False;Property;_RimColor;Rim Color 边缘光颜色;20;0;Create;False;0;0;0;False;3;Space(10);Header(Rim);Space(10);False;0,1,0.8758622,0;0.9528301,0.8000113,0.03146139,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;146;846.6235,1317.821;Inherit;False;Property;_OutlineColor;Outline Color 描边颜色;24;0;Create;False;0;0;0;False;3;Space(10);Header(Outline);Space(10);False;0,0,0,0;0.5377356,0.494108,0.494108,0.4980391;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;667;-6745.981,4035.45;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;484;1469.215,2758.352;Inherit;False;RimColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;662;-30.10315,-74.54114;Inherit;False;389;LightColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;692;-7339.247,925.9124;Inherit;False;CharacterLightDirection;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;482;710.4302,3425.127;Inherit;False;389;LightColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;311;-4381.828,-466.2372;Inherit;False;178;DarkBaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;598;-830.266,3075.029;Inherit;False;594;RimOffsetLength;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;215;-5895.892,-1146.362;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;302;-4404.271,838.0471;Inherit;False;Property;_DarkThreshold;Dark Threshold 暗部阈值;11;0;Create;False;0;0;0;False;0;False;0.001;-0.1;-0.1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;664;-6547.59,4217.434;Inherit;False;Global;_SceneLightProbe;_SceneLightProbe;33;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;414;-3644.606,4363.092;Inherit;False;4;SpecSize;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;467;516.047,2664.182;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;537;-183.7874,74.4062;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;517;-3502.426,425.8647;Inherit;False;Step Antialiasing;-1;;343;2a825e80dfb3290468194f83380797bd;0;2;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;298;-5515.163,2181.236;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;130;-2130.963,216.233;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;485;-441.7791,32.99942;Inherit;False;True;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.4545454;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;86;-4690.912,2150.281;Inherit;False;Property;_SpecSize;Spec Size 高光范围大小;15;0;Create;False;0;0;0;False;0;False;30;1;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;670;-6605.473,3849.175;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;530;-3626.659,30.86198;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-908.5545,-118.559;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;194;-5694.546,2190.131;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;174;-5760.609,588.1214;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;689;-58.25208,482.8803;Inherit;False;688;DissolveClip;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;701;-6020.99,4220.707;Inherit;False;Property;_ADDITIONAL_LIGHT;_ADDITIONAL_LIGHT;36;0;Create;True;0;0;0;True;0;False;1;0;1;True;;Toggle;2;Key0;Key1;Create;False;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;538;-553.7874,181.4062;Inherit;False;536;InnerLine;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;4;-6011.428,-1381.054;Inherit;False;SpecSize;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;88;-4266.67,1978.962;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;24;-5516.96,-2167.214;Inherit;False;BaseColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;213;-6390.336,-1060.473;Inherit;False;Property;_AOIntensity;AO Intensity AO强度;6;0;Create;False;0;0;0;False;0;False;0;1;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;42;-5886.658,1045.898;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;375;-6398.206,-2046.307;Inherit;False;Property;_Saturation;Saturation 饱和度;2;0;Create;False;0;0;0;False;0;False;1;1;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;638;2526.413,1636.806;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;315;-6713.984,2845.838;Inherit;False;55;HalfLambert;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;644;2049.457,1851.688;Inherit;False;Constant;_OutlineMulti;Outline Multi;15;0;Create;True;0;0;0;False;0;False;0.001;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;223;-3827.771,-15.40732;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;229;-3369.584,2211.087;Inherit;False;267;ShadowRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;131;-2468.285,106.7487;Inherit;False;124;TintColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;102;-4068.245,1937.54;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;671;-6843.473,3958.175;Inherit;False;Global;_CharacterLightIntensity;_CharacterLightIntensity;33;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;328;-4235.505,2228.021;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;202;-6249.942,656.6541;Inherit;False;200;WorldNormalData;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;123;-4426.068,-1199.115;Inherit;False;Property;_TintColor;Tint Color 整体颜色;7;0;Create;False;0;0;0;False;0;False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;307;-3118.559,629.5845;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;184;-2899.281,175.6067;Inherit;False;24;BaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;656;1571.242,2065.643;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;702;-6243.305,4152.386;Inherit;False;Constant;_Vector2;Vector 2;37;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;290;-3800,4065.321;Inherit;True;Property;_EnvMap;EnvMap 环境贴图;27;0;Create;False;0;0;0;False;3;Space(10);Header(Env);Space(10);False;-1;None;f4834423fa23b2b4c817a1b4e58be066;True;0;False;white;LockedToCube;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;603;-191.689,2680.685;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;27;-1248.973,-2.211781;Inherit;False;97;SpecColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;459;-803.7074,2590.308;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;415;-3641.629,4520.235;Inherit;False;24;BaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;424;-3483.878,776.7406;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;554;-3813.73,852.0693;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;699;-7946.706,956.2625;Inherit;False;Global;_CharacterLightDirection;_CharacterLightDirection;33;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.4059417,0.6427875,-0.6496426,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-3875.582,2122.506;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;183;-4382.047,-802.6061;Inherit;False;178;DarkBaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-6048.578,-1491.957;Inherit;False;DiffuseControl;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;317;-6197.144,2866.921;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;536;-5776.352,-2047.277;Inherit;False;InnerLine;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;53;-5651.315,1539.59;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;650;1314.167,2195.131;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;478;1247.946,2798.577;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;199;-6465.404,81.17452;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;431;-3548.69,2108.206;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;132;-1841.449,192.6859;Inherit;False;DiffuseColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;527;-4085.398,-22.66081;Inherit;False;ForceShadowMulti;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;599;-518.266,2991.029;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;642;923.78,2051.568;Inherit;False;Property;_OutlineBias;Outline Bias 描边偏移;26;0;Create;False;0;0;0;False;0;False;10;10;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;651;1891.244,1578.822;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;323;-6420.21,2885.007;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;560;111.5717,313.6279;Inherit;False;484;RimColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;108;-3398.385,1944.892;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;466;188.385,2716.299;Inherit;False;1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;409;-3291.407,4092.346;Inherit;False;5;5;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;316;-6733.144,2967.921;Inherit;False;Property;_LambertGradient;Lambert Gradient 光照阴影过渡;5;0;Create;False;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;385;294.217,649.1799;Inherit;False;Property;_StencilNo;StencilNo 程序用不要改;34;0;Create;False;0;0;0;True;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;332;-292.9798,931.7334;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;333;-98.97981,967.7333;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-2791.245,1703.472;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldToCameraMatrix;498;-1237.82,2817.735;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.DynamicAppendNode;634;-516.0611,1703.762;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;632;-521.0611,1450.762;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;173;-5955.787,580.0799;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ShadeVertexLightsHlpNode;563;-843.0562,552.1145;Inherit;False;4;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;526;-4231,-18.7608;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;341;1054.064,1086.146;Inherit;False;Constant;_Float3;Float 3;34;0;Create;True;0;0;0;False;0;False;0.8;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;99;-2893.413,1536.317;Inherit;False;24;BaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;171;-6409.301,573.2872;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScreenDepthNode;458;184.1403,2601.959;Inherit;False;1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;429;-3574.69,1999.206;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-5665.482,1041.027;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;-2324.677,1659.658;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.5;False;1;COLOR;0
Node;AmplifyShaderEditor.ViewMatrixNode;643;1159.653,1797.448;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.GetLocalVarNode;327;-4614.505,2363.021;Inherit;False;39;NDotV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;630;-332.026,1976.077;Inherit;False;Constant;_Float1;Float 1;35;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;38;-6151.381,1041.025;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;293;-4083.494,4233.489;Inherit;False;Property;_Roughness;Roughness 粗糙度;28;0;Create;False;0;1;Option1;0;0;False;0;False;0;3.91;0;6;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;410;-3720.407,4270.346;Inherit;False;Property;_Explose;Explose 曝光度;29;0;Create;False;0;0;0;False;0;False;0.02;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;39;-5449.743,1047.266;Inherit;False;NDotV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;178;-5502.666,-1961.326;Inherit;False;DarkBaseColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;211;-2588.69,1748.647;Inherit;False;209;AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;649;1365.652,1858.448;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;-2574.793,1594.431;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;547;-798.5707,1677.122;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;648;2729.872,1645.497;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;98;-4648.96,1933.021;Inherit;False;101;NDotH;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;109;-3854.478,2233.903;Inherit;False;Property;_SpecThreshold;Spec Threshold 高光阈值;18;0;Create;False;0;0;0;False;0;False;0;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;336;262.9402,936.149;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;626;320.9097,1663.99;Inherit;False;2;2;0;FLOAT3x3;0,0,0,1,1,1,1,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;553;-6054.829,-2045.599;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;557;-4035.73,878.0693;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;364;-6380.231,2350.64;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;97;-1879.678,1672.346;Inherit;False;SpecColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;663;-6213.923,3971.966;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;340;1214.565,1189.769;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;411;-1238.717,204.5234;Inherit;False;262;IndirectSpecular;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;531;-4037.577,163.4403;Inherit;False;209;AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;339;872.4304,1136.702;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0.6,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;640;3424.614,1812.877;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;295;-3242.73,2322.238;Inherit;False;294;SpecIntensity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldReflectionVector;288;-4157.195,4077.257;Inherit;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ComponentMaskNode;654;1557.84,1859.131;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;209;-5672.906,-1140.959;Inherit;False;AO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;617;-391.2348,1870.746;Inherit;False;FLOAT3;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;321;-2501.109,379.1667;Inherit;False;319;LambertGradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;252;-1234.367,104.969;Inherit;False;484;RimColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;628;89.9741,1907.077;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;491;-949.2574,2879.571;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;373;-6102.175,-2161.579;Inherit;False;Saturation;-1;;337;7a2acff08cb40dd4ea5d3c76916123dd;0;2;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;659;749.4368,1896.056;Inherit;False;637;OutlineNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;652;1890.84,1902.131;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;310;-3801.493,-638.2314;Inherit;False;DarkColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;669;-6856.473,3783.175;Inherit;False;Global;_CharacterLightColor;_CharacterLightColor;33;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;325;-4677.956,2102.306;Inherit;False;55;HalfLambert;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;-3354.392,2076.446;Inherit;False;Property;_SpecIntensity;Spec Intensity 高光强度;14;0;Create;False;0;0;0;False;0;False;30;8;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;334;55.0202,966.7333;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.004;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;105;-3726.847,1938.583;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;210;-2024.711,458.341;Inherit;False;209;AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;627;-152.026,1875.077;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;2;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-5460.661,1539.183;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;376;-6101.108,-1940.154;Inherit;False;Saturation;-1;;340;7a2acff08cb40dd4ea5d3c76916123dd;0;2;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;639;2953.294,1903.329;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldToObjectTransfNode;646;3168.884,1700.998;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;460;-1201.195,3240.876;Inherit;False;Property;_RimWidth;RimWidth;22;0;Create;True;0;0;0;False;0;False;0.1;0.103;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;481;449.6954,3355.273;Inherit;False;Property;_RimIntensity;Rim Intensity 边缘光强度;23;0;Create;False;0;0;0;False;0;False;0;43;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;601;507.0524,2837.335;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;558;-4031.73,995.0693;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;-6708.996,2370.643;Inherit;False;35;DiffuseControl;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;326;-4408.505,2228.021;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.UnityObjToViewPosHlpNode;655;2195.365,1575.274;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SwizzleNode;426;1433.001,1328.381;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;469;182.412,2869.225;Inherit;False;Property;_RimThreshold;RimThreshold;21;0;Create;True;0;0;0;False;0;False;5;2;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;690;-100.2521,275.8803;Inherit;False;688;DissolveClip;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.MatrixFromVectors;625;-169.0905,1547.99;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.CustomExpressionNode;660;1036.706,1891.419;Inherit;False; return TransformObjectToWorldNormal(vertexNormal)@;3;False;1;True;vertexNormal;FLOAT3;0,0,0;In;;Inherit;False;TransformObjectToWorldNormal;True;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;657;1279.574,2076.578;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;367;-5770.249,-2152.921;Inherit;False;True;2;0;FLOAT3;0,0,0;False;1;FLOAT;2.2;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;686;-296.1049,439.9813;Inherit;False;684;DissolveAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.InverseViewMatrixNode;647;2691.832,1515.338;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.RangedFloatNode;631;-82.02597,1996.077;Inherit;False;Constant;_Float2;Float 2;35;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;177;-6545.191,-1948.833;Inherit;True;Property;_DarkMap;Dark Map 暗部贴图;1;0;Create;False;0;0;0;False;0;False;-1;None;bf934e42d2608494891a6c95876f5525;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;597;-517.266,2862.029;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;181;-3147.217,320.9396;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BitangentVertexDataNode;614;-815.2096,1531.862;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;658;2368.967,1825.771;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;591;-983.3842,3404.03;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;228;-3216.584,1573.086;Inherit;False;Property;_SpecTintColor;SpecTintColor 高光颜色;13;0;Create;False;0;0;0;False;3;Space(10);Header(Specular);Space(10);False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalizeNode;172;-6156.271,534.4064;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;637;572.9271,1655.625;Inherit;False;OutlineNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;546;-100.1213,349.5384;Inherit;False;544;OutlineColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;548;-137.9927,592.521;Inherit;False;545;OutlineOffset;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TangentVertexDataNode;613;-801.937,1380.582;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;685;-269.1049,238.9813;Inherit;False;684;DissolveAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;616;-624.3488,1878.074;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;697;-1284.025,2958.675;Inherit;False;692;CharacterLightDirection;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;345;-4960.496,-70.173;Inherit;False;Constant;_DeepShadowRange;DeepShadowRange;34;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;133;-1235.915,-114.8979;Inherit;False;132;DiffuseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;633;-516.0611,1566.762;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;698;-7637.189,966.1545;Inherit;False;True;True;True;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;696;-6608.848,1657.787;Inherit;False;692;CharacterLightDirection;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexColorNode;653;1008.219,2144.806;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;668;-6341.981,3843.45;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;124;-4102.175,-1191.813;Inherit;False;TintColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;191;-6368.428,2106.64;Inherit;False;55;HalfLambert;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;207;-4095.308,-115.2147;Inherit;False;196;LambertTerm;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;101;-5498.107,580.4492;Inherit;False;NDotH;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;520;-4091.068,65.95428;Inherit;False;519;ForceShadowRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;551;-6391.769,4301.333;Inherit;False;SRP Additional Light;-1;;339;6c86746ad131a0a408ca599df5f40861;3,6,1,9,1,23,1;5;2;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;15;FLOAT3;0,0,0;False;14;FLOAT3;1,1,1;False;18;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;666;-5774.61,3943.444;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;533;-3385.372,16.33658;Inherit;False;FinalShadowValue;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;389;-5540.718,3951.006;Inherit;False;LightColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;700;-555.2177,269.3236;Inherit;False;389;LightColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;550;-6993.561,4313.756;Inherit;False;200;WorldNormalData;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;395;-2446.34,473.3823;Inherit;False;389;LightColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;519;-4476.597,-17.57151;Inherit;False;ForceShadowRange;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;220;-4964.4,36.66344;Inherit;False;35;DiffuseControl;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;695;-6743.433,502.8137;Inherit;False;692;CharacterLightDirection;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;122;-2496.255,248.6072;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;1,1,1,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;313;-3380.892,561.1847;Inherit;False;310;DarkColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;314;-3480.125,673.6398;Inherit;False;125;ShadowColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;703;-6539.211,-1744.186;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;1;False;white;Auto;False;Instance;177;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;580;258.5524,386.3699;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;Outline1;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;True;True;1;False;-1;True;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;True;True;True;255;True;385;255;False;-1;255;False;-1;6;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Outline1;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;581;238.5524,82.3699;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;Character_Die_Dissolve_Standard;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;True;True;True;255;True;385;255;False;-1;255;False;-1;6;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;583;227.5524,135.3699;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;582;227.5524,135.3699;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;584;227.5524,135.3699;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;675;0;673;1
WireConnection;675;1;673;2
WireConnection;676;0;675;0
WireConnection;676;1;674;1
WireConnection;678;0;676;0
WireConnection;678;1;674;2
WireConnection;679;0;678;0
WireConnection;679;1;677;0
WireConnection;680;0;679;0
WireConnection;682;1;680;0
WireConnection;683;0;681;0
WireConnection;683;1;682;1
WireConnection;684;0;683;0
WireConnection;688;0;687;0
WireConnection;368;0;376;0
WireConnection;267;0;181;0
WireConnection;263;0;265;0
WireConnection;263;1;102;0
WireConnection;329;0;328;0
WireConnection;196;0;298;0
WireConnection;319;0;317;0
WireConnection;611;0;635;0
WireConnection;609;0;608;0
WireConnection;52;0;51;0
WireConnection;604;0;459;2
WireConnection;604;1;599;0
WireConnection;518;1;345;0
WireConnection;518;2;220;0
WireConnection;387;0;550;0
WireConnection;200;0;199;0
WireConnection;92;0;108;0
WireConnection;92;1;90;0
WireConnection;92;2;229;0
WireConnection;92;3;295;0
WireConnection;595;0;460;0
WireConnection;608;0;611;0
WireConnection;294;0;3;3
WireConnection;528;1;467;0
WireConnection;528;2;487;0
WireConnection;216;0;3;4
WireConnection;216;1;213;0
WireConnection;51;0;204;0
WireConnection;51;1;696;0
WireConnection;493;0;491;0
WireConnection;544;0;426;0
WireConnection;487;0;601;0
WireConnection;635;0;610;0
WireConnection;635;1;636;0
WireConnection;309;0;308;0
WireConnection;309;1;311;0
WireConnection;641;0;647;0
WireConnection;641;1;648;0
WireConnection;265;0;264;0
WireConnection;265;1;103;0
WireConnection;545;0;640;0
WireConnection;337;0;336;0
WireConnection;337;1;330;0
WireConnection;55;0;54;0
WireConnection;87;1;86;0
WireConnection;594;0;589;0
WireConnection;125;0;182;0
WireConnection;338;0;337;0
WireConnection;338;1;330;0
WireConnection;331;0;330;0
WireConnection;299;0;365;0
WireConnection;299;1;300;0
WireConnection;182;0;121;0
WireConnection;182;1;183;0
WireConnection;365;0;364;0
WireConnection;262;0;409;0
WireConnection;465;0;603;0
WireConnection;465;1;604;0
WireConnection;465;2;459;3
WireConnection;465;3;459;4
WireConnection;589;0;595;0
WireConnection;589;1;591;4
WireConnection;417;1;28;0
WireConnection;417;0;133;0
WireConnection;417;2;27;0
WireConnection;667;0;588;0
WireConnection;484;0;478;0
WireConnection;692;0;698;0
WireConnection;215;0;216;0
WireConnection;467;0;458;0
WireConnection;467;1;466;0
WireConnection;537;0;485;0
WireConnection;537;1;538;0
WireConnection;537;2;700;0
WireConnection;517;1;117;0
WireConnection;517;2;534;0
WireConnection;298;0;194;0
WireConnection;130;0;131;0
WireConnection;130;1;122;0
WireConnection;130;2;321;0
WireConnection;485;0;417;0
WireConnection;670;0;669;0
WireConnection;670;1;671;0
WireConnection;530;0;223;0
WireConnection;530;1;531;0
WireConnection;28;0;133;0
WireConnection;28;1;27;0
WireConnection;194;0;191;0
WireConnection;194;1;299;0
WireConnection;174;0;173;0
WireConnection;701;1;702;0
WireConnection;701;0;551;0
WireConnection;4;0;3;2
WireConnection;88;0;98;0
WireConnection;88;1;87;0
WireConnection;24;0;367;0
WireConnection;42;0;38;0
WireConnection;638;0;655;0
WireConnection;638;1;658;0
WireConnection;223;0;207;0
WireConnection;223;1;520;0
WireConnection;102;0;103;0
WireConnection;102;1;88;0
WireConnection;328;0;326;0
WireConnection;307;0;313;0
WireConnection;307;1;314;0
WireConnection;307;2;424;0
WireConnection;656;0;657;0
WireConnection;656;1;650;0
WireConnection;290;1;288;0
WireConnection;290;2;293;0
WireConnection;603;0;459;1
WireConnection;603;1;597;0
WireConnection;424;0;554;0
WireConnection;554;0;301;0
WireConnection;554;1;557;0
WireConnection;554;2;558;0
WireConnection;106;0;329;0
WireConnection;106;1;107;0
WireConnection;35;0;3;1
WireConnection;317;0;323;0
WireConnection;536;0;553;0
WireConnection;53;0;52;0
WireConnection;650;0;653;4
WireConnection;478;0;528;0
WireConnection;478;1;483;0
WireConnection;478;2;481;0
WireConnection;478;3;486;0
WireConnection;431;0;109;0
WireConnection;431;1;110;0
WireConnection;132;0;130;0
WireConnection;527;0;526;0
WireConnection;599;0;493;1
WireConnection;599;1;598;0
WireConnection;323;0;315;0
WireConnection;323;3;316;0
WireConnection;108;0;105;0
WireConnection;108;1;429;0
WireConnection;108;2;431;0
WireConnection;466;0;465;0
WireConnection;409;0;290;0
WireConnection;409;1;410;0
WireConnection;409;2;414;0
WireConnection;409;3;416;0
WireConnection;409;4;415;0
WireConnection;332;0;331;0
WireConnection;332;1;331;1
WireConnection;333;0;332;0
WireConnection;333;1;331;2
WireConnection;93;0;228;0
WireConnection;93;1;92;0
WireConnection;634;0;613;3
WireConnection;634;1;614;3
WireConnection;634;2;547;3
WireConnection;632;0;613;1
WireConnection;632;1;614;1
WireConnection;632;2;547;1
WireConnection;173;0;172;0
WireConnection;173;1;202;0
WireConnection;526;0;519;0
WireConnection;171;0;695;0
WireConnection;171;1;170;0
WireConnection;458;0;459;0
WireConnection;429;0;109;0
WireConnection;429;1;110;0
WireConnection;43;0;42;0
WireConnection;96;0;95;0
WireConnection;96;1;211;0
WireConnection;38;0;203;0
WireConnection;38;1;36;0
WireConnection;39;0;43;0
WireConnection;178;0;368;0
WireConnection;649;0;643;0
WireConnection;649;1;660;0
WireConnection;95;0;99;0
WireConnection;95;1;93;0
WireConnection;648;0;638;0
WireConnection;336;0;334;0
WireConnection;336;1;334;0
WireConnection;336;2;334;0
WireConnection;626;0;625;0
WireConnection;626;1;628;0
WireConnection;553;0;1;4
WireConnection;553;1;703;4
WireConnection;557;0;302;0
WireConnection;557;1;556;0
WireConnection;364;0;140;0
WireConnection;97;0;96;0
WireConnection;663;0;667;0
WireConnection;663;1;387;0
WireConnection;663;2;664;0
WireConnection;340;0;341;0
WireConnection;340;1;339;0
WireConnection;340;2;330;0
WireConnection;340;3;146;0
WireConnection;339;0;330;0
WireConnection;339;1;338;0
WireConnection;640;0;646;0
WireConnection;640;1;639;0
WireConnection;288;0;255;0
WireConnection;654;0;649;0
WireConnection;209;0;215;0
WireConnection;617;0;616;0
WireConnection;628;0;627;0
WireConnection;628;1;631;0
WireConnection;491;0;498;0
WireConnection;491;1;697;0
WireConnection;373;2;1;0
WireConnection;373;3;375;0
WireConnection;652;0;654;0
WireConnection;652;2;656;0
WireConnection;310;0;309;0
WireConnection;334;0;333;0
WireConnection;105;0;263;0
WireConnection;105;1;106;0
WireConnection;627;0;617;0
WireConnection;627;1;630;0
WireConnection;54;0;53;0
WireConnection;376;2;177;0
WireConnection;376;3;375;0
WireConnection;646;0;641;0
WireConnection;601;0;458;0
WireConnection;601;1;469;0
WireConnection;601;2;602;0
WireConnection;558;0;302;0
WireConnection;558;1;556;0
WireConnection;326;0;325;0
WireConnection;326;1;327;0
WireConnection;655;0;651;0
WireConnection;426;0;340;0
WireConnection;625;0;632;0
WireConnection;625;1;633;0
WireConnection;625;2;634;0
WireConnection;660;0;659;0
WireConnection;657;0;642;0
WireConnection;367;0;373;0
WireConnection;597;0;493;0
WireConnection;597;1;598;0
WireConnection;181;0;517;0
WireConnection;658;0;645;0
WireConnection;658;1;644;0
WireConnection;658;2;652;0
WireConnection;591;0;593;0
WireConnection;172;0;171;0
WireConnection;637;0;626;0
WireConnection;633;0;613;2
WireConnection;633;1;614;2
WireConnection;633;2;547;2
WireConnection;698;0;699;0
WireConnection;668;0;670;0
WireConnection;124;0;123;0
WireConnection;101;0;174;0
WireConnection;551;11;550;0
WireConnection;666;0;668;0
WireConnection;666;1;663;0
WireConnection;666;2;701;0
WireConnection;533;0;530;0
WireConnection;389;0;666;0
WireConnection;519;0;518;0
WireConnection;122;0;307;0
WireConnection;122;1;184;0
WireConnection;122;2;267;0
WireConnection;581;2;537;0
WireConnection;581;3;685;0
WireConnection;581;4;690;0
ASEEND*/
//CHKSM=A868CC1DF924EB52A14A66A3E5A41B29FEFF19A2