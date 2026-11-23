using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using Vuforia;

/// <summary>
/// Editor-only helper for the lab report: in Play Mode saves Game view screenshots
/// to ../media while an cylinder target is tracked (up to 3 per target).
/// </summary>
[InitializeOnLoad]
public static class AutoShots
{
    const int MaxPerTarget = 3;
    const double MinInterval = 2.5;

    static readonly Dictionary<string, int> counts = new Dictionary<string, int>();
    static double lastShot;

    static AutoShots()
    {
        EditorApplication.update += Update;
    }

    static void Update()
    {
        if (!Application.isPlaying) return;
        if (EditorApplication.timeSinceStartup - lastShot < MinInterval) return;

        foreach (var obs in Object.FindObjectsByType<ObserverBehaviour>(FindObjectsSortMode.None))
        {
            if (obs is DevicePoseBehaviour) continue;
            if (obs.TargetStatus.Status != Status.TRACKED) continue;

            string name = obs.TargetName;
            counts.TryGetValue(name, out int n);
            if (n >= MaxPerTarget) continue;

            string dir = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "media"));
            Directory.CreateDirectory(dir);
            string file = Path.Combine(dir, $"play-{name}-{n + 1}.png");
            ScreenCapture.CaptureScreenshot(file);
            counts[name] = n + 1;
            lastShot = EditorApplication.timeSinceStartup;
            Debug.Log($"[AutoShots] saved {file}");
            return;
        }
    }
}
