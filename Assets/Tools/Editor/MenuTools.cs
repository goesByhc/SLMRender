using UnityEditor;
using UnityEngine;

public class MenuTools : MonoBehaviour
{
    [MenuItem("Tools/清理Material中废弃属性")]
    public static void ClearMaterialUnusedProperties()
    {
        var matGuids = AssetDatabase.FindAssets("t:Material", new string[] {"Assets/HotUpdateResources/Materials"});

        for (var idx = 0; idx < matGuids.Length; ++idx)
        {
            var guid = matGuids[idx];
            EditorUtility.DisplayProgressBar(string.Format("批处理中...{0}/{1}", idx + 1, matGuids.Length),
                "清理Material废弃属性", (idx + 1.0f) / matGuids.Length);

            var mat = AssetDatabase.LoadAssetAtPath<Material>(AssetDatabase.GUIDToAssetPath(guid));
            var matInfo = new SerializedObject(mat);
            var propArr = matInfo.FindProperty("m_SavedProperties");
            propArr.Next(true);
            do
            {
                if (!propArr.isArray)
                {
                    continue;
                }

                for (int i = propArr.arraySize - 1; i >= 0; --i)
                {
                    var prop = propArr.GetArrayElementAtIndex(i);
                    if (!mat.HasProperty(prop.displayName))
                    {
                        propArr.DeleteArrayElementAtIndex(i);
                    }
                }
            } while (propArr.Next(false));

            matInfo.ApplyModifiedProperties();
        }

        AssetDatabase.SaveAssets();
        EditorUtility.ClearProgressBar();

        Debug.Log("clear all material's properties is done!");
    }

    [MenuItem("Tools/清理Material中KeyWords")]
    public static void ClearMaterialKeyWords()
    {
        var matGuids = AssetDatabase.FindAssets("t:Material", new string[] {"Assets/HotUpdateResources/Materials"});

        for (var idx = 0; idx < matGuids.Length; ++idx)
        {
            var guid = matGuids[idx];
            EditorUtility.DisplayProgressBar(string.Format("批处理中...{0}/{1}", idx + 1, matGuids.Length),
                "清理Material keywords", (idx + 1.0f) / matGuids.Length);

            var mat = AssetDatabase.LoadAssetAtPath<Material>(AssetDatabase.GUIDToAssetPath(guid));
            var matInfo = new SerializedObject(mat);
            var propArr = matInfo.FindProperty("m_ShaderKeywords");
            propArr.stringValue = "";
            matInfo.ApplyModifiedProperties();
        }

        AssetDatabase.SaveAssets();
        EditorUtility.ClearProgressBar();

        Debug.Log("clear all material's keywords is done!");
    }


    [MenuItem("Tools/刷新AssetDatabase")]
    public static void DoRefreshAssetDatabase()
    {
        AssetDatabase.Refresh();
    }

    [MenuItem("Tools/Select Object Set Active %q")]
    public static void ActiveSelectObjects()
    {
        Object[] objects = Selection.objects;
        if (objects != null && objects.Length > 0)
        {
            for (int i = 0; i < objects.Length; i++)
            {
                if (objects[i] is GameObject)
                {
                    GameObject go = objects[i] as GameObject;
                    go.SetActive(!go.activeSelf);
                }
            }
        }
    }

    [MenuItem("Tools/重启Unity编辑器")]
    public static void ResetUnityEditor()
    {
        EditorApplication.OpenProject($"{Application.dataPath}/../");
    }

}