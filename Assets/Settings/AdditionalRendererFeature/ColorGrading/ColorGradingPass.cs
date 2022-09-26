using UnityEngine;
using UnityEngine.Experimental.Rendering;

namespace UnityEngine.Rendering.Universal.ColorGrading
{
    public class ColorGradingPass : AdditionalRenderPass<ColorAdjustments>
    {
        public override RenderPassEvent renderPass => RenderPassEvent.AfterRenderingTransparents; 
        
        public override string shaderPath => "PostProcess/ColorGrading";

        private int _MainTex = Shader.PropertyToID("_MainTex");

        protected override void Init()
        {
            base.Init();
            m_TemporaryColorTexture01.Init("ColorGrading_Temp");
        }
        
        public static readonly int _Vignette_Params1   = Shader.PropertyToID("_Vignette_Params1");
        public static readonly int _Vignette_Params2   = Shader.PropertyToID("_Vignette_Params2");
        
        public static readonly int _Lut_Params         = Shader.PropertyToID("_Lut_Params");
        public static readonly int _UserLut_Params     = Shader.PropertyToID("_UserLut_Params");
        public static readonly int _InternalLut        = Shader.PropertyToID("_InternalLut");
        public static readonly int _UserLut            = Shader.PropertyToID("_UserLut");
        
        public override void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData)
        {
            
            var desc = GetStereoCompatibleDescriptor(colorDescriptor.width, colorDescriptor.height);

            desc.graphicsFormat = GraphicsFormat.R8G8B8A8_SRGB;

            cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, desc, FilterMode.Bilinear);

            cmd.Blit(colorSource, m_TemporaryColorTexture01.id);

            Camera camera = renderingData.cameraData.camera;
            cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
            cmd.SetViewport(new Rect(0, 0, camera.pixelWidth, camera.pixelHeight));

            if (renderingData.cameraData.camera.GetComponent<UniversalAdditionalCameraData>().cameraStack.Count > 0)
            {
                cmd.SetRenderTarget(
                    colorSource, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, // color
                    depthSource, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare); // depth
            }
            else
            {
                cmd.SetRenderTarget(
                    colorSource, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, // color
                    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare); // depth
            }

            cmd.SetGlobalTexture(_MainTex, m_TemporaryColorTexture01.id);

            SetupVignette(cmd, ref renderingData, material);
            SetupColorGrading(cmd, ref renderingData, material);
            
            //这里使用了DrawMesh的方式来替代Blit，因为Blit无法正确获取StencilBuffer
            cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, material, 0, 0);
            cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
            
            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);
        }

        void SetupVignette(CommandBuffer cmd, ref RenderingData renderingData, Material material)
        {

            var stack = VolumeManager.instance.stack;
            // 从堆栈中查找对应的属性参数组件
            var m_Vignette = stack.GetComponent<Vignette>();
            
            var color = m_Vignette.color.value;
            var center = m_Vignette.center.value;
            var aspectRatio = colorDescriptor.width / (float)colorDescriptor.height;
    
            var v1 = new Vector4(
                color.r, color.g, color.b,
                m_Vignette.rounded.value ? aspectRatio : 1f
            );
            var v2 = new Vector4(
                center.x, center.y,
                m_Vignette.intensity.value * 3f,
                m_Vignette.smoothness.value * 5f
            );
    
            material.SetVector(_Vignette_Params1, v1);
            material.SetVector(_Vignette_Params2, v2);
        }

        void SetupColorGrading(CommandBuffer cmd, ref RenderingData renderingData, Material material)
        {
            ref var postProcessingData = ref renderingData.postProcessingData;
            bool hdr = postProcessingData.gradingMode == ColorGradingMode.HighDynamicRange;
            int lutHeight = postProcessingData.lutSize;
            int lutWidth = lutHeight * lutHeight;

            var m_ColorAdjustments = volumeComponent;

            // Source material setup
            float postExposureLinear = Mathf.Pow(2f, m_ColorAdjustments.postExposure.value);
            // cmd.SetGlobalTexture(_InternalLut, m_InternalLut.Identifier());
            material.SetVector(_Lut_Params, new Vector4(1f / lutWidth, 1f / lutHeight, lutHeight - 1f, postExposureLinear));
            // material.SetTexture(_UserLut, m_ColorLookup.texture.value);
            // material.SetVector(_UserLut_Params, !m_ColorLookup.IsActive()
            //     ? Vector4.zero
            //     : new Vector4(1f / m_ColorLookup.texture.value.width,
            //         1f / m_ColorLookup.texture.value.height,
            //         m_ColorLookup.texture.value.height - 1f,
            //         m_ColorLookup.contribution.value)
            // );

            if (hdr)
            {
                material.EnableKeyword(ShaderKeywordStrings.HDRGrading);
            }
        }



    }
}