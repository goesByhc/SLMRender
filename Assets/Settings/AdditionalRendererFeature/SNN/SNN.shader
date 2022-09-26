Shader "PostProcess/SNN"
{
    
    CGINCLUDE
    #include "UnityCG.cginc"
    
    sampler2D _MainTex;
    uniform float4 _MainTex_TexelSize;
    uniform float4 _Offset;
    uniform float _HalfWidth;

    
        
    // Calculate color distance
    float CalcDistance(in half3 c0, in half3 c1) {
        half3 sub = c0 - c1;
        return dot(sub, sub);
    }

    // Symmetric Nearest Neighbor
    half4 frag_CalcSNN(in v2f_img i): SV_Target {

        // return half4(half3(1,0,0), 1);

        // half2 src_size = iResolution.xy;
        // half2 inv_src_size = 1.0f / src_size;
        // half2 uv = fragCoord * inv_src_size;
        half2 uv = i.uv;

        half4 mainTex = tex2D(_MainTex, uv).rgba;
        half3 c0 = mainTex.rgb;

    // return half4(c0 * half3(1,0.5,0.5), 1);

        half4 sum = half4(0.0f, 0.0f, 0.0f, 0.0f);

        half sumAlpha = 0;

        // return half4(_Offset.xxx, 1);
        
        for (int i = 0; i <= _HalfWidth; ++i) {
            half4 c1 = tex2D(_MainTex, uv + half2(+i, 0) * _Offset.xy).rgba;
            // // return half4(c1, 1.0f);
            half4 c2 = tex2D(_MainTex, uv + half2(-i, 0) * _Offset.xy).rgba;
            
            float d1 = CalcDistance(c1, c0);
            float d2 = CalcDistance(c2, c0);
            if (d1 < d2) {
                sum.rgb += c1.rgb;
                sumAlpha += c1.a;
            } else {
                sum.rgb += c2.rgb;
                sumAlpha += c2.a;
            }

            // sum.rgb += 0.3f;
            sum.a += 1.0f;

        }

        // return sum.rgb;
        
        for (int j = 1; j <= _HalfWidth; ++j) {
            for (int i = -_HalfWidth; i <= _HalfWidth; ++i) {
                half4 c1 = tex2D(_MainTex, uv + half2(+i, +j) * _Offset.xy).rgba;
                half4 c2 = tex2D(_MainTex, uv + half2(-i, -j) * _Offset.xy).rgba;
                
                float d1 = CalcDistance(c1, c0);
                float d2 = CalcDistance(c2, c0);
                if (d1 < d2) {
                    sum.rgb += c1.rgb;
                    sumAlpha += c1.a;
                } else {
                    sum.rgb += c2.rgb;
                    sumAlpha += c2.a;
                }
                sum.a += 1.0f;
            }
        }
        return half4(sum.rgb / sum.a, mainTex.a);
    }
        
    // Kuwahara
    half4 frag_CalcKuwahara(in v2f_img i): SV_Target {
        half2 uv = i.uv;
        
        float n = float((_HalfWidth + 1) * (_HalfWidth + 1));
        float inv_n = 1.0f / n;
        
        half3 col = half3(0, 0, 0);
        
        float sigma2 = 0.0f;
        float min_sigma = 100.0f;
        
        half3 m = half3(0, 0, 0);
        half3 s = half3(0, 0, 0);
        
        
        for (int j = -_HalfWidth; j <= 0; ++j) {
            for (int i = -_HalfWidth; i <= 0; ++i) {
                half3 c = tex2D(_MainTex, uv + half2(i, j) * _Offset.xy).rgb;
                m += c;
                s += c * c;
            }
        }
        
        m *= inv_n;
        s = abs(s * inv_n - m * m);
        
        sigma2 = s.x + s.y + s.z;
        if (sigma2 < min_sigma) {
            min_sigma = sigma2;
            col = m;
        }
        
        m = half3(0, 0, 0);
        s = half3(0, 0, 0);
        
        for (int j = -_HalfWidth; j <= 0; ++j) {
            for (int i = 0; i <= _HalfWidth; ++i) {
                half3 c = tex2D(_MainTex, uv + half2(i, j) * _Offset.xy).rgb;
                m += c;
                s += c * c;
            }
        }
        
        m *= inv_n;
        s = abs(s * inv_n - m * m);
        
        sigma2 = s.x + s.y + s.z;
        if (sigma2 < min_sigma) {
            min_sigma = sigma2;
            col = m;
        }
        
        m = half3(0, 0, 0);
        s = half3(0, 0, 0);
        
        for (int j = 0; j <= _HalfWidth; ++j) {
            for (int i = 0; i <= _HalfWidth; ++i) {
                half3 c = tex2D(_MainTex, uv + half2(i, j) * _Offset.xy).rgb;
                m += c;
                s += c * c;
            }
        }
        
        m *= inv_n;
        s = abs(s * inv_n - m * m);
        
        sigma2 = s.x + s.y + s.z;
        if (sigma2 < min_sigma) {
            min_sigma = sigma2;
            col = m;
        }
        
        m = half3(0, 0, 0);
        s = half3(0, 0, 0);
        
        for (int j = 0; j <= _HalfWidth; ++j) {
            for (int i = -_HalfWidth; i <= 0; ++i) {
                half3 c = tex2D(_MainTex, uv + half2(i, j) * _Offset.xy).rgb;
                m += c;
                s += c * c;
            }
        }
        
        m *= inv_n;
        s = abs(s * inv_n - m * m);
        
        sigma2 = s.x + s.y + s.z;
        if (sigma2 < min_sigma) {
            min_sigma = sigma2;
            col = m;
        }
        
        return half4(col, 1.0f);
    }

    ENDCG
    
    Properties
    {
//        _MainTex ("Texture", 2D) = "white" {}
        _Offset ("Offset", Vector) = (1, 1, 1, 1)
        _HalfWidth ("HalfWidth", Range(0, 5)) = 5
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

//        ColorMask RGB
        
        Stencil
        {
            Ref 50
            Comp NotEqual
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_CalcSNN
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_CalcKuwahara
            ENDCG
        }
    }
}
