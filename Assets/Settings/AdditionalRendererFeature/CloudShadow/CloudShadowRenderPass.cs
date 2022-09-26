using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.CloudShadow;

public class CloudShadowRenderPass : AdditionalRenderPass<CloudShadowVolume>
{
    
    public override RenderPassEvent renderPass => RenderPassEvent.BeforeRenderingPostProcessing;

    public override string shaderPath => "PostProcess/CloudShadow";

    private int _ViewPortRay = Shader.PropertyToID("_ViewPortRay");
    private int _Color = Shader.PropertyToID("_Color");
    private int _CloudTex = Shader.PropertyToID("_CloudTex");
    private int _StartXYSpeedXY = Shader.PropertyToID("_StartXYSpeedXY");
    private int _Scale = Shader.PropertyToID("_Scale");
    private int _Intensity = Shader.PropertyToID("_Intensity");


    public override void Render(ScriptableRenderContext context, CommandBuffer cmd, ref RenderingData renderingData)
    {
        
        var currentCamera = renderingData.cameraData.camera;
        var aspect = currentCamera.aspect;
        var far = currentCamera.farClipPlane;
        var right = currentCamera.transform.right;
        var up = currentCamera.transform.up;
        var forward = currentCamera.transform.forward;
        var halfFovTan = Mathf.Tan(currentCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);

        //计算相机在远裁剪面处的xyz三方向向量
        var rightVec = right * far * halfFovTan * aspect;
        var upVec = up * far * halfFovTan;
        var forwardVec = forward * far;

        //构建四个角的方向向量
        var topLeft = (forwardVec - rightVec + upVec);
        var topRight = (forwardVec + rightVec + upVec);
        var bottomLeft = (forwardVec - rightVec - upVec);
        var bottomRight = (forwardVec + rightVec - upVec);

        var viewPortRay = Matrix4x4.identity;

        viewPortRay.SetRow(0, bottomLeft);
        viewPortRay.SetRow(1, topLeft);
        viewPortRay.SetRow(2, topRight);
        viewPortRay.SetRow(3, bottomRight);
        //viewPortRay = viewPortRay * m_RotateXMatri;
        material.SetMatrix(_ViewPortRay, viewPortRay);

        material.SetColor(_Color, volumeComponent.m_Color.value);
        material.SetTexture(_CloudTex, volumeComponent.m_Tex.value);
        material.SetVector(_StartXYSpeedXY, volumeComponent.m_StartXYSpeedXY.value);
        material.SetFloat(_Scale, volumeComponent.m_Scale.value);
        material.SetFloat(_Intensity, volumeComponent.m_Intensity.value);

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

        //这里使用了DrawMesh的方式来替代Blit，因为Blit无法正确获取StencilBuffer
        cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, material, 0, 0);
        cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);

    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
}
