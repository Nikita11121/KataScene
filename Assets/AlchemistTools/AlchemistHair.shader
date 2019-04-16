Shader "Alchemist/Hair"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		[Normal]_Normals("Normals", 2D) = "bump" {}
		_NormalScale ("NormalScale", Range(0,6)) = 0.5
        //_Glossiness ("Smoothness", Range(0,1)) = 0.5
        //_Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "Queue"="Opaque" "RenderType"="Opaque" "IgnoreProjector"="True"}
        //Blend SrcAlpha OneMinusSrcAlpha
		LOD 200
		//ZWrite Off
		
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        //#pragma surface surf Standard fullforwardshadows
		#pragma surface surf SimpleSpecular //fullforwardshadows//alpha:fade noambient novertexlights nodirlightmap nolightmap noforwardadd// fullforwardshadows
		//#include "AutoLight.cginc"

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        uniform sampler2D _MainTex;
		uniform sampler2D _Normals;


        struct Input
        {
            float2 uv_MainTex;
        };

		half _NormalScale;
        //half _Glossiness;
        //half _Metallic;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        /*UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)*/

		float4 LightingSimpleSpecular(SurfaceOutput s, float3 lightDir, float3 viewDir, float atten) {
			float3 h = normalize(lightDir + viewDir);

			float diff = max(0, dot(s.Normal, lightDir));

			float nh = max(0, dot(s.Normal, h));
			float spec = 0.28 * pow(nh, 48.0);

			float4 c;

			c.rgb = (1.5 * atten - 0.2) * s.Albedo * _LightColor0.rgb *  diff + _LightColor0.rgb * pow(spec, 3); // (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * pow(spec, 1))*/; //s.Albedo * _LightColor0.rgb * diff;// (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * /*pow(spec, 1) * 7*/pow(spec, POW) * 7 * POWER) * atten;

			c.a = 1;//s.Alpha;
			return c;
		}


        void surf (Input IN, inout SurfaceOutput o)
        {

            // Albedo comes from a texture tinted by color
            float4 c = tex2D (_MainTex, IN.uv_MainTex) * float4(4.62, 2.77, 2.05, 2.05); //* 2.05;
			//c.r = c.r * 2.25;
			//c.g = c.g * 1.35;

            o.Albedo = c.rgb;
			o.Normal = UnpackScaleNormal( tex2D( _Normals, IN.uv_MainTex ), _NormalScale);
            // Metallic and smoothness come from slider variables
            //o.Metallic = _Metallic;
            //o.Smoothness = _Glossiness;
			//o.Alpha = c.a * 4 ;
			clip(c.a - 0.3);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
