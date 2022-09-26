using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;

public class DrawObjectRenderFeature : ScriptableRendererFeature
{
    private LayerMask mask;
    private int stencilValue;
    private StencilState Stencil;
    private List<DrawObjectsPass> passes = new List<DrawObjectsPass>();
    public DrawObjectSettings settings;
    
    public override void Create()
    {
        var instance = CreateInstance<ForwardRendererData>();
        
        passes.Clear();
        
        for (int i = 0; i < settings.settings.Count; i++)
        {
            var settings = this.settings.settings[i];
            var pass = new DrawObjectsPass(settings.name, new ShaderTagId[] { new ShaderTagId(settings.shaderTagId) }, 
                settings.isOpaque, 
                settings.renderPassEvent + settings.renderPassAdd,
                settings.isOpaque ? RenderQueueRange.opaque :  RenderQueueRange.transparent,
                settings.isOpaque ? instance.opaqueLayerMask : instance.transparentLayerMask,
                Stencil, stencilValue);

            passes.Add(pass);
        }
        
    }
//添加pass到渲染队列
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        for (int i = 0; i < passes.Count; i++)
        {
            var pass = passes[i];
            renderer.EnqueuePass(pass);
        }
    }
    
    
    
}

