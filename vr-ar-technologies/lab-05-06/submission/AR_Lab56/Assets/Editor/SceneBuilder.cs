using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using Vuforia;

/// <summary>Builds the Ground Plane and Mid Air AR scenes, configures player settings and produces two Android APKs.</summary>
public static class SceneBuilder
{
    const string GroundScenePath = "Assets/Scenes/GroundPlane.unity";
    const string MidAirScenePath = "Assets/Scenes/MidAir.unity";
    const string MatDir = "Assets/Materials";

    static string ProjectRoot => Path.GetDirectoryName(Application.dataPath);

    // ---------------------------------------------------------------- common

    static GameObject CreateCameraAndLight()
    {
        var camGo = new GameObject("ARCamera") { tag = "MainCamera" };
        var cam = camGo.AddComponent<Camera>();
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Color.black;
        cam.nearClipPlane = 0.01f;
        cam.farClipPlane = 100f;
        camGo.AddComponent<AudioListener>();
        camGo.AddComponent<VuforiaBehaviour>();
        camGo.AddComponent<DefaultInitializationErrorHandler>();
        camGo.AddComponent<QuitApp>();

        var lightGo = new GameObject("Directional Light");
        var light = lightGo.AddComponent<Light>();
        light.type = LightType.Directional;
        lightGo.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
        return camGo;
    }

    /// <summary>Runs a Vuforia menu item and returns the newly created component of type T.</summary>
    static T CreateViaMenu<T>(string menuPath) where T : Component
    {
        var before = new System.Collections.Generic.HashSet<Object>(Object.FindObjectsByType<T>(FindObjectsSortMode.None));
        if (!EditorApplication.ExecuteMenuItem(menuPath))
            throw new System.Exception("Menu item not available: " + menuPath);
        T result = null;
        foreach (var c in Object.FindObjectsByType<T>(FindObjectsSortMode.None))
            if (!before.Contains(c)) result = c;
        if (result == null) throw new System.Exception("Component " + typeof(T).Name + " was not created by " + menuPath);
        Debug.Log($"SceneBuilder: created {typeof(T).Name} on '{result.gameObject.name}' via {menuPath}");
        return result;
    }

    /// <summary>Sets ContentPositioningBehaviour.AnchorStage / DuplicateStage (names verified against the package).</summary>
    static void ConfigurePositioning(GameObject positioner, GameObject stage, bool duplicate)
    {
        var cpb = positioner.GetComponent<ContentPositioningBehaviour>();
        if (cpb == null) throw new System.Exception("ContentPositioningBehaviour missing on " + positioner.name);
        cpb.AnchorStage = stage.GetComponent<AnchorBehaviour>();
        cpb.DuplicateStage = duplicate;
        EditorUtility.SetDirty(cpb);
        Debug.Log($"SceneBuilder: {positioner.name} AnchorStage={cpb.AnchorStage?.name} DuplicateStage={cpb.DuplicateStage}");
    }

    // ---------------------------------------------------------------- primitives / models

    static Material Mat(string name, Color color)
    {
        Directory.CreateDirectory(MatDir);
        var path = $"{MatDir}/{name}.mat";
        var m = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (m == null)
        {
            m = new Material(Shader.Find("Standard")) { color = color };
            AssetDatabase.CreateAsset(m, path);
        }
        return m;
    }

    static GameObject Prim(PrimitiveType type, string name, Transform parent, Vector3 pos, Vector3 scale, Vector3 euler, Material mat)
    {
        var g = GameObject.CreatePrimitive(type);
        g.name = name;
        Object.DestroyImmediate(g.GetComponent<Collider>());
        g.transform.SetParent(parent, false);
        g.transform.localPosition = pos;
        g.transform.localScale = scale;
        g.transform.localEulerAngles = euler;
        g.GetComponent<Renderer>().sharedMaterial = mat;
        return g;
    }

    /// <summary>Low-poly race car (~0.25 m long, +X forward), wheels touch y=0.</summary>
    static GameObject BuildRaceCar(Transform parent)
    {
        var red = Mat("CarRed", new Color(0.85f, 0.1f, 0.1f));
        var dark = Mat("CarDark", new Color(0.1f, 0.1f, 0.12f));
        var glass = Mat("CarGlass", new Color(0.6f, 0.8f, 0.95f));
        var root = new GameObject("RaceCar");
        root.transform.SetParent(parent, false);
        var t = root.transform;
        Prim(PrimitiveType.Cube, "Body", t, new Vector3(0, 0.05f, 0), new Vector3(0.25f, 0.04f, 0.1f), Vector3.zero, red);
        Prim(PrimitiveType.Cube, "Cabin", t, new Vector3(-0.02f, 0.088f, 0), new Vector3(0.1f, 0.035f, 0.08f), Vector3.zero, glass);
        Prim(PrimitiveType.Cube, "Spoiler", t, new Vector3(-0.115f, 0.085f, 0), new Vector3(0.02f, 0.01f, 0.11f), Vector3.zero, dark);
        float r = 0.03f;
        foreach (var x in new[] { -0.075f, 0.075f })
            foreach (var z in new[] { -0.058f, 0.058f })
                Prim(PrimitiveType.Cylinder, $"Wheel_{x:+0.0;-0.0}_{z:+0.0;-0.0}", t, new Vector3(x, r, z), new Vector3(2 * r, 0.0125f, 2 * r), new Vector3(90, 0, 0), dark);
        return root;
    }

    /// <summary>Low-poly aircraft (~0.4 m long, nose along +Z); returns the root. Propeller spins around local Z.</summary>
    static GameObject BuildAircraft(Transform parent)
    {
        var body = Mat("PlaneBody", new Color(0.9f, 0.9f, 0.92f));
        var accent = Mat("PlaneAccent", new Color(0.15f, 0.35f, 0.85f));
        var dark = Mat("PlaneDark", new Color(0.12f, 0.12f, 0.12f));
        var root = new GameObject("LowPolyAircraft");
        root.transform.SetParent(parent, false);
        var t = root.transform;
        Prim(PrimitiveType.Capsule, "Fuselage", t, Vector3.zero, new Vector3(0.08f, 0.2f, 0.08f), new Vector3(90, 0, 0), body);
        Prim(PrimitiveType.Cube, "Wings", t, new Vector3(0, 0, 0.03f), new Vector3(0.5f, 0.01f, 0.1f), Vector3.zero, accent);
        Prim(PrimitiveType.Cube, "TailWing", t, new Vector3(0, 0.005f, -0.17f), new Vector3(0.18f, 0.01f, 0.06f), Vector3.zero, accent);
        Prim(PrimitiveType.Cube, "Fin", t, new Vector3(0, 0.04f, -0.17f), new Vector3(0.01f, 0.08f, 0.07f), Vector3.zero, accent);
        Prim(PrimitiveType.Sphere, "Cockpit", t, new Vector3(0, 0.04f, 0.05f), new Vector3(0.06f, 0.04f, 0.1f), Vector3.zero, dark);
        Prim(PrimitiveType.Sphere, "Spinner", t, new Vector3(0, 0, 0.215f), new Vector3(0.03f, 0.03f, 0.03f), Vector3.zero, dark);
        var prop = Prim(PrimitiveType.Cube, "Propeller", t, new Vector3(0, 0, 0.23f), new Vector3(0.22f, 0.02f, 0.006f), Vector3.zero, dark);
        var rot = prop.AddComponent<RotateScript>();
        rot.axis = Vector3.forward; // longitudinal axis of the aircraft (local Z of the propeller)
        rot.speed = 720f;
        return root;
    }

    // ---------------------------------------------------------------- scenes

    [MenuItem("AR Lab/Build Ground Plane Scene")]
    public static void BuildGroundPlane()
    {
        Directory.CreateDirectory("Assets/Scenes");
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        CreateCameraAndLight();

        var finder = CreateViaMenu<PlaneFinderBehaviour>("GameObject/Vuforia Engine/Ground Plane/Plane Finder");
        var stage = CreateViaMenu<AnchorBehaviour>("GameObject/Vuforia Engine/Ground Plane/Ground Plane Stage");
        ConfigurePositioning(finder.gameObject, stage.gameObject, true);

        BuildRaceCar(stage.transform);

        EditorSceneManager.SaveScene(scene, GroundScenePath);
        Debug.Log("SceneBuilder: scene saved " + GroundScenePath);
    }

    [MenuItem("AR Lab/Build Mid Air Scene")]
    public static void BuildMidAir()
    {
        Directory.CreateDirectory("Assets/Scenes");
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        CreateCameraAndLight();

        var positioner = CreateViaMenu<MidAirPositionerBehaviour>("GameObject/Vuforia Engine/Mid Air/Mid Air Positioner");
        var stage = CreateViaMenu<AnchorBehaviour>("GameObject/Vuforia Engine/Mid Air/Mid Air Stage");
        ConfigurePositioning(positioner.gameObject, stage.gameObject, false);

        BuildAircraft(stage.transform);

        EditorSceneManager.SaveScene(scene, MidAirScenePath);
        Debug.Log("SceneBuilder: scene saved " + MidAirScenePath);
    }

    // ---------------------------------------------------------------- settings / build

    static string FindLicenseFile()
    {
        var dir = ProjectRoot;
        for (int i = 0; i <= 5 && !string.IsNullOrEmpty(dir); i++)
        {
            var candidate = Path.Combine(dir, "vuforia_license.txt");
            if (File.Exists(candidate)) return candidate;
            dir = Path.GetDirectoryName(dir);
        }
        return null;
    }

    public static void ConfigurePlayer(string productName, string appId)
    {
        PlayerSettings.companyName = "Lab";
        PlayerSettings.productName = productName;
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, appId);
        PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel30;
        PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
        PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
        PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { GraphicsDeviceType.OpenGLES3 });
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;

        Directory.CreateDirectory("Assets/Resources");
        var licensePath = FindLicenseFile();
        var cfg = VuforiaConfiguration.Instance;
        if (cfg == null) { Debug.LogWarning("SceneBuilder: VuforiaConfiguration.Instance is null."); return; }
        if (licensePath != null)
        {
            cfg.Vuforia.LicenseKey = File.ReadAllText(licensePath).Trim();
            Debug.Log("SceneBuilder: license key loaded from " + licensePath); // never log the key itself
        }
        else
            Debug.LogWarning("SceneBuilder: vuforia_license.txt not found; license key not set.");
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

    static void BuildOne(string scenePath, string apkName, string productName, string appId)
    {
        ConfigurePlayer(productName, appId);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(scenePath, true) };
        var outPath = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "build", apkName));
        Directory.CreateDirectory(Path.GetDirectoryName(outPath));
        var opts = new BuildPlayerOptions
        {
            scenes = new[] { scenePath },
            locationPathName = outPath,
            target = BuildTarget.Android,
            targetGroup = BuildTargetGroup.Android,
            options = BuildOptions.None
        };
        var report = BuildPipeline.BuildPlayer(opts);
        Debug.Log($"SceneBuilder: build result {report.summary.result}, size {report.summary.totalSize}, path {outPath}");
        if (report.summary.result != BuildResult.Succeeded)
            throw new System.Exception("Build failed for " + apkName);
    }

    /// <summary>Builds only the scene and settings (no APK), for Play Mode testing. scene = "ground" or "midair".</summary>
    public static void PrepareOnly()
    {
        try
        {
            string scene = "ground";
            var args = System.Environment.GetCommandLineArgs();
            for (int i = 0; i < args.Length - 1; i++) if (args[i] == "-scene") scene = args[i + 1];
            if (scene == "midair") { ConfigurePlayer("AR Lab6 MidAir", "com.lab.arlab6"); BuildMidAir(); }
            else { ConfigurePlayer("AR Lab5 GroundPlane", "com.lab.arlab5"); BuildGroundPlane(); }
        }
        catch (System.Exception e) { Debug.LogError("SceneBuilder: PrepareOnly failed: " + e); EditorApplication.Exit(1); }
    }

    public static void BuildAll()
    {
        try
        {
            ConfigurePlayer("AR Lab5 GroundPlane", "com.lab.arlab5");
            BuildGroundPlane();
            BuildMidAir();
            BuildOne(GroundScenePath, "AR_Lab5_GroundPlane.apk", "AR Lab5 GroundPlane", "com.lab.arlab5");
            BuildOne(MidAirScenePath, "AR_Lab6_MidAir.apk", "AR Lab6 MidAir", "com.lab.arlab6");
        }
        catch (System.Exception e)
        {
            Debug.LogError("SceneBuilder: BuildAll failed: " + e);
            EditorApplication.Exit(1);
        }
    }
}
