using UnityEditor;
using UnityEngine;

/// <summary>Editor-only helper: asks macOS for webcam access so Vuforia Play Mode can use the camera.</summary>
public static class CameraAccess
{
    static double deadline;

    [MenuItem("AR Lab/Request Camera Access")]
    static void Request()
    {
        Application.RequestUserAuthorization(UserAuthorization.WebCam);
        deadline = EditorApplication.timeSinceStartup + 60;
        EditorApplication.update -= Poll;
        EditorApplication.update += Poll;
        Debug.Log("[CameraAccess] requested, waiting up to 60 s for the macOS answer...");
    }

    static void Poll()
    {
        bool ok = Application.HasUserAuthorization(UserAuthorization.WebCam);
        if (!ok && EditorApplication.timeSinceStartup < deadline) return;
        EditorApplication.update -= Poll;
        Debug.Log($"[CameraAccess] authorized={ok}, devices={WebCamTexture.devices.Length}");
    }
}
