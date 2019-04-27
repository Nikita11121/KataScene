﻿using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Rendering/Deferred AO")]
public class RMAO : MonoBehaviour
{
    #region Public Properties

    [Range(1.0f, 2.0f)]
    public float _power = 1.0f;
    public float power
    {
        get { return _power; }
        set { _power = value; }
    }

    [Range(0.2f, 2)]
    public float _lightContribution = 0.8f; 
    public float lightContribution
    {
        get { return _lightContribution; }
        set { _lightContribution = value; }
    }

    [SerializeField]
    public enum DebugMode { None, Lighting, LightingNoAO, AO };
    [SerializeField]
    DebugMode _debugMode = DebugMode.None;
    public DebugMode debugMode
    {
        get { return _debugMode; }
        set { _debugMode = value; }
    }

    #endregion

    #region Private Resources

    RenderTexture _halfRes, _denoise, _downSamplingTex, _downSamplingNormalDepth;
    Material _material;

    [SerializeField, HideInInspector]
    private Shader _shader;

    [SerializeField, HideInInspector]
    Texture2D _noise;

    Vector2 screenResCur;
    int res = 1;
    int curRes = 0;
    int samplesCount = 1;

    bool CheckDeferredShading()
    {
        var path = GetComponent<Camera>().actualRenderingPath;
        return path == RenderingPath.DeferredShading;
    }

    #endregion

    #region MonoBehaviour Functions

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {

        if (!CheckDeferredShading())
        {
            Graphics.Blit(source, destination);
            return;
        }

        if (_material == null)
        {
            _material = new Material(_shader);
            _material.hideFlags = HideFlags.DontSave;
        }

        _material.shaderKeywords = null;
        _material.EnableKeyword("_DEBUG_" + _debugMode.ToString());

        if (screenResCur.x != Camera.current.scaledPixelWidth || screenResCur.y != Camera.current.scaledPixelHeight)
        {

            _halfRes = new RenderTexture(Camera.current.scaledPixelWidth, Camera.current.scaledPixelHeight, 0, RenderTextureFormat.ARGBFloat)
            {
                filterMode = FilterMode.Bilinear
            };

            _denoise = new RenderTexture(Camera.current.scaledPixelWidth, Camera.current.scaledPixelHeight, 0, RenderTextureFormat.ARGBFloat)
            {
                filterMode = FilterMode.Bilinear
            };

            //_downSamplingTex = new RenderTexture(Camera.current.scaledPixelWidth / 2, Camera.current.scaledPixelHeight / 2, 0, RenderTextureFormat.ARGBFloat)
            //{
            //    filterMode = FilterMode.Bilinear,
            //};

            screenResCur.x = Camera.current.scaledPixelWidth;
            screenResCur.y = Camera.current.scaledPixelHeight;
        }

        _material.SetFloat("_power", _power);
        _material.SetFloat("_lightContribution", _lightContribution);
        _material.SetTexture("_Noise", _noise);
        _material.SetInt("_resolution", res);


        Graphics.Blit(source, _halfRes, _material, 0);

        // blur vertical
        _material.SetVector("_DenoiseAngle", new Vector2(0, 1));
        Graphics.Blit(_halfRes, _denoise, _material, 1);
        // blur horizontal
        _material.SetVector("_DenoiseAngle", new Vector2(1, 0));
        Graphics.Blit(_denoise, _halfRes, _material, 1);

        // blur vertical 
        _material.SetVector("_DenoiseAngle", new Vector2(0, 1));
        Graphics.Blit(_halfRes, _denoise, _material, 1);
        //blur horizontal
        _material.SetVector("_DenoiseAngle", new Vector2(1, 0));
        Graphics.Blit(_denoise, _halfRes, _material, 1);

        //Upscaling    
        _material.SetTexture("_HalfRes", _halfRes);
        Graphics.Blit(source, destination, _material, 2);
    }

    #endregion
}
