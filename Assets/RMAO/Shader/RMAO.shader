Shader "Hidden/RMAO"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		//Ambient Occlusion ( 0 )
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragAO
			#define UNITY_GBUFFER_INCLUDED
			#include "UnityCG.cginc"
			#include "UnityGBuffer.cginc"

			//Input data
				#pragma multi_compile _BOUNCE_True _BOUNCE_False
				#if _BOUNCE_True
					sampler2D _screenColor;
				#endif
				sampler2D _MainTex;
				uniform half4 _MainTex_TexelSize;
				sampler2D_float _CameraDepthTexture;
				sampler2D _CameraGBufferTexture2;
				sampler2D _Noise;
				half _scale, _attenuation, _power;
			
			struct appdata	
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
			};

			struct v2f	
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)	
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 fragAO (v2f i) : SV_Target
			{

				float2 uv = i.uv;

				
				// Sample a view-space normal vector on the g-buffer.
				float3 norm_o = tex2D(_CameraGBufferTexture2, i.uv).xyz;
				norm_o = mul((float3x3)unity_WorldToCamera, norm_o * 2 - 1);

				// Sample a linear depth on the depth buffer.
				float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				depth_o = LinearEyeDepth(depth_o);

				//Noise texture
				float4 noise = tex2D(_Noise, uv * (_ScreenParams.xy / 8));
				noise.xy = noise.xy * 2 - 1;
				noise.w /= depth_o;

				// Reconstruct the view-space position.
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
				float3 pos_o = float3((i.uv * 2 - 1 - p13_31) / p11_22, 1) * depth_o + norm_o * 0.005 * (1 + depth_o);
							
				//Calculate SSAO
				float4 occ = 0;

				const float4 rndLength[4] ={
					0,		 1,		 0,			0.06,
					0.81,	-0.33,	 0.47,		0.12,
					-0.81,	-0.33,	 0.47,		0.25,
					0.0,	-0.33,	-0.94,		0.5,
				};

				//////
				//00//
				//////
					//Random vector and ray length
					float4 delta = rndLength[0];
					delta.xy = reflect(delta.xy, noise.xy);

					float2 uv_s = uv + normalize(delta.xy + norm_o.xy) * delta.w * noise.w;

					float3 v_s2 = float3((uv_s * 2 - 1 - p13_31) / p11_22, 1) * LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv_s)) - pos_o;

					float a1 = max(dot(v_s2, norm_o) - 0.002 * depth_o, 0.0);
					float a2 = dot(v_s2, v_s2) + 0.0001;
					float d1 = 1 - smoothstep(0, 1, length(v_s2));

					occ += a1 / a2 * d1;

				//////
				//01//
				//////
					//Random vector and ray length
					delta = rndLength[1];
					delta.xy = reflect(delta.xy, noise.xy);

					uv_s = uv + normalize(delta.xy + norm_o.xy) * delta.w  * noise.w;

					v_s2 = float3((uv_s * 2 - 1 - p13_31) / p11_22, 1) * LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv_s)) - pos_o;

					a1 = max(dot(v_s2, norm_o) - 0.002 * depth_o, 0.0);
					a2 = dot(v_s2, v_s2) + 0.0001;
					d1 = 1 - smoothstep(0, 1, length(v_s2));

					occ += a1 / a2 * d1;

				//////
				//02//
				//////
					//Random vector and ray length
					delta = rndLength[2];
					delta.xy = reflect(delta.xy, noise.xy);

					uv_s = uv + normalize(delta.xy + norm_o.xy) * delta.w  * noise.w;

					v_s2 = float3((uv_s * 2 - 1 - p13_31) / p11_22, 1) * LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv_s)) - pos_o;

					a1 = max(dot(v_s2, norm_o) - 0.002 * depth_o, 0.0);
					a2 = dot(v_s2, v_s2) + 0.0001;
					d1 = 1 - smoothstep(0, 1, length(v_s2));

					occ += a1 / a2 * d1;

				//////
				//03//
				//////
					//Random vector and ray length
					delta = rndLength[3];
					delta.xy = reflect(delta.xy, noise.xy);

					uv_s = uv + normalize(delta.xy + norm_o.xy) * delta.w * noise.w;

					v_s2 = float3((uv_s * 2 - 1 - p13_31) / p11_22, 1) * LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv_s)) - pos_o;

					a1 = max(dot(v_s2, norm_o) - 0.002 * depth_o, 0.0);
					a2 = dot(v_s2, v_s2) + 0.0001;
					d1 = 1 - smoothstep(0, 1, length(v_s2));

					occ += a1 / a2 * d1;

				occ /= 4;

				occ = max(0, 1 - occ);

				return occ;
			}

			ENDCG
		}

		//Blur ( 1 )
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragBlur
			#define UNITY_GBUFFER_INCLUDED
			#include "UnityCG.cginc"
			#include "UnityGBuffer.cginc"

			//Input data
				sampler2D_float _CameraDepthTexture;
				sampler2D _CameraGBufferTexture2;
				sampler2D _MainTex;
				uniform half4 _MainTex_TexelSize;
				float2 _DenoiseAngle;
				float _BilateralThreshold;

			struct appdata	
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
			};

			struct v2f	
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
			};

			v2f vert (appdata v)	
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				float2 d1 = 1.3846153846 * _DenoiseAngle * _MainTex_TexelSize.xy;
				float2 d2 = 3.2307692308 * _DenoiseAngle * _MainTex_TexelSize.xy;
				o.uv1 = float4(o.uv + d1, o.uv - d1);
				o.uv2 = float4(o.uv + d2, o.uv - d2);
				return o;
			}

			inline half compare(half3 n1, half3 n2)
			{
				return pow((dot(n1, n2) + 1.0) * 0.5, 8);
			}

			inline float3 getNormal(half2 uv)
			{
				float3 n = tex2D(_CameraGBufferTexture2, uv).xyz * 2 - 1;
				return n;
			}

			fixed4 fragBlur (v2f i) : SV_Target
			{

				half3 n0 = getNormal(i.uv);

				half w0 = 0.2270270270;
				half w1 = compare(n0, getNormal(i.uv1.zw)) * 0.3162162162;
				half w2 = compare(n0, getNormal(i.uv1.xy)) * 0.3162162162;
				half w3 = compare(n0, getNormal(i.uv2.zw)) * 0.0702702703;
				half w4 = compare(n0, getNormal(i.uv2.xy)) * 0.0702702703;
				half accumWeight = w0 + w1 + w2 + w3 + w4;

				half3 accum = tex2D(_MainTex, i.uv).r * w0;
				accum += tex2D(_MainTex, i.uv1.zw).rgb * w1;
				accum += tex2D(_MainTex, i.uv1.xy).rgb * w2;
				accum += tex2D(_MainTex, i.uv2.zw).rgb * w3;
				accum += tex2D(_MainTex, i.uv2.xy).rgb * w4;

				return half4(accum / accumWeight, 1.0);
				return tex2D(_MainTex, i.uv);
			}

			ENDCG
		}

		//Upscaling  ( 2 )
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragUPSCALE
			#define UNITY_GBUFFER_INCLUDED
			#include "UnityCG.cginc"
			#include "UnityGBuffer.cginc"

			//Input data
				#pragma multi_compile _DEBUG_None _DEBUG_AO

				sampler2D _MainTex;
				sampler2D_float _CameraDepthTexture;
				sampler2D _CameraGBufferTexture0, _CameraGBufferTexture1;
				sampler2D _HalfRes;
				float _lightContribution;
				float3 _FogParams;

			struct appdata	
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
			};

			struct v2f	
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)	
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 fragUPSCALE (v2f i) : SV_Target
			{
			 
				float2 uv = i.uv;

				float4 scene = tex2D(_MainTex, uv);
				float ao = tex2D(_HalfRes, uv).r;

				//Sky Clamp
					float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
					depth_o = LinearEyeDepth(depth_o);
					float skyClamp = step(999, depth_o);				
					ao = lerp(ao, 1, skyClamp);	

				#if _DEBUG_None
					
					float4 sceneColor = tex2D(_CameraGBufferTexture1, i.uv) + tex2D(_CameraGBufferTexture0, uv);	
					float4 sceneLight = scene / sceneColor;
					sceneLight.a = 0.2126 * sceneLight.r + 0.7152 * sceneLight.g + 0.0722 * sceneLight.b;
					half shadowmask = smoothstep(0.05, _lightContribution, sceneLight.a);
					ao = max(0, lerp(ao, 1, shadowmask));
					scene.rgb *= lerp(sceneColor * sceneColor, 1, ao);
					
				#elif _DEBUG_AO

					scene.rgb = ao;

				#endif

				return scene;
			}

			ENDCG
		}		
	}
}
