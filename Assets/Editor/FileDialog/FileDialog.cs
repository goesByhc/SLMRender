
#if UNITY_EDITOR

using System.Runtime.InteropServices;
using System;
using UnityEngine;


/// <summary>
/// 文件日志类
/// </summary>
// [特性(布局种类.有序,字符集=字符集.自动)]
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public class ChinarFileDialog
{
    public int    structSize    = 0;
    public IntPtr dlgOwner      = IntPtr.Zero;
    public IntPtr instance      = IntPtr.Zero;
    public String filter        = null;
    public String customFilter  = null;
    public int    maxCustFilter = 0;
    public int    filterIndex   = 0;
    public String file          = null;
    public int    maxFile       = 0;
    public String fileTitle     = null;
    public int    maxFileTitle  = 0;
    public String initialDir    = null;
    public String title         = null;
    public int    flags         = 0;
    public short  fileOffset    = 0;
    public short  fileExtension = 0;
    public String defExt        = null;
    public IntPtr custData      = IntPtr.Zero;
    public IntPtr hook          = IntPtr.Zero;
    public String templateName  = null;
    public IntPtr reservedPtr   = IntPtr.Zero;
    public int    reservedInt   = 0;
    public int    flagsEx       = 0;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public class OpenFileDlg : ChinarFileDialog
{
}

public class OpenFileDialog
{
    [DllImport("Comdlg32.dll", SetLastError = true, ThrowOnUnmappableChar = true, CharSet = CharSet.Auto)]
    public static extern bool GetOpenFileName([In, Out] OpenFileDlg ofd);
}


[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public class SaveFileDlg : ChinarFileDialog
{

    public SaveFileDlg(string ext)
    {
        structSize   = Marshal.SizeOf(this);
        filter       = ext;
        file         = new string(new char[256]);
        maxFile      = file.Length;
        fileTitle    = new string(new char[64]);
        maxFileTitle = fileTitle.Length;
        initialDir   = Application.dataPath; //默认路径
        title        = "保存项目";
        defExt       = ext;
        flags        = 0x00080000 | 0x00001000 | 0x00000800 | 0x00000200 | 0x00000008;
    }
}

public class SaveFileDialog
{
    [DllImport("Comdlg32.dll", SetLastError = true, ThrowOnUnmappableChar = true, CharSet = CharSet.Auto)]
    public static extern bool GetSaveFileName([In, Out] SaveFileDlg ofd);


    public static string GetSaveAssetPath(string ext = "asset")
    {
        var dlg = new SaveFileDlg(ext);
        if (GetSaveFileName(dlg))
        {
            return dlg.file.Substring(System.Environment.CurrentDirectory.Length + 1);
        }
        return "";
    }

}

#endif
