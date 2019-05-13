// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Human/Skin"
{
	Properties
	{
		[NoScaleOffset]_Albedo("(RGB) Albedo, (A) Thikness Mask", 2D) = "white" {}
		[NoScaleOffset]_Metallic("(R)Metallic, (G) AO, (B) Subdermal, (A) Smoothness", 2D) = "white" {}
		_SmoothnessMin("Smoothness Min", Range( 0 , 1)) = 0
		_SmoothnessMax("Smoothness Max", Range( 0 , 1)) = 1
		[NoScaleOffset]_BumpMap("Normal", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range( 0 , 1)) = 1
		_SubdermalColor("Subdermal Color", Color) = (0.7294118,0.03529412,0.1137255,0)
		[NoScaleOffset]_SubdermalLightVector("Subdermal Light Vector", 2D) = "gray" {}
		_SSSpower("SSS power", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		ZWrite On
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#pragma target 2.0
		#pragma only_renderers d3d9 d3d11 glcore gles gles3 
		#pragma surface surf StandardCustomLighting keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform sampler2D _Albedo;
		uniform sampler2D _BumpMap;
		uniform float _NormalScale;
		uniform float4 _SubdermalColor;
		uniform sampler2D _Metallic;
		uniform sampler2D _SubdermalLightVector;
		uniform float _SSSpower;
		uniform float _SmoothnessMin;
		uniform float _SmoothnessMax;

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float2 uv_Albedo43 = i.uv_texcoord;
			float4 tex2DNode43 = tex2D( _Albedo, uv_Albedo43 );
			float3 ase_worldPos = i.worldPos;
			float3 normalizeResult178 = normalize( ( _WorldSpaceLightPos0.xyz - ase_worldPos ) );
			float3 lerpResult179 = lerp( _WorldSpaceLightPos0.xyz , normalizeResult178 , _WorldSpaceLightPos0.w);
			float2 uv_BumpMap34 = i.uv_texcoord;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float dotResult7 = dot( lerpResult179 , ase_normWorldNormal );
			float dotResult35 = dot( lerpResult179 , normalize( (WorldNormalVector( i , UnpackScaleNormal( tex2Dlod( _BumpMap, float4( uv_BumpMap34, 0, (1.5 + (dotResult7 - 0.0) * (5.0 - 1.5) / (1.0 - 0.0))) ), _NormalScale ) )) ) );
			float smoothstepResult40 = smoothstep( (-0.15 + (tex2DNode43.a - 0.0) * (-0.5 - -0.15) / (1.0 - 0.0)) , 1.0 , dotResult35);
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float2 uv_Metallic29 = i.uv_texcoord;
			float4 tex2DNode29 = tex2D( _Metallic, uv_Metallic29 );
			float4 temp_output_144_0 = ( _SubdermalColor * tex2DNode29.b );
			float2 uv_Albedo23 = i.uv_texcoord;
			float smoothstepResult221 = smoothstep( -0.5 , 0.5 , dotResult35);
			float4 lerpResult193 = lerp( temp_output_144_0 , tex2Dlod( _Albedo, float4( uv_Albedo23, 0, 1.0) ) , smoothstepResult221);
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float2 uv_SubdermalLightVector113 = i.uv_texcoord;
			float4 temp_cast_0 = (1.0).xxxx;
			UnityGI gi141 = gi;
			float3 diffNorm141 = WorldNormalVector( i , float4( mul( ase_worldToTangent, ( ( tex2D( _SubdermalLightVector, uv_SubdermalLightVector113 ) * 2.0 ) - temp_cast_0 ).rgb ) , 0.0 ).rgb );
			gi141 = UnityGI_Base( data, 1, diffNorm141 );
			float3 indirectDiffuse141 = gi141.indirect.diffuse + diffNorm141 * 0.0001;
			float4 temp_output_223_0 = ( ( ( smoothstepResult40 * ase_lightAtten * ase_lightColor * lerpResult193 ) + ( temp_output_144_0 * float4( indirectDiffuse141 , 0.0 ) * (0.05 + (tex2DNode43.a - 0.0) * (0.65 - 0.05) / (1.0 - 0.0)) ) ) * _SSSpower );
			SurfaceOutputStandard s30 = (SurfaceOutputStandard ) 0;
			float grayscale192 = Luminance(temp_output_223_0.rgb);
			float4 temp_cast_7 = (grayscale192).xxxx;
			s30.Albedo = max( ( tex2DNode43 - temp_cast_7 ) , float4( 0,0,0,0 ) ).rgb;
			float2 uv_BumpMap45 = i.uv_texcoord;
			s30.Normal = WorldNormalVector( i , UnpackScaleNormal( tex2D( _BumpMap, uv_BumpMap45 ), _NormalScale ) );
			s30.Emission = float3( 0,0,0 );
			s30.Metallic = tex2DNode29.r;
			s30.Smoothness = (_SmoothnessMin + (tex2DNode29.a - 0.0) * (_SmoothnessMax - _SmoothnessMin) / (1.0 - 0.0));
			s30.Occlusion = tex2DNode29.g;

			data.light = gi.light;

			UnityGI gi30 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g30 = UnityGlossyEnvironmentSetup( s30.Smoothness, data.worldViewDir, s30.Normal, float3(0,0,0));
			gi30 = UnityGlobalIllumination( data, s30.Occlusion, s30.Normal, g30 );
			#endif

			float3 surfResult30 = LightingStandard ( s30, viewDir, gi30 ).rgb;
			surfResult30 += s30.Emission;

			#ifdef UNITY_PASS_FORWARDADD//30
			surfResult30 -= s30.Emission;
			#endif//30
			c.rgb = ( temp_output_223_0 + float4( surfResult30 , 0.0 ) ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16700
1927;1;1906;1020;1505.269;-102.1606;1.3;True;True
Node;AmplifyShaderEditor.WorldPosInputsNode;176;-1942.839,-82.67628;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightPos;175;-1995.854,-188.956;Float;False;0;3;FLOAT4;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleSubtractOpNode;177;-1711.483,-81.99289;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;178;-1554.107,-74.37237;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;179;-1354.617,-182.4352;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;4;-1341.615,-28.50801;Float;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;7;-1120.444,-99.66238;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1201.142,303.4925;Float;False;Property;_NormalScale;Normal Scale;5;0;Create;True;0;0;False;0;1;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;33;-957.874,-96.42376;Float;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1.5;False;4;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;34;-738.8762,-96.26342;Float;True;Property;_TextureSample2;Texture Sample 2;4;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;True;Instance;45;MipLevel;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;113;-930.1362,715.3829;Float;True;Property;_SubdermalLightVector;Subdermal Light Vector;7;1;[NoScaleOffset];Create;True;0;0;False;0;1360841c97424314b874971c105f6045;1360841c97424314b874971c105f6045;True;0;False;gray;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;123;-631.0937,809.3325;Float;False;Constant;_Float1;Float 1;7;0;Create;True;0;0;False;0;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;148;-414.2244,-90.69723;Float;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;122;-477.0952,727.5337;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;126;-472.5953,831.4328;Float;False;Constant;_Float2;Float 2;7;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;125;-331.6958,742.2336;Float;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;29;-188.2112,1254.584;Float;True;Property;_Metallic;(R)Metallic, (G) AO, (B) Subdermal, (A) Smoothness;1;1;[NoScaleOffset];Create;False;0;0;False;0;f6d6f473a127fe748a8bbdf98641bbf0;f6d6f473a127fe748a8bbdf98641bbf0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldToTangentMatrix;128;-460.8921,646.1906;Float;False;0;1;FLOAT3x3;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-773.6805,206.8566;Float;False;Constant;_Float0;Float 0;8;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;43;-192.0857,959.3061;Float;True;Property;_Albedo;(RGB) Albedo, (A) Thikness Mask;0;1;[NoScaleOffset];Create;False;0;0;False;0;3185c9c390d5e4249a5877f8dac13690;3185c9c390d5e4249a5877f8dac13690;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;143;-175.8186,507.0544;Float;False;Property;_SubdermalColor;Subdermal Color;6;0;Create;True;0;0;False;0;0.7294118,0.03529412,0.1137255,0;0.7294118,0.03529412,0.1137246,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;35;-195.8167,-150.9102;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;23;-588.7289,199.4385;Float;True;Property;_TextureSample1;Texture Sample 1;0;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Instance;43;MipLevel;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;221;-170.7791,-23.78972;Float;False;3;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;135;-123.9144,697.8055;Float;False;2;2;0;FLOAT3x3;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;235.6058,577.8109;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCRemapNode;64;154.8037,25.10806;Float;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-0.15;False;4;FLOAT;-0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;16;398.6728,236.4842;Float;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SmoothstepOpNode;40;378.7282,0.3275883;Float;False;3;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;222;308.5866,794.0296;Float;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.05;False;4;FLOAT;0.65;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;141;237.4486,693.7939;Float;False;Tangent;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;193;431.6302,416.0309;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightAttenuation;1;356.9598,141.2594;Float;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;764.8398,369.3269;Float;False;4;4;0;FLOAT;0;False;1;FLOAT;1;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;766.6745,538.4652;Float;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;224;801.4449,664.8869;Float;False;Property;_SSSpower;SSS power;8;0;Create;True;0;0;False;0;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;85;991.649,507.6059;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;223;1187.351,566.6362;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;219;1323.018,752.8219;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;220;644.6281,817.6678;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCGrayscale;192;678.5395,878.0028;Float;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;154;-961.9335,1071.983;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;191;928.6241,975.8804;Float;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;215;612.4464,1528.785;Float;False;Property;_SmoothnessMax;Smoothness Max;3;0;Create;True;0;0;False;0;1;0.8;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;213;600.4655,1435.602;Float;False;Property;_SmoothnessMin;Smoothness Min;2;0;Create;True;0;0;False;0;0;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;217;955.8947,1295.826;Float;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;45;399.4312,1050.595;Float;True;Property;_BumpMap;Normal;4;1;[NoScaleOffset];Create;False;0;0;False;0;f79445743be1833418262939e0ab40d4;f79445743be1833418262939e0ab40d4;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;201;1114.504,975.4077;Float;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomStandardSurface;30;1304.619,1036.036;Float;False;Metallic;Tangent;6;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,1;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;47;1648.215,873.2252;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1898.942,641.1124;Float;False;True;0;Float;ASEMaterialInspector;0;0;CustomLighting;Human/Skin;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;Back;1;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;True;True;True;True;True;False;False;False;False;False;False;False;False;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;177;0;175;1
WireConnection;177;1;176;0
WireConnection;178;0;177;0
WireConnection;179;0;175;1
WireConnection;179;1;178;0
WireConnection;179;2;175;2
WireConnection;7;0;179;0
WireConnection;7;1;4;0
WireConnection;33;0;7;0
WireConnection;34;2;33;0
WireConnection;34;5;48;0
WireConnection;148;0;34;0
WireConnection;122;0;113;0
WireConnection;122;1;123;0
WireConnection;125;0;122;0
WireConnection;125;1;126;0
WireConnection;35;0;179;0
WireConnection;35;1;148;0
WireConnection;23;2;72;0
WireConnection;221;0;35;0
WireConnection;135;0;128;0
WireConnection;135;1;125;0
WireConnection;144;0;143;0
WireConnection;144;1;29;3
WireConnection;64;0;43;4
WireConnection;40;0;35;0
WireConnection;40;1;64;0
WireConnection;222;0;43;4
WireConnection;141;0;135;0
WireConnection;193;0;144;0
WireConnection;193;1;23;0
WireConnection;193;2;221;0
WireConnection;42;0;40;0
WireConnection;42;1;1;0
WireConnection;42;2;16;0
WireConnection;42;3;193;0
WireConnection;84;0;144;0
WireConnection;84;1;141;0
WireConnection;84;2;222;0
WireConnection;85;0;42;0
WireConnection;85;1;84;0
WireConnection;223;0;85;0
WireConnection;223;1;224;0
WireConnection;219;0;223;0
WireConnection;220;0;219;0
WireConnection;192;0;220;0
WireConnection;154;0;48;0
WireConnection;191;0;43;0
WireConnection;191;1;192;0
WireConnection;217;0;29;4
WireConnection;217;3;213;0
WireConnection;217;4;215;0
WireConnection;45;5;154;0
WireConnection;201;0;191;0
WireConnection;30;0;201;0
WireConnection;30;1;45;0
WireConnection;30;3;29;1
WireConnection;30;4;217;0
WireConnection;30;5;29;2
WireConnection;47;0;223;0
WireConnection;47;1;30;0
WireConnection;0;13;47;0
ASEEND*/
//CHKSM=647F9D710E9EF04FFBD83CB555015383D26FD1DE