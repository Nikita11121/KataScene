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
        [SerializeField] private Renderer[] renderers;
        [SerializeField] private Material mat;
        [SerializeField] private Texture2D mainTex;
        [SerializeField] private Texture2D occlusionTex;
        [SerializeField] private Texture2D normalMap;
        [SerializeField] private Texture2D subdermisMap;
        [SerializeField] private Texture2D specularMap;
        [SerializeField] private Texture2D translucencyMap;

        private Texture2D _albedo;
        private Texture2D _albedo2;

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
                    if (occlusionTex != null)
                        oclusionCol = occlusionTex.GetPixel(x * occlusionTex.width / mainTex.width, y * occlusionTex.height / mainTex.height);

                    Color subdermisCol = Color.black;
                    if (subdermisMap != null)
                        subdermisCol = subdermisMap.GetPixel(x * subdermisMap.width / mainTex.width, y * subdermisMap.height / mainTex.height);

                    Color outCol = mainCol * oclusionCol * color * (Color.white * 0.75f + subdermisCol / 4); //* Color.white/**/;
                    if (translucencyMap != null)
                        outCol.a = translucencyMap.GetPixel(x * translucencyMap.width / mainTex.width, y * translucencyMap.height / mainTex.height).r;
                    _albedo.SetPixel(x, y, outCol);
                }
            }
            _albedo.Apply();
            mat.mainTexture = _albedo;


            if (_albedo2 != null && _albedo2)
                DestroyImmediate(_albedo2);
            _albedo2 = new Texture2D(mainTex.width, mainTex.height);
            for (int x = 0; x < mainTex.width; x++)
            {
                for (int y = 0; y < mainTex.height; y++)
                {
                    Color outCol = Color.black;
                    if (specularMap != null)
                        outCol = specularMap.GetPixel(x * specularMap.width / mainTex.width, y * specularMap.height / mainTex.height);
                    _albedo2.SetPixel(x, y, outCol);
                }
            }
            _albedo2.Apply();
            mat.SetTexture("_SpecularTex", _albedo2);

            for (int i = 0; i < renderers.Length; i++)
                renderers[i].material = mat;
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
