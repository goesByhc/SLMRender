Shader "GammaUIFix"
{
    Properties
    {
        [HideInInspector] _MainTex ("UI Texture", 2D) = "white" {}
        //_UITex ("_UITex", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _CameraColorTexture;
            sampler2D _MainTex;

            float4 frag (v2f i) : SV_Target
            {
                // float4 uicol = tex2D(_MainTex, i.uv); //ui in lighter color
                // uicol.rgb = GammaToLinearSpace(uicol.rgb) / max(uicol.a, 0.00001);
                // float4 col = tex2D(_CameraColorTexture, i.uv); //3d in normal color
                // return half4((uicol.rgb * uicol.a) + col * (1 - uicol.a), 1);

                
                // float4 uicol = tex2D(_MainTex, i.uv); //ui in lighter color
                // uicol.a = LinearToGammaSpace(uicol.a); //make ui alpha in lighter color
                // uicol.rgb = uicol.rgb / max(uicol.a, 0.00001);
                //
                // float4 col = tex2D(_CameraColorTexture, i.uv); //3d in normal color
                // col.rgb = LinearToGammaSpace(col.rgb); //make 3d in lighter color
                //
                // float4 result;
                // result.rgb = lerp(col.rgb,uicol.rgb,uicol.a); //do linear blending
                // result.rgb = GammaToLinearSpace(result.rgb); //make result normal color
                // result.a = 1;
                //
                // return result;


                float4 uicol = tex2D(_MainTex, i.uv); //ui in lighter color
                uicol.a = LinearToGammaSpace(uicol.a); //make ui alpha in lighter color
                
                float4 col = tex2D(_CameraColorTexture, i.uv); //3d in normal color
                col.rgb = LinearToGammaSpace(col.rgb); //make 3d in lighter color
                
                float4 result;
                result.rgb = lerp(col.rgb,uicol.rgb,uicol.a); //do linear blending
                result.rgb = GammaToLinearSpace(result.rgb); //make result normal color
                result.a = 1;
                
                return result;
                
            }
            ENDCG
        }
    }
}
