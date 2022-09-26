using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom/FXAA")]
    public sealed class FXAA : VolumeComponent, IPostProcessComponent
    {
        [Header("开启FXAA"),Tooltip("是否开启")]
        public BoolParameter isEnable = new BoolParameter(true); 
        
        public bool IsActive() => isEnable.value && isEnable.overrideState;

        public bool IsTileCompatible() => false;
    }
}