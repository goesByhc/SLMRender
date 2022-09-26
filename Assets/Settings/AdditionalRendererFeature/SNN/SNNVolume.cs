using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom/SNN")]
    public class SNNVolume : VolumeComponent, IPostProcessComponent
    {
        public ClampedFloatParameter offset = new ClampedFloatParameter(0, 0, 3);
        
        public ClampedFloatParameter halfWidth = new ClampedFloatParameter(0, 0, 5);

        public bool IsActive()
        {
            return offset.value > 0 && halfWidth.value > 0;
        }
        public bool IsTileCompatible()
        {
            return false;
        }

    }
}