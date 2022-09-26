namespace UnityEngine.Rendering.Universal.Internal
{
    public class FXAAPass : AdditionalRenderPass<FXAA>
    {
        static readonly string PASSNAME = "FXAA";
        private ProfilingSampler _profilingSampler { get; set; }
        private static readonly int _SourceSize = Shader.PropertyToID("_SourceSize");
        private static readonly int _SourceTex = Shader.PropertyToID("_SourceTex");
        private bool isFinalCamera;
        public FXAAPass()
        {
            _profilingSampler = new ProfilingSampler(PASSNAME);
            m_TemporaryColorTexture01.Init("_AfterPostProcessTexture");
            m_TemporaryColorTexture02.Init("FXAA");
            isFinalCamera = false;
        }
        
        public override bool IsActive(bool isSceneViewCamera, bool isBaseCamera, bool isPostProcessEnabled, ref RenderingData renderingData)
        {
            // if (renderingData.cameraData.camera == URPCamera.UICamera)
            // {
            //     return false;
            // }
            
            bool isActive = !isSceneViewCamera
                            && volumeComponent.IsActive()
                            && isPostProcessEnabled;
            return isActive;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            base.OnCameraSetup(cmd, ref renderingData);
            isFinalCamera = renderingData.cameraData.resolveFinalTarget;
        }

        public override void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData)
        {
            using (new ProfilingScope(cmd, _profilingSampler))
            {
                cmd.GetTemporaryRT(m_TemporaryColorTexture02.id, colorDescriptor);
                var renderTarget = isFinalCamera ? m_TemporaryColorTexture01.id : colorSource;
                cmd.Blit(renderTarget, m_TemporaryColorTexture02.id);
                var cameraData = renderingData.cameraData;
                Camera camera = cameraData.camera;
                SetSourceSize(cmd, renderingData.cameraData.cameraTargetDescriptor);

                CoreUtils.SetRenderTarget(
                    cmd,
                    renderTarget,
                    RenderBufferLoadAction.DontCare,
                    RenderBufferStoreAction.Store,
                    ClearFlag.None,
                    Color.black);
                cmd.SetGlobalTexture(_SourceTex, m_TemporaryColorTexture02.id);
                cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                cmd.SetViewport(new Rect(0, 0, camera.pixelWidth, camera.pixelHeight));

                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, material, 0, 0);
                cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
            }
        }

        private void SetSourceSize(CommandBuffer cmd, RenderTextureDescriptor desc)
        {
            float width = desc.width;
            float height = desc.height;
            if (desc.useDynamicScale)
            {
                width *= ScalableBufferManager.widthScaleFactor;
                height *= ScalableBufferManager.heightScaleFactor;
            }

            cmd.SetGlobalVector(_SourceSize, new Vector4(width, height, 1.0f / width, 1.0f / height));
        }

        public override RenderPassEvent renderPass => RenderPassEvent.AfterRendering;
        public override string shaderPath => "PostProcess/FXAA";
        
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture02.id);
        }
    }
}