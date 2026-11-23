using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using Vuforia;

/// <summary>Builds the AR lab scene, configures import/player settings and produces the Android APK.</summary>
public static class SceneBuilder
{
    const string ScenePath = "Assets/Scenes/Main.unity";
    const string TexturesDir = "Assets/Textures";
    const string ModelsDir = "Assets/Models/RobotKyle";
    const string StonesPath = "Assets/Textures/stones.png";
    const string Uah100Path = "Assets/Textures/uah100.jpg";
    const string Uah1000Path = "Assets/Textures/uah1000.jpg";

    static string ProjectRoot => Path.GetDirectoryName(Application.dataPath);

    static T LoadOrWarn<T>(string path) where T : Object
    {
        var a = AssetDatabase.LoadAssetAtPath<T>(path);
        if (a == null) Debug.LogWarning($"SceneBuilder: asset not found, skipping: {path}");
        return a;
    }

    [MenuItem("AR Lab/Build Scene")]
    public static void BuildScene()
    {
        Directory.CreateDirectory("Assets/Scenes");
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        // Camera
        var camGo = new GameObject("ARCamera") { tag = "MainCamera" };
        var cam = camGo.AddComponent<Camera>();
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Color.black;
        cam.nearClipPlane = 0.01f;
        cam.farClipPlane = 100f;
        camGo.AddComponent<AudioListener>();
        camGo.AddComponent<VuforiaBehaviour>();
        camGo.AddComponent<DefaultInitializationErrorHandler>();

        // Light
        var lightGo = new GameObject("Directional Light");
        var light = lightGo.AddComponent<Light>();
        light.type = LightType.Directional;
        lightGo.transform.rotation = Quaternion.Euler(50f, -30f, 0f);

        // Targets
        var targetsGo = new GameObject("Targets");
        var rt = targetsGo.AddComponent<RuntimeTargets>();

        var stones = LoadOrWarn<Texture2D>(StonesPath);
        if (stones != null)
        {
            var entry = new RuntimeTargets.TargetEntry { name = "stones", marker = stones, widthMeters = 0.2f };
            entry.contentPrefab = FindRobotPrefab();
            if (entry.contentPrefab == null)
            {
                Debug.LogWarning("SceneBuilder: Robot Kyle prefab not found, using placeholder cube.");
                entry.contentPrefab = MakePlaceholderCube();
            }
            rt.targets.Add(entry);
        }

        var uah100 = LoadOrWarn<Texture2D>(Uah100Path);
        var uah1000 = LoadOrWarn<Texture2D>(Uah1000Path);
        if (uah100 != null && uah1000 != null)
        {
            rt.targets.Add(new RuntimeTargets.TargetEntry
            {
                name = "uah100", marker = uah100, widthMeters = 0.15f, overlayTexture = uah1000,
                overlayMaterial = GetOrCreateOverlayMaterial(uah1000)
            });
        }
        else Debug.LogWarning("SceneBuilder: uah100/uah1000 target skipped (texture missing).");

        EditorSceneManager.SaveScene(scene, ScenePath);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        Debug.Log($"SceneBuilder: scene saved, {rt.targets.Count} target(s).");
    }

    static Material GetOrCreateOverlayMaterial(Texture2D tex)
    {
        const string path = "Assets/Materials/Overlay_uah1000.mat";
        var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (mat == null)
        {
            Directory.CreateDirectory("Assets/Materials");
            mat = new Material(Shader.Find("Unlit/Texture"));
            AssetDatabase.CreateAsset(mat, path);
        }
        mat.mainTexture = tex;
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
        return mat;
    }

    static GameObject FindRobotPrefab()
    {
        if (!AssetDatabase.IsValidFolder(ModelsDir)) return null;
        var guids = AssetDatabase.FindAssets("t:Prefab", new[] { ModelsDir });
        if (guids.Length > 0)
            return AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(guids[0]));
        // Fallback: a model file (fbx) usable as a prefab source
        guids = AssetDatabase.FindAssets("t:Model", new[] { ModelsDir });
        if (guids.Length > 0)
            return AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(guids[0]));
        return null;
    }

    static GameObject MakePlaceholderCube()
    {
        const string path = "Assets/Models/PlaceholderCube.prefab";
        Directory.CreateDirectory("Assets/Models");
        var cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.name = "PlaceholderCube";
        Object.DestroyImmediate(cube.GetComponent<Collider>());
        var prefab = PrefabUtility.SaveAsPrefabAsset(cube, path);
        Object.DestroyImmediate(cube);
        return prefab;
    }

    public static void ConfigureTextures()
    {
        if (!AssetDatabase.IsValidFolder(TexturesDir)) { Debug.LogWarning("SceneBuilder: Assets/Textures missing."); return; }
        foreach (var guid in AssetDatabase.FindAssets("t:Texture2D", new[] { TexturesDir }))
        {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            var imp = AssetImporter.GetAtPath(path) as TextureImporter;
            if (imp == null) continue;
            imp.isReadable = true;
            imp.textureCompression = TextureImporterCompression.Uncompressed;
            imp.npotScale = TextureImporterNPOTScale.None;
            imp.maxTextureSize = 2048;
            imp.mipmapEnabled = false;
            var def = imp.GetDefaultPlatformTextureSettings();
            def.format = TextureImporterFormat.RGBA32;
            def.maxTextureSize = 2048;
            def.textureCompression = TextureImporterCompression.Uncompressed;
            imp.SetPlatformTextureSettings(def);
            var android = imp.GetPlatformTextureSettings("Android");
            android.overridden = true;
            android.format = TextureImporterFormat.RGBA32;
            android.maxTextureSize = 2048;
            android.textureCompression = TextureImporterCompression.Uncompressed;
            imp.SetPlatformTextureSettings(android);
            imp.SaveAndReimport();
            Debug.Log($"SceneBuilder: texture configured: {path}");
        }
    }

    static string FindLicenseFile()
    {
        var dir = ProjectRoot;
        for (int i = 0; i <= 4 && !string.IsNullOrEmpty(dir); i++)
        {
            var candidate = Path.Combine(dir, "vuforia_license.txt");
            if (File.Exists(candidate)) return candidate;
            dir = Path.GetDirectoryName(dir);
        }
        return null;
    }

    public static void ConfigurePlayer()
    {
        PlayerSettings.companyName = "Lab";
        PlayerSettings.productName = "AR Lab1";
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.lab.arlab1");
        PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
        PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
        PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { GraphicsDeviceType.OpenGLES3 });
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;

        Directory.CreateDirectory("Assets/Resources"); // Vuforia build tasks write generated files here
        var licensePath = FindLicenseFile();
        var cfg = VuforiaConfiguration.Instance;
        if (cfg == null) { Debug.LogWarning("SceneBuilder: VuforiaConfiguration.Instance is null."); return; }
        if (licensePath != null)
        {
            cfg.Vuforia.LicenseKey = File.ReadAllText(licensePath).Trim();
            Debug.Log("SceneBuilder: license key loaded from " + licensePath); // never log the key itself
        }
        else
            Debug.LogWarning("SceneBuilder: vuforia_license.txt not found (searched project root and 4 parent dirs); license key not set (Vuforia will report a license error at runtime).");
        cfg.Vuforia.MaxSimultaneousImageTargets = 2;
        cfg.PlayMode.PlayModeType = PlayModeType.WEBCAM;
        const string cfgPath = "Assets/Resources/VuforiaConfiguration.asset";
        if (!AssetDatabase.Contains(cfg))
        {
            // Instance may be an unsaved in-memory object; persist it so the player build picks it up.
            AssetDatabase.CreateAsset(cfg, cfgPath);
            Debug.Log("SceneBuilder: created " + cfgPath);
        }
        EditorUtility.SetDirty(cfg);
        AssetDatabase.SaveAssets();
    }

    public static void BuildAll()
    {
        try
        {
            ConfigureTextures();
            ConfigurePlayer();
            BuildScene();

            var outPath = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "build", "AR_Lab1.apk"));
            Directory.CreateDirectory(Path.GetDirectoryName(outPath));
            var opts = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = outPath,
                target = BuildTarget.Android,
                targetGroup = BuildTargetGroup.Android,
                options = BuildOptions.None
            };
            var report = BuildPipeline.BuildPlayer(opts);
            Debug.Log($"SceneBuilder: build result {report.summary.result}, size {report.summary.totalSize}, path {outPath}");
            if (report.summary.result != BuildResult.Succeeded)
                EditorApplication.Exit(1);
        }
        catch (System.Exception e)
        {
            Debug.LogError("SceneBuilder: BuildAll failed: " + e);
            EditorApplication.Exit(1);
        }
    }
}
