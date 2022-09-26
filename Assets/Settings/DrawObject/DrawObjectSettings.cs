using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

[CreateAssetMenu(fileName = "DrawObjectSettings", menuName = "ScriptableObjects/DrawObjectSettings", order = 1)]
public class DrawObjectSettings: ScriptableObject
{
    [SerializeField]
    public List<DrawObjSetting> settings;
}

[Serializable]
public class DrawObjSetting
{
    public string name;
    public string shaderTagId;
    public bool isOpaque;
    public RenderPassEvent renderPassEvent;
    public int renderPassAdd;
}
