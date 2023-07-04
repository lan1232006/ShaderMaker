#ifndef TOON_LIGHT_LERP_INCLUDE
#define TOON_LIGHT_LERP_INCLUDE

inline half invLerp(half from, half to, half value) 
{
    return (value - from) / (to - from);
}

inline half invLerpClamp(half from, half to, half value)
{
    return saturate(invLerp(from,to,value));
}

half remap(half origFrom, half origTo, half targetFrom, half targetTo, half value)
{
    half rel = invLerp(origFrom, origTo, value);
    return lerp(targetFrom, targetTo, rel);
}

//叠加颜色公式
half OverlayBlendMode(half basePixel, half blendPixel) {
	if (basePixel < 0.5)
	{
		return (2.0 * basePixel * blendPixel);
	}
	else
	{
		return (1.0 - 2.0 * (1.0 - basePixel) * (1.0 - blendPixel));
	}
}

half3 NormalBlend(half3 a, half3 b)
{
    return normalize(half3(a.xy+b.xy, a.z*b.z));
}

inline half3 Median3(half3 a, half3 b, half3 c)
{
    return a + b + c - max(max(a, b), c) - min(min(a, b), c);
}

inline half CMax3(half a, half b, half c)
{
    return max(max(a, b), c);
}

inline half3 GammaToLinearSpace(half3 sRGB)
{
    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);
}

inline half3 LinearToGammaSpace (half3 linRGB)
{
    linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
    return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);
}

#endif
