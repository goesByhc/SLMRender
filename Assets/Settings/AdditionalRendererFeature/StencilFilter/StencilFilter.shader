Shader "PostProcess/StencilFilter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Stencil2Color("Stencil2 Color",COLOR)=(1,1,1,1)
        _StencilId("Stencil Id", Int) = 0
    }
    SubShader
    {
        Pass
        {
            Stencil
            {
                Ref 50
                Comp Equal
            }
            
            Cull Off ZWrite Off ZTest Always
            
            ColorMask RGB
            
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            fixed4 _Stencil2Color;
            half4 frag(in v2f_img i): SV_Target
            {
                // half4 c1 = tex2D(_MainTex, i.vertex).rgba;
                half4 c1 = half4(1,1,0,1);
                return c1;
            }
            ENDCG
        }
    }
}