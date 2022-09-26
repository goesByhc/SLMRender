using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.CloudShadow;

public class HairShadowRenderPass : AdditionalRenderPass<HairShadowVolume>
{
    public override RenderPassEvent renderPass => RenderPassEvent.BeforeRenderingPrepasses;

    public override string shaderPath => "";

    public override bool IsActive(bool isSceneViewCamera, bool isBaseCamera, bool isPostProcessEnabled, ref RenderingData renderingData)
    {
        return volumeComponent.IsActive();
    }

    int kDepthBufferBits = 32;
    ShaderTagId shaderTag = new ShaderTagId("DepthHairOnly");
    FilteringSettings filtering;

    private int _InverseVPMatrix = Shader.PropertyToID("_InverseVPMatrix");
    
    protected override void Init()
    {
        base.Init();
        m_TemporaryColorTexture01.Init("_HairShadowDepth");
        filtering = new FilteringSettings(RenderQueueRange.opaque);
    }

    public override bool RefreshVolume()
    {
        bool isEnable = base.RefreshVolume();

        if (isEnable && volumeComponent != null && volumeComponent.IsActive())
        {
            Shader.EnableKeyword("_Character_Hair_Depth_Enable");
        }
        else
        {
            Shader.DisableKeyword("_Character_Hair_Depth_Enable");
        }

        return isEnable;
    }
    
    
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        base.OnCameraSetup(cmd, ref renderingData);
        var passInput = ScriptableRenderPassInput.Depth;
        ConfigureInput(passInput);
    }


    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {

        //Demo1 Use Color Buffer
        // descriptor = cameraTextureDescriptor;

        //Demo2 Use Depth Buffer
        colorDescriptor.colorFormat = RenderTextureFormat.Depth;
        // cameraTextureDescriptor.graphicsFormat = GraphicsFormat.None 
        colorDescriptor.msaaSamples = 1;
        colorDescriptor.depthBufferBits = kDepthBufferBits;
        cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, colorDescriptor);
        // cmd.SetGlobalTexture("_HairShadowDepth", hairShadowDepthIdentifier);

        ConfigureTarget(m_TemporaryColorTexture01.id);
        ConfigureClear(ClearFlag.All, Color.black);
        
    }

    public override void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData)
    {
        var drawSettings = CreateDrawingSettings(shaderTag, ref renderingData,
            renderingData.cameraData.defaultOpaqueSortFlags);

        var camera = renderingData.cameraData.camera;
        
        var vpMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
        Shader.SetGlobalMatrix(_InverseVPMatrix, vpMatrix.inverse);
        
        context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filtering);
    }

    //保留贴图到渲染帧结束
    public override void FrameCleanup(CommandBuffer cmd)
    {
       cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);
    }

}