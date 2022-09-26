//see README here: https://github.com/ColinLeung-NiloCat/UnityURP-MobileScreenSpacePlanarReflection

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DrawManyThingsRenderFeature : ScriptableRendererFeature
{
    public static DrawManyThingsRenderFeature
        instance; //for example scene to call, user should add 1 and not more than 1 MobileSSPRRendererFeature anyway so it is safe to use static ref

    [System.Serializable]
    public class PassSettings
    {
        public bool cullingHZ;
    }

    public PassSettings Settings = new PassSettings();

    public static List<DrawManyThings> drawList = new List<DrawManyThings>();

    private DrawIndirectRenderPass drawIndirectRenderPass;
    private HierarchicalZBufferRenderPass m_ZBufferPass;

    public override void Create()
    {
        // Debug.Log("DrawManyThingsRenderFeature Create");
        instance = this;

        m_ZBufferPass = new HierarchicalZBufferRenderPass();
        drawIndirectRenderPass = new DrawIndirectRenderPass();

        // Configures where the render pass should be injected.
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.renderType != CameraRenderType.Base)
        {
            return;
        }
        
        Shader.SetGlobalInt("_HZCullingEnable", Settings.cullingHZ ? 1 : 0);

        if (Settings.cullingHZ)
        {
            renderer.EnqueuePass(m_ZBufferPass);
        }
        
        drawIndirectRenderPass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(drawIndirectRenderPass);
    }

    public static void AddDrawData(DrawManyThings drawManyThings)
    {
        drawList.Add(drawManyThings);
    }

    public static void RemoveDrawData(DrawManyThings drawManyThings)
    {
        drawList.Remove(drawManyThings);
    }
    
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        m_ZBufferPass.Release();
    }


    public class HierarchicalZBufferRenderPass : ScriptableRenderPass
    {
        // Consts
        private const int MAXIMUM_BUFFER_SIZE = 1024;

        private RenderTexture hzbDepth;
        private Material hzbMat;

        int ID_InvSize;

        public HierarchicalZBufferRenderPass()
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
            hzbMat = new Material(Shader.Find("HZBBuild"));
            
            hzbDepth = new RenderTexture(MAXIMUM_BUFFER_SIZE, MAXIMUM_BUFFER_SIZE, 0, RenderTextureFormat.RHalf);
            hzbDepth.autoGenerateMips = false;

            hzbDepth.useMipMap = true;
            hzbDepth.filterMode = FilterMode.Point;
            hzbDepth.Create();
            Shader.SetGlobalTexture("_HZB_Depth", hzbDepth);

            ID_InvSize = Shader.PropertyToID("_InvSize"); 
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // Create Texture
             if (renderingData.cameraData.cameraType != CameraType.Game)
                 return;

             if (hzbDepth == null)
             {
                 return;
             }

            var cmd = CommandBufferPool.Get("Hi-ZDepth");

            int w = hzbDepth.width;
            int h = hzbDepth.height;
 
            RenderTexture lastRt = null;
            RenderTexture tempRT = null;
            
            var depthZBufferIdentifier = new RenderTargetIdentifier(hzbDepth);
            
            int level = 0;
            while (h > 8)
            {
                hzbMat.SetVector(ID_InvSize, new Vector4(1.0f / w, 1.0f / h, 0, 0));

                tempRT = RenderTexture.GetTemporary(w, h, 0, hzbDepth.format);
                tempRT.filterMode = FilterMode.Point;

                if (lastRt == null)
                {
                    //Copy Depth to Buffer
                    cmd.Blit(null, tempRT, hzbMat, 0);
                }
                else
                {
                    cmd.Blit(lastRt, tempRT, hzbMat, 1);
                    RenderTexture.ReleaseTemporary(lastRt);
                }
                cmd.CopyTexture(tempRT, 0, 0, depthZBufferIdentifier, 0, level);

                lastRt = tempRT;

                w /= 2;
                h /= 2;
                level++;
            }
            
            RenderTexture.ReleaseTemporary(tempRT);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
        
        public void Release()
        {
            
            // Debug.Log("Release HierarchicalZBufferRenderPass");
            if (hzbDepth)
            {
                hzbDepth.Release();
                hzbDepth = null;
            }
            ReleaseMaterial();
        }

        void ReleaseMaterial()
        {
            if (hzbMat)
            {
                GameObject.DestroyImmediate(hzbMat);
            }
        }

    }
    
    public class DrawIndirectRenderPass : ScriptableRenderPass
    {
        private RenderTargetIdentifier renderTarget;
        private RenderTargetIdentifier renderDepthTarget;
        
        public DrawIndirectRenderPass()
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
            renderDepthTarget = new RenderTargetIdentifier("_CameraDepthTexture");
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // cmd.ClearRenderTarget(true, true, Color.black);
        }
        
        public void Setup(RenderTargetIdentifier target)
        {
            renderTarget = target;
        }
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            int kernelIndex = 0;
            for (int i = 0; i < drawList.Count; i++)
            {
                var draw = drawList[i];
                CommandBuffer cmd = CommandBufferPool.Get("DrawManyThings");

                if (renderingData.cameraData.cameraType == CameraType.Game)
                {
                    cmd.SetRenderTarget(renderTarget, renderDepthTarget);
                    // ConfigureTarget(renderTarget, renderDepthTarget);
                    // ConfigureTarget(renderTarget);

                }
                else //为了适配场景摄像机和UI摄像机
                {
                    cmd.SetRenderTarget(renderTarget);
                    // ConfigureTarget(renderTarget);
                }

                if (draw.isActiveAndEnabled)
                {
                    kernelIndex += draw.DispatchKernel(kernelIndex);
                    draw.RenderWithCMD(cmd);
                }

                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        
        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }
}