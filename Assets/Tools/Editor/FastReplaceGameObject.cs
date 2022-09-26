using System.Collections.Generic;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;

public class FastReplaceGameObject : OdinEditorWindow
{
    [MenuItem("Tools/快速替换GameObject")]
    private static void OpenWindow()
    {
        GetWindow<FastReplaceGameObject>().Show();
    }

    
    [Title("要替换的GameObject")]
    public GameObject prefab;
    

    [Title("被替换掉的GameObjects")]
    public List<GameObject> goToReplace;



    [Button("开始替换")]
    public void StartReplace()
    {
        if (prefab == null)
        {
            Debug.LogError("替换失败:prefab 为空");
            return;
        }

        if (goToReplace == null || goToReplace.Count == 0)
        {
            Debug.LogError("替换失败:goToReplace 为空");
            return;
        }


        for (int i = 0; i < goToReplace.Count; i++)
        {
            var go = goToReplace[i];
            var trans = go.transform;
            var parent = go.transform.parent;
            GameObject newGo = PrefabUtility.InstantiatePrefab(prefab, parent) as GameObject;
            newGo.name = prefab.name;
            newGo.transform.SetPositionAndRotation(trans.position, trans.rotation);
            newGo.transform.localScale = trans.localScale;
        }
        
        
    }

    [Button("删除旧的")]
    public void DeleteOld()
    {
        for (int i = 0; i < goToReplace.Count; i++)
        {
            DestroyImmediate(goToReplace[i]);
        }
        goToReplace.Clear();
    }

}


