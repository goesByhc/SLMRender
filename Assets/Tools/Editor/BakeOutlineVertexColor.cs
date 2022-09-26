using System.Collections;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;


public class BakeOutlineVertexColor : OdinEditorWindow
{
    [MenuItem("Tools/BakeOutlineVertexColor烘焙描边")]
    private static void OpenWindow()
    {
        GetWindow<BakeOutlineVertexColor>().Show();
    }
    
    [PropertyOrder(1)]
    [Space(12), HideLabel]
    [Title("MeshToBake", "")]
    public Mesh meshToBake;
    
    [PropertyOrder(2)]
    [Button(ButtonSizes.Large)]
    void BakeMesh()
    {
        bool isBaked = false;
    
        if (meshToBake == null)
        {
            return;
        }
        
        var task = new BakeOutlineTask(meshToBake, isEqualLength);
        task.BakeNormalToVertex(true, 1);
        
        if (!isBaked)
        {
            Debug.Log("BakeOutlineVertexColor Bake Fail");
        }
        
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }
    
    [PropertyOrder(3)]
    [Space(12), HideLabel]
    [Title("ObjToBake", "")]
    public Transform objToBake;


    [PropertyOrder(4)]
    [Title("isEqualLength 是否等长描边", "")]
    public bool isEqualLength = false;
    
    
    [PropertyOrder(5)]
    [Button(ButtonSizes.Large)]
    void BakeObjChildren()
    {
        var meshes = new HashSet<Mesh>();

        foreach (var skinnedMeshRenderer in objToBake.GetComponentsInChildren<SkinnedMeshRenderer>())
        {
            meshes.Add(skinnedMeshRenderer.sharedMesh);
        }

        foreach (var meshFilter in objToBake.GetComponentsInChildren<MeshFilter>())
        {
            meshes.Add(meshFilter.sharedMesh);
        }


        float index = 0;
        
        foreach (var mesh in meshes)
        {
            var path = AssetDatabase.GetAssetPath(mesh);

            if (path.EndsWith("FBX") || path.EndsWith("fbx"))
            {
                Debug.LogWarning("跳过烘焙FBX: " + mesh.name);
                continue;
            }

            var task = new BakeOutlineTask(mesh, isEqualLength);
            task.BakeNormalToVertex(true, index / meshes.Count);
            index++;
        }

        AssetDatabase.Refresh();
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        if (meshes.Count == 0)
        {
            Debug.Log("需要SkinnedMeshRenderer或者MeshFilter");
        }
    }
    
    
    
    [PropertyOrder(6)]
    [Button(ButtonSizes.Large)]
    void SaveBakedAsset()
    {
        var meshes = new HashSet<Mesh>();

        foreach (var skinnedMeshRenderer in objToBake.GetComponentsInChildren<SkinnedMeshRenderer>())
        {
            meshes.Add(skinnedMeshRenderer.sharedMesh);
        }

        foreach (var meshFilter in objToBake.GetComponentsInChildren<MeshFilter>())
        {
            meshes.Add(meshFilter.sharedMesh);
        }


        float index = 0;
        
        foreach (var mesh in meshes)
        {
            var path = AssetDatabase.GetAssetPath(mesh);
            
            // Sisus.Debugging.Debug.Log("Mesh.name:" + mesh.name);

            if (path.EndsWith("FBX") || path.EndsWith("fbx"))
            {
                Mesh tempMesh = Instantiate(mesh);
                var task = new BakeOutlineTask(tempMesh, isEqualLength);
                task.BakeNormalToVertex(true, index / meshes.Count);
                index++;

                var nameSplitIndex = path.LastIndexOf("/");
                var newPath = path.Substring(0, nameSplitIndex + 1);
                newPath += mesh.name + ".asset";
                // var save_path = EditorUtility.SaveFilePanelInProject("Save Mesh As", mesh.name + ".asset", "asset", "Save edited mesh to");
                AssetDatabase.CreateAsset(tempMesh, newPath);
                Debug.Log("创建新的MeshAsset: " + newPath);
            }

            // AssetDatabase.DeleteAsset(AssetDatabase.GetAssetPath(mesh));
            index++;
        }

        AssetDatabase.Refresh();

        if (meshes.Count == 0)
        {
            Debug.Log("需要SkinnedMeshRenderer或者MeshFilter");
        }
    }

    public class BakeOutlineTask
    {
        private List<Vector3> vertices; //所有顶点的位置坐标
        private List<int> triangles; //所有三角形的顶点索引

        private Dictionary<Vector3, List<Vector3>> vertByTriangle; //key：顶点索引，Value:包含这个顶点的[三角形面]的法线集合

        private Mesh mesh;
        private Color[] colors;
        private bool isEqualLength;

        public BakeOutlineTask(Mesh mesh, bool isEqualLength)
        {
            this.mesh = mesh;
            this.isEqualLength = isEqualLength;
        }

        public void BakeNormalToVertex(bool checkReadable, float progress)
        {
            if (!mesh.isReadable && checkReadable)
            {
                Debug.LogError("Mesh不可读写: " + mesh.name);
                return;
            }

            Debug.Log("Bake Mesh: " + mesh.name);

            EditorUtility.DisplayProgressBar("BakeOutlineVertexColor烘焙描边", "Bake Mesh: " + mesh.name, progress);
            
            vertices = new List<Vector3>(mesh.vertices);
            triangles = new List<int>(mesh.triangles);
            vertByTriangle = new Dictionary<Vector3, List<Vector3>>(); //

            // if (mesh.colors.Length < vertices.Count)
            // {
            // Debug.LogError($"MeshColor长度不足 vertices: {mesh.vertices.Length} colors:{mesh.colors.Length}");
            // return;
            // }
            colors = new Color[mesh.vertices.Length];

            // TestCodeBake();
            
            BakeOutlineLengthToVertexColor();
            BakeSmoothedNormalToVertexColor();

            mesh.colors = colors;
            // mesh.UploadMeshData(true);
            
            EditorUtility.SetDirty(mesh);
            
            EditorUtility.ClearProgressBar();
        }
        

        void BakeSmoothedNormalToVertexColor()
        {
            //声明一个Vector3数组，长度与mesh.normals一样，用于存放
            //与mesh.vertices中顶点一一对应的光滑处理后的法线值
            Vector3[] meshNormals = new Vector3[mesh.normals.Length];
            Dictionary<Vector3, Vector3> normalMaps = new Dictionary<Vector3, Vector3>();

            Vector3 normalAdds;
            for (int i = 0; i < mesh.normals.Length; i++)
            {
                var vertice = mesh.vertices[i];
                var normal = mesh.normals[i];
                if (normalMaps.TryGetValue(vertice, out normalAdds))
                {
                    normalMaps[vertice] = normalAdds + normal;
                }
                else
                {
                    normalMaps.Add(vertice, normal);
                }
            }

            for (int i = 0; i < mesh.normals.Length; i++)
            {
                if (normalMaps.TryGetValue(mesh.vertices[i], out normalAdds))
                {
                    meshNormals[i] = normalAdds.normalized;
                }
            }

            //构建模型空间→切线空间的转换矩阵
            ArrayList OtoTMatrixs = new ArrayList();
            for (int i = 0; i < mesh.normals.Length; i++)
            {
                Vector3[] OtoTMatrix = new Vector3[3];
                OtoTMatrix[0] = new Vector3(mesh.tangents[i].x, mesh.tangents[i].y, mesh.tangents[i].z);
                OtoTMatrix[1] = Vector3.Cross(mesh.normals[i], OtoTMatrix[0]);
                OtoTMatrix[1] = new Vector3(OtoTMatrix[1].x * mesh.tangents[i].w, OtoTMatrix[1].y * mesh.tangents[i].w,
                    OtoTMatrix[1].z * mesh.tangents[i].w);
                OtoTMatrix[2] = mesh.normals[i];
                OtoTMatrixs.Add(OtoTMatrix);
            }

            //将meshNormals数组中的法线值一一与矩阵相乘，求得切线空间下的法线值
            for (int i = 0; i < meshNormals.Length; i++)
            {
                Vector3 tNormal;
                tNormal = Vector3.zero;
                tNormal.x = Vector3.Dot(((Vector3[]) OtoTMatrixs[i])[0], meshNormals[i]);
                tNormal.y = Vector3.Dot(((Vector3[]) OtoTMatrixs[i])[1], meshNormals[i]);
                tNormal.z = Vector3.Dot(((Vector3[]) OtoTMatrixs[i])[2], meshNormals[i]);
                meshNormals[i] = tNormal;
            }

            //新建一个颜色数组把光滑处理后的法线值存入其中

            for (int i = 0; i < colors.Length; i++)
            {
                var length = isEqualLength ? 1 : colors[i].r;
                colors[i].r = meshNormals[i].x * length * 0.5f + 0.5f;
                colors[i].g = meshNormals[i].y * length * 0.5f + 0.5f;
                colors[i].b = meshNormals[i].z * length * 0.5f + 0.5f;
                colors[i].a = 1;
            }
        }


        void BakeOutlineLengthToVertexColor()
        {
            for (int i = 0; i < triangles.Count; i += 3)
            {
                var vertexIdx0 = triangles[i];
                var vertexIdx1 = triangles[i + 1];
                var vertexIdx2 = triangles[i + 2];

                var vert0 = vertices[vertexIdx0];
                var vert1 = vertices[vertexIdx1];
                var vert2 = vertices[vertexIdx2];

                var normal = CalVertexNormal(vert0, vert1, vert2);
                AddNormal(vert0, normal);
                AddNormal(vert1, normal);
                AddNormal(vert2, normal);
            }

            List<Vector3> normalList;
            for (int i = 0; i < mesh.vertices.Length; i++)
            {
                if (vertByTriangle.TryGetValue(mesh.vertices[i], out normalList))
                {
                    Vector3 totalNormal = Vector3.zero;
                    ;
                    foreach (var normal in normalList)
                    {
                        totalNormal += normal;
                    }

                    totalNormal /= normalList.Count;
                    var length = totalNormal.magnitude;

                    if (length > 1)
                    {
                        Debug.LogError("Bake outline Length > 1");
                    }

                    colors[i].r = Mathf.Max(Mathf.Min(length * 1.3f, 1), 0.35f);
                    // colors[i].g = colors[i].g * length;
                    // colors[i].b = colors[i].b * length;
                    // colors[i].a = length;
                }
                else
                {
                    Debug.LogError("BakeOutlineLengthToVertexColor Error 找不到顶点");
                }
            }
            
        }

        void AddNormal(Vector3 vertexIndex, Vector3 normal)
        {
            List<Vector3> list;
            if (!vertByTriangle.TryGetValue(vertexIndex, out list))
            {
                list = new List<Vector3>();
                list.Add(normal);
                vertByTriangle.Add(vertexIndex, list);
            }
            else
            {
                list.Add(normal);
            }
        }

        //计算这个三个点组成面的法线
        Vector3 CalVertexNormal(Vector3 vert0, Vector3 vert1, Vector3 vert2)
        {
            Vector3 D1 = (vert1 - vert0).normalized;
            Vector3 D2 = (vert2 - vert1).normalized;
            Vector3 normal = Vector3.Cross(D1, D2);
            return normal;
        }
    }
}