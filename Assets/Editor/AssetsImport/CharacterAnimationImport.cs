using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using Object = System.Object;

namespace SlmDemoEditor.AssetsImport
{
    public class AnimationImport : AssetPostprocessor
    {
        private static HashSet<string> loopedAnimationNames = new HashSet<string>() {"act_idle", "act_run", "act_stun", "com_idle", "com_walk" };
        
        private void OnPostprocessAnimation(GameObject root, AnimationClip clip)
        {
            var assetPath = assetImporter.assetPath;
            //处理角色动画文件 todo:需要和本地文件合并
            ExportAnimation(root, clip, clip.name,assetPath);
        }
        
        [MenuItem("美术/导出选中的动画 %K")] 
        static void MenuExportAnimation()
        {
            var selectObjs = Selection.objects;
            if (selectObjs == null)
                return;

            foreach (var selectObj in selectObjs)
            {
                var path = AssetDatabase.GetAssetPath(selectObj);
                var assets = AssetDatabase.LoadAllAssetsAtPath(path);
                foreach (var asset in assets)
                {
                    if (asset is AnimationClip clip && asset.name.IndexOf("preview", StringComparison.Ordinal) < 0)
                    {
                        ExportAnimation(selectObj, clip, path, asset.name,false);
                    }
                }
            }
        }
        
        
        private static void ExportAnimation(Object root, AnimationClip clip, string path, string clipName, bool isCheckPath = true)
        {
            if (path.Contains("RAW/Animation/Character"))
            {
                var directoryInfo = Directory.GetParent(path);
                var fullName = directoryInfo.FullName;
                fullName = fullName.Replace(@"\", "/");
                var index = fullName.IndexOf("RAW/Animation/", StringComparison.Ordinal);
                fullName = fullName.Substring(index + "RAW/Animation/".Length);
                fullName = $"Assets/HotUpdateResources/Animations/{fullName}";

                var animPath = $"{fullName}/{clipName}.anim";
                if (isCheckPath && File.Exists(animPath))
                {
                    return;
                }
                
                
                if (!Directory.Exists(fullName))
                {
                    Directory.CreateDirectory(fullName);
                }
                AnimationClip newClip = new AnimationClip();
                EditorUtility.CopySerialized(clip, newClip);
                
                AssetDatabase.CreateAsset(newClip, animPath);
                
                AssetDatabase.SaveAssets();
                
                Debug.Log($"Export AnimationClip To {animPath}");

                // Debug.Log($"IsLoopAnimation  name: {clipName}, IsLoopAnimation: {IsLoopAnimation(clipName)}");
                if (IsLoopAnimation(clipName))
                {
                    
                    var clipAsset = AssetDatabase.LoadAssetAtPath<AnimationClip>(animPath);
                    var clipObject = new SerializedObject(clipAsset);
                    var settings = clipObject.FindProperty("m_AnimationClipSettings");
                    var loopTime = settings.FindPropertyRelative("m_LoopTime");
                    loopTime.boolValue = true;
                    clipObject.ApplyModifiedProperties();
                
                    EditorUtility.SetDirty(clipAsset);
                    AssetDatabase.SaveAssets();
                    AssetDatabase.Refresh();
                }
                

            }
        }

        private static bool IsLoopAnimation(string clipName)
        {
            return loopedAnimationNames.Contains(clipName);
        }
    }
}