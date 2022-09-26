using System;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;

public class ColorToSRGBWindow : OdinEditorWindow
{
    [MenuItem("Tools/ColorToSRGBWindow")]
    private static void OpenWindow()
    {
        GetWindow<ColorToSRGBWindow>().Show();
    }
    
    
    [Space(12), HideLabel]
    [Title("GammaHex", "")]
    // [ValidateInput("HasMeshRendererDynamicMessage", "Prefab must have a MeshRenderer component")]
    public string GammaHex;

    [Space(12), HideLabel]
    public string LinearHex;

    [Button(ButtonSizes.Large)]
    public void CalcLinearColor()
    {
        var color = ToColor(GammaHex);
        color = FastLinearToSRGB(color);
        LinearHex = ToRGBHex(color);
    }
    
    public string ToRGBHex(Color c)
    {
        return string.Format("#{0:X2}{1:X2}{2:X2}", ToByte(c.r), ToByte(c.g), ToByte(c.b));
    }

    private static byte ToByte(float f)
    {
        f = Mathf.Clamp01(f);
        return (byte)(f * 255);
    }

    Color FastLinearToSRGB(Color c)
    {
        float r = c.r;
        float g = c.g;
        float b = c.b;

        r = LinearToSRGB(r);
        g = LinearToSRGB(g);
        b = LinearToSRGB(b);
        return new Color(r, g, b);
    }

    float LinearToSRGB(float c)
    {
        float sRGBLo = c * 12.92f;
        float sRGBHi = (PositivePow(c, 1.0f/2.4f) * 1.055f) - 0.055f;
        float sRGB   = (c <= 0.0031308) ? sRGBLo : sRGBHi;
        return sRGB;
    }

    float PositivePow(float f, float p)
    {
        return Mathf.Pow(Mathf.Abs(f), p);
    }

    public static Color ToColor(string color)
    {
        if (color.StartsWith("#", StringComparison.InvariantCulture))
        {
            color = color.Substring(1); // strip #
        }

        if (color.Length == 6)
        {
            color += "FF"; // add alpha if missing
        }

        var hex = Convert.ToUInt32(color, 16);
        var r = ((hex & 0xff000000) >> 0x18) / 255f;
        var g = ((hex & 0xff0000) >> 0x10) / 255f;
        var b = ((hex & 0xff00) >> 8) / 255f;
        var a = ((hex & 0xff)) / 255f;

        return new Color(r, g, b, a);
    }
    
}