Shader "URP/WaterShader"
{
	Properties
	{
		_Distortion("Distortion",Range(0,10)) = 2
		_FlowSpeed("FlowSpeed",Range(0.1,5)) = 1
		_FoamTex("FoamTex",2D) = "White"{}
		_CausticsTex("CausticsTex",2D) = "White"{}
		_CausticsTex02("CausticsTex02",2D) = "White"{}
		_CausticsSpeed("CausticsSpeed",Range(0.01,0.3)) = 0.1
		_CausticsIntensity("CausticsIntensity",Range(0,5)) = 1
		_WaveSpeed("WaveSpeed",Range(0.1,5)) = 1
		_Frequency("Frequency",Vector)=(1,1,1,1)
		_Edge("Edge",Range(0.9,1.5)) = 1
		_Deep("Deep",Range(0,20)) = 5
		_Deep01("Deep01",Range(0,20)) = 5
		_DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
		_SpecularColor("SpecularColor",Color) = (1,1,1,1)
		_SpecularRange("SpecularRange",Range(0.1,200)) = 1
		_SpecularStrenght("SpecularStrenght",Range(0.1,2)) = 1
		_SpecularX("SpecularX",Range(0,1))=0
		_SpecularY("SpecularY",Range(0,1))=0
	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha 

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#define UNITY_PI            3.14159265359f

			

			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float2 uv : TEXCOORD;
				float4 tangentOS : TANGENT;
			};

			struct v2f
			{
				
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float2 uv : TEXCOORD3;
				float3 worldNormal : TEXCOOORD4;
				float4 bumpUv1:TEXCOORD5;
				float3 tangentWS:TEXCOORD6;
				float3 bitangentDir:TEXCOORD7;
			};
			TEXTURE2D(_FoamTex) ;
			SAMPLER(sampler_FoamTex);
			
			TEXTURE2D(_ReflectionTex) ;
			
			sampler2D _DumpTex;
			TEXTURE2D (_CausticsTex);
			TEXTURE2D (_CausticsTex02);
            
			CBUFFER_START(UnityPerMaterial)
                float _FlowSpeed,_Deep,_Deep01;
				float4 _FoamTex_ST;
				float4 _CausticsTex_ST;
				//half4 _ReflectionTex_TexelSize;
				float _Distortion,_CausticsSpeed,_CausticsIntensity;
				float4 _WaveSpeed;
			    float4 _DepthGradientShallow;
				float4 _DepthGradientDeep;
				float _Edge;
				float4 _SpecularColor,_Frequency;
				float _SpecularRange;
				float _SpecularStrenght;
				float _SpecularX;
				float _SpecularY;
            CBUFFER_END

			float3 GerstnerWave( float3 position, float4 wave )
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = 2 * UNITY_PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, position.xz) - c * _Time.y);
				float a = steepness / k;
							

				return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

            	//float offset=sin(_Frequency.x*_Time.y+v.vertex.x*_Frequency.y+v.vertex.y*_Frequency.y+v.vertex.z*_Frequency.y*100)*_Frequency.z;
            	float3 offset = GerstnerWave(o.worldPos,_Frequency);
            	o.worldPos.y +=offset.y;
            	v.vertex.xyz = TransformWorldToObject(o.worldPos);
            	o.vertex = TransformObjectToHClip(v.vertex.xyz);	
            	
				o.screenPos = ComputeScreenPos(o.vertex);		
				o.uv = TRANSFORM_TEX(v.uv,_CausticsTex) ;
				o.worldNormal = TransformObjectToWorldNormal(v.normal);

            	o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                //副切线
                o.bitangentDir = normalize(cross(o.worldNormal, o.tangentWS) * v.tangentOS.w);
				return o;
			}

			real3 toRGB(real3 grad){
  				 return grad.rgb;
			}
            	
			//噪声图生成
			float2 rand(float2 st, int seed)
			{
				float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
				return -1 + 2 * frac(sin(s) * 43758.5453123);
			}
			float noise(float2 st, int seed)
			{
				st.y += _Time.y*_FlowSpeed;

				float2 p = floor(st);
				float2 f = frac(st);
 
				float w00 = dot(rand(p, seed), f);
				float w10 = dot(rand(p + float2(1, 0), seed), f - float2(1, 0));
				float w01 = dot(rand(p + float2(0, 1), seed), f - float2(0, 1));
				float w11 = dot(rand(p + float2(1, 1), seed), f - float2(1, 1));
				
				float2 u = f * f * (3 - 2 * f);

				return lerp(lerp(w00, w10, u.x), lerp(w01, w11, u.x), u.y);
			}
			//海浪的涌起法线计算
			float3 swell( float3 pos , float anisotropy){
				float3 normal;
				float height = noise(pos.xz * 0.1,0);
				height *= anisotropy ;//使距离地平线近的区域的海浪高度降低
				normal = normalize(
					cross ( 
						float3(0,ddy(height),1),
						float3(1,ddx(height),0)
					)//两片元间高度差值得到梯度
				);
				return normal;
			}

			real4 blendSeaColor(real4 col1,real4 col2)
			{
				real4 col = min(1,1.5-col2.a)*col1+col2.a*col2;
				return col;
			}
			
			
			real4 frag (v2f i) : SV_Target
			{
				real4 col = (1,1,1,1);
				float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.screenPos.xy/i.screenPos.w);
				sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);
                float partZ = i.screenPos.z;
				float diffZ00 =  (sceneZ - partZ)/_Deep01;
				diffZ00 = saturate(diffZ00);
				diffZ00  = step(diffZ00,0.5);
				///重构世界空间坐标
				float2 UV = i.vertex.xy / _ScaledScreenParams.xy;
				#if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(UV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

				float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
				///重构完成
				
				float diffZ = (i.worldPos.y-worldPos.y)/_Deep;

				diffZ = saturate(diffZ);
				
				//按照距离海滩远近叠加渐变色
				col.rgb = lerp(_DepthGradientDeep,_DepthGradientShallow,diffZ);

				//海浪波动
				half3 worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 v = i.worldPos - _WorldSpaceCameraPos;
				float anisotropy = saturate(1/ddy(length(v.xz))/10);//通过临近像素点间摄像机到片元位置差值来计算哪里是接近地平线的部分
				float3 swelledNormal = swell( i.worldPos , anisotropy);
				// 反射天空盒
                //half3 reflDir = reflect(-worldViewDir, swelledNormal);
				//real4 reflectionColor = SAMPLE_TEXTURECUBE(unity_SpecCube0,samplerunity_SpecCube0, reflDir);
				//return reflectionColor;

				
				//其余物体的平面反射
				
				float height = noise(i.worldPos.xz * 0.1,2);
				float height2 = noise(-i.worldPos.xz * 0.1,2);
				float offset = (height + height2)* _Distortion ;
				i.screenPos.x += pow(offset,2) * saturate(diffZ)  ;
				real4 reflectionColor = SAMPLE_TEXTURE2D(_ReflectionTex,sampler_FoamTex,i.screenPos.xy / i.screenPos.w);//tex2D(_ReflectionTex, i.screenPos.xy / i.screenPos.w);
				//reflectionColor = blendSeaColor(reflectionColor,reflectionColor2);
				//return reflectionColor;
				
				//海面高光
				// half4 bump10 = (tex2D(_DumpTex, i.bumpUv1.xy / _NormalsScale) * 2) + (tex2D(_DumpTex, i.bumpUv1.zw / _NormalsScale) * 2) - 2;
				// half3 oriOffset = UnpackNormal(bump10);
				// oriOffset.xy = oriOffset.xy * _NormalsStrength;
				// half3 bump = normalize(oriOffset);
				// float3x3 tangentTransform = float3x3(i.tangentWS, i.bitangentDir, normalize(i.worldNormal));
				// float3 bumpWorld = normalize(mul(bump, tangentTransform));
				float3 L = normalize(_MainLightPosition.xyz -i.worldPos);
				float3 H = normalize(worldViewDir+L+float3(_SpecularX,0,_SpecularY));
				real3 specular = _SpecularColor.rgb * _SpecularStrenght * pow(max(0,dot(swelledNormal,H)),_SpecularRange);
				col += real4(specular,1);
				
				//岸边浪花
				// i.uv.y -= _Time.y*_WaveSpeed;
				// real4 foamTexCol = SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,i.uv);
				// real4 foamCol = saturate((0.8-height) * (foamTexCol.r  +foamTexCol.g )* diffZ) * step(diffZ,_Edge) * step(0.5,_Edge);
				// foamCol = step(0.5,foamCol);
				// //col += foamCol;
				//水路交接处
				i.uv.xy += _Time.y*_CausticsSpeed;
				real4 CausticsTex = SAMPLE_TEXTURE2D(_CausticsTex,sampler_FoamTex,i.uv)*(1-(diffZ*0.95));
				i.uv.xy -= _Time.y*_CausticsSpeed*2;
				real4 CausticsTex02 = SAMPLE_TEXTURE2D(_CausticsTex02,sampler_FoamTex,i.uv)*(1-(diffZ*0.95));
				CausticsTex= min(CausticsTex,CausticsTex02)*_CausticsIntensity;

				// 菲涅尔反射
				float f0 = 0.02;
    			float vReflect = f0 + (1-f0) * pow(1 - dot(worldViewDir,swelledNormal),5);
				vReflect = saturate(vReflect * 2.0);				
				col = lerp(col , reflectionColor , vReflect);

				//地平线处边缘光，使海水更通透
				col += ddy(length(v.xz))/200+CausticsTex;
				//接近海滩部分更透明
				float alpha = diffZ;			
                col.a = alpha;

				return col+diffZ00;
			}
			ENDHLSL
		}
	}
}