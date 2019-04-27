using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Rendering/Deferred AO")]
public class RMAO : MonoBehaviour
{
    #region Public Properties

    [SerializeField]
    public enum Quality { Low, Middle, Hight, Ultra };
    [SerializeField]
    Quality _quality = Quality.Middle;
    public Quality quality
    {
        get { return _quality; }
        set { _quality = value; }
    }

    [Range(1.0f, 100.0f)]
    public float _scale = 1.0f;
    public float scale
    {
        get { return _scale; }
        set { _scale = value; }
    }

    [Range(1.0f, 3f)]
    public float _attenuation = 2.0f;
    public float attenuation
    {
        get { return _attenuation; }
        set { _attenuation = value; }
    }

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
    bool _bounceApproximation = false;
    public bool bounceApproximation
    {
        get { return _bounceApproximation; }
        set { _bounceApproximation = value; }
    }

    [SerializeField]
    public enum DownSampling { Full, Half, Quarter };
    [SerializeField]
    DownSampling _downSampling = DownSampling.Full;
    public DownSampling downSampling
    {
        get { return _downSampling; }
        set { _downSampling = value; }
    }

    [SerializeField]
    public enum DebugMode { None, Lighting, AO, Bounce };
    [SerializeField]
    DebugMode _debugMode = DebugMode.None;
    public DebugMode debugMode
    {
        get { return _debugMode; }
        set { _debugMode = value; }
    }

    #endregion

    #region Private Resources

    RenderTexture _halfRes, _denoise, _screenColor, _downSamplingTex, _downSamplingNormalDepth;
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

    private void Update()
    {
       
    }

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

        if (_quality == Quality.Low)
            samplesCount = 4;
        else if (_quality == Quality.Middle)
            samplesCount = 6;
        else if (_quality == Quality.Hight)
            samplesCount = 8;
        else if (_quality == Quality.Ultra)
            samplesCount = 10;

        if (_downSampling == DownSampling.Full)
            res = 1;
        else if (_downSampling == DownSampling.Half)
            res = 2;
        else if (_downSampling == DownSampling.Quarter)
            res = 4;

        

        _material.shaderKeywords = null;

        _material.EnableKeyword("_DEBUG_" + _debugMode.ToString());
        _material.EnableKeyword("_BOUNCE_" + _bounceApproximation.ToString());
        _material.EnableKeyword("_DEBUG_" + _debugMode.ToString());
        _material.EnableKeyword("_DOWNSAMPLING_" + _downSampling.ToString());

        if (screenResCur.x != Camera.current.scaledPixelWidth || screenResCur.y != Camera.current.scaledPixelHeight || curRes != res)
        {

            _halfRes = new RenderTexture(Camera.current.scaledPixelWidth, Camera.current.scaledPixelHeight, 0, RenderTextureFormat.ARGBFloat)
            {
                filterMode = FilterMode.Bilinear
            };

            _denoise = new RenderTexture(Camera.current.scaledPixelWidth, Camera.current.scaledPixelHeight, 0, RenderTextureFormat.ARGBFloat)
            {
                filterMode = FilterMode.Bilinear
            };

            //Get scene Color in low resolution
            if (_bounceApproximation)
            {
                _screenColor = new RenderTexture(256, 128, 0, RenderTextureFormat.ARGBFloat)
                {
                    filterMode = FilterMode.Bilinear,
                    useMipMap = true, 
                    autoGenerateMips = true,
                    wrapMode = TextureWrapMode.Clamp
                };
            }

            if (_downSampling != DownSampling.Full)
            {
                _downSamplingTex = new RenderTexture(Camera.current.scaledPixelWidth / res, Camera.current.scaledPixelHeight / res, 0, RenderTextureFormat.ARGBFloat)
                {
                    filterMode = FilterMode.Point,
                };
                _downSamplingNormalDepth = new RenderTexture(Camera.current.scaledPixelWidth / res, Camera.current.scaledPixelHeight / res, 0, RenderTextureFormat.ARGBFloat)
                {
                    filterMode = FilterMode.Point,
                };
                curRes = res;
            }
            else
            {
                _downSamplingTex = null;
                curRes = res;
            }

            screenResCur.x = Camera.current.scaledPixelWidth;
            screenResCur.y = Camera.current.scaledPixelHeight;
        }

        _material.SetFloat("_samplesCount", samplesCount);
        _material.SetFloat("_scale", _scale);
        _material.SetFloat("_attenuation", _attenuation);
        _material.SetFloat("_power", _power);
        _material.SetFloat("_lightContribution", _lightContribution);
        _material.SetTexture("_Noise", _noise);
        _material.SetInt("_resolution", res);

        if (_bounceApproximation)
        {
            Graphics.Blit(source, _screenColor, _material, 4);
            _material.SetTexture("_screenColor", _screenColor);
        }

       // Calculate AO
        if (_downSampling == DownSampling.Full)
        {
            Graphics.Blit(source, _halfRes, _material, 0);
            // blur vertical
            _material.SetVector("_DenoiseAngle", new Vector2(0, 1));
            Graphics.Blit(_halfRes, _denoise, _material, 1);
        }
        else if (_downSampling == DownSampling.Half || _downSampling == DownSampling.Quarter)
        {
            Graphics.Blit(source, _downSamplingTex, _material, 0);
            // blur vertical
            _material.SetVector("_DenoiseAngle", new Vector2(0, 1));
            Graphics.Blit(_downSamplingTex, _denoise, _material, 1);
        }

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
