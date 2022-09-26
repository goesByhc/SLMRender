using System;

namespace UnityEngine.Rendering.Universal.CloudShadow
{
    [Serializable, VolumeComponentMenu("Custom/CloudShadow")]
    public class CloudShadowVolume : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("叠加颜色")]
        public ColorParameter m_Color = new ColorParameter(Color.black);

        public ClampedFloatParameter m_Intensity = new ClampedFloatParameter(0f, 0f, 1f);
        
        [Tooltip("XY为起始位置，zw为XY移动速度")]
        public Vector4Parameter m_StartXYSpeedXY = new Vector4Parameter(new Vector4(0, 0, 100, 100));
        
        [Tooltip("贴图缩放大小，值越小越大")]
        public FloatParameter m_Scale = new FloatParameter(1f);

        public TextureParameter m_Tex = new TextureParameter(null);
        
        public bool IsActive()
        {
            return m_Intensity.value > 0;
        }
        
        public bool IsTileCompatible()
        {
            return false;
        }
        
    }
}