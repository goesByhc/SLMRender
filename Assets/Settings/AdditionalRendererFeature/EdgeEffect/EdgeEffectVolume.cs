using System;

// 通用渲染管线程序集
namespace UnityEngine.Rendering.Universal
{
    // 实例化类     添加到Volume组件菜单中
    [Serializable, VolumeComponentMenu("Custom/EdgeEffect")]
    // 集成VolumeComponent组件和IPostProcessComponent接口，用以继承Volume框架
    public class EdgeEffectVolume : VolumeComponent, IPostProcessComponent
    {
        public ColorParameter edgeColor = new ColorParameter(Color.black);
        public ClampedFloatParameter sampleRange = new ClampedFloatParameter(0f, 0, 3);
        public ClampedFloatParameter normalDiffThreshold = new ClampedFloatParameter(1f, 0, 3);
        public ClampedFloatParameter depthDiffThreshold = new ClampedFloatParameter(1f, 0, 3);

        // 实现接口
        public bool IsActive() => sampleRange.value > 0;
        
        public bool IsTileCompatible()
        {
            return false;
        }
    }
}