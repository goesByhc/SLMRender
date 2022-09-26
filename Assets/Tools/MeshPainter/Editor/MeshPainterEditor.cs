using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System.IO;
using System.Collections;

#if UNITY_EDITOR
[CustomEditor(typeof(MeshPainter))]
[CanEditMultipleObjects]
public class MeshPainterEditor : Editor
{
    private static MeshPainterBrushConfig configCache = new MeshPainterBrushConfig();

    private MeshPainterBrushConfig config = new MeshPainterBrushConfig();

    private MeshPainter _target;
    private UnityEngine.Object monoScript;

    private MeshShaderType configData;

    private Tool LastTool = Tool.None;

    string contolTexName = "";

    bool lastIsPaint = false;
    bool isPaint = false;

    Texture[] brushTex;
    Texture[] texLayer;

    bool hasFourProperty = false;
    int brushSizeInPourcent;
    Texture2D MaskTex;

    Shader currentShader;
    Shader lastShader;

    string lastLayer = "";
    MeshRenderer seletMeshrender;
    int maxTextureCount;


    private List<string> shadernames = new List<string>();

    private RaycastHit[] hits = new RaycastHit[10];

    void OnSceneGUI()
    {
        if (isPaint)
        {
            if (Tools.current == Tool.None)
            {
                Painter();
                //强制每一帧绘制
                SceneView.RepaintAll();
            }
            else
            {
                Painter();
                //强制每一帧绘制
                isPaint = false;
            }
        }
        ShortcutsUpdate();

        SceneView.RepaintAll();
    }


    private void OnEnable()
    {
        _target = (MeshPainter)target;

        this.monoScript = MonoScript.FromMonoBehaviour(this.target as MonoBehaviour);

        #region 数据检索
        
        string meshPaintEditorFolder = MeshPainterStringUtility.meshPaintEditorFolder;
        if (!MeshPainterStringUtility.Exists(meshPaintEditorFolder))
        {
            //Debug.Log("相对路径"+ Application.dataPath);
            string temp = MeshPainterStringUtility.FindPath(Application.dataPath, "Brushes");
            //Debug.Log("修正文件夹路径:"+   Directory.GetParent(temp));
            string t = Directory.GetParent(temp).ToString();
            string r = MeshPainterStringUtility.RelativePath(t + "/");
            Debug.Log("modify folder path:" + r);
            MeshPainterStringUtility.meshPaintEditorFolder = r;
        }

        //===================================================================================================//
        string[] findDatas;
        string result = "";
        // if (File.Exists(MeshPainterStringUtility.shaderNameDatas + MeshPainterStringUtility.fileExr))
        // {
        //     configData = AssetDatabase.LoadAssetAtPath<MeshShaderType>(MeshPainterStringUtility.shaderNameDatas + MeshPainterStringUtility.fileExr);
        // }
        // else
        {
            findDatas = AssetDatabase.FindAssets("MeshPaintShaderDatas");
            foreach (var item in findDatas)
            {
                if (result == "") result = AssetDatabase.GUIDToAssetPath(item).ToString();
            }

            //Debug.Log(result);
            configData = AssetDatabase.LoadAssetAtPath<MeshShaderType>(result);
        }

        #endregion

        if (configData != null && configData.shaders.Count > 0)
        {
            string tempName = "";

            for (int i = 0; i < configData.shaders.Count; i++)
            {
                tempName = configData.shaders[i].shaderName;
                if (!shadernames.Contains(tempName))
                {
                    shadernames.Add(tempName);
                }
            }
            
        }
        else
        {
            Debug.Log("<color=red>" + "See the current shader data file path does not exist：" + "Assets/ThirdPartys/MeshPaint/ScriptsData/MeshPaintShaderDatas" + "</color>");
        }

        SyncConfigFromCache();


        GetMaterialTexture();
        GetBrush();
    }

    private void OnDisable()
    {
        //Tools.current = LastTool;
        isPaint = false;

        seletMeshrender = null;

        GetMaterialTexture();
        GetBrush();
        //切换目标时保存数据
        if (configData)
            EditorUtility.SetDirty(configData);
    }

    private bool isCheak = false;


    public override void OnInspectorGUI()
    {
        EditorGUI.BeginDisabledGroup(true);
        EditorGUILayout.ObjectField("Script", this.monoScript, typeof(MonoScript), false);
        EditorGUI.EndDisabledGroup();

        Repaint();


        isCheak = Cheak();

        if (isCheak == true && configData != null)
        {
            //=================================================Switch Drawing==========================================================================
            GUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            GUIStyle boolBtnOn = new GUIStyle(GUI.skin.GetStyle("Button")); //Get Button Style
            isPaint = GUILayout.Toggle(isPaint, EditorGUIUtility.IconContent("EditCollider"), boolBtnOn, GUILayout.Width(35), GUILayout.Height(25)); //编辑模式开关
            //isPaint = GUILayout.Toggle(isPaint, EditorGUIUtility.IconContent("EditCollider"), boolBtnOn, GUILayout.Width(35), GUILayout.Height(25));//编辑模式开关
            //===============================================================================================//   
            if (isPaint)
            {
                GUILayout.Label("Drawing", GUILayout.Height(25));
            }

            GUILayout.FlexibleSpace();
            GUILayout.EndHorizontal();

            //=================================================Brush attributes==========================================================================//

            config.brushSize = EditorGUILayout.Slider("Brush Size -+", config.brushSize, MeshPainterBrushConfig.brushSizeMin, MeshPainterBrushConfig.brushSizeMax); //Brush size
            config.brushOrthValue = (int)EditorGUILayout.Slider("Brush OrthographicSize ;'", config.brushOrthValue, MeshPainterBrushConfig.brushOrthValueMin, MeshPainterBrushConfig.brushOrthValueMax);
            config.brushStrength = EditorGUILayout.Slider("Brush Strength []", config.brushStrength, MeshPainterBrushConfig.brushStrengthMin, MeshPainterBrushConfig.brushStrengthMax); //Brush Strength

            // configData.showUV = EditorGUILayout.Toggle("Show UV", configData.showUV);

            // EditorGUILayout.ObjectField("Drawable Shader Data： ", configData, typeof(MeshShaderType), true);

            //=================================================Get maps Brush======================================================================


            //=================================================Mapping list==========================================================================

            GUILayout.BeginHorizontal();

            GUILayout.FlexibleSpace();
            GUILayout.BeginHorizontal("box", GUILayout.Width(270));
            //=======================2020-11-21=======================//
            int texCount = 3;
            if (hasFourProperty)
            {
                texCount = 4;
            }

            int gridWidth = 90 * texCount;

            //=======================2020-11-21=======================//
            config.textureIndex = GUILayout.SelectionGrid(config.textureIndex, texLayer, texCount, "gridlist", GUILayout.Width(gridWidth), GUILayout.Height(90)); //2020-11-21//

            // Debug.Log($"beforeTextureIndex {beforeTextureIndex} textureIndex {textureIndex}");
            GUILayout.EndHorizontal();
            GUILayout.FlexibleSpace();

            GUILayout.EndHorizontal();

            //=================================================Brush List==========================================================================

            GUILayout.BeginHorizontal();

            GUILayout.FlexibleSpace();
            GUILayout.BeginHorizontal("box", GUILayout.Width(318));
            config.brushIndex = GUILayout.SelectionGrid(config.brushIndex, brushTex, 9, "gridlist", GUILayout.Width(340), GUILayout.Height(70));
            GUILayout.EndHorizontal();
            GUILayout.FlexibleSpace();

            GUILayout.EndHorizontal();
            //========================================//
            //========================================//
            if (lastIsPaint != isPaint)
            {
                if (isPaint && Tools.current != Tool.None)
                {
                    Tools.current = Tool.None;
                }
            }


            SaveConfigToCache();

            //========================================//
        }
        //serializedObject.ApplyModifiedProperties();
    }


    public void ShortcutsUpdate()
    {
        
        // Debug.Log($"Event.current.type: {Event.current.type} Event.current.keyCode:{Event.current.keyCode}");
        
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Minus)
        {
            config.brushSize -= 0.5f;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Equals)
        {
            config.brushSize += 0.5f;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.LeftBracket)
        {
            config.brushStrength -= 0.1f;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.RightBracket)
        {
            config.brushStrength += 0.1f;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Semicolon)
        {
            config.brushOrthValue--;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Quote)
        {
            config.brushOrthValue++;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Comma)
        {
            config.textureIndex--;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Period)
        {
            config.textureIndex++;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Alpha7)
        {
            config.textureIndex = 0;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Alpha8)
        {
            config.textureIndex = 1;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Alpha9)
        {
            config.textureIndex = 2;
        }
        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.Alpha0)
        {
            config.textureIndex = 3;
        }
        

        config.brushSize = Math.Min(Math.Max(config.brushSize, MeshPainterBrushConfig.brushSizeMin), MeshPainterBrushConfig.brushSizeMax);
        config.brushOrthValue = Math.Min(Math.Max(config.brushOrthValue, MeshPainterBrushConfig.brushOrthValueMin), MeshPainterBrushConfig.brushOrthValueMax);
        config.brushStrength = Math.Min(Math.Max(config.brushStrength, MeshPainterBrushConfig.brushStrengthMin), MeshPainterBrushConfig.brushStrengthMax);
        config.textureIndex = Math.Min(Math.Max(config.textureIndex, 0), maxTextureCount - 1);

    }


    /// <summary>
    /// Get Material ball texture
    /// </summary>
    public void GetMaterialTexture()
    {
        if (_target.transform)
        {
            seletMeshrender = _target.transform.GetComponent<MeshRenderer>();

            maxTextureCount = GetMaxTextureCountByShader();

            //TODO:动态数量
            hasFourProperty = maxTextureCount == 4;
            if (hasFourProperty)
            {
                texLayer = new Texture[4];
            }
            else
            {
                texLayer = new Texture[3];
            }

            if (seletMeshrender)
            {
                try
                {
                    Texture2D tex_1 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_1));
                    Texture2D tex_2 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_2));
                    Texture2D tex_3 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_3));

                    var Color_str = "_Color";

                    Color col_1 = seletMeshrender.sharedMaterial.GetColor(MeshPainterStringUtility.tex_1 + Color_str);
                    Color col_2 = seletMeshrender.sharedMaterial.GetColor(MeshPainterStringUtility.tex_2 + Color_str);
                    Color col_3 = seletMeshrender.sharedMaterial.GetColor(MeshPainterStringUtility.tex_3 + Color_str);

                    texLayer[0] = MergeTexture(tex_1, col_1);
                    texLayer[1] = MergeTexture(tex_2, col_2);
                    texLayer[2] = MergeTexture(tex_3, col_3);

                    if (hasFourProperty)
                    {
                        Texture2D tex_4 = AssetPreview.GetAssetPreview(seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.tex_4));
                        Color col_4 = seletMeshrender.sharedMaterial.GetColor(MeshPainterStringUtility.tex_4 + Color_str);
                        texLayer[3] = MergeTexture(tex_4, col_4);
                    }

                    MaskTex = (Texture2D)seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.shaderControlTexName); //Get the Control map from the shader
                }
                catch (System.Exception e)
                {
                    // if (showUV)
                    // {
                    //     Debug.Log(e + "shader：Map not found");
                    // }
                }
            }
        }
    }

    public static Texture2D MergeTexture(Texture2D a, Color b)
    {
        var newTexture = new Texture2D(a.width, a.height);
        newTexture.filterMode = FilterMode.Point;

        for (int i = 0; i < newTexture.width; i++)
        {
            for (int j = 0; j < newTexture.height; j++)
            {
                var color = a.GetPixel(i, j);
                color.r = color.r * b.r;
                color.g = color.g * b.g;
                color.b = color.b * b.b;
                newTexture.SetPixel(i, j, color);
            }
        }

        newTexture.Apply();
        return newTexture;
    }

    /// <summary>
    /// 获取笔刷
    /// </summary>    
    public void GetBrush()
    {
        string MeshPaintEditorFolder = MeshPainterStringUtility.meshPaintEditorFolder;
        ArrayList BrushList = new ArrayList();
        Texture BrushesTL;
        int BrushNum = 0;
        do
        {
            BrushesTL = (Texture)AssetDatabase.LoadAssetAtPath(MeshPaintEditorFolder + "Brushes/Brush" + BrushNum + ".png", typeof(Texture));

            if (BrushesTL)
            {
                BrushList.Add(BrushesTL);
            }

            BrushNum++;
        } while (BrushesTL);

        brushTex = BrushList.ToArray(typeof(Texture)) as Texture[];
    }

    /// <summary>
    /// Check for compliance with the rendering conditions
    /// </summary>
    /// <returns></returns>
    bool Cheak()
    {
        bool Cheak = false;
        bool isHaveShader = false;

        if (_target.transform)
            seletMeshrender = _target.transform.GetComponent<MeshRenderer>();
        if (seletMeshrender)
        {
            Texture ControlTex = seletMeshrender.sharedMaterial.GetTexture(MeshPainterStringUtility.shaderControlTexName);
            currentShader = seletMeshrender.sharedMaterial.shader;

            if (currentShader != null)
            {
                if (configData && shadernames.Count > 0)
                {
                    for (int i = 0; i < shadernames.Count; i++)
                    {
                        if (currentShader == Shader.Find(shadernames[i].ToString()))
                        {
                            isHaveShader = true;
                            break;
                        }
                    }
                }

                if (lastShader != currentShader)
                {
                    //Debug.Log("<color=#FF9900>" + "current shader:    " + "</color>" + currentShader.name);
                    //Debug.Log("<color=#29A7FF>" + "Is it inconsistent with the last drawing shader----->>>>>" + "</color>" + isHaveShader);
                    lastShader = currentShader;
                }
            }
            else
            {
                if (ControlTex != null)
                    Cheak = true;
                else
                    Cheak = false;

                return Cheak;
            }

            if (isHaveShader == true)
            {
                if (ControlTex == null)
                {
                    EditorGUILayout.HelpBox("Control map not found in current model shader, drawing function is not available！", MessageType.Error);
                    Cheak = false;
                }
                else
                {
                    Cheak = true;
                }
            }
            else
            {
                EditorGUILayout.HelpBox("shader error！Replace！当前Shader不支持使用MeshPainter来绘制", MessageType.Error);
                Cheak = false;
            }
        }

        return Cheak;
    }

    /// <summary>
    /// Core drawing
    /// </summary>
    public void Painter()
    {
        MeshFilter temp = null;
        if (_target.transform)
        {
            temp = _target.transform.GetComponent<MeshFilter>();
        }
        else
        {
            return;
        }

        float orthographicSize = (config.brushSize * _target.transform.localScale.x) * (temp.sharedMesh.bounds.size.x / (config.brushOrthValue * 100)); //The orthogonal size of the brush on the model

        brushSizeInPourcent = (int)Mathf.Round((config.brushSize * MaskTex.width) / (config.brushOrthValue * 0.5f * 100)); //The size of the brush on the model
        bool ToggleF = false;
        Event e = Event.current; //Detection input

        HandleUtility.AddDefaultControl(0); //2021-1-5

        RaycastHit raycastHit = new RaycastHit();
        Ray terrainRay = HandleUtility.GUIPointToWorldRay(e.mousePosition); //Emitting a ray from the mouse position
        //================================================================================================================//

        int count = Physics.RaycastNonAlloc(terrainRay, hits, Mathf.Infinity, 1 << _target.gameObject.layer);

        bool isHitTarget = false;
        for (int i = 0; i < count; i++)
        {
            var hit = hits[i];
            if (hit.collider.gameObject == _target.gameObject)
            {
                raycastHit = hit;
                isHitTarget = true;
            }
        }

        // Debug.Log("Count" + count  + " hit " + isHitTarget);

        if (!isHitTarget)
        {
            return;
        }

        Color targetColor = new Color(1f, 1f, 1f, 1f);
        switch (config.textureIndex)
        {
            case 0:
                targetColor = new Color(1f, 0f, 0f, 0f);
                break;
            case 1:
                targetColor = new Color(0f, 1f, 0f, 0f);
                break;
            case 2:
                targetColor = new Color(0f, 0f, 1f, 0f);
                break;
            case 3:
                targetColor = new Color(0f, 0f, 0f, 1f);
                break;
        }

        
        
        Handles.color = new Color(1f, 1f, 0f, 1f);
        Handles.DrawWireDisc(raycastHit.point, raycastHit.normal, orthographicSize * 2); //Display a circle at the mouse position according to the brush size

        Handles.color = new Color(targetColor.r, targetColor.g, targetColor.b, 1);
        Handles.DrawLine(raycastHit.point, raycastHit.point + raycastHit.normal * 5, 2); //Displays the normal direction at the mouse position according to the brush size

        //Mouse click or press and drag to draw
        if ((e.type == EventType.MouseDrag && e.alt == false && e.control == false && e.shift == false &&
             e.button == 0) || (e.type == EventType.MouseDown && e.shift == false && e.alt == false &&
                                e.control == false && e.button == 0 && ToggleF == false))
        {
            //Select the channel to draw


            Vector2 pixelUV = raycastHit.textureCoord;

            #region ----Determine if UV is over-framed

            float changX = 0;
            float changY = 0;
            if (Mathf.Abs(pixelUV.x) > 1 || Mathf.Abs(pixelUV.y) > 1)
            {
                // if (showUV)
                //     Debug.LogError("UV superframe original value:" + pixelUV);
                if (pixelUV.x > 1)
                {
                    changX = pixelUV.x % 1;
                }
                else if (pixelUV.x < -1)
                {
                    changX = 1 - Mathf.Abs(pixelUV.x % (-1));
                    // if (showUV)
                    //     Debug.Log((pixelUV.x % (-1)));
                }
                else
                {
                    changX = pixelUV.x;
                }


                if (pixelUV.y > 1)
                {
                    changY = pixelUV.y % 1;
                }
                else if (pixelUV.y < -1)
                {
                    changY = 1 - Mathf.Abs(pixelUV.y % (-1));
                }
                else
                {
                    changY = pixelUV.y;
                }

                pixelUV = new Vector2(changX, changY);
                // if (showUV)
                //     Debug.Log("UV Superframe:" + pixelUV + "    X:" + changX + "    Y:" + changY);
            }

            if ((pixelUV.y < 0 && pixelUV.y >= -1) || (pixelUV.x < 0 && pixelUV.x >= -1))
            {
                // if (showUV)
                //     Debug.LogError("UV Negative original value:" + pixelUV);
                if (pixelUV.x < 0 && pixelUV.x >= -1)
                {
                    changX = 1 - Mathf.Abs(pixelUV.x);
                }
                else
                {
                    changX = pixelUV.x;
                }

                if (pixelUV.y < 0 && pixelUV.y >= -1)
                {
                    changY = 1 - Mathf.Abs(pixelUV.y);
                }
                else
                {
                    changY = pixelUV.y;
                }

                pixelUV = new Vector2(changX, changY);
                // if (showUV)
                //     Debug.Log("UV Negative:" + pixelUV + "    X:" + changX + "    Y:" + changY);
            }

            if ((pixelUV.y >= 0 && pixelUV.y <= 1) && (pixelUV.x >= 0 && pixelUV.x <= 1))
            {
                // if (showUV)
                //     Debug.Log("UV in the box:" + pixelUV);
            }

            #endregion

            //Calculate the area covered by the brush
            int PuX = Mathf.FloorToInt(pixelUV.x * MaskTex.width);
            int PuY = Mathf.FloorToInt(pixelUV.y * MaskTex.height);
            int x = Mathf.Clamp(PuX - brushSizeInPourcent / 2, 0, MaskTex.width - 1);
            int y = Mathf.Clamp(PuY - brushSizeInPourcent / 2, 0, MaskTex.height - 1);
            int width = Mathf.Clamp((PuX + brushSizeInPourcent / 2), 0, MaskTex.width) - x;
            int height = Mathf.Clamp((PuY + brushSizeInPourcent / 2), 0, MaskTex.height) - y;

            Color[] terrainBay = MaskTex.GetPixels(x, y, width, height, 0); //Get the color of the area that the Control map is covered by the brush

            Texture2D TBrush = brushTex[config.brushIndex] as Texture2D; //Get brush trait map
            float[] brushAlpha = new float[brushSizeInPourcent * brushSizeInPourcent]; //Brush transparency

            //Calculate the transparency of the brush based on the brush map
            for (int i = 0; i < brushSizeInPourcent; i++)
            {
                for (int j = 0; j < brushSizeInPourcent; j++)
                {
                    brushAlpha[j * brushSizeInPourcent + i] = TBrush.GetPixelBilinear(((float)i) / brushSizeInPourcent, ((float)j) / brushSizeInPourcent).a;
                }
            }

            //Calculate the color after drawing
            for (int i = 0; i < height; i++)
            {
                for (int j = 0; j < width; j++)
                {
                    int index = (i * width) + j;
                    float Stronger = brushAlpha[
                        Mathf.Clamp((y + i) - (PuY - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1) 
                        * brushSizeInPourcent 
                        + Mathf.Clamp((x + j) - (PuX - brushSizeInPourcent / 2), 0, brushSizeInPourcent - 1)] * config.brushStrength;

                    terrainBay[index] = Color.Lerp(terrainBay[index], targetColor, Stronger);
                }
            }

            Undo.RegisterCompleteObjectUndo(MaskTex, "meshPaint"); //Save history for revocation

            MaskTex.SetPixels(x, y, width, height, terrainBay, 0); //Save the drawn Control texture
            MaskTex.Apply();
            ToggleF = true;
        }

        if (e.type == EventType.MouseUp && e.alt == false && e.button == 0) // && ToggleF == true)
        {
            SaveTexture(); //Draw to save the Control texture
            ToggleF = false;
        }
    }

    public int GetMaxTextureCountByShader()
    {
        if (seletMeshrender.sharedMaterial.HasProperty(MeshPainterStringUtility.tex_4))
        {
            return 4;
        }

        if (seletMeshrender.sharedMaterial.HasProperty(MeshPainterStringUtility.tex_3))
        {
            return 3;
        }

        if (seletMeshrender.sharedMaterial.HasProperty(MeshPainterStringUtility.tex_2))
        {
            return 2;
        }

        if (seletMeshrender.sharedMaterial.HasProperty(MeshPainterStringUtility.tex_1))
        {
            return 1;
        }

        return 0;
    }


    public void SaveTexture()
    {
        var path = AssetDatabase.GetAssetPath(MaskTex);
        var bytes = MaskTex.EncodeToPNG();

        if (bytes == null || bytes.Length == 0)
        {
            Debug.LogError("SaveTexture Fail");
            return;
        }

        //Debug.Log("SaveTexture " + path);
        File.WriteAllBytes(path, bytes);
    }

    public void SaveConfigToCache()
    {
        configCache.brushSize = config.brushSize;
        configCache.brushOrthValue = config.brushOrthValue;
        configCache.brushStrength = config.brushStrength;
        configCache.textureIndex = config.textureIndex;
        configCache.brushIndex = config.brushIndex;
    }

    public void SyncConfigFromCache()
    {
        config.brushSize = configCache.brushSize;
        config.brushOrthValue = configCache.brushOrthValue;
        config.brushStrength = configCache.brushStrength;
        config.textureIndex = configCache.textureIndex;
        config.brushIndex = configCache.brushIndex;
    }

    public class MeshPainterBrushConfig
    {
        public float brushSize = 3f;
        public int brushOrthValue = 2;
        public float brushStrength = 0.5f;
        public int textureIndex = 0;
        public int brushIndex = 0;

        public const float brushSizeMin = 1f;
        public const float brushSizeMax = 10f;
        public const int brushOrthValueMin = 1;
        public const int brushOrthValueMax = 10;
        public const float brushStrengthMin = 0f;
        public const float brushStrengthMax = 1f;


    }
}
#endif