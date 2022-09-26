using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

[ExecuteInEditMode()]
public class VisionManager : MonoBehaviour
{

    private static List<VisionManager> _managers = new List<VisionManager>();
    private static VisionManager currentManager;
    private static bool initedShaderId = false;

    
    [Min(0)]
    public float weight = 1;
    
    [Title("SH环境系数")]
    public Vector4 SHAr;
    public Vector4 SHAg;
    public Vector4 SHAb;
    public Vector4 SHBr;
    public Vector4 SHBg;
    public Vector4 SHBb;
    public Vector4 SHC;
    [Range(0, 1f)]
    public float ShIntensity = 1;

    [Title("Bloom")]
    [Range(-1f, 1f)]
    public float SceneBloomAdd = 0f;
    [Range(-1f, 1f)]
    public float CharacterBloomAdd = 0f;
    [Range(-1f, 1f)]
    public float VFXBloomAdd = 0f;

    
    [Title("人物灯光")]
    public bool SceneLightProbe = false;
    public Color characterLightColor = Color.white;
    public Color characterShadowColor = new Color(0.85f, 0.85f, 0.85f, 1f);
    [Min(0)] 
    public float characterLightIntensity = 1;

    public GameObject characterLightDirectionNode;


    [Title("ShadowTest")] 
    public float shadowLightWidth;
    public float shadowLightRandomRadius;

    
    
    private static int sceneBloomAddId;
    private static int characterBloomAddId;
    private static int vfxBloomAddId;
    private static int sceneLightProbeId;
    private static int characterLightColorId;
    private static int characterShadowColorId;
    private static int characterLightIntensityId;
    private static int characterLightDirectionId;

    private static int[] shIds = new int[7];
    private static int shIntensityId;

    private long enableTime = 0;

    // private static int totalInstId = 0;
    // private int Instid = 0;

    private void Reset()
    {
        characterLightDirectionNode = this.gameObject;
        _managers.Clear();
        _managers.Add(this);
        currentManager = this;
    }

    private void Awake()
    {
        if (initedShaderId == false)
        {
            InitShaderIds();
            initedShaderId = true;
        }

        // totalInstId++;
        // Instid = totalInstId;
        
        _managers.Add(this);
        Debug.Log("VisionManager Awake");
    }

    private void InitShaderIds()
    {
        shIds[0] = Shader.PropertyToID("custom_SHAr");
        shIds[1] = Shader.PropertyToID("custom_SHAg");
        shIds[2] = Shader.PropertyToID("custom_SHAb");
        shIds[3] = Shader.PropertyToID("custom_SHBr");
        shIds[4] = Shader.PropertyToID("custom_SHBg");
        shIds[5] = Shader.PropertyToID("custom_SHBb");
        shIds[6] = Shader.PropertyToID("custom_SHC");
        shIntensityId = Shader.PropertyToID("custom_SH_Intensity");
        
        
        sceneBloomAddId = Shader.PropertyToID("_SceneBloomAdd");
        characterBloomAddId = Shader.PropertyToID("_CharacterBloomAdd");
        vfxBloomAddId = Shader.PropertyToID("_VFXBloomAdd");
        sceneLightProbeId = Shader.PropertyToID("_SceneLightProbe");
        characterLightColorId = Shader.PropertyToID("_CharacterLightColor");
        characterShadowColorId = Shader.PropertyToID("_CharacterShadowColor");
        characterLightIntensityId = Shader.PropertyToID("_CharacterLightIntensity");
        characterLightDirectionId = Shader.PropertyToID("_CharacterLightDirection");

    }

    private void OnEnable()
    {
        enableTime = new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds();
        
        RefreshCurrentManager();
#if UNITY_EDITOR
        if (!Application.isPlaying) //保证编辑器下 开关的时候有用
        {
            InitShaderIds();
            currentManager = this;
        }
#endif
    }

    private static void OrderManager()
    {
        _managers.Sort((a, b) =>
        {
            if (!a.isActiveAndEnabled)
            {
                return -1;
            }
            
            if (a.weight != b.weight)
            {
                return a.weight.CompareTo(b.weight);
            }
            else
            {
                return a.enableTime.CompareTo(b.enableTime);
            }
        });
    }

    static void RefreshCurrentManager()
    {
        // Debug.Log("RefreshCurrentManager");
        OrderManager();
        currentManager = null;
        
        if (_managers.Count > 0)
        {
            currentManager = _managers[_managers.Count - 1];
        }
        
        // Debug.Log($"RefreshCurrentManager LastTime : {currentManager.enableTime}  instId: {currentManager.Instid}" );
        
    }

    private void OnDestroy()
    {
        _managers.Remove(this);
        RefreshCurrentManager();
    }
    
    void Update()
    {
        if (currentManager == this)
        {
            UpdateParameters();
        }
    }

    private void OnValidate()
    {
        UpdateParameters();
    }

    private void UpdateParameters()
    {

        
        // Debug.Log("UpdateParameters SHAr:" + SHAr);
        Shader.SetGlobalVector(shIds[0], SHAr);
        Shader.SetGlobalVector(shIds[1], SHAg);
        Shader.SetGlobalVector(shIds[2], SHAb);
        Shader.SetGlobalVector(shIds[3], SHBr);
        Shader.SetGlobalVector(shIds[4], SHBg);
        Shader.SetGlobalVector(shIds[5], SHBb);
        Shader.SetGlobalVector(shIds[6], SHC);
        Shader.SetGlobalFloat(shIntensityId, ShIntensity);
        
        
        Shader.SetGlobalFloat(sceneBloomAddId, SceneBloomAdd);
        Shader.SetGlobalFloat(characterBloomAddId, CharacterBloomAdd);
        Shader.SetGlobalFloat(vfxBloomAddId, VFXBloomAdd);
        Shader.SetGlobalFloat(sceneLightProbeId, SceneLightProbe ? 1 : 0);
        Shader.SetGlobalFloat(characterLightIntensityId, characterLightIntensity);
        Shader.SetGlobalColor(characterLightColorId, characterLightColor);
        Shader.SetGlobalColor(characterShadowColorId, characterShadowColor);

        if (characterLightDirectionNode != null)
        {
            var direction = characterLightDirectionNode.transform.forward * -1;
            Shader.SetGlobalVector(characterLightDirectionId, new Vector4(direction.x, direction.y, direction.z, 0));
        }
        
        
        
        
        Shader.SetGlobalFloat("_LightWidth", shadowLightWidth);
        Shader.SetGlobalFloat("_LightRandomRadius", shadowLightRandomRadius);


    }
}
