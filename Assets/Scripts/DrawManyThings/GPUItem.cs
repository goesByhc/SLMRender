using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

[Serializable]
public struct GPUItem
{
    public Vector3 Position;
    public Matrix4x4 Matrix;

    public GPUItem( Matrix4x4 matrix, Vector3 position)
    {
        Matrix = matrix;
        Position = position;
    }
}

[Serializable]
public class GPUType
{
    public Material TypeMaterial;
    public Mesh TypeMesh;
    public uint TypeId;
    public uint TypeLOD;
}
