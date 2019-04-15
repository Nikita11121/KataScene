using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AlchemistLab
{
    public class PostEffect : MonoBehaviour
    {
        [SerializeField] private Material mat;
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            Graphics.Blit(source, destination, mat);
        }
    }
}
