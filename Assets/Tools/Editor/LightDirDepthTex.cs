using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;


[Serializable]
public class LightDirShadowStruct
{
    
}

public class LightDirDepthTex : OdinEditorWindow {
    
    [MenuItem("Tools/LightDirDepthTex")]
    private static void OpenWindow()
    {
        GetWindow<LightDirDepthTex>().Show();
    }
    
    
    public Light mainLight;
    public Texture2D depthTex;
    public Renderer treeRenderer;
    public GameObject targetDepth;
    public Shader shader;
    public Camera camera;

    // void Start () {
    // 	//GetComponent<Renderer>().sharedMaterial.mainTexture = depthTex;
    // }
    
    [Button(ButtonSizes.Large)]
    void generateDepthTex()
    {
    
        var transform = targetDepth.transform;
        
        Vector3 startPos = transform.TransformPoint(new Vector3(-0.5f, -0.5f, 0));
        Vector3 endXPos = transform.TransformPoint(new Vector3(0.5f, -0.5f, 0));
        Vector3 endYPos = transform.TransformPoint(new Vector3(-0.5f, 0.5f, 0));
        
        int texSize = 512;
        var stepXPos = (endXPos - startPos) / texSize;
        var stepYPos = (endYPos - startPos) / texSize;
        depthTex = new Texture2D(texSize, texSize, TextureFormat.RGB24, false,true);
        var colors = depthTex.GetPixels();
        var treeTex0 = treeRenderer.sharedMaterials[0].mainTexture as Texture2D;
        var treeColors0 = treeTex0.GetPixels();
        // var treeTex1 = treeRenderer.sharedMaterials[1].mainTexture as Texture2D;
        // var treeColors1 = treeTex1.GetPixels();
        var submesh0Vts=treeRenderer.GetComponent<MeshFilter>().sharedMesh.GetTriangles(0).Length/3;
         
        for (int i = 0; i < texSize; i++)
        {
            for (int j = 0; j < texSize; j++)
            {
                //Gizmos.DrawRay(startPos + stepXPos * j + stepYPos * i, -transform.forward);
                RaycastHit info;
                float rayDis = 200;
                int transparentReset = 0;
                Vector3 rayStart = startPos + stepXPos * j + stepYPos * i + -mainLight.transform.forward * rayDis/2;
                resetRaycast:
                Debug.DrawRay(rayStart,mainLight.transform.forward, Color.red);
                if (Physics.Raycast(rayStart,  mainLight.transform.forward, out info, rayDis)){
                    //	colors[j, i] =
                    // var treeTex = info.triangleIndex < submesh0Vts ? treeTex0 : treeTex1;
                    // var treeColors = info.triangleIndex < submesh0Vts ? treeColors0 : treeColors1;
    
                    // Debug.Log("Cast Something");
                    var treeTex = treeTex0;
                    var treeColors = treeColors0;
                    int hitX =Mathf.Clamp( (int)( Mathf.Clamp01( info.textureCoord.x) * treeTex.width),0, treeTex.width-1);
                    int hitY = Mathf.Clamp((int)(Mathf.Clamp01(info.textureCoord.y) * treeTex.height), 0, treeTex.height - 1);
    
                    
                    if (treeColors[hitY * treeTex.width + hitX].a < 0.5 && transparentReset < 3) {
                        transparentReset++;
                        rayStart = info.point+ mainLight.transform.forward*0.01f;
                        rayDis -= info.distance;
                        goto resetRaycast;
    
                    }
                    if (treeColors[hitY * treeTex.width + hitX].a < 0.5)
                    {
                        colors[j + texSize * i] = Color.black;
                    }
                    else {
                        colors[j + texSize * i] = Color.white * (Vector3.Dot(startPos + stepXPos * j + stepYPos * i - info.point, mainLight.transform.forward)/10*0.5f+0.5f);//  treeColors[hitY* treeTex.width+ hitX].a<0.5?Color.black: Color.red;
                    }
                //	colors[j + texSize * i] =   Color.red;
    
                }
                else {
                    colors[j+texSize*i] = Color.black;
                }
    
    
            }
    
        }
        depthTex.SetPixels(colors);
        depthTex.Apply(false);
        // GetComponent<Renderer>().sharedMaterial.mainTexture = depthTex;
        File.WriteAllBytes(Application.dataPath + "/depthTex.png", depthTex.EncodeToPNG());
    }


    [Button]
    void RenderDepthTex()
    {
        var rt = new RenderTexture(1024, 1024, 24);
        camera.targetTexture = rt;
        
        camera.SetReplacementShader(shader, "RenderType");
        camera.Render();
        
        var mat = 
        
        SaveRenderTextureToPNG(rt);

    }
    
    
    //将RenderTexture保存成一张png图片  
    public bool SaveRenderTextureToPNG(RenderTexture rt)
    {
        RenderTexture prev = RenderTexture.active;
        RenderTexture.active = rt;
        Texture2D png = new Texture2D(rt.width, rt.height, TextureFormat.ARGB32, false);
        png.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        byte[] bytes = png.EncodeToPNG();
        
        File.WriteAllBytes(Application.dataPath + "/depthTex.png", bytes);

        Debug.Log("Save Finish");
        
        AssetDatabase.Refresh();
        
        
        // if (!Directory.Exists(contents))
        //     Directory.CreateDirectory(contents);
        // FileStream file = File.Open(contents + "/" + pngName + ".png", FileMode.Create);
        // BinaryWriter writer = new BinaryWriter(file);
        // writer.Write(bytes);
        // file.Close();
        // Texture2D.DestroyImmediate(png);
        // png = null;
        // RenderTexture.active = prev;
        return true;

    }

}