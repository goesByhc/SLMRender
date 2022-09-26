using System.Collections.Generic;
using JetBrains.Annotations;
using UnityEngine.Rendering.Universal.ColorGrading;
using UnityEngine.Rendering.Universal.Internal;

namespace UnityEngine.Rendering.Universal
{
    public class AdditionalRendererFeature : ScriptableRendererFeature
    {
        private List<IAdditionalRenderPass> passList = new List<IAdditionalRenderPass>();


        #region CreatePassHere

        public override void Create()
        {
            passList.Clear();

            passList.Add(new HairShadowRenderPass());
            passList.Add(new CloudShadowRenderPass());
            passList.Add(new BrightnessSaturationContrastRenderPass());
            passList.Add(new ColorGradingPass());
            passList.Add(new SNNRenderPass());
            passList.Add(new FXAAPass());
            passList.Add(new StylizedDetailPass());
            passList.Add(new EdgeEffectPass());
        }

        #endregion

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            ref var cameraData = ref renderingData.cameraData;
            // bool m_IsStereo = renderingData.cameraData.isStereoEnabled;
            bool isSceneViewCamera = cameraData.isSceneViewCamera;
            bool isBaseCamera = cameraData.renderType == CameraRenderType.Base;
            bool isPostProcessEnabled = cameraData.postProcessEnabled;
            // if (!cameraData.postProcessEnabled)
            // {
            //     return;
            // }

            for (int i = 0; i < passList.Count; i++)
            {
                var pass = passList[i];

                bool hasVolume = pass.RefreshVolume();
                bool active = pass.IsActive(isSceneViewCamera, isBaseCamera, isPostProcessEnabled, ref renderingData);
                
                
                // Debug.Log($"HasVolume: {hasVolume} isActive: {active}");

                if (hasVolume && active)
                {
                    renderer.EnqueuePass(pass as ScriptableRenderPass);
                }
            }
        }

        protected override void Dispose(bool disposing)
        {
            for (int i = 0; i < passList.Count; i++)
            {
                var pass = passList[i];
                pass.Release();
            }

            passList.Clear();
        }
    }
}