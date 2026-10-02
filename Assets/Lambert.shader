Shader "Custom/Lambert"
{

    Properties

    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

    }

 

    SubShader

    {

        Tags

        {

            "RenderType"="Opaque"

            "Queue"="Geometry"

            "RenderPipeline"="UniversalRenderPipeline"

        }

 

        Pass

        {

            Name "UniversalForward"

            Tags { "LightMode"="UniversalForward" }

 

            HLSLPROGRAM

            #pragma vertex vert

            #pragma fragment frag

 

            // Q1: What is the purpose of the #pragma vertex vert directive?

            // Q2: Which included URP library provides lighting-related functions such as GetMainLight()?

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

 

            struct Attributes

            {

                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS   : NORMAL;

            };

 

            // Q3: Why must positionHCS use the SV_POSITION semantic?

            struct Varyings

            {

                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;

            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // Q4: Why is _Color placed inside UnityPerMaterial?

            CBUFFER_START(UnityPerMaterial)
                
                float4 _Color;

            CBUFFER_END

 

            Varyings vert (Attributes IN)

            {

                Varyings OUT;
                
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                return OUT;

            }

 

            half4 frag (Varyings IN) : SV_Target

            {
                
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
                half3 finalColor = texColor.rgb * _Color.rgb;
                float3 N = SafeNormalize(IN.normalWS);
                
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                float NdotL = saturate(dot(N, lightDir));

                return half4(finalColor * NdotL, 1.0);

            }

 

            ENDHLSL

        }

    }

 

    FallBack Off

}