using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomTimeLine
{
    [System.Serializable]
    public class MaterialPropertys
    {
        public string propertyName;
        public Gradient gradient;
        public Color TopColor;
        public Color MidColor;
        public Color ButtomColor;
        private Texture2D gradientTexture;
        public Material SkyBoxMat;
        private void MakeGradinetMap(string ShaderTexName,Gradient gradient)
        {
            
            gradientTexture = new Texture2D(128, 1);  
            for (int i = 0; i < 128; i++)  
            {  
                float t = (float)i / 255.0f;  
                Color color = gradient.Evaluate(t);  
                gradientTexture.SetPixel(i, 0, color);  
            }

            gradientTexture.wrapMode = TextureWrapMode.Clamp;
            gradientTexture.Apply();
            SkyBoxMat.SetTexture(ShaderTexName, gradientTexture);
        }
        private Gradient ColorChange(Color TopColor, Color midColor , Color BottomColor)
        {
            Gradient grad = new Gradient();
            grad.SetKeys(  
                new GradientColorKey[] { new GradientColorKey(TopColor, 0.0f),new GradientColorKey(midColor, 0.1f), new GradientColorKey(BottomColor, 0.6f) },  
                new GradientAlphaKey[] { new GradientAlphaKey(1.0f, 0.0f), new GradientAlphaKey(1.0f, 1.0f) }  
            );

            return grad;
        }
    }
}

