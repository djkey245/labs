using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>
/// Lab 2 helper: applies the Android settings required by the lab, names the AR template scene,
/// creates the manual AR scene (AR Session + XR Origin) and builds the APK in batchmode.
/// </summary>
public static class Lab2Builder
{
    const string TemplateScenePath = "Assets/Scenes/AR Template Scene.unity";
    const string OldSamplePath = "Assets/Scenes/SampleScene.unity";
    const string ManualScenePath = "Assets/Scenes/Manual AR Scene.unity";

    static string ProjectRoot => Path.GetDirectoryName(Application.dataPath);

    [MenuItem("AR Lab/1. Prepare (Android settings + scenes)")]
    public static void PrepareAll()
    {
        ConfigureAndroid();
        RenameTemplateScene();
        CreateManualScene();
        SetBuildScenes();
        AssetDatabase.SaveAssets();
        DumpHierarchy(TemplateScenePath, "hierarchy-template-scene.txt");
        DumpHierarchy(ManualScenePath, "hierarchy-manual-scene.txt");
        Debug.Log("[Lab2Builder] PrepareAll done");
    }

    static void ConfigureAndroid()
    {
        var android = UnityEditor.Build.NamedBuildTarget.Android;
        PlayerSettings.companyName = "Lab";
        PlayerSettings.productName = "Kovalchuk AR Project";
        PlayerSettings.SetApplicationIdentifier(android, "com.lab.arlab2");
        PlayerSettings.SetScriptingBackend(android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
        // ARCore does not need Vulkan; keep OpenGLES3 only (as in the lab manual).
        PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
        PlayerSettings.SetGraphicsAPIs(BuildTarget.Android,
            new[] { UnityEngine.Rendering.GraphicsDeviceType.OpenGLES3 });
        Debug.Log("[Lab2Builder] Android: IL2CPP, ARM64, minSdk 26, OpenGLES3, id com.lab.arlab2");
    }

    static void RenameTemplateScene()
    {
        if (File.Exists(Path.Combine(ProjectRoot, TemplateScenePath))) return;
        var err = AssetDatabase.MoveAsset(OldSamplePath, TemplateScenePath);
        Debug.Log("[Lab2Builder] rename SampleScene -> AR Template Scene: " + (string.IsNullOrEmpty(err) ? "ok" : err));
    }

    static void CreateManualScene()
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        bool s = EditorApplication.ExecuteMenuItem("GameObject/XR/AR Session");
        bool o = EditorApplication.ExecuteMenuItem("GameObject/XR/XR Origin (Mobile AR)");
        Debug.Log($"[Lab2Builder] menu AR Session={s}, XR Origin (Mobile AR)={o}, roots={scene.rootCount}");
        EditorSceneManager.SaveScene(scene, ManualScenePath);
    }

    static void SetBuildScenes()
    {
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(TemplateScenePath, true) };
    }

    static void DumpHierarchy(string scenePath, string fileName)
    {
        var scene = EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Single);
        var sb = new StringBuilder();
        sb.AppendLine("# " + scenePath);
        foreach (var root in scene.GetRootGameObjects()) Walk(root.transform, 0, sb);
        var dir = Path.Combine(ProjectRoot, "..", "..", "src");
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, fileName), sb.ToString());
    }

    static void Walk(Transform t, int depth, StringBuilder sb)
    {
        var comps = string.Join(", ", t.GetComponents<Component>()
            .Where(c => c != null && !(c is Transform) && !(c is RectTransform) && !(c is CanvasRenderer))
            .Select(c => c.GetType().Name));
        sb.AppendLine(new string(' ', depth * 2) + t.name + (comps.Length > 0 ? "  [" + comps + "]" : "") + (t.CompareTag("MainCamera") ? "  <MainCamera>" : ""));
        if (depth >= 3) return; // report needs only the top of the hierarchy
        foreach (Transform c in t) Walk(c, depth + 1, sb);
    }

    [MenuItem("AR Lab/2. Build Android APK")]
    public static void BuildApk()
    {
        var outDir = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "build"));
        Directory.CreateDirectory(outDir);
        var apk = Path.Combine(outDir, "Kovalchuk_AR_Project.apk");
        var opts = new BuildPlayerOptions
        {
            scenes = new[] { TemplateScenePath },
            locationPathName = apk,
            target = BuildTarget.Android,
            options = BuildOptions.None
        };
        var report = BuildPipeline.BuildPlayer(opts);
        Debug.Log($"[Lab2Builder] build result={report.summary.result}, size={report.summary.totalSize}, path={apk}");
        if (Application.isBatchMode)
            EditorApplication.Exit(report.summary.result == BuildResult.Succeeded ? 0 : 1);
    }
}
