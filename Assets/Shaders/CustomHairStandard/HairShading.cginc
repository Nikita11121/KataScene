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

float3 ShiftTangent(float3 T, float3 N,float shift)
{
    float3 shiftedT = T + shift * N;//cross(T, N);
    return normalize (shiftedT);
}
        
float StrandSpecular(float3 T, float3 halfDir, float exponent)
{
    float dotTH = dot(T, halfDir);
    float sinTH= sqrt(1.0 - dotTH * dotTH);
    float dirAtten = smoothstep(-1.0, 0.0, dotTH);

    return dirAtten* pow(sinTH, exponent);
}

inline float3 CalculateSpecular(half roughness, float nh, float lh)
{
    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155
    half a = roughness;
    float a2 = a*a;

    float d = nh * nh * (a2 - 1.f) + 1.00001f;

#ifdef UNITY_COLORSPACE_GAMMA
    // Tighter approximation for Gamma only rendering mode!
    // DVF = sqrt(DVF);
    // DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
    float specularTerm = a / (max(0.32f, lh) * (1.5f + roughness) * d);
#else
    float specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4);
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
    float3 diffuse = diffColor;
    
    float3 halfDir = Unity_SafeNormalize (float3(light.dir) + viewDir);
    half nl = saturate((dot(normal, light.dir) + _WrapLightingStrength) / (1.0f + _WrapLightingStrength));

    half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
    half perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
    half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

    float3 specular = _SpecularColor1.a * CalculateSpecular(roughness * _SpecularExponent1, dot(t1, halfDir), nl);
    specular += _SpecularColor2.a * shiftTexValue.y * CalculateSpecular(roughness * _SpecularExponent2, dot(t2, halfDir), nl);
    
    half nv = saturate(dot(normal, viewDir));

#ifdef UNITY_COLORSPACE_GAMMA
    half surfaceReduction = 0.28;
#else
    half surfaceReduction = (0.6-0.08*perceptualRoughness);
#endif

    surfaceReduction = 1.0 - roughness*perceptualRoughness*surfaceReduction;

    // final color assembly
#ifdef _ALPHABLEND_ON
    half3 lightColor = light.color * saturate(sign(nl));
#else
    half3 lightColor = light.color;
#endif

    float4 o;
    o.rgb = (diffuse + specular * _Color) * nl * lightColor + gi.diffuse * diffColor + gi.specular * surfaceReduction * FresnelLerpFast (specular * nl, grazingTerm, nv);
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