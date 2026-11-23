using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using Vuforia;

/// <summary>Builds the Multi Target AR scene, configures player settings and produces the Android APK.</summary>
public static class SceneBuilder
{
    const string ScenePath = "Assets/Scenes/Main.unity";
    const string ModelsDir = "Assets/Models/RobotKyle";

    // Target Manager database (Assets/StreamingAssets/Vuforia/AR_VF_MultiDB.{dat,xml})
    const string DatabaseXml = "Vuforia/AR_VF_MultiDB.xml"; // relative to StreamingAssets
    const string TargetName = "marsbox";
    static readonly Vector3 BoxSize = new Vector3(0.12f, 0.16f, 0.06f); // width, height, length (m)
    const float ContentHeight = 0.07f; // m, height of the 3D content standing on top of the box

    static string ProjectRoot => Path.GetDirectoryName(Application.dataPath);

    [MenuItem("AR Lab/Build Scene")]
    public static void BuildScene()
    {
        Directory.CreateDirectory("Assets/Scenes");
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        // AR camera
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

        // Multi Target (same as GameObject > Vuforia Engine > Multi Target)
        var mtGo = CreateMultiTarget(TargetName, "MultiTarget", BoxSize);

        // Content: child of the Multi Target, standing on its top face
        var content = InstantiateContent();
        content.transform.SetParent(mtGo.transform, true);
        PlaceOnTop(content, mtGo, ContentHeight, BoxSize.y);

        // Show/hide content depending on tracking status
        mtGo.AddComponent<DefaultObserverEventHandler>();

        EditorSceneManager.SaveScene(scene, ScenePath);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        Debug.Log($"SceneBuilder: scene saved, multi target scale {mtGo.transform.localScale}.");
    }

    static GameObject CreateMultiTarget(string targetName, string objectName, Vector3 size)
    {
        var existing = new System.Collections.Generic.HashSet<UnityEngine.Object>();
        foreach (var e in Object.FindObjectsByType<MultiTargetBehaviour>(FindObjectsSortMode.None)) existing.Add(e);
        if (!EditorApplication.ExecuteMenuItem("GameObject/Vuforia Engine/Multi Target"))
            throw new System.Exception("Menu item GameObject/Vuforia Engine/Multi Target not available.");
        MultiTargetBehaviour beh = null;
        foreach (var c in Object.FindObjectsByType<MultiTargetBehaviour>(FindObjectsSortMode.None))
            if (!existing.Contains(c)) beh = c;
        if (beh == null) throw new System.Exception("MultiTargetBehaviour was not created.");

        // Inspector fields: Database + Target
        var so = new SerializedObject(beh);
        var it = so.GetIterator();
        var dump = new System.Text.StringBuilder("SceneBuilder: MultiTargetBehaviour props:");
        while (it.NextVisible(true)) dump.Append(' ').Append(it.propertyPath);
        Debug.Log(dump.ToString());
        so.FindProperty("mDataSetPath").stringValue = DatabaseXml;
        so.FindProperty("mTrackableName").stringValue = targetName;
        var init = so.FindProperty("mInitializedInEditor");
        if (init != null) init.boolValue = true;
        so.ApplyModifiedProperties();
        // SetSize is not supported for Multi Targets: the size comes from the database (0.12 x 0.16 x 0.06 m)
        Debug.Log($"SceneBuilder: multi target db={DatabaseXml} target={targetName} size={size} scale={beh.transform.localScale}");

        beh.gameObject.name = objectName;
        EditorUtility.SetDirty(beh);
        return beh.gameObject;
    }

    static GameObject InstantiateContent()
    {
        GameObject prefab = null;
        if (AssetDatabase.IsValidFolder(ModelsDir))
        {
            var guids = AssetDatabase.FindAssets("t:Model", new[] { ModelsDir });
            if (guids.Length > 0)
                prefab = AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(guids[0]));
        }
        if (prefab != null) return (GameObject)PrefabUtility.InstantiatePrefab(prefab);
        Debug.LogWarning("SceneBuilder: Robot Kyle not found, using a sphere.");
        var s = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        s.name = "Sphere";
        return s;
    }

    /// <summary>Scales the content to ContentHeight (world metres) and stands it on the top face of the cylinder.</summary>
    static void PlaceOnTop(GameObject content, GameObject target, float contentHeight, float sideLength)
    {
        var t = target.transform;
        content.transform.localRotation = Quaternion.identity;
        content.transform.localPosition = Vector3.zero;
        content.transform.localScale = Vector3.one;
        var b = WorldBounds(content);
        float k = contentHeight / Mathf.Max(b.size.y, 1e-4f);
        content.transform.localScale = Vector3.one * k;
        b = WorldBounds(content);
        float topWorldY = t.position.y + sideLength * 0.5f; // sideLength = box height here
        var cx = new Vector3(t.position.x - b.center.x, topWorldY - b.min.y, t.position.z - b.center.z);
        content.transform.position += cx;
        foreach (var c in content.GetComponentsInChildren<Collider>()) Object.DestroyImmediate(c);
    }

    static Bounds WorldBounds(GameObject go)
    {
        var rs = go.GetComponentsInChildren<Renderer>();
        if (rs.Length == 0) return new Bounds(go.transform.position, Vector3.one * 0.01f);
        var b = rs[0].bounds;
        foreach (var r in rs) b.Encapsulate(r.bounds);
        return b;
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
        PlayerSettings.productName = "AR Lab4";
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.lab.arlab4");
        PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel29;
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
            Debug.LogWarning("SceneBuilder: vuforia_license.txt not found; license key not set (Vuforia will report a license error at runtime).");
        cfg.Vuforia.MaxSimultaneousImageTargets = 1; // Multi Target counts as one target
        cfg.PlayMode.PlayModeType = PlayModeType.WEBCAM;
        const string cfgPath = "Assets/Resources/VuforiaConfiguration.asset";
        if (!AssetDatabase.Contains(cfg))
        {
            AssetDatabase.CreateAsset(cfg, cfgPath);
            Debug.Log("SceneBuilder: created " + cfgPath);
        }
        EditorUtility.SetDirty(cfg);
        AssetDatabase.SaveAssets();
    }

    /// <summary>Builds only the scene and settings (no APK), for Play Mode testing.</summary>
    public static void PrepareOnly()
    {
        try { ConfigurePlayer(); BuildScene(); }
        catch (System.Exception e) { Debug.LogError("SceneBuilder: PrepareOnly failed: " + e); EditorApplication.Exit(1); }
    }

    public static void BuildAll()
    {
        try
        {
            ConfigurePlayer();
            BuildScene();

            var outPath = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "build", "AR_Lab4.apk"));
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
