using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Vuforia;

/// <summary>Opens Main scene, enters Play Mode, logs Vuforia target status and saves Game view screenshots, then exits.</summary>
[InitializeOnLoad]
public static class PlayTest
{
    const string Key = "PlayTest.active";
    static double start, lastLog, lastShot;
    static int shots;

    static PlayTest()
    {
        if (SessionState.GetBool(Key, false)) EditorApplication.update += Tick;
    }

    public static void Run()
    {
        SessionState.SetBool(Key, true);
        EditorSceneManager.OpenScene("Assets/Scenes/Main.unity");
        EditorApplication.EnterPlaymode();
    }

    static void Tick()
    {
        if (!Application.isPlaying) return;
        if (start == 0) { start = EditorApplication.timeSinceStartup; Debug.Log("[PlayTest] started"); }
        double t = EditorApplication.timeSinceStartup - start;
        if (t - lastLog > 2)
        {
            lastLog = t;
            foreach (var o in Object.FindObjectsByType<ObserverBehaviour>(FindObjectsSortMode.None))
                Debug.Log($"[PlayTest] t={t:F0}s {o.GetType().Name} '{o.TargetName}' status={o.TargetStatus.Status} info={o.TargetStatus.StatusInfo} scale={o.transform.localScale}");
            Debug.Log($"[PlayTest] webcam devices={WebCamTexture.devices.Length}");
        }
        if (t - lastShot > 4 && t > 6 && shots < 4)
        {
            lastShot = t; shots++;
            var dir = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "media"));
            Directory.CreateDirectory(dir);
            ScreenCapture.CaptureScreenshot(Path.Combine(dir, $"playtest-{shots}.png"));
        }
        if (t > 30)
        {
            SessionState.SetBool(Key, false);
            EditorApplication.Exit(0);
        }
    }
}
