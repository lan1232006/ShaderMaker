#ifndef TOON_LIGHT_SHARED01_INCLUDE
#define TOON_LIGHT_SHARED01_INCLUDE
 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


#include "ToonLightCommon.hlsl"
#include "PBRFunction.hlsl"

struct Attributes
{
    float3 positionOS   : POSITION;
    half3 normalOS      : NORMAL;
    half4 tangentOS     : TANGENT;
    float2 uv           : TEXCOORD0;

    float2 uv1           : TEXCOORD1; //normal map
    
    float2 uv2           : TEXCOORD2; //ao map
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float4 positionWSAndFogFactor   : TEXCOORD1;
    half3 normalWS                  : TEXCOORD2;

    float4 posCS : SV_POSITION; 
    float4 scrPos : TEXCOORD3;  //屏幕空间坐标
    float3 positionVS : TEXCOORD4;
    float4 positionNDC: TEXCOORD5;//ndc坐标

    float4 positionCS : TEXCOORD6;

    //normal map field
    float2 uv1                       : TEXCOORD7;//normal map
    float3 lightDir : TEXCOORD8;     // 光照方向

    //ao map field
    float2 uv2                       : TEXCOORD9;//ao map
    float3 tangentWS : TEXCOORD10;
    float3 bitangentWS : TEXCOORD11;

};

sampler2D _BaseMap; 
sampler2D _NormalMap; 
sampler2D _AoMap; 
sampler2D _MetalMap;
sampler2D _FlowMap;

TEXTURE2D(_HairSoildColor);
SAMPLER(sampler_HairSoildColor);


//sampler2D _EmissionMap;
sampler2D _OcclusionMap,_MetallicMap;
sampler2D _LightingMap;
sampler2D _RampMap;


sampler2D _CustomMaskMap; 


CBUFFER_START(UnityPerMaterial)
    // base color
    float4  _BaseMap_ST;
    half4   _BaseColor,_SecondColor,_PBRColor;
    half4   _BaseSkinColor;
    float _Smoothness, _MetallicStrength;

    float4 _MaskColor;
    float _isEmission;
    float isFace = false;
	float4 _NormalMap_ST;
    float _NormalScale,_MinZ;
    float _DiffuseScale;

    float4 _MetalMap_ST;
    float _MatCapIntensity;

	float4 _FlowMap_ST;
	float4 _FlowMapCol;
	float _SpeedX,_DiffuseIntensity;


    // alpha
    half    _Cutoff;

	//_UseSSaoIntensity
	half _UseSSaoIntensity;
	half _UseSSaoRang;
	

    // rim
	float4 _ColorRim;
    float _ColorRimBackIntensity;
    float _OffsetMul;
    float _Threshold;
    float _OffsetMulHard;
    // float _FresnelMask;
    // float _RimRadius;

    // float _RimPower;
    float _RimAreaMid;
    float _RimAreaSoft;
	float _HairShadowDistace;
	float _HeightCorrectMax;
	float _HeightCorrectMin;

    // emission
    //float   _UseEmission;
    half3   _EmissionColor;
    half    _EmissionMulByBaseColor;
    //half3   _EmissionMapChannelMask;

    // occlusion
    float   _UseOcclusion;
    half    _OcclusionStrength;
    half    _OcclusionIndirectStrength;
    half    _OcclusionDirectStrength;
    half4   _OcclusionMapChannelMask;
    half    _OcclusionRemapStart;
    half    _OcclusionRemapEnd;

    // lighting
    half    _SpecularMultiplier;

    // shadow
    half3   _ShadowColor;
    half    _ShadowAmount;

	half3 _RampMapColor;

    // dynamic
    half4   _ForwardDirection,_PbrLightDir;


    //hsv
    // float4 _HSVTarget;
    // half   _HSVRange;
    // half4  _HSV;   

	half _Saturation;
	half _Hue;
	half _Value;

CBUFFER_END

TEXTURE2D_X_FLOAT(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

struct ToonSurfaceData
{
    half3   albedo;
    half3   diffuse;
    half3   ao;
    half    alpha;
    half3   emission;
    half    occlusion;
    half3   specular;
    float2  uv;
};

struct LightingDatas
{
    half3   normalWS;
    float3  positionWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
    half4   lightingMapColor;

	float4 scrPos;  //屏幕空间坐标
	float4 positionNDC;//ndc坐标
	float4 positionCS; 
};

Varyings VertexShaderWork(Attributes input)
{
    Varyings output;

    //法线贴图...
    output.uv1 = TRANSFORM_TEX(input.uv1,_NormalMap);

    float3 binormal = cross( normalize(input.normalOS), normalize(input.tangentOS.xyz) ) * input.tangentOS.w;
    float3x3 rotation = float3x3( input.tangentOS.xyz, binormal, input.normalOS);

    // Transform the light direction from object space to tangent space
    output.lightDir = mul(rotation, TransformWorldToObject(GetCameraPositionWS()) - input.positionOS).xyz;


    //高度贴图...     
    // float height = tex2Dlod(_NormalMap, float4(output.uv1,0,0)).x*2-1;
    // input.positionOS += input.normalOS * (height * _NormalScale); 

    //AO贴图...
   // output.uv2 = TRANSFORM_TEX(input.uv2, _AoMap);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float3 positionWS = vertexInput.positionWS;

    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    output.uv = TRANSFORM_TEX(input.uv,_BaseMap);

    output.positionWSAndFogFactor = float4(positionWS, fogFactor);
    output.normalWS = vertexNormalInput.normalWS;
    output.tangentWS = vertexNormalInput.tangentWS;
    output.bitangentWS = vertexNormalInput.bitangentWS;
    output.positionCS = TransformWorldToHClip(positionWS);

    output.posCS = vertexInput.positionCS;
    output.scrPos = ComputeScreenPos(vertexInput.positionCS);
    output.positionVS = vertexInput.positionVS;
    output.positionNDC = vertexInput.positionNDC;    

    return output;
}

Varyings vertMask(Attributes input)
{
    Varyings output = (Varyings)0;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.posCS = vertexInput.positionCS;
    output.uv = TRANSFORM_TEX(input.uv,_BaseMap);

    return output;
}

// ------------------------------ fragment ---------------------------

#include "ToonLightEquation01.hlsl"


float4 fragMask(Varyings input) : SV_Target
{
    float4 texValue = tex2D(_CustomMaskMap, input.uv);
    return float4(texValue.r, 0, 0, 1);
}


half4 GetFinalBaseColor(Varyings input)
{
    half4 baseMapColor = tex2D(_BaseMap, input.uv);

    //normalMap 扰动基础纹理uv
    // half4 normalMap = tex2D(_NormalMap,input.uv1);
    // half2 offset = UnpackNormal(normalMap).rg;
    // //移动UV后采样
    // input.uv.xy += offset * _NormalScale;
    // half4 baseMapColor = tex2D(_BaseMap,input.uv);
    half ramp =(input.positionWSAndFogFactor.y - _MinZ) / (1.9 - _MinZ) * (1 - 0) + 0;
    half4 color01 = GetBaseColor(baseMapColor.a);
    half4 color = lerp(_SecondColor,color01,ramp);

    return baseMapColor *color;
}

float3 GetTangentNormal(Varyings input)
{
    float4 packedNormal = tex2D(_NormalMap, input.uv1);
    float3 tangentNormal;
    tangentNormal = UnpackNormal(packedNormal);
    tangentNormal.xy *= _NormalScale;
    tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
    return tangentNormal;
}
float3 GetTangentNormalWS(Varyings input)
{
    float4 packedNormal = tex2D(_NormalMap, input.uv1);
    float3 tangentNormal;
    tangentNormal = UnpackNormal(packedNormal);
    tangentNormal.xy *= _NormalScale;
    tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
    
    float3x3 rotation = float3x3( input.tangentWS, input.bitangentWS, input.normalWS);
    float3 normalWS = mul(tangentNormal,rotation);
    return normalWS;
}

float3 GetFinalDiffuseColor(Varyings input, float3 albedo)
{
    float3 tangentLightDir = normalize(input.lightDir);
    float3 tangentNormal =  GetTangentNormal(input); 
    float3 diffuse = _MainLightColor.rgb * albedo * max(0,dot(tangentNormal, tangentLightDir)) * _DiffuseScale; 


    return diffuse;
}

float3 GetFinalAOColor(Varyings input)
{
	return 0;
}


half3 GetFinalEmissionColor(Varyings input)
{
    half3 result = 0;
    // if(_UseEmission)
    // {
    //     result = tex2D(_EmissionMap, input.uv).rgb * _EmissionMapChannelMask * _EmissionColor.rgb;
    // }

    return result;
}

half GetFinalOcculsion(Varyings input)
{
    half result = 1;
    if(_UseOcclusion)
    {
        half4 texValue = tex2D(_OcclusionMap, input.uv);
        half occlusionValue = dot(texValue, _OcclusionMapChannelMask);
        occlusionValue = lerp(1, occlusionValue, _OcclusionStrength);
        occlusionValue = invLerpClamp(_OcclusionRemapStart, _OcclusionRemapEnd, occlusionValue);
        result = occlusionValue;
    }

    return result;
}

void DoClipTestToTargetAlphaValue(half alpha) 
{
#if _UseAlphaClipping
    //if(alpha < 1)
        clip(alpha - _Cutoff);
#endif
}

ToonSurfaceData InitializeSurfaceData(Varyings input)
{
    ToonSurfaceData output;

    // albedo
    float4 baseColorFinal = GetFinalBaseColor(input);
    output.albedo = baseColorFinal.rgb;
    output.alpha = baseColorFinal.a;

    // 模型一般不需要做alpha测试，影响效率
    half4 baseMapColor = tex2D(_BaseMap, input.uv);
	//DoClipTestToTargetAlphaValue(1);
	DoClipTestToTargetAlphaValue(baseMapColor.a);

    //DIFFUSE
    output.diffuse = GetFinalDiffuseColor(input, output.albedo);

    //Ambient Occlusion
    output.ao = GetFinalAOColor(input);

    // emission
    output.emission = GetFinalEmissionColor(input);

    // occlusion
    output.occlusion = GetFinalOcculsion(input);

    // specular
    output.specular = half3(0,0,0);
    output.uv = input.uv;
    return output;
}

LightingDatas InitializeLightingData(Varyings input)
{
    LightingDatas lightingData;
    lightingData.positionWS = input.positionWSAndFogFactor.xyz;
    lightingData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);  
    lightingData.normalWS = normalize(input.normalWS);
    lightingData.lightingMapColor = tex2D(_LightingMap, input.uv);

	lightingData.scrPos = input.scrPos;
	lightingData.positionNDC = input.positionNDC;
	lightingData.positionCS = input.posCS;

    return lightingData;
}



half3 ShadeAllLights(Varyings input, inout ToonSurfaceData surfaceData, LightingDatas lightingData)
{
    half3 indirectResult = ShadeGI(surfaceData, lightingData);
    Light mainLight = GetMainLight();

    float3 shadowTestPosWS = lightingData.positionWS;
    //float3 shadowTestPosWS = lightingData.positionWS + mainLight.direction;
    
//#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
#if _IsUseRealtimeShadow
    float4 shadowCoord = TransformWorldToShadowCoord(shadowTestPosWS);
    mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
#endif 

    half3 mainLightResult = ShadeMainLight(surfaceData, lightingData, mainLight);

    //计算实时阴影颜色
    float3 realTimeShadowColor = lerp(_RampMapColor, 1, mainLight.shadowAttenuation);


    //叠加实时阴影
	mainLightResult *= realTimeShadowColor;

    half3 additionalLightSumResult = 0;

#ifdef _ADDITIONAL_LIGHTS
    //额外光源
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        int perObjectLightIndex = GetPerObjectLightIndex(i);
        Light light = GetAdditionalPerObjectLight(perObjectLightIndex, lightingData.positionWS);
        //light.shadowAttenuation = AdditionalLightShadow(perObjectLightIndex, shadowTestPosWS, 0, 0);
        light.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, lightingData.positionWS);

        additionalLightSumResult += ShadeAdditionalLight(surfaceData, lightingData, light);
        //additionalLightSumResult += ShadeSingleLight(light, lightingData.normalWS, lightingData.viewDirectionWS, true);
    }
#endif

	//复刻 unity urp ssao
#if defined(_SCREEN_SPACE_OCCLUSION) && defined(_UseSSao)
	AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(GetNormalizedScreenSpaceUV(input.posCS)); 
	if(aoFactor.directAmbientOcclusion < _UseSSaoRang)
		mainLightResult *= aoFactor.directAmbientOcclusion * _UseSSaoIntensity;
	if (aoFactor.indirectAmbientOcclusion < _UseSSaoRang)
		indirectResult *= aoFactor.indirectAmbientOcclusion * _UseSSaoIntensity;
#endif


    half3 emissionResult = ShadeEmission(surfaceData, lightingData);

    half rimIntensity = ShadeRim(input, surfaceData, lightingData, mainLight);
    float4 rimResult = float4(rimIntensity *  GetBaseColor(surfaceData.alpha).rgb * _ColorRim.rgb, 1);


    //return   rimIntensity > 0 ? rimResult.rgb : CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, 0, surfaceData, lightingData);
    return  CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, rimResult, surfaceData, lightingData);
}

half3 ApplyFog(half3 color, Varyings input)
{
    half fogFactor = input.positionWSAndFogFactor.w;
    color = MixFog(color, fogFactor);
    return color;  
}

float4 BaseColorAlphaClipTest(Varyings input) : SV_Target
{
    DoClipTestToTargetAlphaValue(GetFinalBaseColor(input).a);

	float4 color;
	color.xyz = float3(0.0, 0.0, 0.0);
	color.a = 1;
	return color;

}


//////////////////////////////////////////////////////////
//等于
float when_eq(float x, float y)
{
	return 1.0 - abs(sign(x - y));
}
//RGB to HSV
float3 RGBConvertToHSV(float3 rgb)
{
	float R = rgb.x, G = rgb.y, B = rgb.z;
	float3 hsv;
	float max1 = max(R, max(G, B));
	float min1 = min(R, min(G, B));

	float IsR = when_eq(R, max1);
	float IsG = when_eq(G, max1);
	float IsB = when_eq(B, max1);
	float RVal = IsR * (G - B) / (max1 - min1 + 1e-20f);
	float GVal = IsG * (2 + (B - R) / (max1 - min1 + 1e-20f));
	float BVal = IsB * (4 + (R - G) / (max1 - min1 + 1e-20f));
	hsv.x = RVal + GVal + BVal;

	hsv.x = hsv.x * 60.0;

	// if (hsv.x < 0) 
	// 	hsv.x = hsv.x + 360;
	hsv.x = hsv.x + 360 * step(hsv.x, 0);

	hsv.z = max1;
	hsv.y = (max1 - min1) / (max1 + 1e-20f);
	return hsv;
}

//HSV to RGB
float3 HSVConvertToRGB(float3 hsv)
{
	float R, G, B;
	//float3 rgb;
	if (hsv.y == 0)
	{
		R = G = B = hsv.z;
	}
	else
	{
		hsv.x = hsv.x / 60.0;
		int i = (int)hsv.x;
		float f = hsv.x - (float)i;
		float a = hsv.z * (1 - hsv.y);
		float b = hsv.z * (1 - hsv.y * f);
		float c = hsv.z * (1 - hsv.y * (1 - f));
		switch (i)
		{
		case 0: R = hsv.z; G = c; B = a;
			break;
		case 1: R = b; G = hsv.z; B = a;
			break;
		case 2: R = a; G = hsv.z; B = c;
			break;
		case 3: R = a; G = b; B = hsv.z;
			break;
		case 4: R = c; G = a; B = hsv.z;
			break;
		default: R = hsv.z; G = a; B = b;
			break;
		}
	}
	return float3(R, G, B);
}
half3 ShadePBR(half3 albedo,LightingDatas lightingData,Varyings input,half4 metallicGlossTex)
{

    Light mainLight = GetMainLight();
    float3 Lightdirection =normalize(_PbrLightDir);
    half4 metallicGloss = metallicGlossTex;
    half metallic = metallicGloss.x * _MetallicStrength;
    //half roughness = 1 - metallicGloss.y * _Smoothness;
    _Smoothness = 1-_Smoothness;
    half perceptualRoughness = metallicGloss.a*_Smoothness;
    half smoothness = 1 -perceptualRoughness;
    half roughness = perceptualRoughness*perceptualRoughness;
    float sqrRoughness = roughness*roughness;
    
    //half metallicGloss.g = tex2D(_metallicGloss.gMap, input.uv).g;
    

    float3 TnormalWS = GetTangentNormalWS(input);
    //get input
    //float3 normalWS = normalize(input.normalWS);
    float3 viewDirWS = SafeNormalize(GetCameraPositionWS()-lightingData.positionWS);
    float3 halfDir = normalize(viewDirWS+Lightdirection);
    float NdotH = max(saturate(dot(TnormalWS, halfDir)),0.000001);
    float NdotL = max(saturate(dot(input.normalWS, Lightdirection)),0.000001);
    float NdotV = max(saturate(dot(TnormalWS, viewDirWS)),0.000001);
    float HdotL = max(saturate(dot(halfDir, Lightdirection)),0.000001);
    float VdotH = max( saturate(dot(viewDirWS,halfDir)),0.000001);
    float3 F0 = lerp(0.04, albedo, metallic);
    
    ///////////////////////////
    //    direct light       //
    //////////////////////////
    //specular section
    float D = D_Function(NdotH, roughness);
    //return NdotL;
    float G = G_Function(NdotL, NdotV, sqrRoughness);
    //return G;
    float3 F = F_Function(HdotL, F0);
    //return float4(TnormalWS,1);
    
    float3 BRDFSpeSection = (D*G*F)/(4*NdotL*NdotV);
    float3 DirectSpeColor = BRDFSpeSection*mainLight.color*NdotL*PI;
    //return dot(TnormalWS,mainLight.direction);
    //return float4(mainLight.direction, 1);
    
    //diffuse section
    float3 KS = F;
    float3 KD = (1-KS)*(1-metallic);
    float3 directDiffColor = KD*albedo.xyz*mainLight.color*NdotL;
    float3 directColor = DirectSpeColor+directDiffColor;
    //return dot(TnormalWS, Lightdirection);
    //return float4(directColor, 1);                
    ///////////////////////////
    //    indirect light       //
    //////////////////////////

    //indirect diffuse 
    float3 SHcolor = SH_IndirectionDiff(TnormalWS);            
    float3 IndirKS=IndirF_Function(NdotV,F0,roughness);
    //float3 ambient = 0.01 * albedo;
    //half3 imgBaseLightDiff = max(half3(0.0, 0.0, 0.0), ambient + IndirKS);
    float3 IndirKD = (1-IndirKS)*(1-metallic);
    //float3 IndirDiffColor=SHcolor*IndirKD*albedo.xyz*_DiffuseIntensity*metallicGloss.a;
    //间接光漫反射 目前 给一个定值
    float3 IndirDiffColor=albedo.xyz*_DiffuseIntensity*metallicGloss.a;
    //return float4(IndirDiffColor,1);

    //indirect specular 
    float3 IndirSpeCubeColor = IndirSpeCube(TnormalWS,viewDirWS,perceptualRoughness);
    
    //return float4(IndirSpeCubeColor,1);
    float3 IndirSpeCubeFactor = IndirSpeFactor(roughness,smoothness,BRDFSpeSection,F0,NdotV); 
    //return float4(IndirSpeCubeFactor,1);
    float3 IndirSpeColor = IndirSpeCubeColor*IndirSpeCubeFactor;
    //return float4(IndirSpeColor,1);
    float3 IndirColor = IndirSpeColor+IndirDiffColor;
    //return float4(IndirColor,1);
    float3 Pbr_albedo = IndirColor+directColor;
    //return float4(input.color.aaa,1);

    return float4(Pbr_albedo, 1);
}


// this is frag
half4 ShadeFinalColor(Varyings input) : SV_TARGET
{
    //half4 albedo = tex2D(_BaseMap, input.uv);
    half4 metallicGloss = 0;
    //return (0,0,0,0);
    ToonSurfaceData surfaceData = InitializeSurfaceData(input);
    LightingDatas lightingData = InitializeLightingData(input);
    half3 color01 = ShadeAllLights(input, surfaceData, lightingData);
    half3 color02 =0;
#ifdef _OpenPbr
    float4 customLight  = _PbrLightDir;

    metallicGloss = tex2D(_MetallicMap,input.uv);
    color02 = ShadePBR(surfaceData.albedo,lightingData,input,metallicGloss)*_PBRColor;
#endif

    //color = applyHsv(color,_HSVRange,_HSV.xyz);
    //half3 finalColor =color02;
    half3 finalColor = lerp(color01,color02,metallicGloss.b);
	half3 colorHSV;
	colorHSV = RGBConvertToHSV(finalColor);   //转换为HSV
	colorHSV.x += _Hue; //调整偏移色相 Hue值
	colorHSV.x = fmod(colorHSV.x, 360.0);    //超过360的值从0开始
	colorHSV.y *= _Saturation;  //调整 饱和度
	colorHSV.z *= _Value; //调整 色调                           
	finalColor = HSVConvertToRGB(colorHSV);   //将调整后的HSV，转换为RGB颜色


// #ifdef ToonShaderIsOutline
//     finalColor = ConvertSurfaceColorToOutlineColor(color);
// #endif

    //finalColor = ApplyFog(finalColor, input);

	if (isFace)
		surfaceData.alpha = 1;

    return half4(finalColor, surfaceData.alpha);
    //return half4(color, 0.5);
}

#endif