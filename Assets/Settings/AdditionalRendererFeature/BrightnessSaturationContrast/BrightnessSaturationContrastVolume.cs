using System;

// 通用渲染管线程序集
namespace UnityEngine.Rendering.Universal
{
    // 实例化类     添加到Volume组件菜单中
    [Serializable, VolumeComponentMenu("Custom/BrightnessSaturationContrast")]
    // 集成VolumeComponent组件和IPostProcessComponent接口，用以继承Volume框架
    public class BrightnessSaturationContrastVolume : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("亮度")]
        public ClampedFloatParameter brightness = new ClampedFloatParameter(1f, 0, 3);
        [Tooltip("饱和度")]
        public ClampedFloatParameter saturation = new ClampedFloatParameter(1f, 0, 3);
        [Tooltip("对比度")]
        public ClampedFloatParameter contrast = new ClampedFloatParameter(1f, 0, 3);

        // 实现接口
        public bool IsActive() => brightness.value != 1 || saturation.value != 1 || contrast.value != 1;
        
        public bool IsTileCompatible()
        {
            return false;
        }
    }
}