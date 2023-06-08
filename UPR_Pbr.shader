Shader "URP/URP_Pbr"
{
    Properties
    {
        [Header(Base Color)]
        [HDR]_BaseColor ("BaseColor", Color) = (1,1,1,1) //颜色 
        [NoScaleOffset]_MainTex ("Albedo", 2D) = "white" {} //基础颜色(反照率)
        [NoScaleOffset]_RampTex ("RampTex", 2D) = "white" {}
        //金属图,r通道存储金属度,g通道环境光遮蔽贴图,b存URP_Pbr遮罩，a通道存储光粗糙度
        //g通道目前用a替代
        [Header(Metallic)]
        [NoScaleOffset]_MetallicMap("MetallicMap", 2D) = "white" {} 
        _MetallicStrength ("MetallicStrength", Range(0,2)) = 1 //金属强度Metallic strength
        _Smoothness("Smoothness",Range(-0.5,0.5)) = 0 //光滑度
        [Header(Normal)]
        [NoScaleOffset]_NormalMap("NormalMap", 2D) = "white"{} //法线贴图
        _NormalIntesity("_NormalIntesity",Range(0,3)) = 1
        //_metallicGloss.gMap("metallicGloss.gMap",2D) = "white"{} //环境光遮蔽贴图, g通道
        [Header(OutLine)]
        _OutlineCol("OutlineCol", Color) = (1,1,1,1)  
        _OutlineFactor("OutlineFactor", Range(0,2)) = 1
        [Header(Fresnel)]
        [HDR]_FresnlColor("FresnlColor", Color) = (1,1,1,1) 
        _Fresnl("Fresnl", Range(0,10)) = 6
        [Toggle(_IsClip)]_IsClip("开启透贴", int) = 0
        [Toggle(_IsPbr)]_IsPbr("开启PBR材质", int) = 0
        [Toggle(_IsSkin)]_IsSkin("开启皮肤3S", int) = 0
        [NoScaleOffset]_Skin3STEX ("Skin3STEX", 2D) = "white" {}
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
        #include"Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #pragma shader_feature_local _ _IsClip 
        #pragma shader_feature_local _ _IsPbr 
        #pragma shader_feature_local _ _IsSkin 
        sampler2D _MainTex, _MetallicMap, _NormalMap,_Skin3STEX,_RampTex;
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseColor,_FresnlColor;
        //float4 _MainTex_ST, _MetallicMap_ST, _NormalMap_ST;
        float _Smoothness, _MetallicStrength;
        float _Clip;
        float4 _OutlineCol;  
        float _OutlineFactor,_Fresnl,_NormalIntesity; 
        CBUFFER_END
        
        struct Attributes
        {
            float3 positionOS: POSITION;
            half3 normalOS: NORMAL;
            half4 tangentOS: TANGENT;
            float2 uv: TEXCOORD0;
            float4 color :COLOR;
        };
        
        struct Varyings
        {
            float2 uv: TEXCOORD0;
            float3 positionWS: TEXCOORD1;
            half3 normalWS: TEXCOORD2;
            half3 tangentWS: TEXCOORD3;
            half3 bitangentWS: TEXCOORD4;
            float4 positionCS: SV_POSITION;
            float4 color   :TEXCOORD5;
        };    
        ENDHLSL

        pass {
            Tags{"LightMode" = "OutLine"  }
            Cull Front
            Name "Outline"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            Varyings vert (Attributes v)
            {
                Varyings o;
                o.color = v.color;
                float3 positionWS =TransformObjectToWorld(v.positionOS.xyz); 
                float3 pos_world = v.positionOS.xyz;
                //float3 viewPos =UnityObjectToViewPos(v.positionOS.xyz);
                float camDist = distance(_WorldSpaceCameraPos,positionWS.xyz);
                camDist = lerp(1,camDist,0.9);
                pos_world = pos_world + normalize(v.normalOS)* _OutlineFactor*v.color.a* 0.0007*camDist;
                o.positionCS = TransformObjectToHClip(pos_world);
                o.uv = v.uv;
                //o.color = pow(v.color,2.2);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 color = i.color;
                return half4(color.rgb*_OutlineCol,1);
            }
            ENDHLSL
        }

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
                output.uv = input.uv;
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = vertexNormalInputs.normalWS;
                output.tangentWS = vertexNormalInputs.tangentWS;
                output.bitangentWS = vertexNormalInputs.bitangentWS;
                //output.color =input.color;
                output.color = pow(input.color,2.2);//Gamma矫正
                //output.color.w = input.color.w;
                return output;
            }
            
            half4 frag(Varyings input): SV_TARGET
            {
                //half4 output = (1,1,1,1);
                half4 color = input.color;
                //properties
                half4 albedo = tex2D(_MainTex,input.uv);
            //light 
                Light mainLight = GetMainLight();
            //get normal map in WS
                float4 normalTex = tex2D(_NormalMap, input.uv);
                float3 normalTS =  UnpackNormalScale(normalTex,1); //tangent space normal
                //normalTS.z = sqrt(1-dot(normalTS.xy, normalTS.xy));//叉乘计算副切线
                float3x3 T2W = {input.tangentWS, input.bitangentWS, normalize(input.normalWS)};
                T2W = transpose(T2W);
                float3 normalWS = NormalizeNormalPerPixel(mul(T2W, normalTS));
                normalWS*=_NormalIntesity;
            //View
                float3 positionWS = input.positionWS;
                float3 viewDirWS = SafeNormalize(GetCameraPositionWS()-positionWS);
            #ifdef _IsClip
                clip(albedo.a - _Clip);
            #endif

            float3 Pbr_albedo=0;
            #ifdef _IsPbr
                half4 metallicGloss = tex2D(_MetallicMap,input.uv);
                half metallic = metallicGloss.x * _MetallicStrength;
                //half roughness = 1 - metallicGloss.y * _Smoothness;
                _Smoothness = 1-_Smoothness;
                half smoothness = 1 -metallicGloss.a;
                half roughness = metallicGloss.a*_Smoothness;
                roughness = roughness*roughness;
                
                //half metallicGloss.g = tex2D(_metallicGloss.gMap, input.uv).g;
                

 
                //get input
                //float3 normalWS = normalize(input.normalWS);

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
                float3 SHcolor = SH_IndirectionDiff(normalWS)*metallicGloss.a;               
                float3 IndirKS=IndirF_Function(NdotV,F0,roughness);
                float3 IndirKD = (1-IndirKS)*(1-metallic);
                float3 IndirDiffColor=SHcolor*IndirKD*albedo.xyz;
                //return float4(IndirDiffColor,1);

                //indirect specular 
                float3 IndirSpeCubeColor = IndirSpeCube(normalWS,viewDirWS,roughness,metallicGloss.a);
                //return float4(IndirSpeCubeColor,1);
                float3 IndirSpeCubeFactor = IndirSpeFactor(roughness,smoothness,BRDFSpeSection,F0,NdotV); 
                float3 IndirSpeColor = IndirSpeCubeColor*IndirSpeCubeFactor;
                //return float4(IndirSpeColor,1);
                float3 IndirColor = IndirSpeColor+IndirDiffColor;
                //return float4(IndirColor,1);
                Pbr_albedo = IndirColor+directColor;
                //return float4(input.color.aaa,1);
                return float4(Pbr_albedo, 1);
            #endif
            // #ifdef _IsSkin
            //     //light 
            //     Light mainLight = GetMainLight();
            //     float deltaWorldNormal = length(fwidth(input.normalWS));
            //     float deltaWorldPos = length(fwidth(input.positionWS));
            //     half3 worldViewDir = normalize (_WorldSpaceCameraPos-input.positionWS);
            //     float curvature = (deltaWorldNormal / deltaWorldPos);
            //     float NdotL = dot(input.normalWS, mainLight.direction)*0.5+0.5;
            //     float toon = lerp(0.2,1,NdotL);
            //     float NdotV = dot(input.normalWS,worldViewDir);
            //     half4 Skin3STEX = tex2D(_Skin3STEX,float2(NdotL,0.95));
            //     float fresnel = ( pow (1.0 - NdotV, 5.0))*_BaseColor;
            //     //return half4(curvature,curvature,curvature,1)
            //     //return (fresnel+albedo)*toon; 
            // #endif
                half3 N = normalize(input.normalWS);
                half3 L = normalize(mainLight.direction);
                //使用模型法线计算光照，用贴图法线计算漫反射
                half lamb01 = dot(normalWS,L)*0.5+0.5;
                half lamb02 = dot(N,L);//这里没有用半lambert，为了配合边缘光
                //光照颜色
                half4 Ramp = tex2D(_RampTex, float2(lamb02,0.5));
                //return float4(input.color.aaa,1);
                half lamb03 = step(0.4,lamb02);
                //漫反射颜色
                half4 colorL = lerp(albedo*0.5,albedo,lamb01);
                //直接光漫反射
                half4 finalColor = colorL*Ramp;
                //边缘光
                half NdotView =dot(N,viewDirWS);
                half4 fresCol = pow(1-NdotView,_Fresnl)*_FresnlColor*lamb03;
                //fresCol = step(0.2,fresCol)*_FresnlColor*lamb03;
                //return lamb02;
                return finalColor*_BaseColor+fresCol;
                //return lerp(albedo,Pbr_albedo,_MetallicMap.b); 
            }
            
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}