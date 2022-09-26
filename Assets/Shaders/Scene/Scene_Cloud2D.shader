Shader "Scene_Cloud2D"
{
    Properties
    {
        [NoScaleOffset]_MainGradientTexture("Main Gradient", 2D) = "white" {}
        [NoScaleOffset]_GeometryGradientTexture("Geometry Gradient", 2D) = "white" {}
        _EdgeDistortion("Edge Distortion", Range(0, 1)) = 0.2
        _BaseVerticalOffset("Base Vertical Offset", Range(0, 1)) = 0.6
        _HeightGradientStrength("Height Gradient Strength", Range(0, 1)) = 1
        _EdgeHighlightColor("Edge Highlight", Color) = (0.8705883, 0.8705883, 0.8705883, 1)
        _Opacity("Opacity", Range(0, 1)) = 1
        [Header(Shadow)]
        _ShadowColor("Shadow Color", Color) = (0.7490196, 0.8078432, 0.882353, 1)
        _ShadowAmount("Shadow Amount", Range(0, 1)) = 0.8
        _ShadowDistortion("Shadow Distortion", Range(0, 1)) = 0.3
        _ShadowCenter("Shadow Center[V2]", Vector) = (1, 0.15, 0, 0)
        _ShadowRange("Shadow Range[V2]", Vector) = (0.3, 0.85, 0, 0)
        [Header(Animation)]
        _RandomOffset("Random Offset[V2]", Vector) = (0, 0, 0, 0)
        _OffsetSpeed("Offset Speed[V2]", Vector) = (0, 0, 0, 0)
        _ObjectPositionImpact("Object Position Impact", Range(0, 1)) = 1
        [Header(Geometry)]
        Geometry_Density_Large("Geometry Density Large", Float) = 5
        Geometry_Density_Medium("Geometry Density Medium", Float) = 20
        Geometry_Density_Small("Geometry Density Small", Float) = 50
        [ToggleUI]_Billboard("Face Camera", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        
        
        
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../Core.hlsl"
            #include "../Noise.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainGradientTexture_TexelSize;
            float4 _GeometryGradientTexture_TexelSize;
            float _EdgeDistortion;
            float _BaseVerticalOffset;
            float4 _ShadowColor;
            float _ShadowAmount;
            float _ShadowDistortion;
            float2 _ShadowCenter;
            float2 _ShadowRange;
            float4 _EdgeHighlightColor;
            float _Opacity;
            float _HeightGradientStrength;
            float2 _RandomOffset;
            float2 _OffsetSpeed;
            float _ObjectPositionImpact;
            float Header_Geometry_Density;
            float Geometry_Density_Large;
            float Geometry_Density_Medium;
            float Geometry_Density_Small;
            float _Billboard;
        CBUFFER_END
        

        ENDHLSL
        

        Pass
        {
            Name "Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Off
//            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest LEqual
            ZWrite Off
            ColorMask RGB

            HLSLPROGRAM

            // Pragmas
            #pragma vertex vert
            #pragma fragment frag

            // Object and Global properties
            SAMPLER(SamplerState_Linear_Repeat);
            TEXTURE2D(_MainGradientTexture);
            SAMPLER(sampler_MainGradientTexture);
            TEXTURE2D(_GeometryGradientTexture);
            SAMPLER(sampler_GeometryGradientTexture);


            
            //Object
            struct VertexInputCloud2D
            {
                float4 positionOS : POSITION;
                float4 uv : TEXCOORD0;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct VertexOutputCloud2D
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                half4 positionOS : TEXCOORD2;
                half4 color : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };



            VertexOutputCloud2D vert(VertexInputCloud2D v)
            {
                VertexOutputCloud2D o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


                half4 posicionCS;

                posicionCS = lerp(TransformObjectToHClip(v.positionOS.xyz), GetBillboardPositionCS(v.positionOS), _Billboard);
                
                o.positionCS = posicionCS;
                o.positionOS = v.positionOS;
            
                o.color = v.color;
                o.uv = v.uv.xy;
                
                return o;
            }

            half4 frag (VertexOutputCloud2D i) : SV_Target
            {
                //Dir
                half2 uv = i.uv;
                half2 positionOS = i.positionOS;

                
                //Basic Shape
                half edgeNoise;
                SimpleNoise_float(i.uv.xy, 120, edgeNoise);
                edgeNoise *= _EdgeDistortion;
                edgeNoise = 1 - edgeNoise;
                half2 edge = edgeNoise * half2(positionOS.x, - positionOS.y) * 2 + 1;
                edge.y = pow(edge.y, 2) * _BaseVerticalOffset;
                half basicShape = smoothstep(1, 0, distance(edge, half2(1,1)));

                
                //Cloud Noise
                half2 noiseCloudUV = _OffsetSpeed * _Time + _RandomOffset + (_ObjectPositionImpact * SHADERGRAPH_OBJECT_POSITION).xy + edge;

                half largeNoise;
                half largeCell;
                NoiseVoronoi_float(noiseCloudUV, 8.5, Geometry_Density_Large, largeNoise, largeCell);
                Gradient gradientLarge = NewGradient(0, 2, 2, float4(1, 1, 1, 0),float4(0, 0, 0, 0.6411841),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0), float2(1, 0),float2(1, 1),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0));
                half4 finalLargeNoise;
                Unity_SampleGradient_float(gradientLarge, largeNoise, finalLargeNoise);
                Unity_Blend_SoftLight_float4(basicShape.xxxx, finalLargeNoise, 0.8, finalLargeNoise);
                
                half mediumNoise;
                half mediumCell;
                NoiseVoronoi_float(noiseCloudUV, 2, Geometry_Density_Medium, mediumNoise, mediumCell);
                Gradient gradientMedium = NewGradient(0, 2, 2, float4(1, 1, 1, 0),float4(0, 0, 0, 1),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0), float2(1, 0),float2(1, 1),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0));
                half4 finalMediumNoise;
                Unity_SampleGradient_float(gradientMedium, mediumNoise, finalMediumNoise);
                Unity_Blend_SoftLight_float4(finalLargeNoise, finalMediumNoise, 0.2, finalMediumNoise);

                half smallNoise;
                half smallCell;
                NoiseVoronoi_float(noiseCloudUV, 2, Geometry_Density_Small, smallNoise, smallCell);
                Gradient gradientSmall = NewGradient(0, 2, 2, float4(1, 1, 1, 0),float4(0, 0, 0, 1),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0), float2(1, 0),float2(1, 1),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0));
                half4 finalSmallNoise;
                Unity_SampleGradient_float(gradientSmall, smallNoise, finalSmallNoise);
                Unity_Blend_SoftLight_float4(finalMediumNoise, finalSmallNoise, 0.1, finalSmallNoise);

                half4 finalCloudNoise = max(finalSmallNoise, half4(0,0,0,0));


                //VerticalGradient
                Gradient gradientVertical = NewGradient(0, 2, 2, float4(0, 0, 0, 0),float4(1, 1, 1, 0.5799954),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0), float2(1, 0),float2(1, 1),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0));
                half4 verticalBlend;
                Unity_SampleGradient_float(gradientVertical, i.uv.y, verticalBlend);
                Unity_Blend_Multiply_float4(finalCloudNoise, verticalBlend, _HeightGradientStrength, verticalBlend);


                //Color
                UnityTexture2D mainGradientTex = UnityBuildTexture2DStructNoScale(_MainGradientTexture);
                half4 mainColor;
                Unity_SampleGradientTexture(mainGradientTex, verticalBlend.r, mainColor);

                // return mainColor;

                // return half4(SAMPLE_TEXTURE2D(_MainGradientTexture, sampler_MainGradientTexture, i.uv).rgb, 1);

                //Shadow
                half shadowNoise;
                SimpleNoise_float(i.uv, 120, shadowNoise);
                shadowNoise *= _ShadowDistortion;
                shadowNoise = 1 - shadowNoise;

                half2 shadowNoisePos = shadowNoise * (i.positionOS.xy + 0.5);// * half2(1.23, 2);
                half shadowDistance = distance(shadowNoisePos, _ShadowCenter);

                // return half4(shadowDistance.rrr, 1);
                
                half shadow = smoothstep(_ShadowRange.y, _ShadowRange.x, shadowDistance);
                
                Gradient gradientShadow = NewGradient(0, 2, 2, float4(0, 0, 0, 0.002944991),float4(1, 1, 1, 0.6852979),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0), float2(1, 0),float2(1, 1),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0));
                float4 finalShadow;
                Unity_SampleGradient_float(gradientShadow, shadow, finalShadow);
                finalShadow *= _ShadowAmount;
                Unity_Blend_Multiply_float4(mainColor, _ShadowColor, finalShadow, mainColor);

                // return half4(finalShadow.rgb, _Opacity);


                //EdgeHighlight
                Gradient gradientEdge = NewGradient(0, 2, 2, float4(0.624, 0.624, 0.624, 0),float4(0, 0, 0, 0.7764706),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0),float4(0, 0, 0, 0), float2(1, 0),float2(1, 1),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0),float2(0, 0));
                half4 edgeHighlight;
                Unity_SampleGradient_float(gradientEdge, finalCloudNoise.r, edgeHighlight);

                Unity_Blend_Screen_float4(mainColor, _EdgeHighlightColor, edgeHighlight, mainColor);



                //Geometry
                UnityTexture2D geometryGradientTex = UnityBuildTexture2DStructNoScale(_GeometryGradientTexture);
                half4 geometryColor;
                Unity_SampleGradientTexture(geometryGradientTex, finalCloudNoise.r, geometryColor);
                half alpha = max(geometryColor.r * _Opacity, 0);
                // alpha = GammaToLinearSpace(alpha.rrr).r;
                
                // return half4(SAMPLE_TEXTURE2D(_GeometryGradientTexture, sampler_GeometryGradientTexture, float2(i.uv.x, 0.5)).rgb, 1);

                half4 finalColor = half4(mainColor.rgba * alpha);
                
                // return half4(alpha.rrr, 1);

                return half4(finalColor.rgb, alpha); 
                
            }



            ENDHLSL
        }
    }
}