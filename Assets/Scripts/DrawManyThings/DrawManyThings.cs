using System;
using System.Collections;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;

public class DrawManyThings : MonoBehaviour
{
    
    public GameObject[] grassRoots;
    
    public GPUDataObject[] m_GPUDataObjects;
    
    public Mesh m_Mesh;
    public int m_SubMeshIndex = 0;
    public float clipAdjust = 0.7f;
    public float modelRadius = 0.5f;
    
    public Material m_DrawMat;

    private List<GPUInstancingObj> m_GPUInstancingObjs;

    private ComputeShader m_ComputeShader;


    private void Awake()
    {
        m_ComputeShader = (ComputeShader)Resources.Load("CullingComputeShader");
        
        if (m_ComputeShader == null)
        {
            Debug.LogError("DrawManyThings 找不到Shader CullingComputeShader");
        }
        

        if (m_GPUDataObjects != null)
        {
            m_GPUInstancingObjs = new List<GPUInstancingObj>(m_GPUDataObjects.Length);
            for(int i = 0; i < m_GPUDataObjects.Length; i++)
            {
                m_GPUInstancingObjs.Add(new GPUInstancingObj(m_ComputeShader,i, m_Mesh, m_SubMeshIndex ,m_DrawMat, m_GPUDataObjects[i]));
            }
        }
        else
        {
            m_GPUInstancingObjs = new List<GPUInstancingObj>();
        }

    }

    void Start()
    {
        DrawManyThingsRenderFeature.AddDrawData(this);
    }

    void Update()
    {
        // Render();
        for(int i = 0; i < m_GPUInstancingObjs.Count; i++)
        {
            m_GPUInstancingObjs[i].SetModelRadius(modelRadius);
            m_GPUInstancingObjs[i].SetClipAdjust(clipAdjust);
        }
    }

    public void AddDrawObj(GPUDataObject gpuDataObject)
    {
        int index = m_GPUInstancingObjs.Count;
        m_GPUInstancingObjs.Add(new GPUInstancingObj(m_ComputeShader,index, m_Mesh, m_SubMeshIndex ,m_DrawMat, gpuDataObject));
    }
    
    
    //返回在第几个obj和第几个Item
    public (int, int) AddDrawItem(GPUItem gpuItem)
    {
        GPUInstancingObj lastObj;
        
        if (m_GPUInstancingObjs.Count == 0)
        {
            lastObj = new GPUInstancingObj(m_ComputeShader,0, m_Mesh, m_SubMeshIndex ,m_DrawMat, new GPUDataObject(new List<GPUItem>()));
            m_GPUInstancingObjs.Add(lastObj);
        }
        
        lastObj = m_GPUInstancingObjs[m_GPUInstancingObjs.Count - 1];
        int objIndex = m_GPUInstancingObjs.Count - 1;
        if (!lastObj.CanAddItem())
        {
            objIndex = m_GPUInstancingObjs.Count;
            lastObj = new GPUInstancingObj(m_ComputeShader,objIndex, m_Mesh, m_SubMeshIndex ,m_DrawMat, new GPUDataObject(new List<GPUItem>()));
            m_GPUInstancingObjs.Add(lastObj);
        }
        int index = lastObj.AddItem(gpuItem);
        return (objIndex, index);
    }

    public int RemoveDrawItem(int objIndex, int index)
    {
        var obj = m_GPUInstancingObjs[objIndex];

        if (index == obj.GetInstanceCount() - 1)
        {
            obj.RemoveLast();
            return -1;
        }
        else
        {
            return obj.RemoveItem(index);
        }
    }

    public void UpdateDrawItem(int objIndex, int index, GPUItem item)
    {
        var obj = m_GPUInstancingObjs[objIndex];
        obj.UpdateItem(index, item);
    }


    public void Render()
    {
        for(int i = 0; i < m_GPUInstancingObjs.Count; i++)
        {
            m_GPUInstancingObjs[i].Render();
        }
    }

    public int DispatchKernel(int startKernel)
    {
        for(int i = 0; i < m_GPUInstancingObjs.Count; i++)
        {
            m_GPUInstancingObjs[i].DispatchKernel(startKernel + i);
        }

        return m_GPUInstancingObjs.Count;
    }


    public void RenderWithCMD(CommandBuffer cmd)
    {
        for(int i = 0; i < m_GPUInstancingObjs.Count; i++)
        {
            m_GPUInstancingObjs[i].RenderWithCMD(cmd);
        }
    }

    private void OnDestroy()
    {
        DrawManyThingsRenderFeature.RemoveDrawData(this);
        for (int i = 0; i < m_GPUInstancingObjs.Count; i++)
        {
            m_GPUInstancingObjs[i].Dispose();
        }
    }


#if UNITY_EDITOR

    [Button]
    public void CreateAsset()
    {
        if (EditorApplication.isPlaying)
        {
            Debug.LogWarning("需要退出播放模式");
            return;
        }
        
        if (grassRoots == null || grassRoots.Length == 0)
        {
            Debug.LogError("没有配置GrassRoot！");
            return;
        }

        var nameHash = new HashSet<string>();
        
        for (int i = 0; i < grassRoots.Length; i++)
        {
            var grassRoot = grassRoots[i];
            if (nameHash.Contains(grassRoot.name))
            {
                Debug.LogError("grassRoots中有重名的节点："+ grassRoot.name);
                return;
            }
        }



        var gpuDataPaths = new List<string>();

        for (int i = 0; i < grassRoots.Length; i++)
        {
            var grassRoot = grassRoots[i];
            
            GameObject[] plantGOs = CollectDataInScene(grassRoot);

            List<List<GPUItem>> GPUItems = new List<List<GPUItem>>();

            List<GPUItem> items = null;
        
            for (int j = 0; j < plantGOs.Length; j++)
            {
                //Debug.Log(plantGOs[i].name);

                if (items == null)
                {
                    items = new List<GPUItem>();
                    GPUItems.Add(items);
                }
            
                GPUItem gpuItem = new GPUItem(plantGOs[j].transform.localToWorldMatrix, plantGOs[j].transform.position);
                items.Add(gpuItem);

                if (items.Count == 4095)
                {
                    items = null;
                }
            }
            Scene scene = SceneManager.GetActiveScene ();
            var sceneName = scene.name;
        
            var path = "Assets/HotUpdateResources/ScriptableObjects/GPUData/GPUData_{0}_{1}_{2}.asset";

            for(int j = 0; j < GPUItems.Count; j++)
            {
                GPUDataObject asset = ScriptableObject.CreateInstance<GPUDataObject>();
                asset.GPUItems = GPUItems[j];

                var filePath = string.Format(path, sceneName, grassRoot.name, j);

                AssetDatabase.CreateAsset(asset, filePath);
                AssetDatabase.SaveAssets();
                Debug.Log(name + " has GPUitems count : " + asset.GPUItems.Count);
            }

        
            //Selection.activeObject = asset;
        
            
            for(int j = 0; j < GPUItems.Count; j++)
            {
                var filePath = string.Format(path, sceneName, grassRoot.name, j);
                // m_GPUDataObjects[j] = AssetDatabase.LoadAssetAtPath<GPUDataObject>(filePath);
                gpuDataPaths.Add(filePath);
            }
        
            grassRoot.SetActive(false);
        }

        AssetDatabase.Refresh();
        EditorUtility.FocusProjectWindow();

        m_GPUDataObjects = new GPUDataObject[gpuDataPaths.Count];
        for (int i = 0; i < gpuDataPaths.Count; i++)
        {
            m_GPUDataObjects[i] = AssetDatabase.LoadAssetAtPath<GPUDataObject>(gpuDataPaths[i]);
        }

    }
    
    
    public static GameObject[] CollectDataInScene(GameObject root)
    {
        int childrenCount = root.transform.childCount;

        GameObject[] children = new GameObject[childrenCount];
        for (int i = 0; i < childrenCount; ++i)
        {
            children[i] = root.transform.GetChild(i).gameObject;
        }

        Debug.Log(root + " has children gameObject: " + children.Length);

        return children;
    }
    
#endif

}
