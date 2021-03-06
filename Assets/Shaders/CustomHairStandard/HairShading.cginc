#ifndef HAIR_SHADING_INCLUDED
#define HAIR_SHADING_INCLUDED

struct HairOutput
{
    fixed3 Albedo;      // base (diffuse or specular) color
    fixed3 Normal;      // tangent space normal, if written
    half3 Emission;
    half Metallic;      // 0=non-metal, 1=metal
    half Smoothness;    // 0=rough, 1=smooth
    half Occlusion;     // occlusion (default 1)
    fixed Alpha;        // alpha for transparencies
    fixed2 Uv0;
    float3 WorldNormal; 
    float3 WorldTangent;
};

fixed _SpecularShift1;
fixed4 _SpecularColor1;
fixed _SpecularExponent1;

fixed _SpecularShift2;
fixed4 _SpecularColor2;
fixed _SpecularExponent2;

fixed _WrapLightingStrength;

#define MARMO_SKIN_IBL 1
#define MARMO_MIP_GLOSS 1

inline fixed3 CalculateMarmosetSpecularIBL(half4 exposureIBL, float3 reflectionVec, fixed specIntensity, fixed glossLod)
{
    fixed3 result = 0;
    
    #ifdef MARMO_SPECULAR_IBL
		float3 skyR = reflectionVec;
		#ifdef MARMO_SKY_BLEND
			float3 skyR1 = skyRotate(_SkyMatrix1, skyR); //per-fragment matrix multiply, expensive			
		#endif
		skyR = skyRotate(_SkyMatrix,skyR); //per-fragment matrix multiply, expensive
		
		#ifdef MARMO_MIP_GLOSS
			half3 specIBL = glossCubeLookup(_SpecCubeIBL, skyR, glossLod);
		#else
			half3 specIBL =  specCubeLookup(_SpecCubeIBL, skyR) * specIntensity;
		#endif
		
		#ifdef MARMO_SKY_BLEND
			#ifdef MARMO_MIP_GLOSS
				half3 specIBL1 = glossCubeLookup(_SpecCubeIBL, skyR1, glossLod);
			#else
				half3 specIBL1 =  specCubeLookup(_SpecCubeIBL, skyR1) * specIntensity;
			#endif
			specIBL = lerp(specIBL1, specIBL, _BlendWeightIBL);
		#endif
		
		result = specIBL.rgb * exposureIBL.y;
	#endif

    return result;
}

inline fixed3 CalculateMarmosetDiffuseIBL(half4 exposureIBL, float3 worldN, fixed hairMask)
{
    fixed3 result = 0;
    
	//DIFFUSE IBL
	#ifdef MARMO_DIFFUSE_IBL
		
		float3 skyN = skyRotate(_SkyMatrix, worldN); //per-fragment matrix multiply, expensive
		skyN = normalize(skyN);
		#ifdef MARMO_SKIN_IBL						
			//SH DIFFUSE			
			float3 band0, band1, band2;
			float3 unity0, unity1, unity2;
			SHLookup(skyN,band0,band1,band2);
			#ifdef MARMO_SKY_BLEND
				float3 skyN1 = skyRotate(_SkyMatrix1, worldN); //per-fragment matrix multiply, expensive
				skyN1 = normalize(skyN1);
				float3 band01, band11, band21;
				SHLookup1(skyN1,band01,band11,band21);
				band0 = lerp(band01, band0, _BlendWeightIBL);
				band1 = lerp(band11, band1, _BlendWeightIBL);
				band2 = lerp(band21, band2, _BlendWeightIBL);
			#endif
			
			SHLookupUnity(worldN,unity0,unity1,unity2);
			band0 = (band0*exposureIBL.x) + unity0;
			band1 = (band1*exposureIBL.x) + unity1;
			band2 = (band2*exposureIBL.x) + unity2;
			
			result = SHConvolve(band0, band1, band2, hairMask);//subdermis.rgb*skinMask);
			
		#endif
	#endif

    return result * exposureIBL.w;
}

void CalculateMarmosetIBL(float3 worldN, fixed hairMask, float3 reflectionVec, fixed specIntensity, fixed glossLod, out fixed3 diffuse, out fixed3 specular)
{
    #ifdef MARMO_SKY_BLEND
		half4 exposureIBL = lerp(_ExposureIBL1, _ExposureIBL, _BlendWeightIBL);
	#else
		half4 exposureIBL = _ExposureIBL;
	#endif
	
    #if LIGHTMAP_ON
		exposureIBL.xy *= _ExposureLM;
	#endif
	
	diffuse = CalculateMarmosetDiffuseIBL(exposureIBL, worldN, hairMask);
	specular = CalculateMarmosetSpecularIBL(exposureIBL, reflectionVec, specIntensity, glossLod);
}

inline float3 ShiftTangent(float3 T, float3 N,float shift)
{
    float3 shiftedT = T + shift * N;//cross(T, N);
    return normalize (shiftedT);
}

inline float2 CalculateSpecularTwo(half2 roughness, half2 nh, float lh)
{
    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155
    half2 a = roughness;
    float2 a2 = a*a;

    float2 d = nh * nh * (a2 - 1.f) + 1.00001f;

#ifdef UNITY_COLORSPACE_GAMMA
    // Tighter approximation for Gamma only rendering mode!
    // DVF = sqrt(DVF);
    // DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
    float2 specularTerm = a / (max(0.32f, lh) * (1.5f + roughness) * d);
#else
    float2 specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4);
#endif

    // on mobiles (where half actually means something) denominator have risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE)
    specularTerm = specularTerm - 1e-4f;
#endif

#if defined (SHADER_API_MOBILE)
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

#if defined(_SPECULARHIGHLIGHTS_OFF)
    specularTerm = 0.0;
#endif

    return specularTerm;
}

float4 HairLighting(half3 diffColor, half3 specColor, half3 shiftTexValue, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 tangent, float3 viewDir,
    UnityLight light, UnityIndirect gi)
{
    shiftTexValue.x -= 0.5;

    // shift tangents
    float3 t1 = ShiftTangent(tangent, normal, _SpecularShift1 + shiftTexValue.x);
    float3 t2 = ShiftTangent(tangent, normal, _SpecularShift2 + shiftTexValue.x);// diffuse lighting: the lerp shifts the shadow boundary for asofter look
    
    float3 halfDir = Unity_SafeNormalize (float3(light.dir) + viewDir);
    half nl = saturate((dot(normal, light.dir) + _WrapLightingStrength) / (1.0f + _WrapLightingStrength));

    half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
    half perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
    half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

    float2 specularComponents = CalculateSpecularTwo(
        half2(_SpecularExponent1, _SpecularExponent2), 
        half2(dot(t1, halfDir), dot(t2, halfDir)), nl);
        
    float3 specular = _SpecularColor1.rgb * _SpecularColor1.a * specularComponents.x;
    specular += _SpecularColor2.rgb * _SpecularColor2.a * shiftTexValue.y * specularComponents.y;
    
    half nv = saturate(dot(normal, viewDir));

#ifdef UNITY_COLORSPACE_GAMMA
    half surfaceReduction = 0.28;
#else
    half surfaceReduction = (0.6-0.08*perceptualRoughness);
#endif

    surfaceReduction = 1.0 - roughness*perceptualRoughness*surfaceReduction;

    // final color assembly
    float4 o;
    fixed3 diffuseIBL;
    fixed3 specularIBL;
    
    CalculateMarmosetIBL(normal, shiftTexValue.y, -reflect(viewDir, normal), roughness, roughness * 7, diffuseIBL, specularIBL);

    o.rgb = (diffColor + specular) * nl * light.color
          + (gi.diffuse + diffuseIBL) * diffColor 
          + (gi.specular + specularIBL) * surfaceReduction * FresnelLerpFast (specColor, grazingTerm, nv);
          
    o.a = 1;
    
    return o;
}

half4 BRDF3_Unity_PBS_Hair (half3 diffColor, half3 specColor, half3 shiftTexValue, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 tangent, float3 viewDir,
    UnityLight light, UnityIndirect gi)
{
    return HairLighting(diffColor, specColor, shiftTexValue, oneMinusReflectivity, smoothness, normal, tangent, viewDir, light, gi);
}


#endif // HAIR_SHADING_INCLUDED