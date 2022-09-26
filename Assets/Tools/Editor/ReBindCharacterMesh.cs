using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;

public class ReBindCharacterMesh : OdinEditorWindow
{
    [MenuItem("Tools/ReBindCharacterMesh 重新绑定角色Mesh和材质")]
    private static void OpenWindow()
    {
        GetWindow<ReBindCharacterMesh>().Show();
    }


    public GameObject prefab;
    public bool isBattleCharacter;

    [Button]
    public void Rebind()
    {

        if (prefab == null)
        {
            Debug.LogError("Prefab为空，需要填入重新绑定的角色Prefab");
            return;
        }

        var isBattleStr = isBattleCharacter ? "战斗角色" : "展示角色";
            
        var name = prefab.name;
        var meshPath = $"Assets/HotUpdateResources/Meshes/Character/{name}/";
        var matSubPath = isBattleCharacter ? "CharactersCombat" : "Characters";

        var matPath = $"Assets/HotUpdateResources/Materials/{matSubPath}/{name}/{name}_";
        
        Debug.Log($"----------------------Start: 重新绑定 Mesh & Material {isBattleStr}, {name} ");
        
        // Debug.Log("MeshPath:" + meshPath);
        // Debug.Log("MatPath:" + matPath);

        var transform = prefab.transform;
        var childrenCount = transform.childCount;

        for (int i = 0; i < childrenCount; i++)
        {
            var child = transform.GetChild(i);
            ReBindMesh(child.gameObject, meshPath);
            RebindMaterial(child.gameObject, matPath);
        }
        

        EditorUtility.SetDirty(prefab);
        AssetDatabase.SaveAssets();
        
        Debug.Log($"-----------------------End: 重新绑定 Mesh & Material {isBattleStr}, {name}");

    }

    private void ReBindMesh(GameObject obj, string basePath)
    {
        var meshFilter = obj.GetComponent<MeshFilter>();
        var skinnedRender = obj.GetComponent<SkinnedMeshRenderer>();
        var meshPath = basePath + obj.name + ".asset";
        var mesh = AssetDatabase.LoadAssetAtPath<Mesh>(meshPath);

        if (meshFilter == null && skinnedRender == null)
        {
            return;
        }

        if (mesh == null)
        {
            Debug.LogError($"没有找到Mesh: {meshPath}");
            return;
        }

        if (meshFilter != null)
        {
            meshFilter.sharedMesh = mesh;
            Debug.Log("已绑定Mesh: " + obj.name);
        }

        if (skinnedRender != null)
        {
            skinnedRender.sharedMesh = mesh;
            Debug.Log("已绑定Mesh: " + obj.name);

        }
    }

    private void RebindMaterial(GameObject obj, string basePath)
    {
        var render = obj.GetComponent<Renderer>();
        var matPath = basePath + obj.name + ".mat";
        var mat = AssetDatabase.LoadAssetAtPath<Material>(matPath);

        if (render == null)
        {
            return;
        }

        if (mat == null)
        {
            Debug.LogError($"没有找到材质球:{matPath}");
            return;
        }
        
        if (obj.name == "Hair")
        {
            var depthMat = AssetDatabase.LoadAssetAtPath<Material>("Assets/HotUpdateResources/Materials/Characters/Character_Hair_Depth.mat");
            render.sharedMaterials = new[] {mat, depthMat};
            Debug.Log("已绑定Mat: " + obj.name);
        }
        else
        {
            render.sharedMaterial = mat;
            
            Debug.Log("已绑定Mat: " + obj.name);
        }
    }



}