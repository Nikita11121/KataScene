Shader "Alchemist/Scin"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		[Normal]_Normals("Normals", 2D) = "bump" {}
		_NormalScale ("NormalScale", Range(0,4)) = 0.5
		_Occlusion ("Occlusion", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        uniform sampler2D _MainTex;
		uniform sampler2D _Normals;
		uniform sampler2D _Occlusion;

        struct Input
        {
            float2 uv_MainTex;
        };

		half _NormalScale;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * tex2D (_Occlusion, IN.uv_MainTex) * _Color * 2.05;
			c.r = c.r * 2.25;
			c.g = c.g * 1.35;
            o.Albedo = c.rgb;
			o.Normal = UnpackScaleNormal( tex2D( _Normals, IN.uv_MainTex ), _NormalScale);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
