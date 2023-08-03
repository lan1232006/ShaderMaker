#ifndef TOON_LIGHT_EQUATION01_INCLUDE
#define TOON_LIGHT_EQUATION01_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "ToonLightCommon.hlsl"

half3 ShadeGIDefaultMethod(ToonSurfaceData surfaceData, LightingDatas lightingData)
{
    return half3(0,0,0);
    // 环境光
    //half3 averageSH = SampleSH(0);

    //half indirectOcclusion = lerp(1, surfaceData.occlusion, _OcclusionIndirectStrength);
    //half3 indirectLight = averageSH * (_IndirectLightMultiplier * indirectOcclusion);
    //return max(indirectLight, _IndirectLightMinColor);
}

// // 头发高光处理
// void ShadeHairSpecular(inout ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
// {
//     half3 N = lightingData.normalWS;
//     half3 L = light.direction;
//     half NoL = saturate(dot(N, L));

//     float fresnelPow = 3;
//     float fresnelIntensity = 1;

//     half3 V = lightingData.viewDirectionWS;
//     half3 halfViewLightWS = normalize(V + L);

//     float fresnel = pow(saturate(dot(N, halfViewLightWS)), fresnelPow) * fresnelIntensity;
//     //float aniso = saturate(1-fresnel) * NoL;
//     surfaceData.specular += (light.color * fresnel * NoL);
// }

half4 GetBaseColor(half alpha)
{
    half a = alpha;
    a *= step(0.59, a);
    a *= step(a, 0.61);
    if(a > 0)  // 身体区域颜色特殊处理
        return _BaseSkinColor;
    else
        return _BaseColor;
}


// 高光值在surfaceData, 不需要返回值
half3 CalcSpecular(inout ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{
    half3 N = lightingData.normalWS;
    half3 L = light.direction;
    half3 V = lightingData.viewDirectionWS;
    half3 H = normalize(V + L);
    half NoH = saturate(dot(N, H));
    half NoL = saturate(dot(N, L));
    half NoV = saturate(dot(N, V));


    // 高光处理 C = I * R * pow(max(0,dot(N,H)), s)
	//////lightingData.lightingMapColor.r 当>=0.98归为金属, 否则作为glossiness高光指数的power系数
	//////lightingData.lightingMapColor.g 作为高光ao参与高光颜色计算
	//////lightingData.lightingMapColor.b 既参与计算高光，也用来调制金属色

    half rs = lightingData.lightingMapColor.b; //高光
    half ao = lightingData.lightingMapColor.g;  // 高光ao

	//光照贴图中的r通道 ,  >=0.98归为金属, 否则作为glossiness高光指数的power系数
	half glossiness = lightingData.lightingMapColor.r; 
    half metalR = step(0.98, glossiness);
    half powerR = glossiness * step(glossiness, 0.98);// * (1.0 / 0.9);

    half3 baseColor = surfaceData.albedo; 
    float specularPow = exp2(7 * powerR);   // 计算高光指数项, 影响高光范围
    half3 spec = GetBaseColor(surfaceData.alpha) * rs * pow(NoH, specularPow) * ao;

    //直接使用 lightingData.lightingMapColor.b 来调制金属色
    half3 metalColor = baseColor * rs;
    
    half3 specular = lerp(spec, metalColor, metalR) * NoL * _SpecularMultiplier;

    // 计算一下边缘高光
    // half2 L1 = normalize(L.xz);
    // half2 F = normalize(_ForwardDirection.xz);
    // float rimDot = 1 - NoV;
    // rimDot = smoothstep(0.8, 0.98, rimDot);
    // float rimIntensity = rimDot * abs(dot(-F, L1));
    // half3 rimColor = rimIntensity * _BaseColor * 0.4;
    // //half3 rimColor = rimIntensity * _BaseColor * 0.4 * rs;
    // specular += rimColor;

    return specular*_SpecularColor;
}

//阴影计算
half3 CalcLightColor(ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{

    half2 uv = surfaceData.uv;
    half3 L = light.direction;
    half a = lightingData.lightingMapColor.g;
    a *= step(0.15, a);
    a *= step(a, 0.25);
    if(a > 0) 
    { // 计算脸部阴影
		isFace = true;
        float isSahdow = 0;
        //这张阈值图代表的是阴影在灯光从正前方移动到左后方的变化
        half4 revertTex = tex2D(_LightingMap, float2(1-uv.x, uv.y));
        half2 Left = normalize(TransformObjectToWorldDir(float3(-1, 0, 0)).xz);	//世界空间角色正左侧方向向量
        half2 Front = normalize(TransformObjectToWorldDir(float3(0, 0, 1)).xz);	//世界空间角色正前方向向量
        half2 LightDir = normalize(L.xz);
        half ctrl = clamp(0, 1, dot(Front, LightDir) * 0.5 + 0.5);//计算前向与灯光的角度差（0-1），0代表重合
        half ilm = dot(LightDir, Left) > 0 ? lightingData.lightingMapColor.r : revertTex.r;//确定采样的贴图
        //ctrl值越大代表越远离灯光，所以阴影面积会更大，光亮的部分会减少-阈值要大一点，所以ctrl=阈值
        //ctrl大于采样，说明是阴影点
        isSahdow = step(ilm, ctrl);
        //return isSahdow;
        half bias = smoothstep(0, _ForwardDirection.r, abs(ctrl - ilm));//平滑边界，smoothstep的原理和用法可以参考我上一篇文章
        half3 diffuse = lerp(light.color ,_ShadowColor , isSahdow);
        return diffuse;
    }

    float rampV = 0.75;   
    
    half ao = lightingData.lightingMapColor.g;

    a = surfaceData.alpha;
    a *= step(0.59, a);
    a *= step(a, 0.61);


/*
    rampmap贴图采样，
    原本 皮肤 + 服装两行。
    新增三行，g通道分三个档位，0.4，0.6，0.8

    当lightingmap的g通道比较低是阴影部份且处于背光时，不采样ramp贴图它的背光部份，只采样服装这一行的背光部份颜色值。
*/
    if(a > 0) { // 计算手臂阴影
        rampV = 0.3;
    }
    
    //采样光照贴图G通道中阴影的部份
    if(ao < 0.1)
    {
        rampV = 0.9;
    }
    else
    {
        rampV = 0.6;
    }

    half3 shadowColor = 0;
    half3 N = lightingData.normalWS;
    half NoL = dot(N, L) * 0.5 + 0.5;
	///////当lightingmap的g通道比较低是阴影部份且处于背光时，不采样ramp贴图它的背光部份，只采样服装这一行的背光部份颜色值。
    if(ao < 0.1 && dot(N, L) <= 0)
    {
        NoL = clamp(NoL, 0.25, 0.9); // 避免采样边缘
        shadowColor = tex2D(_RampMap, float2(0.3, 0.6));

       // return lerp(light.color, shadowColor, _ShadowAmount); 
    }
    else
    {
        NoL = clamp(NoL, 0.25, 0.9); // 避免采样边缘
        //采样RampMap阴影颜色值 v : 0.75
        shadowColor = tex2D(_RampMap, float2(NoL, rampV)) ;

		//return shadowColor;
        //return lerp(light.color, shadowColor, _ShadowAmount); 
    }

    //叠加混合
	half3 blendedImage = shadowColor;
	blendedImage.r = OverlayBlendMode(shadowColor.r, _RampMapColor.r);
	blendedImage.g = OverlayBlendMode(shadowColor.g, _RampMapColor.g);
	blendedImage.b = OverlayBlendMode(shadowColor.b, _RampMapColor.b);


	return lerp(light.color, blendedImage, _ShadowAmount);
}

// metalmap的matcap计算
half4 CalcMetalMapColor(ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{
    //新增加：金属部分 metalmap, matcap采样
    half3 normal_world = normalize(lightingData.normalWS);
    half3 normal_view = mul(UNITY_MATRIX_V,float4(normal_world,0.0)).xyz;
    //-1,1 remap 0,1
    half2 uv_normal = (normal_view.xy + float2(1.0,1.0)) * 0.5;

    half glossiness = lightingData.lightingMapColor.r; //光照贴图中的r通道 , >=0.98归为金属,
    half metalR = step(0.98, glossiness);

    half4 MatCapCol = tex2D(_MetalMap, uv_normal) * _MatCapIntensity * GetBaseColor(surfaceData.alpha) * metalR;

    return MatCapCol;
}


// metalmap的matcap计算
// half4 CalcMetalMapColor(ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
// {
//     //新增加：金属部分 metalmap, matcap采样
//     half3 normal_world = normalize(lightingData.normalWS);
//     half3 normal_view = mul(UNITY_MATRIX_V,float4(normal_world,0.0)).xyz;
//     //-1,1 remap 0,1
//     half2 uv_normal = (normal_view.xy + float2(1.0,1.0)) * 0.5;

//     half4 MatCapCol = tex2D(_MetalMap, uv_normal);

//     return MatCapCol;
// }


// 流光flowmap计算
half4 CalcFlowMapColor(inout ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{
	//新增加: 流光flowmap计算
	half glossiness = lightingData.lightingMapColor.r; //光照贴图中的r通道 , >=0.98归为金属,
	half metalR = step(0.98, glossiness);

	half4  FlowMapCol = 0;
	FlowMapCol.a = 1;
	if (metalR)
	{
		half2 uv = half2(surfaceData.uv.x / 2, surfaceData.uv.y);
		uv.x += -_SpeedX * _Time.w;

		float flow = tex2D(_FlowMap, uv).b;
		FlowMapCol = flow * _FlowMapCol;

		if (flow > 0)
		{
			//surfaceData.alpha = FlowMapCol.a;
			FlowMapCol.rgb *= FlowMapCol.a;
		}

	}
	return FlowMapCol;
}


//自发光计算
half3 ShadeEmissionDefaultMethod(ToonSurfaceData surfaceData, LightingDatas lightingData)
{
    //half3 emissionResult = lerp(surfaceData.emission, surfaceData.emission * surfaceData.albedo, _EmissionMulByBaseColor);
    half3 emissionResult = 0;
    half3 emissionColor =  lerp(_EmissionColor, _EmissionColor * surfaceData.albedo, _EmissionMulByBaseColor);

    half a = surfaceData.alpha;
    a *= step(0.29, a);
    a *= step(a, 0.31);
    if(a > 0) { // 计算自发光 
        emissionResult =  emissionColor;// * abs((frac(_Time.y * 0.5) - 0.5) * 3);
        _isEmission = true;
    }
    
    return emissionResult;
}

half3 CompositeAllLightResultsDefaultMethod(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half3 emissionResult, half3 rimResult, ToonSurfaceData surfaceData, LightingDatas lightingData)
{
    half3 lightSum = mainLightResult + additionalLightSumResult;
    half3 rawLightSum = max(indirectResult, mainLightResult + additionalLightSumResult);
    half lightLuminance = Luminance(rawLightSum);
    half3 finalLightMulResult = rawLightSum / max(1, lightLuminance / max(1, log(lightLuminance)));
    // return surfaceData.albedo * finalLightMulResult + emissionResult + rimResult + surfaceData.specular;
    // return surfaceData.albedo * lightSum + emissionResult + rimResult + surfaceData.specular;

    // if(_isEmission) 
    // {
    //     return emissionResult;
    // }
    // else
    // {
    //     return surfaceData.albedo * finalLightMulResult + rimResult + surfaceData.specular;
    // }

    //step(a,b)函数解释:如果a>b返回0;如果a<=b返回1
    return step(0, _isEmission) * emissionResult +  step(_isEmission, 0) * (surfaceData.albedo * finalLightMulResult  + surfaceData.diffuse  + rimResult + surfaceData.specular );
}

half3 ShadeGI(ToonSurfaceData surfaceData, LightingDatas lightingData)
{
    return ShadeGIDefaultMethod(surfaceData, lightingData); 
}

half3 ShadeSingleLight(inout ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{
////////////////////////////////     传统的高光+金属光    
// //     // 阴影处理
//     half3 lightColor = CalcLightColor(surfaceData, lightingData, light);

//     // 高光部分
//     surfaceData.specular = CalcSpecular(surfaceData, lightingData, light);

//     //金属部分matcap图采样
//     half4 metalColor = CalcMetalMapColor(surfaceData, lightingData, light);

    // BlinPhong高光 + 金属高光
    //surfaceData.specular += metalColor;


///////////////////////////////////// 高光 和金属光 插值

    // 阴影处理
    half3 lightColor = CalcLightColor(surfaceData, lightingData, light);

    // 高光部分		
    surfaceData.specular = CalcSpecular(surfaceData, lightingData, light);

    //金属部分matcap图采样
    half4 metalColor = CalcMetalMapColor(surfaceData, lightingData, light);

	//流光贴图采样
	half4 flowColor = CalcFlowMapColor(surfaceData, lightingData, light);
	

    half  specularMask = lightingData.lightingMapColor.r;
    half  specularInt = lightingData.lightingMapColor.b;
    float metalMask = smoothstep(0.9, 1, specularMask);
    float metalSpecularMask = smoothstep(0.2, 0.7, specularInt) * metalMask;

    surfaceData.specular = lerp(surfaceData.specular, 0.8 * surfaceData.specular + metalColor, metalSpecularMask);

	surfaceData.specular += flowColor;



/////////////////////////////////    // 二值化 金属的光
    // // 阴影处理
    // half3 lightColor = CalcLightColor(surfaceData, lightingData, light);

    // // 高光部分
    // surfaceData.specular = CalcSpecular(surfaceData, lightingData, light);

    // //金属部分matcap图采样
    // half4 MetalMap = CalcMetalMapColor(surfaceData, lightingData, light);
    // // 二值化 金属的光
    // MetalMap = step(_MetalMapV, MetalMap.r)*_MatCapIntensity;
    // // 基础高光
    // // BlinPhong高光 + 金属高光
    // //if (SpecularLayer255 >= 200)
    // half glossiness = lightingData.lightingMapColor.r; //光照贴图中的r通道 , >=0.98归为金属,
    // half metalR = step(0.98, glossiness);    
    // if(metalR)
    // {
    //     surfaceData.specular += MetalMap;
    // }


    return lightColor;
}

half3 ShadeMainLight(inout ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{    
    return ShadeSingleLight(surfaceData, lightingData, light);
}

half3 ShadeAdditionalLight(inout ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{
    //return half3(0,0,0);
    return ShadeSingleLight(surfaceData, lightingData, light);
}

half3 ShadeEmission(ToonSurfaceData surfaceData, LightingDatas lightingData)
{
    return ShadeEmissionDefaultMethod(surfaceData, lightingData); 
}

////// 边缘光
float4 TransformHClipToViewPortPos(float4 positionCS)
{
    float4 o = positionCS * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = positionCS.zw;
    return o / o.w;
}

float ShadeRim(Varyings input, ToonSurfaceData surfaceData, LightingDatas lightingData, Light light)
{
    float3 normalWS = input.normalWS;
    float3 normalVS = TransformWorldToViewDir(normalWS, true);
    float3 positionVS = input.positionVS;

	float3 L = light.direction;
	float3 N = lightingData.normalWS;
	float3 V = lightingData.viewDirectionWS;
	float NdotL = dot(N, L);
	float NdotV = saturate(dot(V, N));

    half NdotL01 = dot(N, L) * 0.5 + 0.5;


    //深度偏移的uv结合N.L光照
    float3 samplePositionVS = float3(positionVS.xy + normalVS.xy * _OffsetMul * (NdotL * 0.5 + 0.5 ), positionVS.z); 
    float4 samplePositionCS = TransformWViewToHClip(samplePositionVS);
    float4 samplePositionVP = TransformHClipToViewPortPos(samplePositionCS);

    half a = surfaceData.alpha;
    a *= step(0.19, a);
    a *= step(a, 0.21);
    half isShowRim = 1;
    if(a > 0) { // 判断脸部边缘光 
        // 模型固定y不变, 光照方向只取xz平面
		float2 L1 = normalize(L.xz);
		float2 F = normalize(_ForwardDirection.xz);
		float3 L = light.direction;
		float3 V = lightingData.viewDirectionWS;

        float VF = dot(V, F) * 0.5 + 0.5;
        float FL = dot(F, L1);
        //isShowRim = smoothstep(0.5, 1, 1-abs(VF)) * step(0, FL); 
        isShowRim = step(1, 1-VF)  * step(0, FL); 
    }

//深度边缘光
//https://www.bilibili.com/read/cv11841147/

    float depth = input.positionNDC.z / input.positionNDC.w;
    float linearEyeDepth = Linear01Depth(depth, _ZBufferParams); // 离相机越近越小
    float offsetDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, samplePositionVP).r; // _CameraDepthTexture.r = input.positionNDC.z / input.positionNDC.w
    float linearEyeOffsetDepth = Linear01Depth(offsetDepth, _ZBufferParams);

    float depthDiff = 0;

    // #if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
	// 	depthDiff = abs(linearEyeDepth-linearEyeOffsetDepth);
    // #else 
    //     depthDiff = linearEyeOffsetDepth - linearEyeDepth;
    // #endif

		depthDiff = abs(linearEyeOffsetDepth - linearEyeDepth);


    float rimIntensity = isShowRim * step(_Threshold, depthDiff) * _OffsetMul;
    //平衡边缘光边界
    //rimIntensity = rimIntensity * smoothstep(_RimAreaMid - _RimAreaSoft, _RimAreaMid + _RimAreaSoft, depthDiff );


 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////////////// old ////////////////////////////////
////////////////////    菲尼尔
    // float rimRatio = 1 - NdotV;
    // rimRatio = pow(rimRatio, _FresnelMask);
	// rimIntensity = smoothstep(_RimRadius - 0.01, _RimRadius + 0.01, rimRatio);

//////////////////  菲尼尔 结合 n.l光照,结合光照贴图的通道
    //rimIntensity = pow((1 - smoothstep(_RimRadius,_RimRadius + 0.03,NdotV)), _FresnelMask) * _OffsetMul * (1 - (NdotL * 0.5 + 0.5 )) * (lightingData.lightingMapColor.b);

//////////////////
    // rimIntensity =  step(_Threshold, depthDiff);
    // half rimRatio = pow(1 - NdotV, _RimPower);
    // rimRatio = pow(rimRatio, exp2(lerp(4.0, 0.0, _FresnelMask)));
    // rimIntensity = lerp(0, rimIntensity, rimRatio);

    // half noRimArea = 1 - saturate(NdotL);
    // noRimArea = 1 - smoothstep(_RimAreaMid - _RimAreaSoft, _RimAreaMid + _RimAreaSoft, noRimArea);

    // half skin = step(0.35, lightingData.lightingMapColor.b);
    // half skinArea = 1 - skin * noRimArea; //不接受边缘光的区域
    // rimIntensity = lerp(0, rimIntensity, skinArea) * lerp(1, 0.01, skin);
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 

    //光源投射方向才有边缘光
    //return rimIntensity * step(0.7, NdotL01) + rimIntensity * (1 - step(0.7, NdotL01)) * -_ColorRimBackIntensity;
    //return rimIntensity * step(0.5, NdotL01);


    // 菲尼尔
    //把视线方向归一化
    float3 worldViewDir = normalize(lightingData.viewDirectionWS);
    //计算视线方向与法线方向的夹角，夹角越大，dot值越接近0，说明视线方向越偏离该点，也就是平视，该点越接近边缘
    float rim = 1 - max(0, dot(worldViewDir, lightingData.normalWS));
    //rim = rim * step(0.9, 1 - dot(worldViewDir, lightingData.normalWS));
    rim = rim * step(_Threshold, NdotL01);
    //计算rimLight
    //return rim * _OffsetMul;
    return  pow(rim, 1 / _OffsetMul) * step(_OffsetMulHard, NdotL01);
}

half3 CompositeAllLightResults(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half3 emissionResult, half3 rimResult, ToonSurfaceData surfaceData, LightingDatas lightingData)
{
    return CompositeAllLightResultsDefaultMethod(indirectResult,mainLightResult,additionalLightSumResult,emissionResult, rimResult, surfaceData, lightingData); 
}

#endif
