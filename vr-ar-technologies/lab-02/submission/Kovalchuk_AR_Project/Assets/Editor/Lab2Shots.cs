using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Editor-only helper for the lab report. Creating the file Temp/lab2shots.trigger starts a sequence:
/// select XR Origin / AR Session / Main Camera and capture the editor, enter Play Mode (XR Simulation)
/// and save Game view screenshots to ../media. The Unity window must be visible for editor captures.
/// </summary>
[InitializeOnLoad]
public static class Lab2Shots
{
    const string StepKey = "Lab2Shots.step";
    const string TimeKey = "Lab2Shots.time";
    const string ScenePath = "Assets/Scenes/AR Template Scene.unity";

    static Lab2Shots()
    {
        EditorApplication.update -= Tick;
        EditorApplication.update += Tick;
    }

    static string TriggerFile => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "Temp", "lab2shots.trigger"));

    static string MediaDir
    {
        get
        {
            var dir = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "media"));
            Directory.CreateDirectory(dir);
            return dir;
        }
    }

    static double Now => EditorApplication.timeSinceStartup;

    static void Tick()
    {
        int step = SessionState.GetInt(StepKey, 0);
        double since = Now - SessionState.GetFloat(TimeKey, 0f);

        switch (step)
        {
            case 0:
                if (File.Exists(TriggerFile)) { File.Delete(TriggerFile); Next(1); }
                break;
            case 1:
                if (EditorSceneManager.GetActiveScene().path != ScenePath)
                    EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
                Select("XR Origin (AR Rig)");
                Next(2);
                break;
            case 2 when since > 2:
                CaptureEditor("editor-xr-origin.png");
                Select("AR Session");
                Next(3);
                break;
            case 3 when since > 2:
                CaptureEditor("editor-ar-session.png");
                Select("Main Camera");
                Next(4);
                break;
            case 4 when since > 2:
                CaptureEditor("editor-main-camera.png");
                Next(5);
                EditorApplication.EnterPlaymode();
                break;
            case 5 when EditorApplication.isPlaying && since > 10:
                ScreenCapture.CaptureScreenshot(Path.Combine(MediaDir, "xr-simulation-game-1.png"));
                PressGreetingButton();
                Next(6);
                break;
            case 6 when since > 10:
                ScreenCapture.CaptureScreenshot(Path.Combine(MediaDir, "xr-simulation-game-2.png"));
                Next(7);
                break;
            case 7 when since > 2:
                CaptureEditor("xr-simulation-editor.png");
                Next(8);
                break;
            case 8 when since > 3:
                EditorApplication.ExitPlaymode();
                Debug.Log("[Lab2Shots] done");
                Next(0);
                break;
        }
    }

    static void Next(int step)
    {
        SessionState.SetInt(StepKey, step);
        SessionState.SetFloat(TimeKey, (float)Now);
    }

    static void Select(string name)
    {
        foreach (var t in Object.FindObjectsByType<Transform>(FindObjectsInactive.Include, FindObjectsSortMode.None))
        {
            if (t.name != name) continue;
            Selection.activeGameObject = t.gameObject;
            EditorGUIUtility.PingObject(t.gameObject);
            InternalEditorUtility.RepaintAllViews();
            return;
        }
        Debug.LogWarning("[Lab2Shots] not found: " + name);
    }

    static void PressGreetingButton()
    {
        foreach (var b in Object.FindObjectsByType<Button>(FindObjectsInactive.Include, FindObjectsSortMode.None))
        {
            var p = b.transform; string path = b.name;
            while (p.parent != null) { p = p.parent; path = p.name + "/" + path; }
            if (!path.Contains("Greeting")) continue;
            Debug.Log("[Lab2Shots] press " + path);
            b.onClick.Invoke();
            return;
        }
        Debug.LogWarning("[Lab2Shots] greeting button not found");
    }

    static void CaptureEditor(string file)
    {
        var r = EditorGUIUtility.GetMainWindowPosition();
        float ppp = EditorGUIUtility.pixelsPerPoint; // ReadScreenPixel: position in points, size in pixels
        int w = Mathf.RoundToInt(r.width * ppp), h = Mathf.RoundToInt(r.height * ppp);
        var colors = InternalEditorUtility.ReadScreenPixel(r.position, w, h);
        var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
        tex.SetPixels(colors);
        tex.Apply();
        File.WriteAllBytes(Path.Combine(MediaDir, file), tex.EncodeToPNG());
        Object.DestroyImmediate(tex);
        Debug.Log("[Lab2Shots] saved " + file);
    }
}
