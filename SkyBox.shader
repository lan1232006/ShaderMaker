Shader "URP/SamplerCubeMap"
{
    Properties
    {
        _MainTex ("Texture", Cube) = "white" {}
        [hdr]_Tint("Tint",Color) = (1,1,1,1)
        [NoScaleOffset]_NormalMap("NormalMap", 2D) = "white"{} 
        _AOMap("AO Map",2D) = "white"{}
		_AOAdjust("AO Adjust",Range(0,1)) = 1
        _RoughnessMap("RoughnessMap", 2D) = "white"{} 
        _RoughnessBrightness("Roughness Brightness",Float) = 1
        _RoughnessIntensity("RoughnessIntensity",Range(0,5))=0.5
        _SpecIntensity("SpecIntensity",Range(0.1,1))=1
        [hdr]_SpecTint("SpecTint",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque" } 

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST,_Tint,_SpecTint;
        float4 _MainTex_HDR;
        real4 _BaseColor;
        float _NormalScale,_Smoothness,_RoughnessIntensity;
        float4 _MainTex_ST;
        float _AOAdjust,_RoughnessBrightness,_SpecIntensity;
        CBUFFER_END

        TEXTURECUBE(_MainTex);    
        SAMPLER(sampler_MainTex);
        sampler2D _NormalMap,_RoughnessMap;
        sampler2D _AOMap;

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            half4 tangentOS     : TANGENT;
            half3 normalOS      : NORMAL;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;

            float4 vertex    : SV_POSITION;
            float3 worldPos  :TEXCOORD1;
            float3 tangent_world    :TEXCOORD2;
            float3 bitnormal_world  :TEXCOORD3;
            float3 normal_world    :TEXCOORD4;
        };
        ENDHLSL

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


			inline float3 ACES_Tonemapping(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				float3 encode_color = saturate((x*(a*x + b)) / (x*(c*x + d) + e));
				return encode_color;
			};

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.normal_world = TransformObjectToWorldNormal(v.normalOS,true);
                o.tangent_world= TransformObjectToWorldNormal(v.tangentOS,true);
                o.bitnormal_world = normalize(cross(o.normal_world,o.tangent_world));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();
                float4 normalTex = tex2D(_NormalMap, i.uv);
                float4 rongnessTex = tex2D(_RoughnessMap, i.uv);
                float3 normalTS =  UnpackNormalScale(normalTex,1);
                float3x3 T2W = {normalize(i.tangent_world), normalize(i.bitnormal_world), normalize(i.normal_world)};
                //T2W = transpose(T2W);
                float3 normalWS = normalize(mul(T2W, normalTS));

				half ao = tex2D(_AOMap, i.uv).r;
				ao = lerp(1.0,ao, _AOAdjust);

                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 reflect_Dir = reflect(-view_dir,normalWS);
                
                _RoughnessIntensity*=(6*rongnessTex);
                _RoughnessIntensity*=_RoughnessBrightness;
                _RoughnessIntensity = clamp(0,5,_RoughnessIntensity);

                half4 col = SAMPLE_TEXTURECUBE_LOD(_MainTex, sampler_MainTex, reflect_Dir,_RoughnessIntensity);
                half3 env_color = DecodeHDREnvironment(col, _MainTex_HDR)*_Tint*ao;//确保在移动端能拿到HDR信息

                half NdotL = dot(normalize(mainLight.direction),normalize(i.normal_world));
                half halfLamb = NdotL*0.5+0.5;
                //间接光镜面反射+直接光漫反射
                env_color = lerp(env_color*0.3,env_color*1.2,halfLamb);

                //直接光镜面反射
                real3 H =normalize(normalize(mainLight.direction)+ view_dir);
                half NdotH =saturate( pow(dot(normalWS,H),_SpecIntensity*500)*ao*NdotL);
                half3 specCol = NdotH*_SpecTint;
                //间接光漫反射


                env_color+=specCol;
                env_color = ACES_Tonemapping(env_color);

                //return NdotH;
                return half4(env_color,1);
            }
            ENDHLSL
        }
    }
}
