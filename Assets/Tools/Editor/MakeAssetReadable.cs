using System;
using System.Collections.Generic;
using System.IO;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;

public class MakeAssetReadable : OdinEditorWindow
{
    
    [MenuItem("Tools/MakeAssetReadable 打开文件可读写选项")]
    private static void OpenWindow()
    {
        GetWindow<MakeAssetReadable>().Show();
    }
    
    [Sirenix.OdinInspector.FolderPath]
    public string folderPath; //
    
    
    [Sirenix.OdinInspector.FilePath]
    public string filePath; //


    [PropertyOrder(2)]
    [Button(ButtonSizes.Large)]
    public void MakeReadable()
    {

        var fileList = new List<string>();
        
        if (!String.IsNullOrEmpty(folderPath))
        {
            string basePath = Path.Combine(Directory.GetCurrentDirectory(), folderPath);
            Director(basePath, fileList);
        }


        for (int i = 0; i < fileList.Count; i++)
        {
            var fileName = fileList[i];
            if (fileName.EndsWith(".meta"))
            {
                continue;
            }
            MakeAssetFileReadable(fileName);
        }

        if (!String.IsNullOrEmpty(filePath))
        {
            MakeAssetFileReadable(Path.Combine(Directory.GetCurrentDirectory(), filePath));
        }
        
        AssetDatabase.Refresh();
        
    }
    
    
    
    
    public static void MakeAssetFileReadable(string absolutePath)
    {

        if (absolutePath.EndsWith(".meta"))
        {
            return;
        }
        
        if (!absolutePath.EndsWith(".asset"))
        {
            Debug.LogWarning("文件不是 *.asset 无法修改: " + absolutePath);
            return;
        }
        
        // string filePath = Path.Combine(Directory.GetCurrentDirectory(), absolutePath);
        string filePath = absolutePath;
        filePath = filePath.Replace("/", "\\");
        string fileText = File.ReadAllText(filePath);
        fileText = fileText.Replace("m_IsReadable: 0", "m_IsReadable: 1");
        File.WriteAllText(filePath, fileText);
    }
    
    
    public void Director(string dir, List<string> list)
    {
        DirectoryInfo d = new DirectoryInfo(dir);
        FileInfo[] files = d.GetFiles();//文件
        DirectoryInfo[] directs = d.GetDirectories();//文件夹
        foreach (FileInfo f in files)
        {
            list.Add(f.FullName);//添加文件名到列表中  
        }
        //获取子文件夹内的文件列表，递归遍历  
        foreach (DirectoryInfo dd in directs)
        {
            Director(dd.FullName, list);
        } 
    }

}
