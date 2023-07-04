Shader "WLTX/ToonLight01"
{
    Properties
    {
        //***************基础属性
        [Header(Base Color)]
        [MainTexture]_BaseMap("基础纹理 _BaseMap (Albedo)", 2D) = "white" {}
        [hdr][MainColor]_BaseColor("基础颜色 _BaseColor", Color) = (1,1,1)
        [hdr]_SecondColor("暗部颜色", Color)=(1,1,1,1)
        [hdr]_BaseSkinColor("皮肤的基础颜色 _BaseSkinColor", Color) = (1,1,1)
        _MinZ("_MinZ",Range(-1,1.84) ) = 0

		_Hue("色相", Range(0,359)) = 0
		_Saturation("饱和度", Range(0, 5)) = 1	//调整饱和度
		_Value("亮度", Range(0,3.0)) = 1.0
       
		_NormalMap("法线 NormalMap", 2D) = "bump" {}
        //扰动强度
        _NormalScale("法线强度 NormalScale", Range(0,3)) = 0
        //漫反射强度
        _DiffuseScale("漫反射强度 DiffuseScale", Range(0,3)) = 0

        [Header(OpenPBR)]
        [Toggle(_OpenPbr)]_OpenPbr("开启PBR材质", int) = 0
        _PbrLightDir("PbrLightDir",Vector)=(0.28,-0.35,1,1)
        [NoScaleOffset]_MetallicMap("MetallicMap", 2D) = "white" {} 
        _MetallicStrength ("MetallicStrength", Range(0,1)) = 0 //金属强度Metallic strength
        _Smoothness("Smoothness",Range(-1,1)) = 0 //光滑度
        _DiffuseIntensity("PBR暗部强度",Range(0.1,3))=0.4
        _PBRColor("PBRColor", Color)=(1,1,1,1)

        //***************光照阴影属性
		[Header(Lighting)]
		[NoScaleOffset]_LightingMap("光照贴图 _LightingMap", 2D) = "white" {}
		_SpecularMultiplier("高光强度阈值 _SpecularMultiplier", Range(0,1)) = 1

		[Header(Shadow)]
		[NoScaleOffset]_RampMap("阴影渐变贴图 _RampMap", 2D) = "white" {}
		_RampMapColor("阴影叠加颜色 _RampMapColor", Color) = (1,1,1)
		
		_ShadowAmount("阴影强弱 _ShadowAmount", Range(0,1)) = 0.75
		_ShadowColor("脸部的阴影颜色 _ShadowColor", Color) = (0,0,0)
		
		//_RimAreaMid("边缘光过度范围2 _RimAreaMid", Range(0, 1)) = 0.5
		_RimAreaSoft("脸部阴影柔化", Range(0.01, 1)) = 0.0156

		[Toggle(_IsFace)] _IsFace("IsFace", Float) = 0.0
		_HairShadowDistace("_HairShadowDistance", Float) = 1
		//_HeightCorrectMax("HeightCorrectMax", float) = 1.6
		//_HeightCorrectMin("HeightCorrectMin", float) = 1.51

        [Header(realtime shadow)]
        [Toggle(_IsUseRealtimeShadow)] _IsUseRealtimeShadow("是否开启实时阴影", Float) = 1.0

		[Header(Dynamic)]
		_ForwardDirection("脸部阴影角度方向控制 _ForwardDirection", Vector) = (0, 0, 1, 1)

        //*******************描边属性
        [Header(OutLine)]
        _OutlineCol("OutlineCol", Color) = (1,1,1,1)  
        _OutlineFactor("OutlineFactor", Range(0,2)) = 1




        //*********************rim 边缘光
        [Header(Rim)]
        [hdr]_ColorRim("边缘光的颜色", Color) = (1,1,1,1)
        //_ColorRimBackIntensity("边缘光背光的强度", Float) = 1.0
        _OffsetMul("边缘光宽度", Range(0, 2)) = 1
        _Threshold("边缘光阈值", Range(0, 1)) = 0.8
        _OffsetMulHard("边缘光硬边", Range(0, 1)) = 0.5


        //*********************锦上添花
        [Header(Other Other)]
        //MatCap 金属材质捕获
	    [Header(MetalMap)]
        _MetalMap("金属材质捕获 _MetalMap", 2D) = "white" {}
        _MatCapIntensity("金属材质捕获强度 MatCapIntensity", Range(0,3)) = 0
      
         //FlowMap 流光
	    [Header(FlowMap)]
		_FlowMap("金属流光贴图 _FlowMap", 2D) = "black" {}
		_FlowMapCol("流光颜色",Color) = (1,1,1,1)
		_SpeedX("X轴速度",Range(0.0,2.0)) = 1.0

        //蕾丝透贴
        [Header(Alpha)]
        [Toggle(_UseAlphaClipping)]_UseAlphaClipping("开启蕾丝(Render Queue设置成 2501) _UseAlphaClipping", Float) = 0
        _Cutoff("蕾丝 _Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5

        //SSAO
		[Header(SSAO)]
		[Toggle(_UseSSao)]_UseSSao("开启环境光阴影遮蔽  _UseSSao", Float) = 0
		_UseSSaoRang("环境光阴影遮蔽范围调节 (_UseSSaoRang)", Range(0.0, 1.0)) = 1.0
		_UseSSaoIntensity("环境光阴影遮蔽强度调节 (_UseSSaoIntensity)", Range(0.0, 2.0)) = 1.0

 

        // _FresnelMask("_FresnelMask", Range(0, 10)) = 1
		// _RimRadius("Rim Radius", Range(0, 1)) = 0.716
		// _RimPower("_RimPower", Range(0, 5)) = 1
        //[Header(Bloom)]
        //_MaskColor("Bloom Mask Color", Color) = (1, 1, 1, 1)
        //_CustomMaskMap("金属泛光贴图 Bloom Mask Map", 2D) = "black" {}

        //Emission 自发光 
        [Header(Emission)]
        //[Toggle]_UseEmission("_UseEmission (on/off Emission completely)", Float) = 0
        _EmissionColor("自发光颜色 _EmissionColor", Color) = (0,0,0)
        _EmissionMulByBaseColor("自发光阈值 _EmissionMulByBaseColor", Range(0,1)) = 0
        //[NoScaleOffset]_EmissionMap("_EmissionMap", 2D) = "white" {}
        //_EmissionMapChannelMask("_EmissionMapChannelMask", Vector) = (1,1,1,0)


        //stencil property
		[Header(Stencil)]
		[IntRange]_Stencil("Stencil ID", Range(0,255)) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", Float) = 8
		[IntRange]_StencilWriteMask("Stencil Write Mask", Range(0,255)) = 255
		[IntRange]_StencilReadMask("Stencil Read Mask", Range(0,255)) = 255
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilPass("Stencil Pass", Float) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilFail("Stencil Fail", Float) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilZFail("Stencil ZFail", Float) = 0 

      
        ////////////////////////////un use/////////////////////////////////////////////////////
		[Space(100)]
		[Header(UnUse)]
		[Header(Occlusion)]
        [HideInInspector][Toggle]_UseOcclusion(" _UseOcclusion (on/off Occlusion completely)", Float) = 0
        [HideInInspector]_OcclusionStrength("_OcclusionStrength", Range(0.0, 1.0)) = 1.0
        [HideInInspector]_OcclusionIndirectStrength("_OcclusionIndirectStrength", Range(0.0, 1.0)) = 0.5
        [HideInInspector]_OcclusionDirectStrength("_OcclusionDirectStrength", Range(0.0, 1.0)) = 0.75
        [HideInInspector][NoScaleOffset]_OcclusionMap("_OcclusionMap", 2D) = "white" {}
        [HideInInspector]_OcclusionMapChannelMask("_OcclusionMapChannelMask", Vector) = (1,0,0,0)
        [HideInInspector]_OcclusionRemapStart("_OcclusionRemapStart", Range(0,1)) = 0
        [HideInInspector]_OcclusionRemapEnd("_OcclusionRemapEnd", Range(0,1)) = 1
    }
    
    SubShader
    {       
   
        HLSLINCLUDE
		#pragma shader_feature_local_fragment _UseAlphaClipping
		#pragma shader_feature_local_fragment _UseSSao
        
        ENDHLSL

	    // Tags{ "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline"   "Queue" = "Transparent" } 



	

        Pass
        {               
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            //0629: 裙子的上半部分一个材质球，裙子的蕾丝一个材质球，分别控制渲染队列，
            //来实现单独对蕾丝的透贴控制，又不对裙子上半部分造成透贴。

			Tags
			{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"UniversalMaterialType" = "Lit"
			"IgnoreProjector" = "True"

			"Queue" = "Opaque" 

			}
      
			Stencil
				{
					Ref[_Stencil]
					Comp[_StencilComp]
					ReadMask[_StencilReadMask]
					WriteMask[_StencilWriteMask]
					Pass[_StencilPass]
					Fail[_StencilFail]
					ZFail[_StencilZFail]
				}


            //Cull Back
			Cull Off
			ZTest LEqual
            ZWrite On
            //Blend One Zero
			Blend SrcAlpha  OneMinusSrcAlpha //透明度混合

            HLSLPROGRAM

            #pragma multi_compile_instancing

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _OpenPbr 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION  //urp ssao
			


            #pragma vertex VertexShaderWork
            #pragma fragment ShadeFinalColor
         
            #pragma shader_feature _IsFace
            #pragma shader_feature _IsUseRealtimeShadow

            #include "ToonLightShared01.hlsl"

            ENDHLSL
        }

		UsePass "Universal Render Pipeline/Lit/ShadowCaster"


        Pass
        {
        
            Tags 
            {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType"="Opaque"
                "UniversalMaterialType" = "Lit"
                "IgnoreProjector" = "True"
                "Queue"="Geometry"
            }


            Name "BloomMask"
            Tags{ "LightMode" = "BloomMask"}

            ZWrite On
            ColorMask RGB
            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            //#pragma exclude_renderers d3d11_9x
            //#pragma target 2.0

            #pragma vertex vertMask
            #pragma fragment fragMask

		
			#include "ToonLightShared01.hlsl"


            ENDHLSL
        }
 

        Pass 
		{
			Tags 
			{
				"RenderPipeline" = "UniversalPipeline"
				"RenderType"="Opaque"
				"UniversalMaterialType" = "Lit"
				"IgnoreProjector" = "True"
				"Queue"="Geometry"
			}
 
			Cull Front
			ZWrite On
            //Blend One Zero
            //Blend One One


			Name "Toon Out Line"
			
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
    		#include "ToonOutlineChange.hlsl"


			#pragma vertex vertOutLine
			#pragma fragment fragOutLine


            ENDHLSL
		}




   //     Pass
   //     {

   //         Tags 
   //         {
   //             "RenderPipeline" = "UniversalPipeline"
   //             "RenderType"="Opaque"
   //             "UniversalMaterialType" = "Lit"
   //             "IgnoreProjector" = "True"
   //             "Queue"="Geometry"
   //         }


   //         Name "ShadowCaster"
   //         Tags{"LightMode" = "ShadowCaster"}

   //         ZWrite On
   //         ZTest LEqual 
   //         ColorMask 0
   //         Cull Back

   //         HLSLPROGRAM

   //         #pragma vertex VertexShaderWork
   //         #pragma fragment BaseColorAlphaClipTest // we only need to do Clip(), no need shading

   //         #define ToonShaderApplyShadowBiasFix

			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
   //         #include "ToonLightShared.hlsl"

   //         ENDHLSL
   //     }



		

        Pass
        {
            Tags 
            {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType"="Opaque"
                "UniversalMaterialType" = "Lit"
                "IgnoreProjector" = "True"
                "Queue"="Geometry"
            }


            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }

	
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"

   CustomEditor "ToonLightShaderGUI01"
}
