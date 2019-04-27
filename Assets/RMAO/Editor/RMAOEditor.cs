using UnityEngine;
using UnityEditor;

[CanEditMultipleObjects]
[CustomEditor(typeof(RMAO))]
public class RMAOAOEditor : Editor
{
    SerializedProperty _power;
    SerializedProperty _lightContribution;
    SerializedProperty _debugMode;

    void OnEnable()
    {
        _power = serializedObject.FindProperty("_power");
        _lightContribution = serializedObject.FindProperty("_lightContribution");
        _debugMode = serializedObject.FindProperty("_debugMode");
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

            EditorGUILayout.PropertyField(_power);
            EditorGUILayout.PropertyField(_lightContribution);
            EditorGUILayout.PropertyField(_debugMode);
        }

        serializedObject.ApplyModifiedProperties();
    }
}
