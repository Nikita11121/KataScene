using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AlchemistLab
{
    public class PostEffect : MonoBehaviour
    {
        [SerializeField] private Material mat;
        private void PassesMat(RenderTexture source, RenderTexture destination, Material mat)
        {
            Graphics.Blit(source, destination, mat);
        }
    }
}
