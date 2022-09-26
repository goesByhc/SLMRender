namespace UnityEngine.Rendering.Universal
{
    public class StencilFilterTool
    {

        public static Material GetStencilMaterial(int stencilId)
        {
            var mat = CoreUtils.CreateEngineMaterial(Shader.Find("PostProcess/StencilFilter"));
            mat.SetInt("_StencilId", stencilId);
            return mat;
        }
    }
}