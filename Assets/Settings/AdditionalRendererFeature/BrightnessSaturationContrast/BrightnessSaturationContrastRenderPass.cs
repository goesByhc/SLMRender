using UnityEngine;

namespace UnityEngine.Rendering.Universal
{
    public class BrightnessSaturationContrastRenderPass : AdditionalRenderPass<BrightnessSaturationContrastVolume>
    {
        public override RenderPassEvent renderPass => RenderPassEvent.BeforeRenderingPostProcessing;

        public override string shaderPath => "PostProcess/Brightness Saturation And Contrast";
        
        protected override void Init()
        {
            base.Init();
            m_TemporaryColorTexture01.Init("BrightnessSaturationContrast_Temp");
        }

        public override void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData)
        {
             material.SetFloat("_Brightness", volumeComponent.brightness.value);
             material.SetFloat("_Saturation", volumeComponent.saturation.value);
             material.SetFloat("_Contrast", volumeComponent.contrast.value);

             // 通过目标相机的渲染信息创建临时缓冲区
             //RenderTextureDescriptor opaqueDesc = m_Descriptor;
             //opaqueDesc.depthBufferBits = 0;
             //cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, opaqueDesc);
             //or
             int tw = colorDescriptor.width;
             int th = colorDescriptor.height;
             var desc = GetStereoCompatibleDescriptor(tw, th);
             cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, desc, FilterMode.Bilinear);

             // 通过材质，将计算结果存入临时缓冲区
             cmd.Blit(colorSource, m_TemporaryColorTexture01.Identifier(), material);
             // 再从临时缓冲区存入主纹理
             cmd.Blit(m_TemporaryColorTexture01.Identifier(), colorSource);

             // 释放临时RT
             cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);
        }
    }
}