using UnityEditor;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace UnityToolbarExtender.Examples
{
	static class ToolbarStyles
	{
		public static readonly GUIStyle commandButtonStyle;
		public static readonly GUIStyle stableRunButtonStyle;

		static ToolbarStyles()
		{
			commandButtonStyle = new GUIStyle("Command")
			{
				fontSize = 14,
				alignment = TextAnchor.MiddleCenter,
				imagePosition = ImagePosition.ImageAbove,
				fontStyle = FontStyle.Bold
			};
			
			stableRunButtonStyle = new GUIStyle("Command")
			{
				fontSize = 14,
				alignment = TextAnchor.MiddleCenter,
				imagePosition = ImagePosition.ImageAbove,
				fontStyle = FontStyle.Bold,
				fixedWidth = 50,
				stretchWidth = true,
			};
		}
	}

	[InitializeOnLoad]
	public class SceneSwitchLeftButton
	{
		static SceneSwitchLeftButton()
		{
			ToolbarExtender.LeftToolbarGUI.Add(OnToolbarGUI);
		}

		static void OnToolbarGUI()
		{
			GUILayout.FlexibleSpace();

			if (GUILayout.Button(new GUIContent("UI", "UI制作"), ToolbarStyles.commandButtonStyle))
			{
				// SceneHelper.StartScene("UI制作");
			}

			if (GUILayout.Button(new GUIContent("游戏", "游戏场景"), ToolbarStyles.commandButtonStyle))
			{
				// SceneHelper.StartScene("Init");
			}
			
			
			// if(GUILayout.Button(new GUIContent("技能", "技能编辑"), ToolbarStyles.commandButtonStyle))
			// {
			// 	SceneHelper.StartScene("技能动作制作");
			// }
			//
			// if(GUILayout.Button(new GUIContent("UI", "UI编辑"), ToolbarStyles.commandButtonStyle))
			// {
			// 	SceneHelper.StartScene("UI制作");
			// }
			
			if(GUILayout.Button(new GUIContent("展示", "角色展示"), ToolbarStyles.commandButtonStyle))
			{
				// SceneHelper.StartScene("CharacterExhibition");
			}

			if(GUILayout.Button(new GUIContent("战斗", "战斗编辑器"), ToolbarStyles.commandButtonStyle))
			{
				// SceneHelper.StartScene("战斗编辑器");
			}

			if(GUILayout.Button(new GUIContent("稳定版", "运行稳定版"), ToolbarStyles.stableRunButtonStyle))
			{
				if (!Application.isPlaying)
				{
					PlayerPrefs.SetInt("UseStableResource", 1);
					EditorApplication.EnterPlaymode();
				}
			}
			
		}
	}
}