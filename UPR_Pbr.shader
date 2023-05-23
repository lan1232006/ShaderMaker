Shader "URP/URP_Pbr"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1,1,1,1) //颜色 
        _BaseMap ("Albedo", 2D) = "white" {} //基础颜色(反照率)
        _MetallicMap("MetallicMap", 2D) = "white" {} //金属图,r通道存储金属度,a通道存储光粗糙度
        _MetallicStrength ("MetallicStrength", Range(0,1)) = 1 //金属强度Metallic strength
        _Smoothness("Smoothness",Range(-0.5,0.5)) = 0 //光滑度
        _NormalMap("NormalMap", 2D) = "white"{} //法线贴图
        _OcclusionMap("OcclusionMap",2D) = "white"{} //环境光遮蔽贴图, g通道
        _Clip("Clip", Range(0,1))=0
       //_normalIntensity("NormalIntensity",Range(1,3))=1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        //Cull Off
        HLSLINCLUDE
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        
        sampler2D _BaseMap, _MetallicMap, _NormalMap, _OcclusionMap;
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseColor;
        float4 _BaseMap_ST, _MetallicMap_ST, _NormalMap_ST, _OcclusionMap_ST;
        float _Smoothness, _MetallicStrength;
        float _Clip;
        CBUFFER_END
        
        struct Attributes
        {
            float3 positionOS: POSITION;
            half3 normalOS: NORMAL;
            half4 tangentOS: TANGENT;
            float2 texcoord: TEXCOORD0;
        };
        
        struct Varyings
        {
            float2 uv: TEXCOORD0;
            float3 positionWS: TEXCOORD1;
            half3 normalWS: TEXCOORD2;
            half3 tangentWS: TEXCOORD3;
            half3 bitangentWS: TEXCOORD4;
            float4 positionCS: SV_POSITION;
        };    
        ENDHLSL
        
        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            HLSLPROGRAM
            #include "MyURPFunction.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);  
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = vertexNormalInputs.normalWS;
                output.tangentWS = vertexNormalInputs.tangentWS;
                output.bitangentWS = vertexNormalInputs.bitangentWS;
                return output;
            }
            
            half4 frag(Varyings input): SV_TARGET
            {
                half4 output = (1,1,1,1);
                
                //properties
                half4 albedo = tex2D(_BaseMap,input.uv) * _BaseColor;
                half2 metallicGloss = tex2D(_MetallicMap,input.uv).ra;
                half metallic = metallicGloss.x * _MetallicStrength;
                //half roughness = 1 - metallicGloss.y * _Smoothness;
                _Smoothness = 1-_Smoothness;
                half smoothness = 1 -metallicGloss.y;
                half roughness = metallicGloss.y*_Smoothness;
                roughness = roughness*roughness;
                
                half occlusion = tex2D(_OcclusionMap, input.uv).g;
                
                //get normal map in WS
                float4 normalTex = tex2D(_NormalMap, input.uv);
                float3 normalTS =  UnpackNormalScale(normalTex,1); //tangent space normal
                //normalTS.z = sqrt(1-dot(normalTS.xy, normalTS.xy));//叉乘计算副切线
                float3x3 T2W = {input.tangentWS, input.bitangentWS, normalize(input.normalWS)};
                T2W = transpose(T2W);
                float3 normalWS = NormalizeNormalPerPixel(mul(T2W, normalTS));

                //light 
                Light mainLight = GetMainLight();
                
                //get input
                //float3 normalWS = normalize(input.normalWS);
                float3 positionWS = input.positionWS;
                float3 viewDirWS = SafeNormalize(GetCameraPositionWS()-positionWS);
                float3 halfDir = normalize(viewDirWS+mainLight.direction);
                float NdotH = max(saturate(dot(normalWS, halfDir)),0.000001);
                float NdotL = max(saturate(dot(normalWS, mainLight.direction)),0.000001);
                float NdotV = max(saturate(dot(normalWS, viewDirWS)),0.000001);
                float HdotL = max(saturate(dot(halfDir, mainLight.direction)),0.000001);
                float3 F0 = lerp(0.04, albedo.xyz, metallic);
                
                ///////////////////////////
                //    direct light       //
                //////////////////////////
                //specular section
                float D = D_Function(NdotH, roughness);
                //return D;
                float G = G_Function(NdotL, NdotV, roughness);
                //return G;
                float3 F = F_Function(HdotL, F0);
                //return float4(F,1);
                
                float3 BRDFSpeSection = (D*G*F)/(4*NdotL*NdotV);
                float3 DirectSpeColor = BRDFSpeSection*mainLight.color*NdotL*PI;
                //return float4(DirectSpeColor, 1);
                
                //diffuse section
                float3 KS = F;
                float3 KD = (1-KS)*(1-metallic);
                float3 directDiffColor = KD*albedo.xyz*mainLight.color*NdotL;
                float3 directColor = DirectSpeColor+directDiffColor;
                                
                ///////////////////////////
                //    indirect light       //
                //////////////////////////

                //indirect diffuse 
                float3 SHcolor = SH_IndirectionDiff(normalWS)*occlusion;               
                float3 IndirKS=IndirF_Function(NdotV,F0,roughness);
                float3 IndirKD = (1-IndirKS)*(1-metallic);
                float3 IndirDiffColor=SHcolor*IndirKD*albedo.xyz;
                //return float4(IndirDiffColor,1);

                //indirect specular 
                float3 IndirSpeCubeColor = IndirSpeCube(normalWS,viewDirWS,roughness,occlusion);
                //return float4(IndirSpeCubeColor,1);
                float3 IndirSpeCubeFactor = IndirSpeFactor(roughness,smoothness,BRDFSpeSection,F0,NdotV); 
                float3 IndirSpeColor = IndirSpeCubeColor*IndirSpeCubeFactor;
                //return float4(IndirSpeColor,1);
                float3 IndirColor = IndirSpeColor+IndirDiffColor;
                //return float4(IndirColor,1);
                float3 color = IndirColor+directColor;
                clip(albedo.a - _Clip);
                return float4(color, 1);
            }
            
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}