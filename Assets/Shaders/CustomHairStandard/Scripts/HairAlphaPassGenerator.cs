using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class HairAlphaPassGenerator : MonoBehaviour
{
    [SerializeField]
    private Renderer _targetHair;

    [SerializeField]
    private int[] _subMeshIndices;

    private Material[] _alphaPassMaterials;

    private Mesh _mesh;

    private CommandBuffer _commandBuffer;

    private HashSet<Camera> _cameras = new HashSet<Camera>();
    
    void OnEnable()
    {
        if (_commandBuffer != null)
        {
            return;
        }

        if (_targetHair == null)
        {
            return;
        }
        
        _alphaPassMaterials = _targetHair.sharedMaterials.Select(Instantiate).ToArray();

        foreach (var each in _alphaPassMaterials)
        {
            HairShaderUtility.SetupMaterialWithBlendMode(each, HairShaderUtility.BlendMode.Fade);
            each.EnableKeyword("_ALPHA_PASS");
        }
        
        _commandBuffer = new CommandBuffer();

        for (var i = 0; i < _subMeshIndices.Length; ++i)
        {
            _commandBuffer.DrawRenderer(_targetHair, _alphaPassMaterials[_subMeshIndices[i]], _subMeshIndices[i], 0);
        }
    }

    void OnRenderObject()
    {
        if (_commandBuffer == null)
        {
            return;
        }
        
        if (_cameras.Contains(Camera.current))
        {
            return;
        }

        _cameras.Add(Camera.current);
        
        Camera.current.AddCommandBuffer(CameraEvent.AfterForwardAlpha, _commandBuffer);
    }

    void OnDisable()
    {
        foreach (var each in _cameras)
        {
            if (each != null)
            {
                each.RemoveCommandBuffer(CameraEvent.AfterForwardAlpha, _commandBuffer);
            }
        }
        
        _cameras.Clear();
        
        _commandBuffer.Dispose();
        _commandBuffer = null;
    }

    void Start()
    {
        return;
        GatherMaterials();

        _mesh = _targetHair.GetComponent<MeshFilter>().sharedMesh;
    }

    void Update()
    {
        return;
        for (var i = 0; i < _subMeshIndices.Length; ++i)
        {
            var subMeshIndex = _subMeshIndices[i];
            Graphics.DrawMesh(_mesh, _targetHair.transform.localToWorldMatrix, _alphaPassMaterials[subMeshIndex], 0, Camera.current, subMeshIndex);
        }
    }

    private void GatherMaterials()
    {
        _alphaPassMaterials = _targetHair.sharedMaterials.Select(Instantiate).ToArray();

        foreach (var each in _alphaPassMaterials)
        {
            HairShaderUtility.SetupMaterialWithBlendMode(each, HairShaderUtility.BlendMode.Fade);
        }
    }
}