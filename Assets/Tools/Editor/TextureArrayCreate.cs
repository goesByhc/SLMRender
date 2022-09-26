using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;
using FilePathAttribute = Sirenix.OdinInspector.FilePathAttribute;

public class TextureArrayCreate : OdinEditorWindow
{

    
    [MenuItem("Tools/TextureArrayCreate 创建TextureArray")]
    private static void OpenWindow()
    {
        GetWindow<TextureArrayCreate>().Show();
    }

    public Texture2D[] ordinaryTextures = new Texture2D[4];

    [Button(ButtonSizes.Large)]
    private void CreateTextureArray()
    {


        if (ordinaryTextures.Length == 0)
        {
            Debug.LogError("需要设置图集");
            return;
        }

        int width = ordinaryTextures[0].width;
        int height = ordinaryTextures[0].height;

        for (int i = 0; i < ordinaryTextures.Length; i++)
        {
            var tex = ordinaryTextures[i];
            if (!tex.isReadable)
            {
                Debug.LogError("贴图需要开启读写:" + tex.name);
                return;
            }

            if (tex.width != width || tex.height != height)
            {
                Debug.LogError("贴图大小不统一:" + tex.name);
                return;
            }
        }
        
        
        EditorUtility.DisplayProgressBar("TextureArrayCreate", "正在创建图集", 0);

        
        // Create Texture2DArray
        Texture2DArray texture2DArray = new Texture2DArray(ordinaryTextures[0].width, ordinaryTextures[0].height, ordinaryTextures.Length, TextureFormat.RGBA32, true, false);
        // Apply settings
        texture2DArray.filterMode = FilterMode.Bilinear;
        texture2DArray.wrapMode = TextureWrapMode.Repeat;
        // Loop through ordinary textures and copy pixels to the
        // Texture2DArray
        for (int i = 0; i < ordinaryTextures.Length; i++)
        {
            texture2DArray.SetPixels(ordinaryTextures[i].GetPixels(0), i, 0);
        }
        // Apply our changes
        texture2DArray.Apply();

        var saveFilePath = SaveFileDialog.GetSaveAssetPath();

        // var path = SavePathTo + "/" + fileName + ".asset";

        var path = saveFilePath; 
        
        // Debug.Log("Pa");
        
        
        AssetDatabase.CreateAsset(texture2DArray, path);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        
        EditorUtility.ClearProgressBar();
        Debug.Log($"Create At {path}");
        // Set the texture to a material
        // objectToAddTextureTo.GetComponent<Renderer>()
            // .sharedMaterial.SetTexture("_MainTex", texture2DArray);
    }
}