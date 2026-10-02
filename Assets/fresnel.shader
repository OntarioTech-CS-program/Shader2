Shader "reflection"
{
    Properties
    {
        _BaseMap   ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        // Q1: What properties control the appearance and strength
        // of the environment reflection?

        _EnvCube      ("Reflection Cubemap", Cube) = "" {}
        _EnvIntensity ("Reflection Intensity", Range(0,2)) = 1.0
        _EnvBlend     ("Reflection Blend (0=Base,1=Env)", Range(0,1)) = 1.0
        _FresnelPow   ("Fresnel Power", Range(0.1, 8)) = 5.0
        _FresnelBoost ("Fresnel Boost", Range(0, 2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 200

        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv0        : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;

                // Q2: Why must this shader pass both the position and
                // normal in world space to the fragment shader?

                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            // Q3: Why does the environment use TEXTURECUBE instead
            // of TEXTURE2D?

            TEXTURECUBE(_EnvCube);
            SAMPLER(sampler_EnvCube);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float  _EnvIntensity;
                float  _EnvBlend;
                float  _FresnelPow;
                float  _FresnelBoost;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                // Q4: What coordinate-space transformations are being
                // performed on the position and normal?

                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 nrmWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionWS  = posWS;
                OUT.normalWS    = nrmWS;
                OUT.positionHCS = TransformWorldToHClip(posWS);
                OUT.uv          = TRANSFORM_TEX(IN.uv0, _BaseMap);

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // Q5: How are _BaseMap and _BaseColor used together
                // to determine the object's base color?

                half3 baseCol =
                    SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb
                    * _BaseColor.rgb;

                // Q6: What does GetWorldSpaceViewDir() calculate,
                // and why is IN.positionWS required?

                float3 V =
                    SafeNormalize(GetWorldSpaceViewDir(IN.positionWS));

                float3 N =
                    SafeNormalize(IN.normalWS);

                // Q7: What does reflect() calculate?
                // Why is -V used instead of V?

                float3 R = reflect(-V, N);

                // Q8: Why is R used to sample the cubemap rather
                // than the object's UV coordinates?

                half3 envCol =
                    SAMPLE_TEXTURECUBE(_EnvCube, sampler_EnvCube, R).rgb
                    * _EnvIntensity;

                // Q9: What happens to ndotv as the viewing direction
                // becomes increasingly parallel to the surface?

                float ndotv = saturate(dot(N, V));

                // Q10: How do _FresnelPow and _FresnelBoost affect
                // the appearance of the reflection?

                float fresnel =
                    pow(1.0 - ndotv, _FresnelPow)
                    * _FresnelBoost;

                envCol *= (1.0 + fresnel);

                // Q11: Predict the output when _EnvBlend is 0, 0.5,
                // and 1. What role does lerp() perform?

                half3 finalCol =
                    lerp(baseCol, envCol, _EnvBlend);

                return half4(finalCol, 1.0);
            }

            ENDHLSL
        }
    }

    FallBack Off
}