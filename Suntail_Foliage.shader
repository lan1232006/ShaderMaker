// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "WLTX/ToonFoliage"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2
		[SingleLineTexture][Header(Maps)][Space(10)][MainTexture]_Albedo("Albedo", 2D) = "white" {}
		[SingleLineTexture]_SmoothnessTexture("Smoothness", 2D) = "white" {}
		_Tiling("Tiling", Float) = 1
		[Header(Settings)][Space(5)]_MainColor("Main Color", Color) = (1,1,1,0)
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		_AlphaCutoff("Alpha Cutoff", Range( 0 , 1)) = 0.35
		[Header(Second Color Settings)][Space(5)][Toggle(_COLOR2ENABLE_ON)] _Color2Enable("Enable", Float) = 0
		_SecondColor("Second Color", Color) = (0,0,0,0)
		[KeywordEnum(World_Position,UV_Based)] _SecondColorOverlayType("Overlay Type", Float) = 0
		_SecondColorOffset("Offset", Float) = 0
		_SecondColorFade("Fade", Range( -1 , 1)) = 0.5
		_WorldScale("World Scale", Float) = 1
		[Header(Wind Settings)][Space(5)][Toggle(_ENABLEWIND_ON)] _EnableWind("Enable", Float) = 1
		_WindForce("Force", Range( 0 , 1)) = 0.3
		_WindWavesScale("Waves Scale", Range( 0 , 1)) = 0.25
		_WindSpeed("Speed", Range( 0 , 1)) = 0.5
		[Toggle(_ANCHORTHEFOLIAGEBASE_ON)] _Anchorthefoliagebase("Anchor the foliage base", Float) = 0
		[Header(Lighting Settings)][Space(5)]_DirectLightOffset("Direct Light Offset", Range( 0 , 1)) = 0
		_DirectLightInt("Direct Light Int", Range( 1 , 10)) = 1
		_IndirectLightInt("Indirect Light Int", Range( 1 , 10)) = 1
		[ASEEnd]_TranslucencyInt("Translucency Int", Range( 0 , 100)) = 1

		[HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
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

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull [_CullMode]
		AlphaToMask Off
		
		HLSLINCLUDE
		#pragma target 3.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
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
		#endif 

		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#pragma multi_compile _ DOTS_INSTANCING_ON
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 120101

			
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma shader_feature _ _SAMPLE_GI
			//#pragma multi_compile _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			//#pragma multi_compile _ DEBUG_DISPLAY
			#define SHADERPASS SHADERPASS_UNLIT


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"


			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma shader_feature_local _ENABLEWIND_ON
			#pragma shader_feature_local _ANCHORTHEFOLIAGEBASE_ON
			// #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			//#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			// #pragma multi_compile _ _SHADOWS_SOFT
			#pragma shader_feature_local _COLOR2ENABLE_ON
			//#pragma shader_feature_local _SECONDCOLOROVERLAYTYPE_WORLD_POSITION _SECONDCOLOROVERLAYTYPE_UV_BASED
			//#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			// #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			// #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			// #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 ase_tangent : TANGENT;
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
				float4 lightmapUVOrVertexSH : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float4 _SecondColor;
			float _WindSpeed;
			float _WindWavesScale;
			float _WindForce;
			float _Tiling;
			float _WorldScale;
			float _SecondColorOffset;
			float _SecondColorFade;
			float _IndirectLightInt;
			float _DirectLightOffset;
			float _DirectLightInt;
			float _TranslucencyInt;
			float _Smoothness;
			float _AlphaCutoff;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _Albedo;
			sampler2D _SmoothnessTexture;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float3 ASEIndirectDiffuse( float2 uvStaticLightmap, float3 normalWS )
			{
			#ifdef LIGHTMAP_ON
				return SampleLightmap( uvStaticLightmap, normalWS );
			#else
				return SampleSH(normalWS);
			#endif
			}
			
			float3 AdditionalLightsFlatMask( float3 WorldPosition, float4 ShadowMask )
			{
				float3 Color = 0;
				#ifdef _ADDITIONAL_LIGHTS
				int numLights = GetAdditionalLightsCount();
				for(int i = 0; i<numLights;i++)
				{
				#if ASE_SRP_VERSION >= 100000
					Light light = GetAdditionalLight(i, WorldPosition, ShadowMask);
				#else
					Light light = GetAdditionalLight(i, WorldPosition);
				#endif
					Color += light.color *(light.distanceAttenuation * light.shadowAttenuation);
					
				}
				#endif
				return Color;
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float mulTime34 = _TimeParameters.x * ( _WindSpeed * 5 );
				float simplePerlin3D35 = snoise( ( ase_worldPos + mulTime34 )*_WindWavesScale );
				float temp_output_231_0 = ( simplePerlin3D35 * 0.01 );
				float2 texCoord357 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				#ifdef _ANCHORTHEFOLIAGEBASE_ON
				float staticSwitch376 = ( temp_output_231_0 * pow( texCoord357.y , 2.0 ) );
				#else
				float staticSwitch376 = temp_output_231_0;
				#endif
				#ifdef _ENABLEWIND_ON
				float staticSwitch341 = ( staticSwitch376 * ( _WindForce * 30 ) );
				#else
				float staticSwitch341 = 0.0;
				#endif
				float Wind191 = staticSwitch341;
				float3 temp_cast_0 = (Wind191).xxx;
				
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( ase_worldNormal, o.lightmapUVOrVertexSH.xyz );
				o.ase_texcoord4.xyz = ase_worldNormal;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord6.xyz = ase_worldTangent;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord7.xyz = ase_worldBitangent;
				
				o.ase_texcoord5.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.zw = 0;
				o.ase_texcoord6.w = 0;
				o.ase_texcoord7.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_0;
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
				float4 texcoord1 : TEXCOORD1;
				float4 ase_tangent : TANGENT;

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
				o.texcoord1 = v.texcoord1;
				o.ase_tangent = v.ase_tangent;
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
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
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

			half4 frag ( VertexOutput IN  ) : SV_Target
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
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 bakedGI436 = ASEIndirectDiffuse( IN.lightmapUVOrVertexSH.xy, ase_worldNormal);
				Light ase_mainLight = GetMainLight( ShadowCoords );
				MixRealtimeAndBakedGI(ase_mainLight, ase_worldNormal, bakedGI436, half4(0,0,0,0));
				float2 temp_cast_1 = (_Tiling).xx;
				float2 texCoord747 = IN.ase_texcoord5.xy * temp_cast_1 + float2( 0,0 );
				float2 Tiling748 = texCoord747;
				float4 tex2DNode1 = tex2D( _Albedo, Tiling748 );
				float4 temp_output_10_0 = ( _MainColor * tex2DNode1 );
				float simplePerlin3D742 = snoise( WorldPosition*_WorldScale );
				simplePerlin3D742 = simplePerlin3D742*0.5 + 0.5;
				float2 texCoord361 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				#if defined(_SECONDCOLOROVERLAYTYPE_WORLD_POSITION)
				float staticSwitch360 = simplePerlin3D742;
				#elif defined(_SECONDCOLOROVERLAYTYPE_UV_BASED)
				float staticSwitch360 = texCoord361.y;
				#else
				float staticSwitch360 = simplePerlin3D742;
				#endif
				float SecondColorMask335 = saturate( ( ( staticSwitch360 + _SecondColorOffset ) * ( _SecondColorFade * 2 ) ) );
				float4 lerpResult332 = lerp( temp_output_10_0 , ( _SecondColor * tex2D( _Albedo, Tiling748 ) ) , SecondColorMask335);
				#ifdef _COLOR2ENABLE_ON
				float4 staticSwitch340 = lerpResult332;
				#else
				float4 staticSwitch340 = temp_output_10_0;
				#endif
				float4 Albedo259 = staticSwitch340;
				float4 IndirectLight612 = ( float4( bakedGI436 , 0.0 ) * Albedo259 * _IndirectLightInt );
				float3 normalizedWorldNormal = normalize( ase_worldNormal );
				float dotResult430 = dot( SafeNormalize(_MainLightPosition.xyz) , normalizedWorldNormal );
				float ase_lightAtten = 0;
				ase_lightAtten = ase_mainLight.distanceAttenuation * ase_mainLight.shadowAttenuation;
				float4 DirectLight614 = ( ( saturate( (dotResult430*1.0 + _DirectLightOffset) ) * ase_lightAtten ) * _MainLightColor * Albedo259 * _DirectLightInt );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float dotResult461 = dot( SafeNormalize(_MainLightPosition.xyz) , ase_worldViewDir );
				float TranslucencyMask660 = (-dotResult461*1.0 + -0.2);
				float dotResult672 = dot( SafeNormalize(_MainLightPosition.xyz) , normalizedWorldNormal );
				float4 Translucency631 = saturate( ( ( TranslucencyMask660 * ( ( ( (dotResult672*1.0 + 1.0) * ase_lightAtten ) * _MainLightColor * Albedo259 ) * 0.25 ) ) * _TranslucencyInt ) );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float fresnelNdotV791 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode791 = ( 0.04 + 1.0 * pow( 1.0 - fresnelNdotV791, 5.0 ) );
				half3 reflectVector831 = reflect( -ase_worldViewDir, ase_worldNormal );
				float3 indirectSpecular831 = GlossyEnvironmentReflection( reflectVector831, 1.0 - _Smoothness, 1.0 );
				float3 LightWrapVector47_g14 = (( 1.0 * 0.5 )).xxx;
				float3 ase_worldTangent = IN.ase_texcoord6.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord7.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal19_g14 = float3(0,0,1);
				float3 worldNormal19_g14 = normalize( float3(dot(tanToWorld0,tanNormal19_g14), dot(tanToWorld1,tanNormal19_g14), dot(tanToWorld2,tanNormal19_g14)) );
				float3 CurrentNormal23_g14 = worldNormal19_g14;
				float dotResult20_g14 = dot( CurrentNormal23_g14 , SafeNormalize(_MainLightPosition.xyz) );
				float NDotL21_g14 = dotResult20_g14;
				float3 AttenuationColor8_g14 = ( _MainLightColor.rgb * ase_lightAtten );
				float3 DiffuseColor70_g14 = ( ( ( max( ( LightWrapVector47_g14 + ( ( 1.0 - LightWrapVector47_g14 ) * NDotL21_g14 ) ) , float3(0,0,0) ) * AttenuationColor8_g14 ) + (UNITY_LIGHTMODEL_AMBIENT).rgb ) * float3( 0,0,0 ) );
				float3 normalizeResult77_g14 = normalize( _MainLightPosition.xyz );
				float3 normalizeResult28_g14 = normalize( ( normalizeResult77_g14 + ase_worldViewDir ) );
				float3 HalfDirection29_g14 = normalizeResult28_g14;
				float dotResult32_g14 = dot( HalfDirection29_g14 , CurrentNormal23_g14 );
				float SpecularPower14_g14 = exp2( ( ( ( _Smoothness * 0.8 ) * 10.0 ) + 1.0 ) );
				float3 specularFinalColor42_g14 = ( AttenuationColor8_g14 * pow( max( dotResult32_g14 , 0.0 ) , SpecularPower14_g14 ) * _Smoothness );
				float dotResult811 = dot( ase_worldNormal , ase_worldViewDir );
				float4 Smoothness734 = saturate( ( float4( ( ( ( ( fresnelNode791 * indirectSpecular831 ) + ( ( DiffuseColor70_g14 + specularFinalColor42_g14 ) * 0.6 ) ) * _Smoothness ) * (dotResult811*1.0 + 0.5) ) , 0.0 ) * tex2D( _SmoothnessTexture, Tiling748 ) ) );
				float3 worldPosValue44_g15 = WorldPosition;
				float3 WorldPosition31_g15 = worldPosValue44_g15;
				float4 shadowMaskValue33_g15 = float4(1,1,1,1);
				float4 ShadowMask31_g15 = shadowMaskValue33_g15;
				float3 localAdditionalLightsFlatMask31_g15 = AdditionalLightsFlatMask( WorldPosition31_g15 , ShadowMask31_g15 );
				float3 FlatResult29_g15 = localAdditionalLightsFlatMask31_g15;
				
				float OpacityMask263 = tex2DNode1.a;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( IndirectLight612 + DirectLight614 + Translucency631 + Smoothness734 + ( Albedo259 * float4( FlatResult29_g15 , 0.0 ) ) ).rgb;
				float Alpha = OpacityMask263;
				float AlphaClipThreshold = _AlphaCutoff;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.clipPos, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
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

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			//#pragma multi_compile _ DOTS_INSTANCING_ON
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 120101

			
			#pragma vertex vert
			#pragma fragment frag

			//#pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma shader_feature_local _ENABLEWIND_ON
			#pragma shader_feature_local _ANCHORTHEFOLIAGEBASE_ON
			//#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			//#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float4 _SecondColor;
			float _WindSpeed;
			float _WindWavesScale;
			float _WindForce;
			float _Tiling;
			float _WorldScale;
			float _SecondColorOffset;
			float _SecondColorFade;
			float _IndirectLightInt;
			float _DirectLightOffset;
			float _DirectLightInt;
			float _TranslucencyInt;
			float _Smoothness;
			float _AlphaCutoff;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _Albedo;


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			

			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float mulTime34 = _TimeParameters.x * ( _WindSpeed * 5 );
				float simplePerlin3D35 = snoise( ( ase_worldPos + mulTime34 )*_WindWavesScale );
				float temp_output_231_0 = ( simplePerlin3D35 * 0.01 );
				float2 texCoord357 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				#ifdef _ANCHORTHEFOLIAGEBASE_ON
				float staticSwitch376 = ( temp_output_231_0 * pow( texCoord357.y , 2.0 ) );
				#else
				float staticSwitch376 = temp_output_231_0;
				#endif
				#ifdef _ENABLEWIND_ON
				float staticSwitch341 = ( staticSwitch376 * ( _WindForce * 30 ) );
				#else
				float staticSwitch341 = 0.0;
				#endif
				float Wind191 = staticSwitch341;
				float3 temp_cast_0 = (Wind191).xxx;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

			#if _CASTING_PUNCTUAL_LIGHT_SHADOW
				float3 lightDirectionWS = normalize(_LightPosition - positionWS);
			#else
				float3 lightDirectionWS = _LightDirection;
			#endif
				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
			#if UNITY_REVERSED_Z
				clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
			#else
				clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
			#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;

				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

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

			half4 frag(VertexOutput IN  ) : SV_TARGET
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

				float2 temp_cast_0 = (_Tiling).xx;
				float2 texCoord747 = IN.ase_texcoord2.xy * temp_cast_0 + float2( 0,0 );
				float2 Tiling748 = texCoord747;
				float4 tex2DNode1 = tex2D( _Albedo, Tiling748 );
				float OpacityMask263 = tex2DNode1.a;
				
				float Alpha = OpacityMask263;
				float AlphaClipThreshold = _AlphaCutoff;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}

			ENDHLSL
		}

		
//		Pass
//		{
//			
//			Name "DepthOnly"
//			Tags { "LightMode"="DepthOnly" }
//
//			ZWrite On
//			ColorMask 0
//			AlphaToMask Off
//
//			HLSLPROGRAM
//			
//			#pragma multi_compile_instancing
//			#pragma multi_compile _ LOD_FADE_CROSSFADE
//			#pragma multi_compile_fog
//			#define ASE_FOG 1
//			#pragma multi_compile _ DOTS_INSTANCING_ON
//			#define _ALPHATEST_ON 1
//			#define ASE_SRP_VERSION 120101
//
//			
//			#pragma vertex vert
//			#pragma fragment frag
//
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
//			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
//
//			#pragma shader_feature_local _ENABLEWIND_ON
//			#pragma shader_feature_local _ANCHORTHEFOLIAGEBASE_ON
//			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
//			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
//
//
//			struct VertexInput
//			{
//				float4 vertex : POSITION;
//				float3 ase_normal : NORMAL;
//				float4 ase_texcoord : TEXCOORD0;
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//			};
//
//			struct VertexOutput
//			{
//				float4 clipPos : SV_POSITION;
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				float3 worldPos : TEXCOORD0;
//				#endif
//				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//				float4 shadowCoord : TEXCOORD1;
//				#endif
//				float4 ase_texcoord2 : TEXCOORD2;
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//				UNITY_VERTEX_OUTPUT_STEREO
//			};
//
//			CBUFFER_START(UnityPerMaterial)
//			float4 _MainColor;
//			float4 _SecondColor;
//			float _WindSpeed;
//			float _WindWavesScale;
//			float _WindForce;
//			float _Tiling;
//			float _WorldScale;
//			float _SecondColorOffset;
//			float _SecondColorFade;
//			float _IndirectLightInt;
//			float _DirectLightOffset;
//			float _DirectLightInt;
//			float _TranslucencyInt;
//			float _Smoothness;
//			float _AlphaCutoff;
//			#ifdef TESSELLATION_ON
//				float _TessPhongStrength;
//				float _TessValue;
//				float _TessMin;
//				float _TessMax;
//				float _TessEdgeLength;
//				float _TessMaxDisp;
//			#endif
//			CBUFFER_END
//			sampler2D _Albedo;
//
//
//			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
//			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
//			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
//			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
//			float snoise( float3 v )
//			{
//				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
//				float3 i = floor( v + dot( v, C.yyy ) );
//				float3 x0 = v - i + dot( i, C.xxx );
//				float3 g = step( x0.yzx, x0.xyz );
//				float3 l = 1.0 - g;
//				float3 i1 = min( g.xyz, l.zxy );
//				float3 i2 = max( g.xyz, l.zxy );
//				float3 x1 = x0 - i1 + C.xxx;
//				float3 x2 = x0 - i2 + C.yyy;
//				float3 x3 = x0 - 0.5;
//				i = mod3D289( i);
//				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
//				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
//				float4 x_ = floor( j / 7.0 );
//				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
//				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
//				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
//				float4 h = 1.0 - abs( x ) - abs( y );
//				float4 b0 = float4( x.xy, y.xy );
//				float4 b1 = float4( x.zw, y.zw );
//				float4 s0 = floor( b0 ) * 2.0 + 1.0;
//				float4 s1 = floor( b1 ) * 2.0 + 1.0;
//				float4 sh = -step( h, 0.0 );
//				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
//				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
//				float3 g0 = float3( a0.xy, h.x );
//				float3 g1 = float3( a0.zw, h.y );
//				float3 g2 = float3( a1.xy, h.z );
//				float3 g3 = float3( a1.zw, h.w );
//				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
//				g0 *= norm.x;
//				g1 *= norm.y;
//				g2 *= norm.z;
//				g3 *= norm.w;
//				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
//				m = m* m;
//				m = m* m;
//				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
//				return 42.0 * dot( m, px);
//			}
//			
//
//			VertexOutput VertexFunction( VertexInput v  )
//			{
//				VertexOutput o = (VertexOutput)0;
//				UNITY_SETUP_INSTANCE_ID(v);
//				UNITY_TRANSFER_INSTANCE_ID(v, o);
//				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
//
//				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
//				float mulTime34 = _TimeParameters.x * ( _WindSpeed * 5 );
//				float simplePerlin3D35 = snoise( ( ase_worldPos + mulTime34 )*_WindWavesScale );
//				float temp_output_231_0 = ( simplePerlin3D35 * 0.01 );
//				float2 texCoord357 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
//				#ifdef _ANCHORTHEFOLIAGEBASE_ON
//				float staticSwitch376 = ( temp_output_231_0 * pow( texCoord357.y , 2.0 ) );
//				#else
//				float staticSwitch376 = temp_output_231_0;
//				#endif
//				#ifdef _ENABLEWIND_ON
//				float staticSwitch341 = ( staticSwitch376 * ( _WindForce * 30 ) );
//				#else
//				float staticSwitch341 = 0.0;
//				#endif
//				float Wind191 = staticSwitch341;
//				float3 temp_cast_0 = (Wind191).xxx;
//				
//				o.ase_texcoord2.xy = v.ase_texcoord.xy;
//				
//				//setting value to unused interpolator channels and avoid initialization warnings
//				o.ase_texcoord2.zw = 0;
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					float3 defaultVertexValue = v.vertex.xyz;
//				#else
//					float3 defaultVertexValue = float3(0, 0, 0);
//				#endif
//				float3 vertexValue = temp_cast_0;
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					v.vertex.xyz = vertexValue;
//				#else
//					v.vertex.xyz += vertexValue;
//				#endif
//
//				v.ase_normal = v.ase_normal;
//
//				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
//
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				o.worldPos = positionWS;
//				#endif
//
//				o.clipPos = TransformWorldToHClip( positionWS );
//				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
//					vertexInput.positionWS = positionWS;
//					vertexInput.positionCS = o.clipPos;
//					o.shadowCoord = GetShadowCoord( vertexInput );
//				#endif
//				return o;
//			}
//
//			#if defined(TESSELLATION_ON)
//			struct VertexControl
//			{
//				float4 vertex : INTERNALTESSPOS;
//				float3 ase_normal : NORMAL;
//				float4 ase_texcoord : TEXCOORD0;
//
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//			};
//
//			struct TessellationFactors
//			{
//				float edge[3] : SV_TessFactor;
//				float inside : SV_InsideTessFactor;
//			};
//
//			VertexControl vert ( VertexInput v )
//			{
//				VertexControl o;
//				UNITY_SETUP_INSTANCE_ID(v);
//				UNITY_TRANSFER_INSTANCE_ID(v, o);
//				o.vertex = v.vertex;
//				o.ase_normal = v.ase_normal;
//				o.ase_texcoord = v.ase_texcoord;
//				return o;
//			}
//
//			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
//			{
//				TessellationFactors o;
//				float4 tf = 1;
//				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
//				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
//				#if defined(ASE_FIXED_TESSELLATION)
//				tf = FixedTess( tessValue );
//				#elif defined(ASE_DISTANCE_TESSELLATION)
//				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
//				#elif defined(ASE_LENGTH_TESSELLATION)
//				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
//				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
//				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
//				#endif
//				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
//				return o;
//			}
//
//			[domain("tri")]
//			[partitioning("fractional_odd")]
//			[outputtopology("triangle_cw")]
//			[patchconstantfunc("TessellationFunction")]
//			[outputcontrolpoints(3)]
//			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
//			{
//			   return patch[id];
//			}
//
//			[domain("tri")]
//			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
//			{
//				VertexInput o = (VertexInput) 0;
//				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
//				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
//				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
//				#if defined(ASE_PHONG_TESSELLATION)
//				float3 pp[3];
//				for (int i = 0; i < 3; ++i)
//					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
//				float phongStrength = _TessPhongStrength;
//				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
//				#endif
//				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
//				return VertexFunction(o);
//			}
//			#else
//			VertexOutput vert ( VertexInput v )
//			{
//				return VertexFunction( v );
//			}
//			#endif
//
//			half4 frag(VertexOutput IN  ) : SV_TARGET
//			{
//				UNITY_SETUP_INSTANCE_ID(IN);
//				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
//
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				float3 WorldPosition = IN.worldPos;
//				#endif
//				float4 ShadowCoords = float4( 0, 0, 0, 0 );
//
//				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
//						ShadowCoords = IN.shadowCoord;
//					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
//						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
//					#endif
//				#endif
//
//				float2 temp_cast_0 = (_Tiling).xx;
//				float2 texCoord747 = IN.ase_texcoord2.xy * temp_cast_0 + float2( 0,0 );
//				float2 Tiling748 = texCoord747;
//				float4 tex2DNode1 = tex2D( _Albedo, Tiling748 );
//				float OpacityMask263 = tex2DNode1.a;
//				
//				float Alpha = OpacityMask263;
//				float AlphaClipThreshold = _AlphaCutoff;
//
//				#ifdef _ALPHATEST_ON
//					clip(Alpha - AlphaClipThreshold);
//				#endif
//
//				#ifdef LOD_FADE_CROSSFADE
//					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
//				#endif
//				return 0;
//			}
//			ENDHLSL
//		}
//
//		
//        Pass
//        {
//			
//            Name "DepthNormals"
//            Tags { "LightMode"="DepthNormalsOnly" }
//
//			ZTest LEqual
//			ZWrite On
//
//        
//			HLSLPROGRAM
//			
//			#pragma multi_compile_instancing
//			#pragma multi_compile _ LOD_FADE_CROSSFADE
//			#pragma multi_compile_fog
//			#define ASE_FOG 1
//			#pragma multi_compile _ DOTS_INSTANCING_ON
//			#define _ALPHATEST_ON 1
//			#define ASE_SRP_VERSION 120101
//
//			
//			#pragma only_renderers d3d11 glcore gles gles3 
//			#pragma multi_compile_fog
//			#pragma instancing_options renderinglayer
//			#pragma vertex vert
//			#pragma fragment frag
//
//        
//			#define ATTRIBUTES_NEED_NORMAL
//			#define ATTRIBUTES_NEED_TANGENT
//			#define VARYINGS_NEED_NORMAL_WS
//
//			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
//
//			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
//			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
//        
//			#pragma shader_feature_local _ENABLEWIND_ON
//			#pragma shader_feature_local _ANCHORTHEFOLIAGEBASE_ON
//			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
//			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
//
//
//			struct VertexInput
//			{
//				float4 vertex : POSITION;
//				float3 ase_normal : NORMAL;
//				float4 ase_texcoord : TEXCOORD0;
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//			};
//
//			struct VertexOutput
//			{
//				float4 clipPos : SV_POSITION;
//				float3 normalWS : TEXCOORD0;
//				float4 ase_texcoord1 : TEXCOORD1;
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//				UNITY_VERTEX_OUTPUT_STEREO
//			};
//        
//			CBUFFER_START(UnityPerMaterial)
//			float4 _MainColor;
//			float4 _SecondColor;
//			float _WindSpeed;
//			float _WindWavesScale;
//			float _WindForce;
//			float _Tiling;
//			float _WorldScale;
//			float _SecondColorOffset;
//			float _SecondColorFade;
//			float _IndirectLightInt;
//			float _DirectLightOffset;
//			float _DirectLightInt;
//			float _TranslucencyInt;
//			float _Smoothness;
//			float _AlphaCutoff;
//			#ifdef TESSELLATION_ON
//				float _TessPhongStrength;
//				float _TessValue;
//				float _TessMin;
//				float _TessMax;
//				float _TessEdgeLength;
//				float _TessMaxDisp;
//			#endif
//			CBUFFER_END
//			sampler2D _Albedo;
//
//
//			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
//			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
//			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
//			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
//			float snoise( float3 v )
//			{
//				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
//				float3 i = floor( v + dot( v, C.yyy ) );
//				float3 x0 = v - i + dot( i, C.xxx );
//				float3 g = step( x0.yzx, x0.xyz );
//				float3 l = 1.0 - g;
//				float3 i1 = min( g.xyz, l.zxy );
//				float3 i2 = max( g.xyz, l.zxy );
//				float3 x1 = x0 - i1 + C.xxx;
//				float3 x2 = x0 - i2 + C.yyy;
//				float3 x3 = x0 - 0.5;
//				i = mod3D289( i);
//				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
//				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
//				float4 x_ = floor( j / 7.0 );
//				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
//				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
//				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
//				float4 h = 1.0 - abs( x ) - abs( y );
//				float4 b0 = float4( x.xy, y.xy );
//				float4 b1 = float4( x.zw, y.zw );
//				float4 s0 = floor( b0 ) * 2.0 + 1.0;
//				float4 s1 = floor( b1 ) * 2.0 + 1.0;
//				float4 sh = -step( h, 0.0 );
//				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
//				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
//				float3 g0 = float3( a0.xy, h.x );
//				float3 g1 = float3( a0.zw, h.y );
//				float3 g2 = float3( a1.xy, h.z );
//				float3 g3 = float3( a1.zw, h.w );
//				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
//				g0 *= norm.x;
//				g1 *= norm.y;
//				g2 *= norm.z;
//				g3 *= norm.w;
//				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
//				m = m* m;
//				m = m* m;
//				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
//				return 42.0 * dot( m, px);
//			}
//			
//      
//			struct SurfaceDescription
//			{
//				float Alpha;
//				float AlphaClipThreshold;
//			};
//        
//			VertexOutput VertexFunction(VertexInput v  )
//			{
//				VertexOutput o;
//				ZERO_INITIALIZE(VertexOutput, o);
//
//				UNITY_SETUP_INSTANCE_ID(v);
//				UNITY_TRANSFER_INSTANCE_ID(v, o);
//				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
//
//				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
//				float mulTime34 = _TimeParameters.x * ( _WindSpeed * 5 );
//				float simplePerlin3D35 = snoise( ( ase_worldPos + mulTime34 )*_WindWavesScale );
//				float temp_output_231_0 = ( simplePerlin3D35 * 0.01 );
//				float2 texCoord357 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
//				#ifdef _ANCHORTHEFOLIAGEBASE_ON
//				float staticSwitch376 = ( temp_output_231_0 * pow( texCoord357.y , 2.0 ) );
//				#else
//				float staticSwitch376 = temp_output_231_0;
//				#endif
//				#ifdef _ENABLEWIND_ON
//				float staticSwitch341 = ( staticSwitch376 * ( _WindForce * 30 ) );
//				#else
//				float staticSwitch341 = 0.0;
//				#endif
//				float Wind191 = staticSwitch341;
//				float3 temp_cast_0 = (Wind191).xxx;
//				
//				o.ase_texcoord1.xy = v.ase_texcoord.xy;
//				
//				//setting value to unused interpolator channels and avoid initialization warnings
//				o.ase_texcoord1.zw = 0;
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					float3 defaultVertexValue = v.vertex.xyz;
//				#else
//					float3 defaultVertexValue = float3(0, 0, 0);
//				#endif
//				float3 vertexValue = temp_cast_0;
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					v.vertex.xyz = vertexValue;
//				#else
//					v.vertex.xyz += vertexValue;
//				#endif
//				v.ase_normal = v.ase_normal;
//
//				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
//				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);
//
//				o.clipPos = TransformWorldToHClip(positionWS);
//				o.normalWS.xyz =  normalWS;
//
//				return o;
//			}
//
//			#if defined(TESSELLATION_ON)
//			struct VertexControl
//			{
//				float4 vertex : INTERNALTESSPOS;
//				float3 ase_normal : NORMAL;
//				float4 ase_texcoord : TEXCOORD0;
//
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//			};
//
//			struct TessellationFactors
//			{
//				float edge[3] : SV_TessFactor;
//				float inside : SV_InsideTessFactor;
//			};
//
//			VertexControl vert ( VertexInput v )
//			{
//				VertexControl o;
//				UNITY_SETUP_INSTANCE_ID(v);
//				UNITY_TRANSFER_INSTANCE_ID(v, o);
//				o.vertex = v.vertex;
//				o.ase_normal = v.ase_normal;
//				o.ase_texcoord = v.ase_texcoord;
//				return o;
//			}
//
//			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
//			{
//				TessellationFactors o;
//				float4 tf = 1;
//				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
//				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
//				#if defined(ASE_FIXED_TESSELLATION)
//				tf = FixedTess( tessValue );
//				#elif defined(ASE_DISTANCE_TESSELLATION)
//				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
//				#elif defined(ASE_LENGTH_TESSELLATION)
//				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
//				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
//				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
//				#endif
//				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
//				return o;
//			}
//
//			[domain("tri")]
//			[partitioning("fractional_odd")]
//			[outputtopology("triangle_cw")]
//			[patchconstantfunc("TessellationFunction")]
//			[outputcontrolpoints(3)]
//			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
//			{
//			   return patch[id];
//			}
//
//			[domain("tri")]
//			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
//			{
//				VertexInput o = (VertexInput) 0;
//				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
//				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
//				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
//				#if defined(ASE_PHONG_TESSELLATION)
//				float3 pp[3];
//				for (int i = 0; i < 3; ++i)
//					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
//				float phongStrength = _TessPhongStrength;
//				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
//				#endif
//				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
//				return VertexFunction(o);
//			}
//			#else
//			VertexOutput vert ( VertexInput v )
//			{
//				return VertexFunction( v );
//			}
//			#endif
//
//			half4 frag(VertexOutput IN ) : SV_TARGET
//			{
//				SurfaceDescription surfaceDescription = (SurfaceDescription)0;
//				float2 temp_cast_0 = (_Tiling).xx;
//				float2 texCoord747 = IN.ase_texcoord1.xy * temp_cast_0 + float2( 0,0 );
//				float2 Tiling748 = texCoord747;
//				float4 tex2DNode1 = tex2D( _Albedo, Tiling748 );
//				float OpacityMask263 = tex2DNode1.a;
//				
//				surfaceDescription.Alpha = OpacityMask263;
//				surfaceDescription.AlphaClipThreshold = _AlphaCutoff;
//
//				#if _ALPHATEST_ON
//					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
//				#endif
//
//				#ifdef LOD_FADE_CROSSFADE
//					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
//				#endif
//
//				float3 normalWS = IN.normalWS;
//				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
//
//			}
//        
//			ENDHLSL
//        }

	
	}
	
	//CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
