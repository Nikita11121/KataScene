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
				int _resolution;
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

			float nrand(float2 uv, float dx, float dy)
			{
				uv += float2(dx, dy);
				return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
			}

			float3 spherical_kernel(float2 uv, float index)
			{
				// Uniformaly distributed points
				// http://mathworld.wolfram.com/SpherePointPicking.html
				float u = nrand(uv, 0, index) * 2 - 1;
				float theta = nrand(uv, 1, index) * UNITY_PI * 2;
				float u2 = sqrt(1 - u * u);
				float3 v = float3(u2 * cos(theta), u2 * sin(theta), u);
				return v;
			}

			fixed4 fragAO (v2f i) : SV_Target
			{

				float2 uv = i.uv;

				//Noise texture
				float4 noise = tex2D(_Noise, uv * (_ScreenParams.xy / float2(4, 4)));
				noise.xyz = normalize(noise.xyz * 2 - 1);
				
				// Sample a view-space normal vector on the g-buffer.
				float3 norm_o = tex2D(_CameraGBufferTexture2, i.uv).xyz;
				norm_o = mul((float3x3)unity_WorldToCamera, norm_o * 2 - 1);

				// Sample a linear depth on the depth buffer.
				float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				depth_o = LinearEyeDepth(depth_o);

				// Reconstruct the view-space position.
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
				float3 pos_o = float3((i.uv * 2 - 1 - p13_31) / p11_22, 1) * depth_o + norm_o * 0.005 * (1 + depth_o);
							
				//Calculate SSAO
				float4 occ = 0;

				const float4 rndLength[4] ={
					0,		 1,		 0,			0.04,
					0.81,	-0.33,	 0.47,		0.075, 
					-0.81,	-0.33,	 0.47,		0.15, 
					0.0,	-0.33,	-0.94,		0.3,
				};

				for (int s = 0; s < 4; s++){	

					//Random vector and ray length
					float4 delta = rndLength[s];
					delta.xyz = reflect(delta.xyz, noise.xyz);
					delta.xyz *= (dot(norm_o, delta.xyz) >= 0) * 2 - 1;

					float3 pos_s0 = pos_o + delta.xyz * delta.w * noise.w;
							
					// Re-project the sampling point.
					float3 pos_sc = mul(proj, pos_s0);
					float2 uv_s = (pos_sc.xy / pos_s0.z + 1) * 0.5;

					float3 v_s2 = float3((uv_s * 2 - 1 - p13_31) / p11_22, 1) * LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv_s)) - pos_o;

					float a1 = max(dot(normalize(v_s2), norm_o), 0.0);
					float d1 = 1 - min(1, length(v_s2) / 0.3);

					occ += a1 * d1;
				}
				occ /= 4;

				occ = (pow(max(0, 1 - occ), 20) + 0.5) / 1.5;

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

			fixed4 fragBlur (v2f i) : SV_Target
			{

				float2 uv = i.uv;

				float depth_o = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
				float3 norm_o = tex2D(_CameraGBufferTexture2, uv).xyz * 2 - 1;

				// Reconstruct the view-space position.
					float3x3 proj = (float3x3)unity_CameraProjection;
					float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
					float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
					float3 pos_o = float3((i.uv * 2 - 1 - p13_31) / p11_22, 1) * depth_o;
					float3 viewDir = normalize(mul((float3x3)unity_CameraToWorld, pos_o));

				//Blur
					float angle = pow(dot(-viewDir, norm_o), 1);
					float thresh = lerp(0.04, 0.004, angle) * depth_o;
					float2 pixelSize = _MainTex_TexelSize.xy * _DenoiseAngle;

					float2 dirKernel[3] = {
						0, 0,
						2, 2,
						-2,-2,
					};

					float totalWeight = 0;
					float4 blur_o = 0;
			
					for (int s = 0; s < 3; s++)
					{				
						float2 newUV = uv + dirKernel[s] * pixelSize;

						float3 norm_s = tex2D(_CameraGBufferTexture2, newUV).xyz * 2 - 1;
						float depth_s = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, newUV));
						
						float weight = saturate(1.0 - abs(depth_o - depth_s) / thresh);
						weight *= 0.8 < dot(norm_s, norm_o);
						
						blur_o += weight * tex2D(_MainTex, newUV);
						totalWeight += weight;
					}
			
					blur_o = blur_o / totalWeight;
					//blur_o = tex2D(_MainTex, uv);

				return blur_o;
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
				float4 ao = tex2D(_HalfRes, uv);
				ao.a = pow(ao.a, 1.5);

				//Sky Clamp
					float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
					depth_o = LinearEyeDepth(depth_o);
					float skyClamp = step(999, depth_o);				
					ao.a = lerp(ao.a, 1, skyClamp);	
								
				float4 sceneAlbedo = tex2D(_CameraGBufferTexture0, uv);
				float4 sceneColor = tex2D(_CameraGBufferTexture1, i.uv) + sceneAlbedo;
				float4 sceneLight = scene / sceneColor;
				sceneLight.a = 0.2126 * sceneLight.r + 0.7152 * sceneLight.g + 0.0722 * sceneLight.b;
				
				#if _DEBUG_None

					half shadowmask = smoothstep(0.05, _lightContribution, sceneLight.a);
					ao.a = max(0, lerp(ao.a, 1, shadowmask));
					scene.rgb *= lerp(sceneColor, 1, ao.a);
					
				#elif _DEBUG_AO

					scene.rgb = ao.a;

				#endif

				return scene;
			}

			ENDCG
		}		
	}
}
