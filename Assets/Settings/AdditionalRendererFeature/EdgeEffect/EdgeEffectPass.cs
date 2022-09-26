using UnityEngine;

namespace UnityEngine.Rendering.Universal
{
    public class EdgeEffectPass : AdditionalRenderPass<EdgeEffectVolume>
    {
        public override RenderPassEvent renderPass => RenderPassEvent.BeforeRenderingPostProcessing;

        public override string shaderPath => "PostProcess/EdgeEffectDepthNormal";
        
        private int _MainTex = Shader.PropertyToID("_MainTex");

        protected override void Init()
        {
            base.Init();
            m_TemporaryColorTexture01.Init("EdgeEffect_Temp");
        }

        public override void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData)
        {
            
            var desc = GetStereoCompatibleDescriptor(colorDescriptor.width, colorDescriptor.height);

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
            
            material.SetColor("_EdgeColor", volumeComponent.edgeColor.value);
            material.SetFloat("_SampleRange", volumeComponent.sampleRange.value);
            material.SetFloat("_NormalDiffThreshold", volumeComponent.normalDiffThreshold.value);
            material.SetFloat("_DepthDiffThreshold", volumeComponent.depthDiffThreshold.value);

            cmd.SetGlobalTexture(_MainTex, m_TemporaryColorTexture01.id);

            //这里使用了DrawMesh的方式来替代Blit，因为Blit无法正确获取StencilBuffer
            cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, material, 0, 0);
            cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
            
            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);

        }

        
    }
}