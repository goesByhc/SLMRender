using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class GPUInstancingObj
{
    // private static int s_BaseMapId = Shader.PropertyToID("_BaseMap");
    // private static int s_BaseMapIndexId = Shader.PropertyToID("_IndexForBasemap");

    private Mesh m_Mesh;
    private Material m_DrawMat;
    private ComputeShader m_ComputeShader;
    private int m_SubMeshIndex;

    private ComputeBuffer m_BufferWithArgs;
    private ComputeBuffer m_PosBuffer;
    private ComputeBuffer m_PosVisibleBuffer;

    private uint[] m_Args = new uint[5] {0, 0, 0, 0, 0}; // The GPU buffer containing the arguments for how many instances of this mesh to draw.

    private int m_CSCullingID;
    private Bounds m_Bounds = new Bounds(Vector3.zero, Vector3.one * 100000);
    
    public static int maxCount = 4096; //固定个数为了方便增删
    private int m_CountsSqrted = 64;
    
    private MaterialPropertyBlock m_MaterialPropertyblock;

    private int gpuItemStride = (4 * 4 + 3) * 4; // float3 + float4x4。 StructuredBuffer的存储非常紧凑。
    private int instanceCount = 0;

    private GPUItem[] positions = new GPUItem[4095];

    private float modelRadius = 0.5f;
    private float clipAdjust = 0.7f;

    public GPUInstancingObj(ComputeShader computeShader, int csIndex, Mesh mesh, int subMeshIndex, Material mat, GPUDataObject gpuDataObject)
    {

        
        m_ComputeShader = computeShader;
        m_Mesh = mesh;
        m_DrawMat = mat;
        m_SubMeshIndex = subMeshIndex;

        positions = ReadData(gpuDataObject);
        m_CountsSqrted = Mathf.CeilToInt(Mathf.Sqrt(instanceCount));

        // 实测这样粗暴的直接指定个数（不用 append 或 InterlockedAdd）也能接近想要的效果，但帧率要更低。
        //m_Args[1] = (uint)instanceCount;
        //m_BufferWithArgs.SetData(m_Args);

        m_Args = new uint[5] {0, 0, 0, 0, 0};
        m_BufferWithArgs = new ComputeBuffer(5, sizeof(uint), ComputeBufferType.IndirectArguments);
        //m_BufferWithArgs = new ComputeBuffer(1, m_Args.Length * sizeof(uint), ComputeBufferType.IndirectArguments); // 跟上面功能一模一样
        m_Args[0] = (uint) m_Mesh.GetIndexCount(0);
        m_Args[1] = (uint) instanceCount;
        m_Args[2] = (uint) m_Mesh.GetIndexStart(0);
        m_Args[3] = (uint) m_Mesh.GetBaseVertex(0);
        m_Args[4] = 0;
        m_BufferWithArgs.SetData(m_Args);

        m_PosBuffer = new ComputeBuffer(maxCount, gpuItemStride); // float3 + float4x4。 StructuredBuffer的存储非常紧凑。
        m_PosBuffer.SetData(positions);

        /* 实测：一个ComputeShader 的 Kernel 对应的ComputeBuffer，如果该Kernel在一帧里被Dispatch()多次，那么ComputeBuffer只能得到最后一次执行的值。
         * 
         原因:
         1. DrawMeshInstancedIndirect()并非立即执行，而是在一个队列里，一帧中某个时间被Unity安排执行，DrawIndirect之间的顺序会保证，但是想要依次: Kernel->DrawIndirect->Kernel->DrawIndirect 不行。
         2. ComputeBuffer 在每次在Dispatch() Kernel执行后都会被改掉， 即便已经通过MaterialPropertyBlock设置给DrawMeshInstancedIndirect()，还是会改，说明mpb只存一个指针。
        */
        // m_CSCullingID = m_ComputeShader.FindKernel("CSCulling_" + csIndex.ToString());
        m_CSCullingID = m_ComputeShader.FindKernel("CSCulling_" + csIndex);

        //m_ComputeShader.SetBuffer(m_CSCullingID, "bufferWithArgs", m_BufferWithArgs); // 如果用InterlockedAdd 的方式，需要这个
        m_ComputeShader.SetBuffer(m_CSCullingID, "posAllBuffer", m_PosBuffer);

        m_PosVisibleBuffer = new ComputeBuffer(maxCount, gpuItemStride, ComputeBufferType.Append);
        m_ComputeShader.SetBuffer(m_CSCullingID, "posVisibleBuffer", m_PosVisibleBuffer);
        
        m_MaterialPropertyblock = new MaterialPropertyBlock();
        
    }

    public void DispatchKernel(int csIndex)
    {
        m_CSCullingID = m_ComputeShader.FindKernel("CSCulling_" + csIndex);
        m_ComputeShader.SetBuffer(m_CSCullingID, "posAllBuffer", m_PosBuffer);
        m_ComputeShader.SetBuffer(m_CSCullingID, "posVisibleBuffer", m_PosVisibleBuffer);
    }

    public void SetModelRadius(float radius)
    {
        modelRadius = radius;
    }

    public void SetClipAdjust(float adjust)
    {
        clipAdjust = adjust;
    }


    public void UpdateItem(int index, GPUItem item)
    {
        if (index >= instanceCount || index < 0)
        {
            Debug.LogError($"GPUInstancingObj UpdateItem indexError, index: {index}, count: {instanceCount}");
        }
        positions[index] = item;
    }

    public int AddItem(GPUItem gpuItem)
    {
        positions[instanceCount] = gpuItem;
        instanceCount++;
        UpdateRenderCount();
        return instanceCount - 1;
    }

    private void UpdateRenderCount()
    {
        m_Args[1] = (uint) instanceCount;
        m_CountsSqrted = Mathf.CeilToInt(Mathf.Sqrt(instanceCount));
        m_BufferWithArgs.SetData(m_Args);
        m_PosBuffer.SetData(positions);
    }

    //返回替换位置的元素
    public int RemoveItem(int index)
    {
        if (index >= instanceCount || index < 0)
        {
            Debug.LogError($"GPUInstancingObj RemoveItem indexError, index: {index}, count: {instanceCount}");
            return -1;
        }

        if (index == instanceCount - 1)
        {
            Debug.LogError("GPUInstancingObj RemoveItem index == instanceCount - 1, Place Use RemoveLast()");
            return -1;
        }
        
        positions[index] = positions[instanceCount - 1];
        RemoveLast();
        return instanceCount;
    }

    public void RemoveLast()
    {
        instanceCount--;
        UpdateRenderCount();
    }

    public int GetInstanceCount()
    {
        return instanceCount;
    }

    public bool CanAddItem()
    {
        return instanceCount < maxCount;
    }

    public void Dispose()
    {
        ReleaseComputeBuffer(m_BufferWithArgs);
        ReleaseComputeBuffer(m_PosBuffer);
        ReleaseComputeBuffer(m_PosVisibleBuffer);
    }

    private void ReleaseComputeBuffer(ComputeBuffer computeBuffer)
    {
        computeBuffer.Release();
        computeBuffer = null;
    }


    public void Render()
    {
        DoCulling();

        //m_BufferWithArgs.GetData(m_Args);
        //Debug.Log("draw m_PosVisibleBuffer.count = " + m_PosVisibleBuffer.count + " args : " + m_Args[1]); // 检查剔除的情况

        m_MaterialPropertyblock.Clear();
        m_MaterialPropertyblock.SetBuffer("posVisibleBuffer", m_PosVisibleBuffer);
        //m_DrawMat.SetBuffer("posVisibleBuffer", m_VisibleCountBuffer); // 建议用 MaterialProertyBlock。因为DrawIndirect()并非立即执行，而是有队列，Material.SetBuffer()会被后续的SetBuffer()改掉。

        // m_MaterialPropertyblock.SetTexture(s_BaseMapId, m_BaseMap);
        // m_MaterialPropertyblock.SetVector(s_BaseMapIndexId, m_IndexForBaseMap);

        Graphics.DrawMeshInstancedIndirect(m_Mesh, m_SubMeshIndex, m_DrawMat, m_Bounds, m_BufferWithArgs, 0,
            m_MaterialPropertyblock, ShadowCastingMode.Off, false);
    }

    
    public void RenderWithCMD(CommandBuffer cmd)
    {
        DoCulling();

        //m_BufferWithArgs.GetData(m_Args);
        // Debug.Log("draw m_PosVisibleBuffer.count = " + m_PosVisibleBuffer.count + " args : " + m_Args[1]); // 检查剔除的情况

        m_MaterialPropertyblock.Clear();
        m_MaterialPropertyblock.SetBuffer("posVisibleBuffer", m_PosVisibleBuffer);
        //m_DrawMat.SetBuffer("posVisibleBuffer", m_VisibleCountBuffer); // 建议用 MaterialProertyBlock。因为DrawIndirect()并非立即执行，而是有队列，Material.SetBuffer()会被后续的SetBuffer()改掉。

        // m_MaterialPropertyblock.SetTexture(s_BaseMapId, m_BaseMap);
        // m_MaterialPropertyblock.SetVector(s_BaseMapIndexId, m_IndexForBaseMap);

        // cmd.DrawMeshInstancedIndirect(m_Mesh, m_SubMeshIndex, m_DrawMat, m_Bounds, m_BufferWithArgs, 0,
        //     m_MaterialPropertyblock, ShadowCastingMode.Off, false);
        
        // Debug.Log("m_BufferWithArgs count:" + m_BufferWithArgs.count);

        cmd.DrawMeshInstancedIndirect(m_Mesh, m_SubMeshIndex, m_DrawMat, 0, m_BufferWithArgs, 0, m_MaterialPropertyblock);
    }
    
    
    void DoCulling()
    {
        //m_Args[1] = 0; // Compute Shader 中用InterlockedAdd() 进行自增得到实际要绘制的个数。
        //m_BufferWithArgs.SetData(m_Args);
        m_PosVisibleBuffer.SetCounterValue(0);

        m_ComputeShader.SetFloat("modelRadius", modelRadius);
        m_ComputeShader.SetFloat("clipAdjust", clipAdjust);

        m_ComputeShader.SetVector("cmrPos", Camera.main.transform.position);
        m_ComputeShader.SetVector("cmrDir", Camera.main.transform.forward);
        m_ComputeShader.SetFloat("cmrHalfFov", Camera.main.fieldOfView / 2);
        Matrix4x4 ProjectionMatrixInShader = GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, false); // C sharp 中Unity都使用OpenGL那套矩阵变换。但是Shader中则根据平台不同有不同的投影矩阵。于是需要将它转化为Shader中实际的矩阵
        var m = ProjectionMatrixInShader * Camera.main.worldToCameraMatrix;
        m_ComputeShader.SetMatrix("matrix_VP", m);
        m_ComputeShader.SetInt("countPerDimention", m_CountsSqrted);
        // m_ComputeShader.SetTextureFromGlobal(m_CSCullingID, "_DepthTexture", "_CameraDepthTexture");

        float threadsPerDimentionPerGroup = 8f; // 二维线程组中每一维的线程个数。使用float 是为了使用 CeilToInt()。对于非2d纹理操作而言，[8,8,1]与[64,1,1]其实没有性能上的差别。
        int dispatchCountPerDimention = Mathf.CeilToInt(m_CountsSqrted / threadsPerDimentionPerGroup);
        m_ComputeShader.Dispatch(m_CSCullingID, dispatchCountPerDimention, dispatchCountPerDimention, 1);

        ComputeBuffer.CopyCount(m_PosVisibleBuffer, m_BufferWithArgs, 4); // copys to args[1]
        //m_Args[1] = (uint)m_VisibleCountBuffer.count; // 存在多个DrawMeshInstancedIndirect()时，这样做得到的m_Args[1]并不准确。症状是有些草没剔除掉。
        //m_BufferWithArgs.SetData(m_Args);
    }

    GPUItem[] ReadData(GPUDataObject dataObject)
    {
        // int instanceCount = 0;
        // instanceCount += dataObject.GPUItems.Count;
        Debug.Log("data count : " + dataObject.GPUItems.Count);

        instanceCount = dataObject.GPUItems.Count;
        for (int j = 0; j < instanceCount; j++)
        {
            positions[j] = dataObject.GPUItems[j];
        }

        return positions;
    }


    GPUItem[] ReadData(GPUDataObject[] dataOBjects)
    {
        int instanceCount = 0;
        for (int i = 0; i < dataOBjects.Length; i++)
        {
            instanceCount += dataOBjects[i].GPUItems.Count;
            Debug.Log("data count : " + dataOBjects[i].GPUItems.Count);
        }

        GPUItem[] positions = new GPUItem[instanceCount];

        int indexBias = 0;
        for (int i = 0; i < dataOBjects.Length; i++)
        {
            indexBias += (i >= 1 ? dataOBjects[i - 1].GPUItems.Count : 0);
            int itemCount = dataOBjects[i].GPUItems.Count;
            for (int j = 0; j < itemCount; j++)
            {
                positions[indexBias + j] = dataOBjects[i].GPUItems[j];
            }
        }

        Debug.Log("total data count : " + positions.Length);
        return positions;
    }
}