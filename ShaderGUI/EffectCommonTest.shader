// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AFX/EffectCommonTest"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin][Enum(On,1,Off,0)]_ZWriteMode("ZWriteMode", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", Float) = 2
		[Enum(Add,1,Blend,10)]_ModeDst("ModeDst (混合模式)", Float) = 10
		[KeywordEnum(RGBA,R,G,B)] _RGB("贴图通道(RGB)", Float) = 0
		[KeywordEnum(OFF,Open)] _ClearColor("颜色剔除(RGBA模式下剔除R通道)", Float) = 0
		[KeywordEnum(MainColor,FrontColor)] _SwitchColor("双面颜色", Float) = 0
		[HDR]_MainColorBack("Front颜色", Color) = (1,1,1,1)
		
		
		[HDR]_MainColor("MainColor", Color) = (1,1,1,1)
		_Glow("Glow", Float) = 1
		_Alpha("Alpha", Float) = 1
		_MainTex("MainTex", 2D) = "white" {}
		_UVSpeed("UV速度 (XY速度Z旋转)", Vector) = (0,0,0,0)
		[Toggle(_CUSTOMDISTURBANCE_ON)] _CustomDisturbance("使用CustomData控制主纹理 (UV2, X,Y流动,W扰动)", Float) = 0
		
		
		[Toggle(_USECOLORMAP_ON)] _UseColorMap("使用颜色贴图", Float) = 0
		_ColorMap("颜色贴图", 2D) = "white" {}
		_ColorPower("颜色强度", Range( -2 , 2)) = 0
		ColorMapSpeed("颜色贴图speed (XY速度Z旋转)", Vector) = (0,0,0,0)
		
		
		[Toggle(_USEDISTURBANCE_ON)] _UseDisturbance("使用扰动", Float) = 0
		_DisturbanceTex("Disturbance扰动 (R)", 2D) = "white" {}
		_FloatDst("扰动强度", Float) = 0
		_DistSpeed("扰动值 (XY速度 ZW方向强度)", Vector) = (0,0,1,1)
		
		
		[Toggle(_USEMASK_ON)] _UseMask("使用遮罩", Float) = 0
		_MaskTex("MaskTex (R&A)", 2D) = "white" {}
		MaskSpeed("MaskSpeed (XY速度Z旋转)", Vector) = (0,0,0,0)
		
		
		[Toggle(_USEDISVO_ON)] _UseDisvo("使用溶解", Float) = 0
		[Toggle]_CustomDissolve("使用CustomData控制溶解 (Z)", Float) = 0
		_DissolveControl("溶解进程", Range( 0 , 1)) = 0
		_DissolveControl1("溶解强度", Range( 1 , 5)) = 1
		_SoftEdge("边缘羽化", Range( 0 , 1)) = 0
		_DissolveTex("溶解贴图(R)", 2D) = "white" {}
		_UVSpeed2("溶解UV速度 (XY速度)", Vector) = (0,0,0,0)
		_PowerSize("方向强度", Float) = 1
		_UVSpeed3("溶解方向(XZ左右YW上下)", Vector) = (0,0,0,0)
		[HDR]_LightColor("边缘光颜色", Color) = (0,0,0,0)
		[ASEEnd]_LightSize("边缘光尺寸", Range( 0 , 5)) = 0

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
		
		Cull [_CullMode]
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend SrcAlpha [_ModeDst], One OneMinusSrcAlpha
			ZWrite [_ZWriteMode]
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _SWITCHCOLOR_MAINCOLOR _SWITCHCOLOR_FRONTCOLOR
			#pragma shader_feature_local _RGB_RGBA _RGB_R _RGB_G _RGB_B
			#pragma shader_feature_local _CUSTOMDISTURBANCE_ON
			#pragma shader_feature_local _USEDISTURBANCE_ON
			#pragma shader_feature_local _CLEARCOLOR_OFF _CLEARCOLOR_OPEN
			#pragma shader_feature_local _USECOLORMAP_ON
			#pragma shader_feature_local _USEMASK_ON
			#pragma shader_feature_local _USEDISVO_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 MaskSpeed;
			float4 _LightColor;
			float4 _MaskTex_ST;
			float4 _MainColor;
			float4 _UVSpeed;
			float4 _MainTex_ST;
			float4 _DistSpeed;
			float4 _DisturbanceTex_ST;
			float4 _UVSpeed2;
			float4 ColorMapSpeed;
			float4 _ColorMap_ST;
			float4 _UVSpeed3;
			float4 _DissolveTex_ST;
			float4 _MainColorBack;
			float _PowerSize;
			float _LightSize;
			float _SoftEdge;
			float _CullMode;
			float _DissolveControl;
			float _CustomDissolve;
			float _Glow;
			float _ColorPower;
			float _FloatDst;
			float _ZWriteMode;
			float _ModeDst;
			float _DissolveControl1;
			float _Alpha;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _MainTex;
			sampler2D _DisturbanceTex;
			SAMPLER(sampler_DisturbanceTex);
			SAMPLER(sampler_MainTex);
			sampler2D _ColorMap;
			sampler2D _MaskTex;
			SAMPLER(sampler_MaskTex);
			sampler2D _DissolveTex;
			SAMPLER(sampler_DissolveTex);


						
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN , half ase_vface : VFACE ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float2 appendResult58 = (float2(_UVSpeed.x , _UVSpeed.y));
				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 temp_cast_0 = (0.0).xx;
				float2 appendResult115 = (float2(_DistSpeed.x , _DistSpeed.y));
				float2 uv_DisturbanceTex = IN.ase_texcoord3.xy * _DisturbanceTex_ST.xy + _DisturbanceTex_ST.zw;
				float2 panner117 = ( 1.0 * _Time.y * appendResult115 + uv_DisturbanceTex);
				float4 tex2DNode118 = tex2D( _DisturbanceTex, panner117 );
				float2 appendResult113 = (float2(( _DistSpeed.z * 0.1 ) , ( _DistSpeed.w * 0.1 )));
				#ifdef _USEDISTURBANCE_ON
				float2 staticSwitch199 = ( tex2DNode118.r * appendResult113 * _FloatDst * tex2DNode118.a );
				#else
				float2 staticSwitch199 = temp_cast_0;
				#endif
				float2 panner13 = ( 1.0 * _Time.y * appendResult58 + ( uv_MainTex + staticSwitch199 ));
				float temp_output_60_0 = radians( _UVSpeed.z );
				float cos59 = cos( temp_output_60_0 );
				float sin59 = sin( temp_output_60_0 );
				float2 rotator59 = mul( panner13 - float2( 0.5,0.5 ) , float2x2( cos59 , -sin59 , sin59 , cos59 )) + float2( 0.5,0.5 );
				float4 texCoord46 = IN.ase_texcoord4;
				texCoord46.xy = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult50 = (float2(texCoord46.x , texCoord46.y));
				float cos69 = cos( temp_output_60_0 );
				float sin69 = sin( temp_output_60_0 );
				float2 rotator69 = mul( ( appendResult50 + uv_MainTex + ( tex2DNode118.r * tex2DNode118.a * appendResult113 * texCoord46.w ) ) - float2( 0.5,0.5 ) , float2x2( cos69 , -sin69 , sin69 , cos69 )) + float2( 0.5,0.5 );
				float2 break185 = rotator69;
				float clampResult183 = clamp( break185.x , 0.0 , 1.0 );
				float clampResult186 = clamp( break185.y , 0.0 , 1.0 );
				float2 appendResult188 = (float2(clampResult183 , clampResult186));
				#ifdef _CUSTOMDISTURBANCE_ON
				float2 staticSwitch49 = appendResult188;
				#else
				float2 staticSwitch49 = rotator59;
				#endif
				float4 tex2DNode5 = tex2D( _MainTex, staticSwitch49 );
				float4 temp_cast_1 = (tex2DNode5.r).xxxx;
				float4 temp_cast_2 = (tex2DNode5.g).xxxx;
				float4 temp_cast_3 = (tex2DNode5.b).xxxx;
				#if defined(_RGB_RGBA)
				float4 staticSwitch197 = tex2DNode5;
				#elif defined(_RGB_R)
				float4 staticSwitch197 = temp_cast_1;
				#elif defined(_RGB_G)
				float4 staticSwitch197 = temp_cast_2;
				#elif defined(_RGB_B)
				float4 staticSwitch197 = temp_cast_3;
				#else
				float4 staticSwitch197 = tex2DNode5;
				#endif
				float4 temp_cast_4 = (tex2DNode5.a).xxxx;
				float4 temp_cast_5 = (tex2DNode5.a).xxxx;
				#if defined(_CLEARCOLOR_OFF)
				float4 staticSwitch192 = temp_cast_4;
				#elif defined(_CLEARCOLOR_OPEN)
				float4 staticSwitch192 = ( staticSwitch197 * tex2DNode5.a );
				#else
				float4 staticSwitch192 = temp_cast_4;
				#endif
				float4 temp_cast_6 = (0.0).xxxx;
				float2 appendResult150 = (float2(ColorMapSpeed.x , ColorMapSpeed.y));
				float2 uv_ColorMap = IN.ase_texcoord3.xy * _ColorMap_ST.xy + _ColorMap_ST.zw;
				float2 panner153 = ( 1.0 * _Time.y * appendResult150 + uv_ColorMap);
				float cos154 = cos( radians( ColorMapSpeed.z ) );
				float sin154 = sin( radians( ColorMapSpeed.z ) );
				float2 rotator154 = mul( panner153 - float2( 0.5,0.5 ) , float2x2( cos154 , -sin154 , sin154 , cos154 )) + float2( 0.5,0.5 );
				#ifdef _USECOLORMAP_ON
				float4 staticSwitch203 = ( staticSwitch197 * ( tex2D( _ColorMap, rotator154 ) * ( _ColorPower * -1.0 ) ) );
				#else
				float4 staticSwitch203 = temp_cast_6;
				#endif
				float2 appendResult63 = (float2(MaskSpeed.x , MaskSpeed.y));
				float2 uv_MaskTex = IN.ase_texcoord3.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				float2 panner18 = ( 1.0 * _Time.y * appendResult63 + uv_MaskTex);
				float cos65 = cos( radians( MaskSpeed.z ) );
				float sin65 = sin( radians( MaskSpeed.z ) );
				float2 rotator65 = mul( panner18 - float2( 0.5,0.5 ) , float2x2( cos65 , -sin65 , sin65 , cos65 )) + float2( 0.5,0.5 );
				float4 tex2DNode19 = tex2D( _MaskTex, rotator65 );
				#ifdef _USEMASK_ON
				float4 staticSwitch201 = ( tex2DNode19.a * staticSwitch192 * tex2DNode19.r );
				#else
				float4 staticSwitch201 = staticSwitch192;
				#endif
				float2 temp_cast_7 = (1.0).xx;
				float temp_output_139_0 = ( (( _CustomDissolve )?( texCoord46.z ):( ( (-0.05 + (_DissolveControl - 0.0) * (1.1 - -0.05) / (1.0 - 0.0)) * _DissolveControl1 ) )) + _SoftEdge );
				float4 appendResult129 = (float4(_UVSpeed2.x , _UVSpeed2.y , 0.0 , 0.0));
				float2 uv_DissolveTex = IN.ase_texcoord3.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				float2 panner132 = ( 1.0 * _Time.y * appendResult129.xy + uv_DissolveTex);
				float cos134 = cos( radians( _UVSpeed2.z ) );
				float sin134 = sin( radians( _UVSpeed2.z ) );
				float2 rotator134 = mul( panner132 - float2( 0.5,0.5 ) , float2x2( cos134 , -sin134 , sin134 , cos134 )) + float2( 0.5,0.5 );
				float temp_output_172_0 = abs( ( ( uv_DissolveTex.x * _UVSpeed3.x ) + ( uv_DissolveTex.y * _UVSpeed3.y ) + ( ( 1.0 - uv_DissolveTex.x ) * _UVSpeed3.z ) + ( ( 1.0 - uv_DissolveTex.y ) * _UVSpeed3.w ) ) );
				float ifLocalVar170 = 0;
				if( temp_output_172_0 <= 0.0 )
				ifLocalVar170 = 1.0;
				else
				ifLocalVar170 = temp_output_172_0;
				float temp_output_167_0 = ( tex2D( _DissolveTex, rotator134 ).r * pow( ifLocalVar170 , _PowerSize ) );
				float smoothstepResult143 = smoothstep( (( _CustomDissolve )?( texCoord46.z ):( ( (-0.05 + (_DissolveControl - 0.0) * (1.1 - -0.05) / (1.0 - 0.0)) * _DissolveControl1 ) )) , temp_output_139_0 , temp_output_167_0);
				float smoothstepResult142 = smoothstep( (( _CustomDissolve )?( texCoord46.z ):( ( (-0.05 + (_DissolveControl - 0.0) * (1.1 - -0.05) / (1.0 - 0.0)) * _DissolveControl1 ) )) , temp_output_139_0 , ( temp_output_167_0 + ( _LightSize * 0.1 ) ));
				float2 appendResult206 = (float2(smoothstepResult143 , smoothstepResult142));
				#ifdef _USEDISVO_ON
				float2 staticSwitch207 = appendResult206;
				#else
				float2 staticSwitch207 = temp_cast_7;
				#endif
				float3 objToWorldDir218 = mul( GetObjectToWorldMatrix(), float4( float3( staticSwitch207 ,  0.0 ), 0 ) ).xyz;
				float4 temp_output_94_0 = ( staticSwitch201 * objToWorldDir218.x );
				float4 appendResult102 = (float4((( ( ( _MainColor * staticSwitch197 * staticSwitch192 ) + staticSwitch203 ) * _Glow * IN.ase_color )).rgb , temp_output_94_0.r));
				float4 temp_output_147_0 = ( staticSwitch201 * objToWorldDir218.y );
				float4 temp_output_145_0 = ( ( temp_output_147_0 - temp_output_94_0 ) * _LightColor );
				float4 temp_output_95_0 = ( appendResult102 + temp_output_145_0 );
				float4 appendResult180 = (float4((( ( staticSwitch203 + ( staticSwitch197 * _MainColorBack ) ) * IN.ase_color * _Glow )).rgb , temp_output_94_0.r));
				float4 switchResult176 = (((ase_vface>0)?(temp_output_95_0):(( appendResult180 + temp_output_145_0 ))));
				#if defined(_SWITCHCOLOR_MAINCOLOR)
				float4 staticSwitch196 = temp_output_95_0;
				#elif defined(_SWITCHCOLOR_FRONTCOLOR)
				float4 staticSwitch196 = switchResult176;
				#else
				float4 staticSwitch196 = temp_output_95_0;
				#endif
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = staticSwitch196.xyz;
				float Alpha = ( IN.ase_color.a * temp_output_94_0 * temp_output_147_0 * _MainColorBack.a * _MainColor.a * _Alpha ).r;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

	
	}
	CustomEditor "RBMJGUI.RBMJEffectsGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18500
2643;89;2336;1173;2953.893;797.3318;1.122648;True;True
Node;AmplifyShaderEditor.CommentaryNode;121;-4193.532,-574.8346;Inherit;False;1345.299;568.73;Comment;11;114;118;113;111;112;117;116;115;110;119;200;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector4Node;110;-4143.532,-349.3819;Float;False;Property;_DistSpeed;扰动值 (XY速度 ZW方向强度);20;0;Create;False;0;0;False;0;False;0,0,1,1;0.5,0.5,1,1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;115;-3763.149,-382.936;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;116;-3865.002,-511.9333;Inherit;False;0;118;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;117;-3597.864,-434.5355;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;-3764.023,-280.1047;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;111;-3765.023,-187.1046;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;113;-3557.793,-250.3931;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;46;-2901.638,225.26;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;148;-2285.667,1167.406;Inherit;False;2696.186;983.4401;Comment;37;143;142;140;139;136;138;167;135;133;169;141;168;166;134;132;131;165;162;163;164;160;129;161;159;128;130;171;170;172;175;173;174;137;206;207;218;219;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;118;-3351.318,-524.8345;Inherit;True;Property;_DisturbanceTex;Disturbance扰动 (R);18;0;Create;False;0;0;False;0;False;-1;None;cb0f0c441ea4d174a9e85196e2467740;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;50;-2385.587,-32.07059;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;130;-2097.802,1247.568;Inherit;False;0;141;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;70;-2459.015,73.75928;Inherit;False;0;5;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;57;-2664.273,-226.962;Inherit;False;Property;_UVSpeed;UV速度 (XY速度Z旋转);11;0;Create;False;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;158;-2450.126,208.0497;Inherit;True;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT2;0,0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;114;-3173.877,-280.9988;Inherit;False;Property;_FloatDst;扰动强度;19;0;Create;False;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;161;-2007.887,1654.444;Inherit;False;Property;_UVSpeed3;溶解方向(XZ左右YW上下);32;0;Create;False;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;160;-1680.187,1572.144;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RadiansOpNode;60;-2226.959,-117.1716;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;159;-1683.187,1661.144;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;119;-2966.065,-499.8503;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;200;-2921.238,-326.5685;Inherit;False;Constant;_OFFDis;OffDist;17;0;Create;False;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;53;-2183.719,58.15974;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;199;-2709.14,-357.6664;Inherit;False;Property;_UseDisturbance;使用扰动;17;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;12;-2647.809,-553.9716;Inherit;False;0;5;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RotatorNode;69;-1965.374,30.84394;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;162;-1509.186,1718.144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;-1507.186,1620.144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;128;-2235.667,1418.788;Inherit;False;Property;_UVSpeed2;溶解UV速度 (XY速度);30;0;Create;False;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;165;-1506.378,1412.54;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;164;-1505.186,1515.144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;58;-2389.998,-218.5138;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;120;-2275,-354;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;166;-1313.314,1484.618;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;129;-1960.363,1421.388;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BreakToComponentsNode;185;-1750.298,-17.66478;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ClampOpNode;183;-1514.003,-72.1989;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;132;-1765.364,1285.386;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.AbsOpNode;172;-1179.186,1494.516;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;13;-2115,-322;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;171;-1312.571,1645.152;Inherit;False;Constant;_Float0;Float 0;16;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RadiansOpNode;131;-1961.061,1568.476;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;149;-1282.884,296.3279;Inherit;False;Property;ColorMapSpeed;颜色贴图speed (XY速度Z旋转);16;0;Create;False;0;0;False;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;135;-1852.058,1871.388;Inherit;False;Property;_DissolveControl;溶解进程;26;0;Create;False;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;186;-1515.299,59.33518;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ConditionalIfNode;170;-1052.305,1501.048;Inherit;False;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;151;-1077.299,128.4007;Inherit;False;0;104;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;150;-961.6862,299.8314;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;134;-1553.862,1283.374;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;41;-1200.231,535.9255;Inherit;False;1380.888;579.6703;Comment;8;62;63;65;61;27;16;18;19;Tipsddddddddddddd;1,1,1,1;0;0
Node;AmplifyShaderEditor.RotatorNode;59;-1817.526,-306.8166;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;174;-1756.812,2075.628;Inherit;False;Property;_DissolveControl1;溶解强度;27;0;Create;False;0;0;False;0;False;1;1;1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;188;-1351.09,3.465405;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;173;-1516.025,1890.028;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-0.05;False;4;FLOAT;1.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;168;-1042.039,1696.95;Inherit;False;Property;_PowerSize;方向强度;31;0;Create;False;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;141;-1325.186,1267.406;Inherit;True;Property;_DissolveTex;溶解贴图(R);29;0;Create;False;0;0;False;0;False;-1;None;cb0f0c441ea4d174a9e85196e2467740;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;169;-881.0103,1548.563;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;49;-1195.329,-248.9635;Inherit;False;Property;_CustomDisturbance;使用CustomData控制主纹理 (UV2, X,Y流动,W扰动);12;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;153;-751.5234,175.5434;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;175;-1269.025,1965.028;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;62;-1363.62,745.567;Inherit;False;Property;MaskSpeed;MaskSpeed (XY速度Z旋转);23;0;Create;False;0;0;False;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;133;-1263.789,1776.966;Inherit;False;Property;_LightSize;边缘光尺寸;34;0;Create;False;0;0;False;0;False;0;0;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RadiansOpNode;152;-762.6678,384.3634;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;136;-1088.2,1931.6;Inherit;False;Property;_CustomDissolve;使用CustomData控制溶解 (Z);25;0;Create;False;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;63;-1108.226,772.2593;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;137;-1099.436,2062.147;Inherit;False;Property;_SoftEdge;边缘羽化;28;0;Create;False;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;108;-438.8711,301.9856;Inherit;False;Property;_ColorPower;颜色强度;15;0;Create;False;0;0;False;0;False;0;-0.96;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;16;-1193.433,616.1877;Inherit;False;0;19;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;167;-692.754,1485.544;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;138;-889.8989,1789.317;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;5;-805.1436,-255.3971;Inherit;True;Property;_MainTex;MainTex;10;0;Create;True;0;0;False;0;False;-1;None;466a28b0baeaa84429a9e633011d64a9;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RotatorNode;154;-501.89,170.3551;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;197;-421.2825,-326.7222;Inherit;False;Property;_RGB;贴图通道(RGB);3;0;Create;False;0;0;False;0;False;0;0;0;True;;KeywordEnum;4;RGBA;R;G;B;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RadiansOpNode;61;-992.8221,862.6723;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;18;-957.028,666.852;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;104;-285.126,98.34008;Inherit;True;Property;_ColorMap;颜色贴图;14;0;Create;False;0;0;False;0;False;-1;None;d1ac0d44bc4fd8d44974e194c1ab2b63;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-631.5669,2024.403;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;157;-138.7443,305.3812;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;140;-696.2958,1691.954;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;143;-384.2509,1526.073;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;193;-370.3916,-131.549;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;142;-385.5222,1860.32;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;96.43319,132.8636;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RotatorNode;65;-762.8595,699.9828;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;10;71.16771,-497.7664;Inherit;False;Property;_MainColor;MainColor;7;1;[HDR];Create;True;0;0;False;0;False;1,1,1,1;1.385459,2.490141,5.340313,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;19;-517.1197,672.0862;Inherit;True;Property;_MaskTex;MaskTex (R&A);22;0;Create;False;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;206;-138.3757,1644.394;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;192;-225.8344,-31.74909;Inherit;False;Property;_ClearColor;颜色剔除(RGBA模式下剔除R通道);4;0;Create;False;0;0;False;0;False;0;0;0;True;;KeywordEnum;2;OFF;Open;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;182;593.5729,869.0618;Inherit;False;Property;_MainColorBack;Front颜色;6;1;[HDR];Create;False;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;205;276.3642,119.6239;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;204;266.8303,-48.39162;Inherit;False;Constant;_OffColorMap;_OffColorMap;8;0;Create;True;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;219;-246.0661,1404.461;Inherit;False;Constant;_OffDiso;_OffDiso;8;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;207;18.03426,1620.312;Inherit;False;Property;_UseDisvo;使用溶解;24;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;559.8036,-354.9038;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-79.70046,661.987;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;177;941.7281,556.4244;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;203;497.0448,81.45782;Inherit;False;Property;_UseColorMap;使用颜色贴图;13;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;201;234.7555,551.171;Inherit;False;Property;_UseMask;使用遮罩;21;0;Create;False;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;6;687.2314,357.7443;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;109;962.0201,-213.4148;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TransformDirectionNode;218;254.798,1619.179;Inherit;False;Object;World;False;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;189;727.7438,233.1969;Inherit;False;Property;_Glow;Glow;8;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;178;1110.184,350.9983;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;549.6271,605.2385;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;190;1165.382,-3.123852;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;147;575.4273,1131.941;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;191;1289.921,511.5641;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;146;1014.519,1561.485;Inherit;False;Property;_LightColor;边缘光颜色;33;1;[HDR];Create;False;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;101;1315.958,50.99134;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;179;1448.937,539.6533;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;144;1018.048,1274.16;Inherit;True;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;180;1681.155,710.2717;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;102;1586.873,86.21265;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;145;1342.944,1332.862;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;181;2062.036,864.5151;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;95;2066.122,320.0749;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;28;1472.181,934.4977;Inherit;False;Property;_Alpha;Alpha;9;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwitchByFaceNode;176;2379.785,545.548;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;21;-1332.2,-713.9002;Inherit;False;528;169;Mode;3;8;11;4;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;4;-1314.724,-672.1155;Inherit;False;Property;_ModeDst;ModeDst (混合模式);2;1;[Enum];Create;False;2;Add;1;Blend;10;0;True;1;;False;10;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;11;-954.658,-673.1155;Inherit;False;Property;_CullMode;CullMode;1;1;[Enum];Create;True;2;On;1;Off;0;1;UnityEngine.Rendering.CullMode;True;1;;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;196;2650.152,402.1259;Inherit;False;Property;_SwitchColor;双面颜色;5;0;Create;False;0;0;False;0;False;0;0;0;True;;KeywordEnum;2;MainColor;FrontColor;Create;True;True;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;1785.744,479.5327;Inherit;False;6;6;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-1121.752,-670.9939;Inherit;False;Property;_ZWriteMode;ZWriteMode;0;1;[Enum];Create;True;2;On;1;Off;0;0;True;1;;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;126;1915.124,258.1763;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;124;1915.124,258.1763;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;123;3037.093,429.2769;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;AFX/EffectCommonTest;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;True;11;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;0;True;2;5;False;-1;10;True;4;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;True;8;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;0;  Use Shadow Threshold;0;Receive Shadows;0;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;False;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;125;1915.124,258.1763;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;False;False;False;False;0;False;-1;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;122;1915.124,258.1763;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;115;0;110;1
WireConnection;115;1;110;2
WireConnection;117;0;116;0
WireConnection;117;2;115;0
WireConnection;112;0;110;3
WireConnection;111;0;110;4
WireConnection;113;0;112;0
WireConnection;113;1;111;0
WireConnection;118;1;117;0
WireConnection;50;0;46;1
WireConnection;50;1;46;2
WireConnection;158;0;118;1
WireConnection;158;1;118;4
WireConnection;158;2;113;0
WireConnection;158;3;46;4
WireConnection;160;0;130;1
WireConnection;60;0;57;3
WireConnection;159;0;130;2
WireConnection;119;0;118;1
WireConnection;119;1;113;0
WireConnection;119;2;114;0
WireConnection;119;3;118;4
WireConnection;53;0;50;0
WireConnection;53;1;70;0
WireConnection;53;2;158;0
WireConnection;199;1;200;0
WireConnection;199;0;119;0
WireConnection;69;0;53;0
WireConnection;69;2;60;0
WireConnection;162;0;159;0
WireConnection;162;1;161;4
WireConnection;163;0;160;0
WireConnection;163;1;161;3
WireConnection;165;0;130;1
WireConnection;165;1;161;1
WireConnection;164;0;130;2
WireConnection;164;1;161;2
WireConnection;58;0;57;1
WireConnection;58;1;57;2
WireConnection;120;0;12;0
WireConnection;120;1;199;0
WireConnection;166;0;165;0
WireConnection;166;1;164;0
WireConnection;166;2;163;0
WireConnection;166;3;162;0
WireConnection;129;0;128;1
WireConnection;129;1;128;2
WireConnection;185;0;69;0
WireConnection;183;0;185;0
WireConnection;132;0;130;0
WireConnection;132;2;129;0
WireConnection;172;0;166;0
WireConnection;13;0;120;0
WireConnection;13;2;58;0
WireConnection;131;0;128;3
WireConnection;186;0;185;1
WireConnection;170;0;172;0
WireConnection;170;2;172;0
WireConnection;170;3;171;0
WireConnection;170;4;171;0
WireConnection;150;0;149;1
WireConnection;150;1;149;2
WireConnection;134;0;132;0
WireConnection;134;2;131;0
WireConnection;59;0;13;0
WireConnection;59;2;60;0
WireConnection;188;0;183;0
WireConnection;188;1;186;0
WireConnection;173;0;135;0
WireConnection;141;1;134;0
WireConnection;169;0;170;0
WireConnection;169;1;168;0
WireConnection;49;1;59;0
WireConnection;49;0;188;0
WireConnection;153;0;151;0
WireConnection;153;2;150;0
WireConnection;175;0;173;0
WireConnection;175;1;174;0
WireConnection;152;0;149;3
WireConnection;136;0;175;0
WireConnection;136;1;46;3
WireConnection;63;0;62;1
WireConnection;63;1;62;2
WireConnection;167;0;141;1
WireConnection;167;1;169;0
WireConnection;138;0;133;0
WireConnection;5;1;49;0
WireConnection;154;0;153;0
WireConnection;154;2;152;0
WireConnection;197;1;5;0
WireConnection;197;0;5;1
WireConnection;197;2;5;2
WireConnection;197;3;5;3
WireConnection;61;0;62;3
WireConnection;18;0;16;0
WireConnection;18;2;63;0
WireConnection;104;1;154;0
WireConnection;139;0;136;0
WireConnection;139;1;137;0
WireConnection;157;0;108;0
WireConnection;140;0;167;0
WireConnection;140;1;138;0
WireConnection;143;0;167;0
WireConnection;143;1;136;0
WireConnection;143;2;139;0
WireConnection;193;0;197;0
WireConnection;193;1;5;4
WireConnection;142;0;140;0
WireConnection;142;1;136;0
WireConnection;142;2;139;0
WireConnection;107;0;104;0
WireConnection;107;1;157;0
WireConnection;65;0;18;0
WireConnection;65;2;61;0
WireConnection;19;1;65;0
WireConnection;206;0;143;0
WireConnection;206;1;142;0
WireConnection;192;1;5;4
WireConnection;192;0;193;0
WireConnection;205;0;197;0
WireConnection;205;1;107;0
WireConnection;207;1;219;0
WireConnection;207;0;206;0
WireConnection;7;0;10;0
WireConnection;7;1;197;0
WireConnection;7;2;192;0
WireConnection;27;0;19;4
WireConnection;27;1;192;0
WireConnection;27;2;19;1
WireConnection;177;0;197;0
WireConnection;177;1;182;0
WireConnection;203;1;204;0
WireConnection;203;0;205;0
WireConnection;201;1;192;0
WireConnection;201;0;27;0
WireConnection;109;0;7;0
WireConnection;109;1;203;0
WireConnection;218;0;207;0
WireConnection;178;0;203;0
WireConnection;178;1;177;0
WireConnection;94;0;201;0
WireConnection;94;1;218;1
WireConnection;190;0;109;0
WireConnection;190;1;189;0
WireConnection;190;2;6;0
WireConnection;147;0;201;0
WireConnection;147;1;218;2
WireConnection;191;0;178;0
WireConnection;191;1;6;0
WireConnection;191;2;189;0
WireConnection;101;0;190;0
WireConnection;179;0;191;0
WireConnection;144;0;147;0
WireConnection;144;1;94;0
WireConnection;180;0;179;0
WireConnection;180;3;94;0
WireConnection;102;0;101;0
WireConnection;102;3;94;0
WireConnection;145;0;144;0
WireConnection;145;1;146;0
WireConnection;181;0;180;0
WireConnection;181;1;145;0
WireConnection;95;0;102;0
WireConnection;95;1;145;0
WireConnection;176;0;95;0
WireConnection;176;1;181;0
WireConnection;196;1;95;0
WireConnection;196;0;176;0
WireConnection;127;0;6;4
WireConnection;127;1;94;0
WireConnection;127;2;147;0
WireConnection;127;3;182;4
WireConnection;127;4;10;4
WireConnection;127;5;28;0
WireConnection;123;2;196;0
WireConnection;123;3;127;0
ASEEND*/
//CHKSM=F86A88AF22EF4CA34AE041E9C8B010455716AC0F