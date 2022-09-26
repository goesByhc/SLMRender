
namespace UnityEngine.Rendering.Universal
{


    public interface IAdditionalRenderPass
    {
        // public void Setup(in RenderTextureDescriptor baseDescriptor, in RenderTargetIdentifier source,
        //     in RenderTargetIdentifier depth, in RenderTargetHandle destination);
        public bool IsActive(bool isSceneViewCamera, bool isBaseCamera, bool isPostProcessEnabled, ref RenderingData renderingData);
        public bool RefreshVolume();
        public void Release();
    }


    public abstract class AdditionalRenderPass<T> : ScriptableRenderPass, IAdditionalRenderPass where T : VolumeComponent , IPostProcessComponent
    {
        
        // 主纹理信息
        public RenderTargetIdentifier colorSource;
        // 深度信息
        public RenderTargetIdentifier depthSource;
        // 当前帧的渲染纹理描述
        public RenderTextureDescriptor colorDescriptor;

        
        // 临时的渲染目标
        public RenderTargetHandle m_TemporaryColorTexture01;
        public RenderTargetHandle m_TemporaryColorTexture02;
        public RenderTargetHandle m_TemporaryColorTexture03;


        public T volumeComponent;
        public Material material;

        
        public AdditionalRenderPass()
        {
            Init();
        }

        protected virtual void Init()
        {
            renderPassEvent = renderPass;
            material = LoadMaterial();
        }

        
        Material LoadMaterial()
        {
            if (string.IsNullOrEmpty(shaderPath))
            {
                return null;
            }
            
            var shader = Shader.Find(shaderPath);
            
            if (shader == null)
            {
                Debug.LogError($" shader: {shaderPath} 渲染通道将不会执行");
                return null;
            }
            
            if (!shader.isSupported)
            {
                Debug.LogError($"shader: {shaderPath} is Not Supported");
                return null;
            }
            return CoreUtils.CreateEngineMaterial(shader);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            colorDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            colorSource = renderingData.cameraData.renderer.cameraColorTarget;
            depthSource = renderingData.cameraData.renderer.cameraDepthTarget;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            
        }

        /// <summary>
        /// URP会自动调用该执行方法
        /// </summary>
        /// <param name="context"></param>
        /// <param name="renderingData"></param>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            
            // 从命令缓冲区池中获取一个带标签的渲染命令，该标签名可以在后续帧调试器中见到
            var cmd = CommandBufferPool.Get(CommandBufferTag);

            // 调用渲染函数
            Render(context, cmd, ref renderingData);

            // 执行命令缓冲区
            context.ExecuteCommandBuffer(cmd);
            // 释放命令缓存
            CommandBufferPool.Release(cmd);
        }

        public RenderTextureDescriptor GetStereoCompatibleDescriptor(int width, int height, int depthBufferBits = 0)
        {
            var desc = colorDescriptor;
            desc.depthBufferBits = depthBufferBits;
            desc.msaaSamples = 1;
            desc.width = width;
            desc.height = height;
            return desc;
        }

        
        public virtual bool RefreshVolume()
        {
            // 从Volume框架中获取所有堆栈
            var stack = VolumeManager.instance.stack;
            // 从堆栈中查找对应的属性参数组件
            volumeComponent = stack.GetComponent<T>();

            return volumeComponent != null && volumeComponent.active;
        }


        public virtual void Release()
        {
            if (material)
            {
                GameObject.DestroyImmediate(material);
                material = null;
            }
        }


        public string CommandBufferTag => typeof(T).Name;

        public abstract RenderPassEvent renderPass { get; }
        public abstract string shaderPath { get; }
        
        public abstract void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData);
        
        public virtual bool IsActive(bool isSceneViewCamera, bool isBaseCamera, bool isPostProcessEnabled, ref RenderingData renderingData)
        {
            bool isActive = !isSceneViewCamera 
                            && isBaseCamera
                            && volumeComponent.IsActive()
                            && isPostProcessEnabled;
            return isActive;
        }

    }
}