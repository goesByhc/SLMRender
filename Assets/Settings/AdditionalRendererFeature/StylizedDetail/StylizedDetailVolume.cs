using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom/StylizedDetailVolume")]
    public class StylizedDetailVolume : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("Controls the amount of contrast added to the image details.")]
        public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0f, 3f, true);

        [Tooltip("Controls smoothing amount.")]
        public ClampedFloatParameter blur = new ClampedFloatParameter(1f, 0, 2, true);

        [Tooltip("Controls structure within the image.")]
        public ClampedFloatParameter edgePreserve = new ClampedFloatParameter(1.25f, 0, 2, true);

        [Tooltip("The distance from the camera at which the effect starts."), Space]
        public MinFloatParameter rangeStart = new MinFloatParameter(10f, 0f);

        [Tooltip("The distance from the camera at which the effect reaches its maximum radius.")]
        public MinFloatParameter rangeEnd = new MinFloatParameter(30f, 0f);
        
        public bool IsActive()
        {
            return intensity.value > 0;
        }
        
        public bool IsTileCompatible()
        {
            return false;
        }
    }
}