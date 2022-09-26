using UnityEngine;
using UnityEngine.UI;

namespace UnityEngine.Rendering.Universal
{
    public class StylizedDetailPass : AdditionalRenderPass<StylizedDetailVolume>
    {
        public override RenderPassEvent renderPass => RenderPassEvent.AfterRenderingTransparents;

        public override string shaderPath => "PostProcess/StylizedDetail";

        static class PropertyIDs {
            internal static readonly int Input = Shader.PropertyToID("_MainTex");
            internal static readonly int PingTexture = Shader.PropertyToID("_PingTexture");
            internal static readonly int BlurStrength = Shader.PropertyToID("_BlurStrength");
            internal static readonly int Blur1 = Shader.PropertyToID("_BlurTex1");
            internal static readonly int Blur2 = Shader.PropertyToID("_BlurTex2");
            internal static readonly int Intensity = Shader.PropertyToID("_Intensity");
            internal static readonly int DownSampleScaleFactor = Shader.PropertyToID("_DownSampleScaleFactor");
            public static readonly int CoCParams = Shader.PropertyToID("_CoCParams");
            public static readonly int _SourceSize = Shader.PropertyToID("_SourceSize");
        }

        protected override void Init()
        {
            base.Init();
            m_TemporaryColorTexture01.Init("SNN_Temp");
        }

        public override void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData)
        {
            const int downSample = 1;

            RenderTextureDescriptor descriptor = colorDescriptor;
            int wh = descriptor.width / downSample;
            int hh = descriptor.height / downSample;
    
            // Assumes a radius of 1 is 1 at 1080p. Past a certain radius our gaussian kernel will look very bad so we'll
            // clamp it for very high resolutions (4K+).
            float blurRadius = volumeComponent.blur.value * (wh / 1080f);
            blurRadius = Mathf.Min(blurRadius, 2f);
            float edgePreserve = volumeComponent.edgePreserve.value * (wh / 1080f);
            edgePreserve = Mathf.Min(edgePreserve, 2f);
    
            var rangeStart = volumeComponent.rangeStart.overrideState ? volumeComponent.rangeStart.value : 0;
            var rangeEnd = volumeComponent.rangeEnd.overrideState ? volumeComponent.rangeEnd.value : -1;
            material.SetVector(PropertyIDs.CoCParams, new Vector2(rangeStart, rangeEnd));
    
            material.SetFloat(PropertyIDs.Intensity, volumeComponent.intensity.value);
            SetSourceSize(cmd, descriptor);
    
            cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, colorDescriptor);
            
            cmd.GetTemporaryRT(PropertyIDs.PingTexture, colorDescriptor, FilterMode.Bilinear);
            cmd.GetTemporaryRT(PropertyIDs.Blur1, colorDescriptor, FilterMode.Bilinear);
            cmd.GetTemporaryRT(PropertyIDs.Blur2, colorDescriptor, FilterMode.Bilinear);
    
            cmd.SetGlobalVector(PropertyIDs.DownSampleScaleFactor,
                                new Vector4(1.0f / downSample, 1.0f / downSample, downSample, downSample));
    
            cmd.SetGlobalFloat(PropertyIDs.BlurStrength, edgePreserve);
            cmd.SetGlobalTexture(PropertyIDs.Input, colorSource);
            CoreUtils.DrawFullScreen(cmd, material, PropertyIDs.PingTexture, null, 1);
            cmd.SetGlobalTexture(PropertyIDs.Input, PropertyIDs.PingTexture);
            CoreUtils.DrawFullScreen(cmd, material, PropertyIDs.Blur1, null, 2);
    
            cmd.SetGlobalFloat(PropertyIDs.BlurStrength, blurRadius);
            cmd.SetGlobalTexture(PropertyIDs.Input, PropertyIDs.Blur1);
            CoreUtils.DrawFullScreen(cmd, material, PropertyIDs.PingTexture, null, 1);
            cmd.SetGlobalTexture(PropertyIDs.Input, PropertyIDs.PingTexture);
            CoreUtils.DrawFullScreen(cmd, material, PropertyIDs.Blur2, null, 2);
    
            cmd.SetGlobalTexture(PropertyIDs.Input, colorSource);
            CoreUtils.DrawFullScreen(cmd, material, colorSource, null, 0);
    
            cmd.ReleaseTemporaryRT(PropertyIDs.PingTexture);
            cmd.ReleaseTemporaryRT(PropertyIDs.Blur1);
            cmd.ReleaseTemporaryRT(PropertyIDs.Blur2);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);
        }
        
        
        public static void SetSourceSize(CommandBuffer cmd, RenderTextureDescriptor desc) {
            float width = desc.width;
            float height = desc.height;
            if (desc.useDynamicScale) {
                width *= ScalableBufferManager.widthScaleFactor;
                height *= ScalableBufferManager.heightScaleFactor;
            }

            cmd.SetGlobalVector(PropertyIDs._SourceSize, new Vector4(width, height, 1.0f / width, 1.0f / height));
        }

    }
}