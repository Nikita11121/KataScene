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
				float u = nrand(uv, 0, index) * 2 - 1;
				float theta = nrand(uv, 1, index) * UNITY_PI * 2;
				float u2 = sqrt(1 - u * u);
				return float3(u2 * cos(theta), u2 * sin(theta), u);
			}

			fixed4 fragAO (v2f i) : SV_Target
			{

				float2 uv = i.uv;

				//Occluded point 
				// Sample a linear depth on the depth buffer.
				float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				depth_o = LinearEyeDepth(depth_o);

				// Sample a view-space normal vector on the g-buffer.
				float3 norm_o = tex2D(_CameraGBufferTexture2, i.uv).xyz;
				norm_o = mul((float3x3)unity_WorldToCamera, norm_o * 2 - 1);

				//Noise texture
				float4 noise = tex2D(_Noise, uv * (_ScreenParams.xy / float2(4, 4)) / _resolution);

				// Reconstruct the view-space position.
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
				float3 pos_o = float3((i.uv * 2 - 1 - p13_31) / p11_22, 1) * depth_o + norm_o * 0.001 * (1 + depth_o);
							
				//Calculate SSAO
				float4 occ = 0;
				
				int raySteps = 3;
				float rndTable [3] ={
					0.005 * _scale, 0.06 * _scale, 0.5 * _scale,
				};

				fixed _samplesCount = 3;
				
				for (int s = 0; s < _samplesCount; s++){	

					//Random vector and ray length
					float3 delta = spherical_kernel(noise.xy, s);
					//delta = reflect(delta, noise.xyz);
					delta *= (dot(norm_o, delta) >= 0) * 2 - 1;

					float depth_s = 0;
					float2 uv_s = 0;

					for (int r = 0; r < raySteps; r++){

						float rayStepLength = rndTable[r];
						float3 pos_s0 = pos_o + delta * rayStepLength;
							
						// Re-project the sampling point.
						float3 pos_sc = mul(proj, pos_s0);
						uv_s = (pos_sc.xy / pos_s0.z + 1) * 0.5;

						depth_s = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv_s));

						if( (pos_s0.z - depth_s) > 0)
						{
							float3 pos_s = float3((uv_s * 2 - 1 - p13_31) / p11_22, 1) * depth_s;
							float3 v_s2 = pos_s - pos_o;

							float d1 = length(v_s2) * 0.66;
							occ.a += 1 - min(1, d1 / (0.5 * _scale));

							r = 10;
						}
					}
				}

				occ /= _samplesCount;
				occ.a = 1 - occ.a;

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
				#pragma multi_compile  _DOWNSAMPLING_Full _DOWNSAMPLING_Half _DOWNSAMPLING_Quarter

				sampler2D_float _CameraDepthTexture;
				sampler2D _CameraGBufferTexture2;
				sampler2D _MainTex, _Noise;
				uniform half4 _MainTex_TexelSize;
				float2 _DenoiseAngle;
				int _resolution;
				sampler2D _downSamplingNormalDepth;

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

				float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth_o = LinearEyeDepth(depth_o);
				float3 norm_o = tex2D(_CameraGBufferTexture2, uv).xyz * 2 - 1;

				// Reconstruct the view-space position.
					float3x3 proj = (float3x3)unity_CameraProjection;
					float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
					float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
					float3 pos_o = float3((i.uv * 2 - 1 - p13_31) / p11_22, 1) * depth_o;
					float3 viewDir = normalize(mul((float3x3)unity_CameraToWorld, pos_o));
					pos_o += norm_o * 0.001 * (depth_o) * _resolution;

				//Blur
					float angle = pow(dot(-viewDir, norm_o), 1);

					float thresh = lerp(0.02, 0.002, angle) * (1 + depth_o);

					float totalWeight = 0;
					float4 blur_o = 0;

					int SAMPLE_COUNT = 5;

					float3 dirKernel[9] = {
						0, 0,	0.38,
						1, 1,	0.31,
						-1,-1,	0.31,
						2, 2,	0.21,
						-2,-2,	0.21,	
						3, 3,	0.12,
						-3,-3,	0.12,	
						4, 4,	0.07,
						-4,-4,	0.07,	
					};

					float2 pixelSize =  _MainTex_TexelSize.xy * _DenoiseAngle;
			
					for (int s = 0; s < SAMPLE_COUNT; s++)
					{				
						float2 newUV = uv + dirKernel[s] * pixelSize * _resolution;

						float3 norm_s = tex2D(_CameraGBufferTexture2, newUV).xyz * 2 - 1;
						float depth_s = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, newUV);
						depth_s = LinearEyeDepth(depth_s);
						
						float weight = saturate(1.0 - abs(depth_o - depth_s) / thresh);
						weight *= smoothstep(0.86, 1, dot(norm_s, norm_o));
						weight += 0.0001;
						
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
				#pragma multi_compile _DEBUG_None _DEBUG_Lighting _DEBUG_AO _DEBUG_Bounce
				#pragma multi_compile _BOUNCE_True _BOUNCE_False

				sampler2D _MainTex;
				sampler2D_float _CameraDepthTexture;
				sampler2D _CameraGBufferTexture0, _CameraGBufferTexture1, _CameraGBufferTexture2;
				sampler2D _HalfRes;
				float _lightContribution, _power;
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

			half ComputeFog(float z)
			{
				half fog = 0.0;
			#if FOG_LINEAR
				fog = (_FogParams.z - z) / (_FogParams.z - _FogParams.y);
			#elif FOG_EXP
				fog = exp2(-_FogParams.x * z);
			#else // FOG_EXP2
				fog = _FogParams.x * z;
				fog = exp2(-fog * fog);
			#endif
				return saturate(fog);
			}

			fixed4 fragUPSCALE (v2f i) : SV_Target
			{
			 
				float2 uv = i.uv;

				float4 scene = tex2D(_MainTex, uv);
				float4 sceneAlbedo = tex2D(_CameraGBufferTexture0, uv);
				float4 sceneColor = tex2D(_CameraGBufferTexture1, i.uv) + sceneAlbedo;
				float4 sceneLight = scene / sceneColor;
				sceneLight.a = 0.2126 * sceneLight.r + 0.7152 * sceneLight.g + 0.0722 * sceneLight.b;
				half shadowmask = smoothstep(0.05, _lightContribution, sceneLight.a);
				float4 ao = tex2D(_HalfRes, uv);

				float depth_o = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth_o = LinearEyeDepth(depth_o);
				float skyClamp = step(999, depth_o);

				float4 combine = scene;
					
				ao.rgb = ao.rgb * _power * 1;
				ao = lerp(ao, float4(0,0,0,1), skyClamp);	
				

				#if _DEBUG_None

					ao.a = max(0, lerp(ao.a, 1, shadowmask));
					combine.rgb *= ao.a;
					//combine.rgb = max(ao.rgb * sceneColor, combine.rgb);
					combine.rgb += ao.rgb * sceneAlbedo;

				#elif _DEBUG_Lighting

					ao.a = max(0, lerp(ao.a, 1, shadowmask));
					combine = sceneLight;
					combine.rgb *= ao.a;
					combine.rgb += ao.rgb * sceneAlbedo;

				#elif _DEBUG_AO

					combine.rgb = ao.a;

				#elif _DEBUG_Lighting || _BOUNCE_True

					combine.rgb = ao.rgb * sceneAlbedo;

				#endif


				return combine;
			}

			ENDCG
		}

		//DownSampled Normal And Depth  ( 3 )
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragAO
			#define UNITY_GBUFFER_INCLUDED
			#include "UnityCG.cginc"
			#include "UnityGBuffer.cginc"

			sampler2D_float _CameraDepthTexture;
			sampler2D _CameraGBufferTexture2;

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
				
				// Sample a linear depth on the depth buffer.
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				depth = LinearEyeDepth(depth);

				// Sample a view-space normal vector on the g-buffer.
				float3 norm = tex2D(_CameraGBufferTexture2, i.uv).xyz;
				norm = mul((float3x3)unity_WorldToCamera, norm * 2 - 1) * 0.5 + 0.5;
				
				return float4(norm, depth);
			}

			ENDCG
		}

		//SceneColor  ( 4 )
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragAO

			sampler2D _MainTex;

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
				
				return tex2D(_MainTex, i.uv);
			}

			ENDCG
		}
	}
}
