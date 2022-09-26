using System;

namespace UnityEngine.Rendering.Universal.CloudShadow
{
    [Serializable, VolumeComponentMenu("Custom/HairShadow")]
    public class HairShadowVolume : VolumeComponent, IPostProcessComponent
    {

        public BoolParameter isEnable = new BoolParameter(false);
        
        public bool IsActive()
        {
            return isEnable.value;
        }
        
        public bool IsTileCompatible()
        {
            return false;
        }
        
    }
}