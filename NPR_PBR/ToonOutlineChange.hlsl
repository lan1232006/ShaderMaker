#ifndef TOON_OUTLINECHANGE_INCLUDE
#define TOON_OUTLINECHANGE_INCLUDE

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "ToonLightCommon.hlsl"


	CBUFFER_START(UnityPerMaterial)
	float4 _OutlineCol;
	float _OutlineFactor;
	CBUFFER_END 
	
	struct Attributes  
	{
		float4 positionOS : POSITION;
		half4 color : COLOR;      
		float3 normalOS : NORMAL;
		float2 uv  : TEXCOORD0; //_BaseMap
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct Varyings 
	{
		float4 positionCS : SV_POSITION;
		half4 color : COLOR;

		float2 uv  : TEXCOORD0;
	}; 
	
	Varyings vertOutLine(Attributes input) 
	{
		Varyings output = (Varyings)0;
		UNITY_SETUP_INSTANCE_ID(input);
		float3 positionWS =TransformObjectToWorld(input.positionOS.xyz); 
		output.color = input.color;
		float3 pos_world = input.positionOS.xyz;
		//output.color=pow(input.color,0.45);//gamma矫正，美术看到的颜色是在2.2空间  存储的值在0.45空间
		float camDist = distance(_WorldSpaceCameraPos,positionWS.xyz);
		camDist = lerp(1,camDist,0.9);
		pos_world = pos_world + normalize(input.normalOS)* _OutlineFactor*input.color.a* 0.0007*camDist;
		output.positionCS = TransformObjectToHClip(pos_world);
		output.uv = input.uv;
		return output;
	}

	
	half4 fragOutLine(Varyings input) : SV_Target
	{
		half4 color = input.color;
		//return half4(color.rgb,1);
		//return 0.5;
		return half4(color.rgb*_OutlineCol,1);
	}

#endif

