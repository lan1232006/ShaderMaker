Shader "URP/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("_BaseColor", Color)=(1,1,1,1)
        _OutlineCol("OutlineCol", Color) = (0,0,0,1)  
        _OutlineFactor("OutlineFactor", Range(0,2)) = 1
    }
    SubShader
    {

        Tags{ "RenderPipline"="UniversalRenderPipline"
                "RenderType"="Opaque" 
            }
            HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #pragma multi_compile_fwdbase
            //CBUFFER内存储除纹理外的小数据有助于性能优化

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            float4 _OutlineCol;  
            float _OutlineFactor; 
            CBUFFER_END
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 color :COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float4 color   :TEXCOORD2;
            };
            ENDHLSL

            pass {
                    // Stencil
                    //     {
                    //         Ref 1 
                    //         Comp NotEqual
                    //     }
                    Tags{"LightMode" = "OutLine"  }//当需要执额外pass时 需要用SRPDefaultUnlit标注  区别于内置管线调整pass上下顺序
                                                   //同样 这个也可以在rendered feature里配置
                                                   //这里"OutLine"就设置在所有不透明物体渲染之后渲染
                    Cull Front
                    //ZWrite off
                    Name "Outline"

                    HLSLPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag
                    v2f vert (appdata v)
                    {
                        v2f o;
                        //v.vertex.xyz *= _OutlineFactor;
                        o.color = v.color;
                        float3 pos_world = v.vertex.xyz;
                        v.color.w-=0.2;
                        pos_world = pos_world + normalize(v.normalOS)* _OutlineFactor*v.color.a* 0.01;
                        o.vertex = TransformObjectToHClip(pos_world);
                        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                        return o;
                    }

                    half4 frag (v2f i) : SV_Target
                    {
                        half4 color = i.color;
                        half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv)*_BaseColor;
                        //return half4(color.rgb,1);
                        return half4(0.8*color.rgb*_OutlineCol,1);
                    }
                    ENDHLSL
                }
 
            pass {
                    // Stencil
                    //     {
                    //         Ref 1 
                    //         Comp Always
                    //         Pass Replace
                    //     }
                    Tags{"LightMode" = "UniversalForward"}
                    //ZWrite[_ZWrite]
                    Cull Back
                    HLSLPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag
                    v2f vert (appdata v)
                    {
                        v2f o;
                        o.vertex = TransformObjectToHClip(v.vertex.xyz);
                        o.normalWS =TransformObjectToWorld(v.normalOS);
                        //o.normal =TransformObjectToWorld(v.normal); 
                        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                        o.color = v.color;
                        return o;
                    }

                    real4 frag (v2f i) : SV_Target
                    {
                        Light light = GetMainLight();
                        real3 N = normalize(i.normalWS);
                        real3 L =  normalize(light.direction);
                        real lamb = dot(N,L);
                        real4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv)*_BaseColor;
                        real toon = step(0.5,lamb);
                        return real4(i.color.aaa,1);
                        return 0.5;
                        return col;
                        return lamb*col*toon;
                    }
                    ENDHLSL
                }
          
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
