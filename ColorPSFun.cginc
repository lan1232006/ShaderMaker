
/****************************************
   hsv调整函数，仿PS的色阶调整，图层混合模式等计算函数
*******************************/
#ifndef NightBlendFun
#define NightBlendFun  


/******************************
***  rgb <-> hsl ***
******************************/
float3 rgb2hsl(float3 color) {
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = lerp(float4(color.bg, K.wz), float4(color.gb, K.xy), step(color.b, color.g));
	float4 q = lerp(float4(p.xyw, color.r), float4(color.r, p.yzx), step(p.x, color.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsl2rgb(float3 color)
{
	color = float3(color.x, clamp(color.yz, 0.0, 1.0));

	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(color.xxx + K.xyz) * 6.0 - K.www);
	return color.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), color.y);
}


// Official HSV to RGB conversion 
//float3 hsl2rgb(float3 c) {
//	float3 rgb = clamp(abs(fmod(c.x*6.0 + float3(0.0, 4.0, 2.0), 6) - 3.0) - 1.0, 0, 1);
//	rgb = rgb * rgb*(3.0 - 2.0*rgb);
//	return c.z * lerp(float3(1, 1, 1), rgb, c.y);
//}


/******************************
***  Hue, Saturation, Bright, Contrast ***
******************************/

float3 Contrast_float(float3 In, float Contrast)
{
	//float midpoint = pow(0.5, 2.2);
	//return (In - midpoint) * Contrast + midpoint;

	//换一个对比度算法
	float3 avgColor = float3(0.5, 0.5, 0.5);
	return lerp(avgColor, In, Contrast);
}


float3 HSV_Adjust(float3 In, float HueOffset, float SaturationOffset, float BrightOffset)
{
	float3 hsv = rgb2hsl(In);

	//调整明度饱和度
	hsv.x = hsv.x + HueOffset;
	hsv.y = hsv.y + SaturationOffset;
	hsv.z = hsv.z + BrightOffset;
	//hsv to rgb

	return hsl2rgb(hsv);
}


/******************************
***  基本的HSV调整 ***
******************************/

float3 ColorHSVGrade(float3 color, float HueShift, float Saturation, float BrightnessFinal, float Contrast) {
	float3 outColor = HSV_Adjust(color, HueShift, Saturation, BrightnessFinal);

	outColor = Contrast_float(outColor, Contrast);

	return max(outColor, 0.0);
}


/******************************
*** 色阶调整 *** 
******************************/

struct ColorLevelParams
{
	float _inBlack;
	float _inMidtones;
	float _inWhite;
	float _outWhite;
	float _outBlack;
	float _outAlpha; //该图层的不透明度，这里应该是效果的影响百分比？
};

// float GetPixelLevel(float pixelColor, ColorLevelParams params)
// {
// 	float pixelResult;
// 	pixelResult = (pixelColor);
// 	pixelResult = max(0, pixelResult - params._inBlack);
// 	pixelResult = saturate(pow(pixelResult / (params._inWhite - params._inBlack), params._inMidtones));
// 	pixelResult = (pixelResult * (params._outWhite - params._outBlack) + params._outBlack) / 255.0;
// 	return pixelResult;
// }

// float3 GetColorLevel(float3 srcColor, ColorLevelParams params)
// {
// 	float outRPixel = GetPixelLevel(srcColor.r, params);
// 	float outGPixel = GetPixelLevel(srcColor.g, params);
// 	float outBPixel = GetPixelLevel(srcColor.b, params);
	
// 	return float3(outRPixel, outGPixel, outBPixel);
// }


//色阶调整，  颜色单位为255
float GetPixelLevel(float pixelColor, ColorLevelParams params)
{
	float pixelResult = 0;

	//输入色阶映射
	pixelResult = 255.0 * ((pixelColor - params._inBlack) / (params._inWhite - params._inBlack));
	if(pixelResult < 0)
		pixelResult = 0;
	if(pixelResult > 255.0)
		pixelResult = 255.0;

	//中间调处理
	pixelResult = 255.0 * pow(pixelResult / 255.0, 1.0 / params._inMidtones);

	//输出色阶映射
	pixelResult = (pixelResult / 255.0) * (params._outWhite - params._outBlack) + params._outBlack;
	if(pixelResult < 0)
		pixelResult = 0;
	if(pixelResult > 255.0)
		pixelResult = 255.0;


	return  (pixelColor + params._outAlpha / 100.0 * (pixelResult - pixelColor)) / 255.0 ;
}

float3 GetColorLevel(float3 srcColor, ColorLevelParams params)
{
	float outRPixel = GetPixelLevel(srcColor.r, params);
	float outGPixel = GetPixelLevel(srcColor.g, params);
	float outBPixel = GetPixelLevel(srcColor.b, params);
	
	return float3(outRPixel, outGPixel, outBPixel);
}


/******************************
*** 叠加混合 ***
******************************/

//overlay blend 叠加
float OverlayBlendMode(float basePixel, float blendPixel) {
	if (basePixel < 0.5)
	{
		return (2.0 * basePixel * blendPixel);
	}
	else
	{
		return (1.0 - 2.0 * (1.0 - basePixel) * (1.0 - blendPixel));
	}	
}

float3 GetOverlayBlend(float3 srcColor, float3 blendColor, float OverlayBlendAlpha)
{
	float3 resultColor = 0;

	resultColor.r = OverlayBlendMode(srcColor.r, blendColor.r);
	resultColor.g = OverlayBlendMode(srcColor.g, blendColor.g);
	resultColor.b = OverlayBlendMode(srcColor.b, blendColor.b);

	return  srcColor + OverlayBlendAlpha / 100.0 * (resultColor - srcColor);
}



/******************************
*** 色相混合 ***
******************************/

float3 GetHueBlendMode(float3 basePixel, float3 blendPixel, float HueBlendAlpha)
{
	float3 colorAHSV = rgb2hsl(basePixel.xyz);
	float3 colorBHSV = rgb2hsl(blendPixel.xyz);

	// hue 色相
	float3 resultColor = float3(colorBHSV.x,colorAHSV.yz);
	resultColor = hsl2rgb(resultColor);

	return  basePixel + HueBlendAlpha / 100.0 * (resultColor - basePixel);
}




#endif 