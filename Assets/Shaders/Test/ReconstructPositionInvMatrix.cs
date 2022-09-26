/********************************************************************
 FileName: ReconstructPositionInvMatrix.cs
 Description:从深度图构建世界坐标，逆矩阵方式
 Created: 2018/06/10
 history: 10:6:2018 13:09 by puppet_master
 https://blog.csdn.net/puppet_master
*********************************************************************/

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class ReconstructPositionInvMatrix : MonoBehaviour {
 
    private Material postEffectMat = null;
    private Camera currentCamera = null;

    public Material objectMat = null;
    
    void Awake()
    {
        currentCamera = GetComponent<Camera>();
    }
 
    void OnEnable()
    {

        // if (Application.isPlaying)
        // {
            // currentCamera = URPCamera.SceneCamera;
        // }
        // else
        // {
            // currentCamera = SceneView.lastActiveSceneView.camera;
        // }
        
        if (currentCamera != null)
        {
            Debug.Log("currentCamera name:" + currentCamera.gameObject.name);
        }
        
        if (postEffectMat == null)
            postEffectMat = new Material(Shader.Find("DepthTexture/ReconstructPositionInvMatrix"));
        currentCamera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void Update()
    {
        if (objectMat != null)
        {
            var vpMatrix = currentCamera.projectionMatrix * currentCamera.worldToCameraMatrix;
            objectMat.SetMatrix("_InverseVPMatrix", vpMatrix.inverse);
            
            Shader.SetGlobalMatrix("_InverseVPMatrix", vpMatrix.inverse);
        }

    }

    void OnDisable()
    {
        currentCamera.depthTextureMode &= ~DepthTextureMode.Depth;
    }
 
    // void OnRenderImage(RenderTexture source, RenderTexture destination)
    // {
    //     if (postEffectMat == null)
    //     {
    //         Graphics.Blit(source, destination);
    //     }
    //     else
    //     {
    //         var vpMatrix = currentCamera.projectionMatrix * currentCamera.worldToCameraMatrix;
    //         postEffectMat.SetMatrix("_InverseVPMatrix", vpMatrix.inverse);
    //         Graphics.Blit(source, destination, postEffectMat);
    //     }
    // }
}