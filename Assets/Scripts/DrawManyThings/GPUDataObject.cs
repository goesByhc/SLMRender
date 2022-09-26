using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class GPUDataObject : ScriptableObject
{
    public List<GPUItem> GPUItems;

    public GPUDataObject( List<GPUItem> gpuItems )
    {
        GPUItems = gpuItems;
    }

}