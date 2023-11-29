using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace RBMJGUI
{

    public class RBMJEffectsGUI : ShaderGUI
    {
        private MaterialEditor m_materialEditor;
        private MaterialProperty[] m_properties;
        private Material m_material;
        
        //一级窗口是否默认不折叠
        private bool ConfigW = true;
        private bool MainTexW = true;
        private bool ColorTexW = false;
        private bool DisturbanceW = false;
        private bool MaskW = false;
        private bool _DissolveW = false;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            m_materialEditor = materialEditor;
            m_properties = properties;
            m_material = materialEditor.target as Material;
            Show();
        }

        #region KeywordEnum类型
        //KeywordEnum类型 集中设置Enum   shader里的KeywordEnum 值为从0开始的连续整数
        //对于KeywordEnum类型请不要使用 Shader.DisableKeyword 来控制 keyword 的开关 会失效  请用material.DisableKeyword
        public enum RGBMode
        {
            RGBA,
            R,
            G,
            B
        }
        public enum ClearColor
        {
            OFF,
            Open
        }
        public enum SwitchColor
        {
            MainColor,
            FrontColor
        }
        
        //设置KeywordEnum
        private void SetMaterialRGBAMode(Material Mat)
        {
            EditorGUI.BeginChangeCheck();
            RGBMode Ret = RGBMode.RGBA;

            if(Array.IndexOf(Mat.shaderKeywords, "_RGB_RGBA") != -1)
            {
                Ret = RGBMode.RGBA;
  
            }
            else if(Array.IndexOf(Mat.shaderKeywords, "_RGB_R") != -1)
            {
                Ret = RGBMode.R;

            }
            else if(Array.IndexOf(Mat.shaderKeywords, "_RGB_G") != -1)
            {
                Ret = RGBMode.G;

            }
            else if(Array.IndexOf(Mat.shaderKeywords, "_RGB_B") != -1)
            {
                Ret = RGBMode.B;
    
            }
            
            if (EditorGUI.EndChangeCheck())
            {
                switch ((RGBMode)EditorGUILayout.EnumPopup(Ret))
                {
                    case RGBMode.RGBA:
                        Mat.EnableKeyword("_RGB_RGBA");
                        Mat.DisableKeyword("_RGB_R");
                        Mat.DisableKeyword("_RGB_G");
                        Mat.DisableKeyword("_RGB_B");
                        break;
                    case RGBMode.R:
                        Mat.EnableKeyword("_RGB_R");
                        Mat.DisableKeyword("_RGB_RGBA");
                        Mat.DisableKeyword("_RGB_G");
                        Mat.DisableKeyword("_RGB_B");
                        break;
                    case RGBMode.G:
                        Mat.EnableKeyword("_RGB_G");
                        Mat.DisableKeyword("_RGB_RGBA");
                        Mat.DisableKeyword("_RGB_R");
                        Mat.DisableKeyword("_RGB_B");
                        break;
                    case RGBMode.B:
                        Mat.EnableKeyword("_RGB_B");
                        Mat.DisableKeyword("_RGB_RGBA");
                        Mat.DisableKeyword("_RGB_G");
                        Mat.DisableKeyword("_RGB_R");
                        break;
                }
            }

        }
        
        private void SetMaterialClearColor(Material Mat)
        {
            EditorGUI.BeginChangeCheck();
            ClearColor Ret = ClearColor.OFF;

            if(Array.IndexOf(Mat.shaderKeywords, "_CLEARCOLOR_OFF") != -1)
            {
                Ret = ClearColor.OFF;
  
            }
            else if(Array.IndexOf(Mat.shaderKeywords, "_CLEARCOLOR_OPEN") != -1)
            {
                Ret = ClearColor.Open;

            }

            if (EditorGUI.EndChangeCheck())
            {
                switch ((ClearColor)EditorGUILayout.EnumPopup(Ret))
                {
                    case ClearColor.OFF:
                        Mat.EnableKeyword("_CLEARCOLOR_OFF");
                        Mat.DisableKeyword("_CLEARCOLOR_OPEN");
                        break;
                    case ClearColor.Open:
                        Mat.EnableKeyword("_CLEARCOLOR_OPEN");
                        Mat.DisableKeyword("_CLEARCOLOR_OFF");
                        break;
                }
            }

        }
        
        private void SetMaterialSwitchColor(Material Mat)
        {
            EditorGUI.BeginChangeCheck();
            SwitchColor Ret = SwitchColor.MainColor;

            if(Array.IndexOf(Mat.shaderKeywords, "_SWITCHCOLOR_MAINCOLOR") != -1)
            {
                Ret = SwitchColor.MainColor;
  
            }
            else if(Array.IndexOf(Mat.shaderKeywords, "_SWITCHCOLOR_FRONTCOLOR") != -1)
            {
                Ret = SwitchColor.FrontColor;

            }

            if (EditorGUI.EndChangeCheck())
            {
                switch ((SwitchColor)EditorGUILayout.EnumPopup(Ret))
                {
                    case SwitchColor.MainColor:
                        Mat.EnableKeyword("_SWITCHCOLOR_MAINCOLOR");
                        Mat.DisableKeyword("_SWITCHCOLOR_FRONTCOLOR");
                        break;
                    case SwitchColor.FrontColor:
                        Mat.EnableKeyword("_SWITCHCOLOR_FRONTCOLOR");
                        Mat.DisableKeyword("_SWITCHCOLOR_MAINCOLOR");
                        break;
                }
            }

        }

        #endregion
        private void Show()
        {
            GUIStyle color;
            color = new GUIStyle(EditorStyles.label);
            color.normal.textColor = Color.green;
            #region 配置参数面板
            EditorGUILayout.BeginHorizontal(EditorStyles.helpBox);
            ConfigW = EditorGUILayout.BeginFoldoutHeaderGroup(ConfigW, "配置参数");
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space(5);
            if(ConfigW)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                MaterialProperty _ZWriteMode = FindProperty("_ZWriteMode", m_properties);
                m_materialEditor.ShaderProperty(_ZWriteMode,"ZWriteMode");
                MaterialProperty _CullMode = FindProperty("_CullMode", m_properties);
                m_materialEditor.ShaderProperty(_CullMode,"CullMode");
                MaterialProperty _ModeDst = FindProperty("_ModeDst", m_properties);
                m_materialEditor.ShaderProperty(_ModeDst,"ModeDst (混合模式)");
                
                MaterialProperty _ClearColor = FindProperty("_ClearColor", m_properties);
                m_materialEditor.ShaderProperty(_ClearColor,"抠黑(RGBA模式下剔除R通道)");
                SetMaterialClearColor(m_material);
                
                MaterialProperty _SwitchColor = FindProperty("_SwitchColor", m_properties);
                m_materialEditor.ShaderProperty(_SwitchColor,"双面颜色");
                SetMaterialSwitchColor(m_material);
                
                if (_SwitchColor.floatValue == 1.0f)
                {
                    EditorGUI.indentLevel++;
                    MaterialProperty _MainColorBack = FindProperty("_MainColorBack", m_properties);
                    m_materialEditor.ShaderProperty(_MainColorBack,"Front颜色");
                    EditorGUI.indentLevel--;
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
            EditorGUILayout.Space(5);
            

            #endregion
            
            
            #region 主纹理面板
            EditorGUILayout.BeginHorizontal(EditorStyles.helpBox);
            MainTexW = EditorGUILayout.BeginFoldoutHeaderGroup(MainTexW, "主纹理");
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space(5);
            if(MainTexW)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                MaterialProperty _MainColor = FindProperty("_MainColor", m_properties);
                m_materialEditor.ShaderProperty(_MainColor,"MainColor");
                
                MaterialProperty _Glow = FindProperty("_Glow", m_properties);
                m_materialEditor.ShaderProperty(_Glow,"Glow");
                
                MaterialProperty _Alpha = FindProperty("_Alpha", m_properties);
                m_materialEditor.ShaderProperty(_Alpha,"Alpha");
  
                MaterialProperty _RGB = FindProperty("_RGB", m_properties);
                m_materialEditor.ShaderProperty(_RGB,"贴图通道（RGB）");
                SetMaterialRGBAMode(m_material);
                
                MaterialProperty _MainTex = FindProperty("_MainTex", m_properties);
                m_materialEditor.ShaderProperty(_MainTex,"MainTex");
                
                MaterialProperty _UVSpeed = FindProperty("_UVSpeed", m_properties);
                m_materialEditor.ShaderProperty(_UVSpeed,"UV速度 (XY速度Z旋转)");
                
                MaterialProperty _CustomDisturbance = FindProperty("_CustomDisturbance", m_properties);
                m_materialEditor.ShaderProperty(_CustomDisturbance,"使用CustomData控制主纹理 (UV2, X,Y流动,W扰动)");
                if (_CustomDisturbance.floatValue == 1.0f)
                {

                    GUILayout.Label("已启用变体 _CUSTOMDISTURBANCE_ON",color);
                    m_material.EnableKeyword("_CUSTOMDISTURBANCE_ON");
                }
                else
                {
                    GUILayout.Label("已关闭变体 _CUSTOMDISTURBANCE_ON");
                    m_material.DisableKeyword("_CUSTOMDISTURBANCE_ON");
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
            EditorGUILayout.Space(5);
            
            #endregion

            #region 颜色贴图面板
      
//颜色贴图面板*************************************************************************************************************
            EditorGUILayout.BeginHorizontal(EditorStyles.helpBox);
            ColorTexW= EditorGUILayout.BeginFoldoutHeaderGroup(ColorTexW, "颜色贴图");
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space(5);
            if (ColorTexW)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                //控制宏开关
                MaterialProperty _OpenColorTex = FindProperty("_UseColorMap", m_properties);
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _OpenColorTex.hasMixedValue;
                var _USECOLORMAP_ON = EditorGUILayout.Toggle("采样颜色贴图", _OpenColorTex.floatValue==1);
                if (EditorGUI.EndChangeCheck())
                    _OpenColorTex.floatValue = _USECOLORMAP_ON ? 1 : 0;
                EditorGUI.showMixedValue = false;
                if (_OpenColorTex.floatValue == 1)
                {
                    m_material.EnableKeyword("_USECOLORMAP_ON");
                    EditorGUI.indentLevel++;
                    GUILayout.Label("已启用变体 _USECOLORMAP_ON",color);
                    MaterialProperty _ColorTex = FindProperty("_ColorMap", m_properties);
                    m_materialEditor.ShaderProperty(_ColorTex, "颜色贴图");
                    if(_ColorTex.textureValue!=null)
                    {
                        MaterialProperty _ColorPower = FindProperty("_ColorPower", m_properties);
                        m_materialEditor.ShaderProperty(_ColorPower, "颜色强度");
                        MaterialProperty ColorMapSpeed = FindProperty("ColorMapSpeed", m_properties);
                        m_materialEditor.ShaderProperty(ColorMapSpeed, "颜色贴图speed (XY速度Z旋转)");
                    }
                    EditorGUI.indentLevel--;
                }
                else
                {
                    m_material.DisableKeyword("_USECOLORMAP_ON");
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
            EditorGUILayout.Space(5);
            #endregion

            #region 扰动贴图面板

//扰动贴图*************************************************************************************************************  

            EditorGUILayout.BeginHorizontal(EditorStyles.helpBox);
            DisturbanceW= EditorGUILayout.BeginFoldoutHeaderGroup(DisturbanceW, "Disturbance扰动 (R)");
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space(5);
            
            if (DisturbanceW)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                MaterialProperty _OpenDisturbance = FindProperty("_UseDisturbance", m_properties);
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _OpenDisturbance.hasMixedValue;
                var _CUSTOMDISTURBANCE_ON = EditorGUILayout.Toggle("使用扰动", _OpenDisturbance.floatValue==1);
                if (EditorGUI.EndChangeCheck())
                    _OpenDisturbance.floatValue = _CUSTOMDISTURBANCE_ON ? 1 : 0;
                EditorGUI.showMixedValue = false;
                if (_OpenDisturbance.floatValue == 1)
                {
                    m_material.EnableKeyword("_USEDISTURBANCE_ON");
                    EditorGUI.indentLevel++;
                    GUILayout.Label("已启用变体 _USEDISTURBANCE_ON",color);
                    MaterialProperty _DisturbTex = FindProperty("_DisturbanceTex", m_properties);
                    m_materialEditor.ShaderProperty(_DisturbTex,"Disturbance扰动 (R)");
                    if(_DisturbTex.textureValue!=null)
                    {
                        EditorGUI.indentLevel++;
                        MaterialProperty _DistSpeed = FindProperty("_DistSpeed", m_properties);
                        m_materialEditor.ShaderProperty(_DistSpeed, "扰动强度");
                        MaterialProperty _FloatDst = FindProperty("_FloatDst", m_properties);
                        m_materialEditor.ShaderProperty(_FloatDst, "扰动值 (XY速度 ZW方向强度)");
                        EditorGUI.indentLevel--;
                    }
                    EditorGUI.indentLevel--;
                }
                else
                {
                    m_material.DisableKeyword("_USEDISTURBANCE_ON");
                }
                EditorGUILayout.EndVertical();
            }
            
            EditorGUILayout.EndFoldoutHeaderGroup();
            EditorGUILayout.Space(5);
            
            #endregion

            #region mask贴图面板

//mask贴图*************************************************************************************************************  
            EditorGUILayout.BeginHorizontal(EditorStyles.helpBox);
            MaskW= EditorGUILayout.BeginFoldoutHeaderGroup(MaskW, "Mask采样");
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space(5);
            if (MaskW)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                MaterialProperty _OpenMaskTex = FindProperty("_UseMask", m_properties);
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _OpenMaskTex.hasMixedValue;
                var _USEMASK_ON = EditorGUILayout.Toggle("使用遮罩", _OpenMaskTex.floatValue==1);
                if (EditorGUI.EndChangeCheck())
                    _OpenMaskTex.floatValue = _USEMASK_ON ? 1 : 0;
                EditorGUI.showMixedValue = false;
                if (_OpenMaskTex.floatValue == 1)
                {
                    m_material.EnableKeyword("_USEMASK_ON");
                    EditorGUI.indentLevel++;
                    GUILayout.Label("已启用变体 _USEMASK_ON",color);
                    MaterialProperty _MaskTex = FindProperty("_MaskTex", m_properties);
                    m_materialEditor.ShaderProperty(_MaskTex,"MaskTex");
                    if(_MaskTex.textureValue!=null)
                    {
                        EditorGUI.indentLevel++;
                        MaterialProperty MaskSpeed = FindProperty("MaskSpeed", m_properties);
                        m_materialEditor.ShaderProperty(MaskSpeed,"MaskSpeed (XY速度Z旋转)");
                        EditorGUI.indentLevel--;
                    }
                    EditorGUI.indentLevel--;
                }
                else
                {
                    m_material.DisableKeyword("_USEMASK_ON");
                
                }
                EditorGUILayout.EndVertical();
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
            EditorGUILayout.Space(5);

            
#endregion     

            #region 溶解贴图面板

//溶解贴图*************************************************************************************************************  
            EditorGUILayout.BeginHorizontal(EditorStyles.helpBox);
            _DissolveW= EditorGUILayout.BeginFoldoutHeaderGroup(_DissolveW, "溶解采样");
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space(5);
            if (_DissolveW)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                MaterialProperty _OpenDissolveTex = FindProperty("_UseDisvo", m_properties);
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _OpenDissolveTex.hasMixedValue;
                var _USEDISVO_ON = EditorGUILayout.Toggle("采样溶解贴图", _OpenDissolveTex.floatValue==1);
                if (EditorGUI.EndChangeCheck())
                    _OpenDissolveTex.floatValue = _USEDISVO_ON ? 1 : 0;
                EditorGUI.showMixedValue = false;
                if (_OpenDissolveTex.floatValue == 1)
                {
                    m_material.EnableKeyword("_USEDISVO_ON");
                    EditorGUI.indentLevel++;
                    GUILayout.Label("已启用变体 _USEDISVO_ON",color);
                    MaterialProperty _DissolveTex = FindProperty("_DissolveTex", m_properties);
                    m_materialEditor.ShaderProperty(_DissolveTex,"溶解贴图(R)");
                    if(_DissolveTex.textureValue!=null)
                    {
                        EditorGUI.indentLevel++;
                        MaterialProperty _CustomDissolve = FindProperty("_CustomDissolve", m_properties);
                        m_materialEditor.ShaderProperty(_CustomDissolve,"使用CustomData控制溶解 (Z)");
                        MaterialProperty _DissolveControl = FindProperty("_DissolveControl", m_properties);
                        m_materialEditor.ShaderProperty(_DissolveControl,"溶解进程");
                        MaterialProperty _DissolveControl1 = FindProperty("_DissolveControl1", m_properties);
                        m_materialEditor.ShaderProperty(_DissolveControl1,"溶解强度");
                        MaterialProperty _SoftEdge = FindProperty("_SoftEdge", m_properties);
                        m_materialEditor.ShaderProperty(_SoftEdge,"边缘羽化");
                        MaterialProperty _UVSpeed2 = FindProperty("_UVSpeed2", m_properties);
                        m_materialEditor.ShaderProperty(_UVSpeed2,"溶解UV速度 (XY速度)");
                        MaterialProperty _PowerSize = FindProperty("_PowerSize", m_properties);
                        m_materialEditor.ShaderProperty(_PowerSize,"方向强度");
                        MaterialProperty _LightColor = FindProperty("_LightColor", m_properties);
                        m_materialEditor.ShaderProperty(_LightColor,"边缘光颜色");
                        MaterialProperty _LightSize = FindProperty("_LightSize", m_properties);
                        m_materialEditor.ShaderProperty(_LightSize,"边缘光尺寸");
                        EditorGUI.indentLevel--;
                    }

                    EditorGUI.indentLevel--;
                }
                else
                {
                    m_material.DisableKeyword("_USEDISVO_ON");
                
                }
                EditorGUILayout.EndVertical();

            }
            EditorGUILayout.EndFoldoutHeaderGroup();
            EditorGUILayout.Space(5);
                    
        #endregion 
        }
    }
}
