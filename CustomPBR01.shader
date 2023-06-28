/*** 
     Custom  Pbr + bakedGI
***/

 Shader "Scene/CustomPBR01"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalTex("法线贴图", 2D) = "bump" { }//汇入法线
		_NormalTexScale("法线强度", Range(-1,3)) = 0//汇入法线强度 
        _RoughnessMap("粗糙度贴图", 2D) = "bump" { }          
        _Roughness ("Roughness", Range(0,10)) = 0.5
        _AO ("AO", Range(0,10)) = 0.5
        //Gamma矫正金属度变化 ，这个矫正是否有必要？做截图对比
        [Gamma]_Metallic ("Metallic", Range(0,1)) = 0.0      
        _DarkColor ("_DarkColor", Color) = (1,1,1,1)   
        [Space(30)]     
        _Hue("色相", Range(0,1)) = 0
        _Saturation("饱和度", Range(-1, 1)) = 1	//调整饱和度
        _Value("亮度", Range(-1, 1.0)) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" 
            "LightMode" = "UniversalForward"
        }

        LOD 200
        Pass
		{
			Tags {

				"RenderType" = "Opaque"	
				"Queue" = "Opaque"  
				"IgnoreProjector" = "True"
			}

            HLSLPROGRAM

            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

			//函数库：主要用于各种的空间变换
			 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
			 //从unity中取得我们的光照
			 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 

           // #include "../../../Utility/ColorPSFun.cginc"

			 #pragma multi_compile_instancing
			 #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			 #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			 #pragma multi_compile _ _SHADOWS_SOFT
            //开启lightmap
             #pragma multi_compile _ LIGHTMAP_ON


			CBUFFER_START(UnityPerMaterial)
				float4 _Color,_DarkColor;
				float _Metallic,_AO;
				float _Roughness;
                float _NormalTexScale;//汇入法线scale

                half _Saturation;
                half _Hue;
                half _Value;

				float4 _MainTex_ST;
			CBUFFER_END

 			TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); //采样贴图，采样前面汇入的maintex贴图，贴图采样器，以及贴图st
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);//采样贴图，采样前面汇入的法线贴图，贴图采样器，以及贴图st
            sampler2D _RoughnessMap;
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;//汇入切线

                float2 uv : TEXCOORD0; 
                float2 lightmapUV   : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

                float3 normal_world : TEXCOORD2;//世界空间的法线
				float3 tangent_world : TEXCOORD3;//世界空间的切线
 				float3 bitangent_world : TEXCOORD4;//世界空间的次切线

                float3 worldPos : TEXCOORD5;
				float4 shadowCoord : TEXCOORD6;

            };
          
            v2f vert(a2v v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal_world = TransformObjectToWorldNormal(v.normal);
                o.normal_world = normalize(o.normal_world);
                o.tangent_world = TransformObjectToWorldDir(v.tangent);//切线变换
                o.bitangent_world = normalize(cross(o.normal_world, o.tangent_world)) * v.tangent.w * unity_WorldTransformParams.w;//次切线

				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);//计算顶点结果
				o.shadowCoord = GetShadowCoord(vertexInput);//	

                //input lightmapUV; output lightmapUV;
                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);

                OUTPUT_SH(o.normal_world, o.vertexSH);//in normal out vertexSH

                return o;
            }

         //正态分布函数D
            float Distribution(float roughness , float nh)
            {
                float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);
                float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * PI);
                return D;
            }

            //几何遮蔽G
            float Geometry(float roughness , float nl , float nv) 
            {
                float kInDirectLight = pow(roughness + 1, 2) / 8;
                float kInIBL = pow(roughness, 2) / 8;
                float GLeft = nl / lerp(nl, 1, kInDirectLight);
                float GRight = nv / lerp(nv, 1, kInDirectLight);
                float G = GLeft * GRight;
                return G;
            }

            //菲尼尔Fresnel
            float3 FresnelEquation(float3 F0 , float vh) 
            {
                float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);
                return F;
            }

            //立方体贴图的Mip等级计算
            float CubeMapMip(float _Roughness) 
            {
                //基于粗糙度计算CubeMap的Mip等级
                float mip_roughness = _Roughness * (1.7 - 0.7 * _Roughness);
                half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS; 
                return mip;
            }

            //间接光的菲涅尔系数
            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
                return F0 + (max(float3(1 ,1, 1) * (1 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }

			//球谐函数 作者：艺术菌毯 https://www.bilibili.com/read/cv16075253 出处：bilibili
			float3 SHProcess(float3 N)  // N:  normalWS 
			{
				float4 SH[7];
				SH[0] = unity_SHAr;
				SH[1] = unity_SHAg;
				SH[2] = unity_SHAb;
				SH[3] = unity_SHBr;
				SH[4] = unity_SHBg;
				SH[5] = unity_SHBb;
				SH[6] = unity_SHC;

				return max(0.0,SampleSH9(SH,N));
			}

            float3 rgb2hsl(float3 color) 
            {
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
                        float4 frag(v2f i) : SV_Target
            {
                
                //**********准备数据************
				//【光照与各种向量】

				Light light = GetMainLight(i.shadowCoord);//获取主光源

                float4 pack_normal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);//法线采样
                float3 unpack_normal = UnpackNormal(pack_normal);//得到法线具体数据
                //法线图的修正
                unpack_normal.xy *= _NormalTexScale;
                unpack_normal.z = 1.0 - saturate(dot(unpack_normal.xy, unpack_normal.xy));
                //normal 转为世界空间法线
                float3 normal = normalize(unpack_normal.x * i.tangent_world + unpack_normal.y * i.bitangent_world + unpack_normal.z * i.normal_world);//法线
                float4 RoughnessMap = tex2D(_RoughnessMap,i.uv);
                //float3 normal = normalize(i.normal);
                float3 lightDir = normalize(light.direction);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 lightColor = light.color;
                float3 halfVector = normalize(lightDir + viewDir);      //半角向量
				half shadowAttenuation = MainLightRealtimeShadow(i.shadowCoord);//shadowAttenuation = 1.

                float roughness = RoughnessMap.g * _Roughness;
                float squareRoughness = roughness * roughness;

                float3 Albedo = _Color.rgb * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);     //颜色

                //采样烘培的光照贴图 !!!
                half3 bakedGI = SAMPLE_GI(i.lightmapUV,i.vertexSH, normal);

                //Albedo *= bakedGI; 
                //return float4(Albedo, 1);

                //对每个数据做限制，防止除0
                float objNdotL =max(saturate(dot(i.normal_world, lightDir)), 0.000001);
                float nl = max(saturate(dot(normal, lightDir)), 0.000001);
                float nv = max(saturate(dot(normal, viewDir)), 0.000001);
                float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);
                float lh = max(saturate(dot(lightDir, halfVector)), 0.000001);
                float nh = max(saturate(dot(normal, halfVector)), 0.000001);
                //**********分割************
                //return nl;
                //********直接光照-镜面反射部分*********
                float D = Distribution(roughness , nh);
                float G = Geometry(roughness , nl , nv);
                //unity_ColorSpaceDielectricSpec是一个Unity常量，大概为float3(0.04) ,但是直接输出后显示的效果是float3(0.22) ,这个应该是gamma空间导致的
                float3 F0 = lerp(0.04 /*unity_ColorSpaceDielectricSpec.rgb*/, Albedo, _Metallic);
                float3 F = FresnelEquation(F0 , vh);

                float3 SpecularResult = (D * G * F) / (nv * nl * 4);
                float3 specColor = SpecularResult * lightColor * nl * PI;
                specColor = saturate(specColor);
                //********直接光照-镜面反射部分完成*********    

                float AO = saturate(pow(RoughnessMap.r,_AO));
                Albedo = lerp(Albedo*_DarkColor,Albedo*1.5,nl)*AO;
                //********直接光照部分完成*********
                float3 finalResult = specColor+Albedo;
                finalResult.xyz = HSV_Adjust(finalResult.xyz, _Hue, _Saturation, _Value);
                //return objNdotL;
                //return float4(directLightResult,1);
                return float4(finalResult, 1);

            }

            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
  
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}


// Shader "WLTX/CustomPBR"
// {
// 	Properties
// 	{
// 		_MainTex("主贴图", 2D) = "white" { }//汇入数据的位置
// 		_BaseColor("基础颜色", color) = (1.0, 1.0, 1.0, 1.0)
// 		_NormalTex("法线贴图", 2D) = "bump" { }//汇入法线
// 		_NormalTexScale("法线强度", float) = 1.0//汇入法线强度
// 		//_MaskTex("遮罩贴图", 2D) = "white" {}

// 		_Roughness("_Roughness", Range(0,1.0)) = 0.5
// 		_Metallic("_Metallic", Range(0,1.0)) = 0.5
// 		_Ao("_Ao", Range(0,1.0)) = 0.5


// 		 //_GlossScale ("高光放缩", range(0.0, 50.0)) = 1.0

// 	}
// 		SubShader
// 	 {
// 		 //定义不透明物体，用的是URP管线，定义队列是不透明队列				
// 		 Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry"  "LightMode" = "UniversalForward"}

// 		 LOD 100

// 		 Pass
// 		 {
// 			 HLSLPROGRAM

// 			 //定义hlsl语言

// 			 //定义顶点着色器的名字
// 			 #pragma vertex vert
// 			 //定义片元着色器的名字
// 			 #pragma fragment frag
// 			 //汇入函数库以及汇入光照的hlsl
// 			 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"//函数库：主要用于各种的空间变换
// 			 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"//从unity中取得我们的光照
// 			 #pragma multi_compile_instancing
// 			 #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
// 			 #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
// 			 #pragma multi_compile _ _SHADOWS_SOFT

// 			 //汇入模型的数据
// 			 struct appdata
// 			 {
// 				 float4 vertex : POSITION;//汇入模型的顶点
// 				 float3 normal : NORMAL;//汇入法线
// 				 float2 uv : TEXCOORD0;//汇入uv
// 				 float4 tangent : TANGENT;//汇入切线

// 			 };

// 			 struct v2f
// 			 {
// 				 float2 uv : TEXCOORD0;
// 				 float3 normal_world : TEXCOORD1;//世界空间的法线
// 				 float3 tangent_world : TEXCOORD2;//世界空间的切线
// 				 float3 bitangent_world : TEXCOORD3;//世界空间的次切线
// 				 float3 vertex_world : TEXCOORD4;//顶点的世界空间
// 				 float4 vertex : SV_POSITION;
// 				 float4 shadowCoord : TEXCOORD5;
// 			 };

// 			 TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); float4 _MainTex_ST;//采样贴图，采样前面汇入的maintex贴图，贴图采样器，以及贴图st
// 			 TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);//采样贴图，采样前面汇入的法线贴图，贴图采样器，以及贴图st
// 			 TEXTURE2D(_MaskTex); SAMPLER(sampler_MaskTex);//采样贴图，采样前面汇入的法线贴图，贴图采样器，以及贴图st
// 			 float _NormalTexScale, _GlossScale;//汇入法线scale
// 			 float4 _BaseColor;

// 			 CBUFFER_START(UnityPerMaterial)
// 			 float _Metallic;
// 			 float _Roughness;
// 			 float _Ao;
// 			 CBUFFER_END

// 				 //【PBR函数库】
// 				 float DistributionGGX(float NoH, float a)
// 				 {
// 					 float a2 = a * a;
// 					 float NoH2 = NoH * NoH;

// 					 float x = (NoH2 * (a2 - 1) + 1);
// 					 return a2 / (PI * x * x);
// 				 }

// 				 float3 FresnelSnhlick(float cosTheta, float3 F0)
// 				 {
// 					 return F0 + pow(1.0 - cosTheta, 5);
// 				 }

// 				 float3 IndirFresnelSnhlick(float roughness,float cosTheta, float3 F0)
// 				 {
// 					 return F0 + (max((1 - roughness),F0) - F0) * pow(1.0 - cosTheta, 5);
// 				 }

// 				 float Geometry(float x, float k)
// 				 {
// 					 return x / (x * (1 - k) + k);
// 				 }

// 				 float GeometrySmith(float NoV, float NoL, float k)
// 				 {
// 					 return Geometry(NoV, k) * Geometry(NoL, k);
// 				 }

// 				 float3 SHProcess(float3 N)
// 				 {
// 					 float4 SH[7];
// 					 SH[0] = unity_SHAr;
// 					 SH[1] = unity_SHAg;
// 					 SH[2] = unity_SHAb;
// 					 SH[3] = unity_SHBr;
// 					 SH[4] = unity_SHBg;
// 					 SH[5] = unity_SHBb;
// 					 SH[6] = unity_SHC;

// 					 return max(0.0,SampleSH9(SH,N));
// 				 }

// 				 v2f vert(appdata v)
// 				 {
// 					 v2f o;
// 					 o.vertex = TransformObjectToHClip(v.vertex);//模型空间转换到裁剪空间
// 					 o.vertex_world = TransformObjectToWorld(v.vertex.xyz);//顶点世界空间
// 					 o.normal_world = TransformObjectToWorldNormal(v.normal);//法线从模型空间转换到世界空间
// 					 o.tangent_world = TransformObjectToWorldDir(v.tangent);//切线变换
// 					 o.bitangent_world = normalize(cross(o.normal_world, o.tangent_world)) * v.tangent.w * unity_WorldTransformParams.w;//次切线
// 					 o.uv = TRANSFORM_TEX(v.uv, _MainTex);//UV由主贴图进行定义
// 					 VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);//计算顶点结果
// 					 o.shadowCoord = GetShadowCoord(vertexInput);//
// 					 return o;
// 				 }

// 				 float4 frag(v2f i) : SV_Target
// 				 {
// 					 // 【主贴图采样】
// 					 float4 Albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BaseColor;//主贴图采样

// 					 float4 pack_normal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);//法线采样
// 					 float3 unpack_normal = UnpackNormal(pack_normal);//得到法线具体数据
// 					 float4 Mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);//金属度采样

// 					 ///
// 					 //float AO = Mask.g;//AO
// 					 float AO = _Ao;

// 					 ///
// 					 float Metallic = _Metallic;//金属度
// 					 //float Metallic =  Mask.r;//金属度

// 					 ///
// 					 float roughness = _Roughness;//粗糙度
// 					 //float smoothness = Mask.a;//光滑度
// 					 //float roughness =  pow(1 - smoothness, 2);//粗糙度


// 					 float3 F0 = lerp(0.04, Albedo.rgb, Metallic);//F0

// 					 //法线图的修正
// 					 unpack_normal.xy *= _NormalTexScale;
// 					 unpack_normal.z = 1.0 - saturate(dot(unpack_normal.xy, unpack_normal.xy));

// 					 //【光照与各种向量】
// 					 Light light = GetMainLight(i.shadowCoord);//获取主光源

// 					 float3 L = light.direction;//获取光照方向
// 					 float3 N = normalize(unpack_normal.x * i.tangent_world + unpack_normal.y * i.bitangent_world + unpack_normal.z * i.normal_world);//法线
// 					 float3 V = normalize(_WorldSpaceCameraPos - i.vertex_world);//视角方向
// 					 float3 H = normalize(L + V);//半程向量
// 					 float3 R = reflect(-V, N);//反射

// 					 //【点乘】
// 					 float NoV = max(0.0, dot(N, V));
// 					 float NoL = max(0.0, dot(N, L));
// 					 float NoH = max(0.0, dot(N, H));

// 					 //DGF
// 					 float D = DistributionGGX(NoH, roughness);
// 					 float k = pow((1 + roughness), 2) / 8;
// 					 float G = GeometrySmith(NoV, NoL, k);
// 					 float3 F = FresnelSnhlick(NoV, F0);//菲涅尔项

// 					 //【计算直接光漫反射】
// 					 float3 ks = F;
// 					 float3 kd = (1 - ks) * (1 - Metallic);
// 					 float3 diffuse = kd * Albedo / PI;



// 					 //【计算直接光高光反射】
// 					 float3 specular = D * F * G / max(4 * NoV * NoL, 0.001);
// 					 float3 DirectColor = (diffuse + specular) * NoL * PI * light.color * AO;



// 					 //【计算间接光漫反射】
// 					 float3 SH = SHProcess(N);
// 					 float3 IndirKs = IndirFresnelSnhlick(roughness,NoV,F0);
// 					 float3 IndirKd = (1 - IndirKs) * (1 - Metallic);
// 					 float3 Indirdiffuse = SH * IndirKd * Albedo;

// 					 //【计算间接光高光】
// 					 float mip_level = roughness * 4;//mip_level 
// 					 float3 IndirSpecular = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,R,mip_level);//采样环境贴图

// 					 float surfaceReduction = 1.0 / (roughness * roughness + 1.0);//高光反射
// 					 float ReflectivitySpecular = specular.r;//直接光反射
// 					 float grazingTerm = saturate((1 - roughness) + ReflectivitySpecular);//算出环境光的反射结果
// 					 float t = pow(1 - NoV,5);//菲尼尔
// 					 float3 IndirF0 = lerp(F0,grazingTerm,t);//间接光F0
// 					 IndirSpecular = IndirSpecular * IndirF0 * surfaceReduction;

// 					 float3 IndirColor = Indirdiffuse + IndirSpecular;



// 					 float3 FinalColor = (IndirColor + DirectColor) * AO;// *light.shadowAttenuation * light.distanceAttenuation;//汇入阴影和汇入距离衰减

// 					 return float4(FinalColor, 1.0);
// 				 }
// 				 ENDHLSL

// 			 }
// 		 //【pass：深度】
// 		 Pass
// 		 {
// 			 Name "DepthOnly"
// 			 Tags { "LightMode" = "DepthOnly" }

// 			 ZWrite On
// 			 ColorMask 0
// 			 Cull off

// 			 HLSLPROGRAM

// 					 // Required to compile gles 2.0 with standard srp library

// 					 #pragma vertex DepthOnlyVertex
// 					 #pragma fragment DepthOnlyFragment

// 					 #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
// 					 #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
// 					 ENDHLSL

// 				 }
// 				 Pass
// 				 {
// 					 Name "ShadowCaster"
// 					 Tags{"LightMode" = "ShadowCaster"}

// 					 ZWrite On
// 					 ZTest LEqual
// 					 ColorMask 0
// 					 Cull[_Cull]

// 					 HLSLPROGRAM
// 						 // Required to compile gles 2.0 with standard srp library
// 						 #pragma prefer_hlslcc gles
// 						 #pragma exclude_renderers d3d11_9x
// 						 #pragma target 2.0

// 						 // -------------------------------------
// 						 // Material Keywords
// 						 #pragma shader_feature _ALPHATEST_ON

// 						 //--------------------------------------
// 						 // GPU Instancing
// 						 #pragma multi_compile_instancing
// 						 #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

// 						 #pragma vertex ShadowPassVertex
// 						 #pragma fragment ShadowPassFragment

// 						 #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
// 						 #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
// 						 ENDHLSL
// 					 }

// 	 }
// }