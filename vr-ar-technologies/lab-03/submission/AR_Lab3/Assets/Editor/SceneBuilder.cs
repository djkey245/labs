using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using Vuforia;

/// <summary>Builds the Cylinder Target AR scene, configures player settings and produces the Android APK.</summary>
public static class SceneBuilder
{
    const string ScenePath = "Assets/Scenes/Main.unity";
    const string ModelsDir = "Assets/Models/RobotKyle";

    // Target Manager database (Assets/StreamingAssets/Vuforia/AR_VF_CylinderDB.{dat,xml})
    const string DatabaseXml = "Vuforia/AR_VF_CylinderDB.xml"; // relative to StreamingAssets
    const string TargetName = "cylinder_target";
    const float SideLength = 0.1f;       // m
    const float TopDiameter = 0.048f;    // m
    const float BottomDiameter = 0.048f; // m
    const float ContentHeight = 0.08f;   // m, height of the 3D content standing on top of the cylinder

    // Second target: can
    const string CanTargetName = "can_target";
    const float CanSideLength = 0.12f;     // m
    const float CanTopDiameter = 0.04f;    // m
    const float CanBottomDiameter = 0.04f; // m
    const float CanContentHeight = 0.07f;  // m

    // Third target: card
    const string CardTargetName = "card_target";
    const float CardSideLength = 0.18f;     // m
    const float CardTopDiameter = 0.04f;    // m
    const float CardBottomDiameter = 0.04f; // m
    const float CardContentHeight = 0.07f;  // m

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

        // Cylinder Target (same as GameObject > Vuforia Engine > Cylinder Target)
        var ctGo = CreateCylinderTarget(TargetName, "CylinderTarget", SideLength, TopDiameter, BottomDiameter);

        ctGo.transform.position = new Vector3(-0.3f, 0f, 0f); // X offset so targets do not overlap in the scene

        // Content
        var content = InstantiateContent();
        content.transform.SetParent(ctGo.transform, true);
        PlaceOnTop(content, ctGo, ContentHeight, SideLength);

        // Show/hide content depending on tracking status
        ctGo.AddComponent<DefaultObserverEventHandler>();

        // Second Cylinder Target: real can
        var canGo = CreateCylinderTarget(CanTargetName, "CanTarget", CanSideLength, CanTopDiameter, CanBottomDiameter);
        canGo.transform.position = new Vector3(0f, 0f, 0f);
        var canContent = InstantiateContent();
        canContent.transform.SetParent(canGo.transform, true);
        PlaceOnTop(canContent, canGo, CanContentHeight, CanSideLength);
        canGo.AddComponent<DefaultObserverEventHandler>();

        // Third Cylinder Target: card
        var cardGo = CreateCylinderTarget(CardTargetName, "CardTarget", CardSideLength, CardTopDiameter, CardBottomDiameter);
        cardGo.transform.position = new Vector3(0.3f, 0f, 0f);
        var cardContent = InstantiateContent();
        cardContent.transform.SetParent(cardGo.transform, true);
        PlaceOnTop(cardContent, cardGo, CardContentHeight, CardSideLength);
        cardGo.AddComponent<DefaultObserverEventHandler>();

        EditorSceneManager.SaveScene(scene, ScenePath);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        Debug.Log($"SceneBuilder: scene saved, cylinder target scale {ctGo.transform.localScale}.");
    }

    static GameObject CreateCylinderTarget(string targetName, string objectName, float sideLength, float topDiameter, float bottomDiameter)
    {
        var existing = new System.Collections.Generic.HashSet<UnityEngine.Object>();
        foreach (var e in Object.FindObjectsByType<CylinderTargetBehaviour>(FindObjectsSortMode.None)) existing.Add(e);
        if (!EditorApplication.ExecuteMenuItem("GameObject/Vuforia Engine/Cylinder Target"))
            throw new System.Exception("Menu item GameObject/Vuforia Engine/Cylinder Target not available.");
        CylinderTargetBehaviour beh = null;
        foreach (var c in Object.FindObjectsByType<CylinderTargetBehaviour>(FindObjectsSortMode.None))
            if (!existing.Contains(c)) beh = c;
        if (beh == null) throw new System.Exception("CylinderTargetBehaviour was not created.");

        // Inspector fields: Database + Target (serialized names verified via SerializedObject dump)
        var so = new SerializedObject(beh);
        so.FindProperty("mDataSetPath").stringValue = DatabaseXml;
        so.FindProperty("mTrackableName").stringValue = targetName;
        so.FindProperty("mInitializedInEditor").boolValue = true;
        so.FindProperty("mSideLength").floatValue = sideLength;
        so.FindProperty("mTopDiameter").floatValue = topDiameter;
        so.FindProperty("mBottomDiameter").floatValue = bottomDiameter;
        so.FindProperty("mTopDiameterRatio").floatValue = topDiameter / sideLength;
        so.FindProperty("mBottomDiameterRatio").floatValue = bottomDiameter / sideLength;
        so.ApplyModifiedProperties();

        // Apply the scale (= side length, as the Inspector does) through the internal setter.
        var setScale = typeof(CylinderTargetBehaviour).GetMethod("SetScale", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
        if (setScale != null) setScale.Invoke(beh, new object[] { sideLength });
        else beh.transform.localScale = Vector3.one * sideLength;
        Debug.Log($"SceneBuilder: cylinder target db={DatabaseXml} target={targetName} side={beh.SideLength} top={beh.TopDiameter} bottom={beh.BottomDiameter} scale={beh.transform.localScale}");

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
        float topWorldY = t.position.y + sideLength * 0.5f;
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
        PlayerSettings.productName = "AR Lab3";
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.lab.arlab3");
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
        cfg.Vuforia.MaxSimultaneousImageTargets = 3; // also bounds simultaneous cylinder targets
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

            var outPath = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "build", "AR_Lab3.apk"));
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
