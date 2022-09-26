using System;
using System.Collections.Generic;
using System.IO;
using NUnit.Framework;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

namespace SlmDemoEditor.AssetsImport
{
    public class CharacterMeshImport : AssetPostprocessor
    {
        private void OnPostprocessModel(GameObject root)
        {
            var assetPath = assetImporter.assetPath;
            //处理mesh文件
            ExportMesh(root, assetPath);
        }

        [MenuItem("美术/导出选中的mesh %M")]
        static void MenuExportMesh()
        {
            var selectObjs = Selection.objects;
            if (selectObjs == null)
                return;

            foreach (var selectObj in selectObjs)
            {
                var path = AssetDatabase.GetAssetPath(selectObj);
                var gameObject = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                ExportMesh(gameObject, path, false);
            }
        }
        
        private static void ExportMesh(GameObject root, string path, bool isCheckPath = true)
        {
            if (path.Contains("RAW/Model/Character"))
            {
                var strArray = root.name.Split('@');
                if (strArray.Length == 0)
                {
                    return;
                }

                var fullName = $"Assets/HotUpdateResources/Meshes/Character/{strArray[0]}";
                if (!Directory.Exists(fullName))
                {
                    Directory.CreateDirectory(fullName);
                }

                var meshes = new List<Mesh>();
                foreach (var mesh in root.GetComponentsInChildren<MeshFilter>())
                {
                    var meshPath = $"{fullName}/{mesh.name}.asset";
                    if(File.Exists(meshPath) && isCheckPath)
                        continue;

                    meshes.Add(mesh.sharedMesh);
                }
                
                foreach (var mesh in root.GetComponentsInChildren<SkinnedMeshRenderer>())
                {
                    var meshPath = $"{fullName}/{mesh.name}.asset";
                    if(File.Exists(meshPath) && isCheckPath)
                        continue;
                    
                    meshes.Add(mesh.sharedMesh);
                }

                float index = 0;
                
                foreach (var mesh in meshes)
                {
                    var meshPath = $"{fullName}/{mesh.name}.asset";
                    var meshTemp = GameObject.Instantiate(mesh);
                    var task = new BakeOutlineVertexColor.BakeOutlineTask(meshTemp, false);
                    task.BakeNormalToVertex(false, index / meshes.Count);
                    AssetDatabase.CreateAsset(meshTemp, meshPath);
                    MakeFileReadable(meshPath);
                    index++;
                }
                
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
            }
        }

        public static void MakeFileReadable(string assetPath)
        {
            string filePath = Path.Combine(Directory.GetCurrentDirectory(), assetPath);
            filePath = filePath.Replace("/", "\\");
            string fileText = File.ReadAllText(filePath);
            fileText = fileText.Replace("m_IsReadable: 0", "m_IsReadable: 1");
            File.WriteAllText(filePath, fileText);
        }

    }
}