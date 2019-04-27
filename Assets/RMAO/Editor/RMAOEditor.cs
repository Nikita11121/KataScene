using UnityEngine;
using UnityEditor;

[CanEditMultipleObjects]
[CustomEditor(typeof(RMAO))]
public class RMAOAOEditor : Editor
{
    SerializedProperty _quality;
    SerializedProperty _scale;
    SerializedProperty _attenuation;
    SerializedProperty _power;
    SerializedProperty _lightContribution;
    SerializedProperty _bounceApproximation;
    SerializedProperty _downSampling;
    SerializedProperty _debugMode;

    void OnEnable()
    {
        _quality = serializedObject.FindProperty("_quality");
        _scale = serializedObject.FindProperty("_scale");
        _attenuation = serializedObject.FindProperty("_attenuation");
        _power = serializedObject.FindProperty("_power");
        _lightContribution = serializedObject.FindProperty("_lightContribution");
        _debugMode = serializedObject.FindProperty("_debugMode");
        _bounceApproximation = serializedObject.FindProperty("_bounceApproximation");
        _downSampling = serializedObject.FindProperty("_downSampling");
    }

    bool CheckDisabled()
    {
        var cam = ((RMAO)target).GetComponent<Camera>();
        return cam.actualRenderingPath != RenderingPath.DeferredShading;
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        if (CheckDisabled())
        {
            var text = "To enable the effect, change Rendering Path to Deferred.";
            EditorGUILayout.HelpBox(text, MessageType.Warning);
        }
        else
        {
            EditorGUILayout.PropertyField(_quality);
            EditorGUILayout.PropertyField(_scale);
            EditorGUILayout.PropertyField(_attenuation);
            EditorGUILayout.PropertyField(_power);
            EditorGUILayout.PropertyField(_lightContribution);
            EditorGUILayout.PropertyField(_bounceApproximation);
            EditorGUILayout.PropertyField(_downSampling);
            EditorGUILayout.PropertyField(_debugMode);
        }

        serializedObject.ApplyModifiedProperties();
    }
}
