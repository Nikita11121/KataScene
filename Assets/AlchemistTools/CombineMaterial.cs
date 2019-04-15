using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AlchemistLab
{
    [ExecuteAlways]
    public class CombineMaterial : MonoBehaviour
    {
        [SerializeField] private bool isRefresh = false;

        [SerializeField] private Color color;
        [SerializeField] private Material mat;
        [SerializeField] private Texture2D mainTex;
        [SerializeField] private Texture2D occlusionText;
        [SerializeField] private Texture2D normalMap;
        [SerializeField] private Texture2D subdermisMap;
        [SerializeField] private Texture2D specularMap;
        [SerializeField] private Texture2D translucencyMap;

        private Texture2D _albedo;

        void Refresh()
        {
            if (_albedo != null && _albedo)
                DestroyImmediate(_albedo);
            _albedo = new Texture2D(mainTex.width, mainTex.height);
            for (int x = 0; x < mainTex.width; x++)
            {
                for (int y = 0; y < mainTex.height; y++)
                {
                    Color mainCol = mainTex.GetPixel(x, y);
                    Color oclusionCol = Color.white;
                    if (occlusionText != null)
                        oclusionCol = occlusionText.GetPixel(x * occlusionText.width / mainTex.width, y * occlusionText.height / mainTex.height);
                    Color outCol = mainCol * oclusionCol * color;
                    _albedo.SetPixel(x, y, outCol);
                }
            }
            _albedo.Apply();
            mat.mainTexture = _albedo;
        }

        // Start is called before the first frame update
        void Start()
        {
            Refresh();
        }

        // Update is called once per frame
        void Update()
        {
            if (isRefresh)
            {
                isRefresh = false;
                Refresh();
            }
        }
    }
}
