using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.Events;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

/// <summary>
/// Lab 7: builds both face-filter scenes (Basic_Face_Filter, InteractiveFilter), the prefabs,
/// an editor-only test scene, and the two Android APKs. Batch entry point: FaceSceneBuilder.BuildAll.
/// </summary>
public static class FaceSceneBuilder
{
    const string BasicScenePath = "Assets/Scenes/Basic_Face_Filter.unity";
    const string InteractiveScenePath = "Assets/Scenes/InteractiveFilter.unity";
    const string TestScenePath = "Assets/Scenes/InteractiveFilter_EditorTest.unity";

    const string BasicPrefabPath = "Assets/_BasicFaceFilter/Prefabs/AR Default Face.prefab";
    const string GlassesPrefabPath = "Assets/_InteractiveFaceFilter/Prefabs/GlassesGroup.prefab";
    const string CanvasPrefabPath = "Assets/_InteractiveFaceFilter/Prefabs/AR_Canvas.prefab";
    const string FaceMatPath = "Assets/_BasicFaceFilter/Materials/Face Debug MAT.mat";
    const string MatDir = "Assets/_InteractiveFaceFilter/Materials";

    static readonly string[] GlassesMeshes =
    {
        "Assets/_InteractiveFaceFilter/Meshes/Glasses_Cat.FBX",
        "Assets/_InteractiveFaceFilter/Meshes/Glasses_Stars.FBX",
        "Assets/_InteractiveFaceFilter/Meshes/Glasses_Mask.FBX",
    };
    static readonly string[] Tags = { "cat", "stars", "mask" };
    static readonly string[] ColorNames = { "Glasses_Red", "Glasses_Blue", "Glasses_Yellow" };
    static readonly Color[] Colors =
    {
        new Color(0.90f, 0.20f, 0.22f), new Color(0.20f, 0.45f, 0.95f), new Color(0.98f, 0.80f, 0.15f),
    };

    static string ProjectRoot => Path.GetDirectoryName(Application.dataPath);

    // ---------------------------------------------------------------- settings

    static void ConfigureAndroid(string productName, string appId)
    {
        var android = UnityEditor.Build.NamedBuildTarget.Android;
        PlayerSettings.companyName = "Lab";
        PlayerSettings.productName = productName;
        PlayerSettings.SetApplicationIdentifier(android, appId);
        PlayerSettings.SetScriptingBackend(android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
        PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
        PlayerSettings.SetGraphicsAPIs(BuildTarget.Android,
            new[] { UnityEngine.Rendering.GraphicsDeviceType.OpenGLES3 });
        Debug.Log($"[FaceSceneBuilder] Android: {productName}, {appId}, IL2CPP, ARM64, minSdk 26, OpenGLES3");
    }

    static void EnsureTags()
    {
        foreach (var t in Tags)
            if (!UnityEditorInternal.InternalEditorUtility.tags.Contains(t))
                UnityEditorInternal.InternalEditorUtility.AddTag(t);
    }

    // ---------------------------------------------------------------- scene base

    /// <summary>Empty scene with AR Session, XR Origin (Mobile AR), Directional Light; ARFaceManager + front camera.</summary>
    static Scene NewFaceScene(out ARFaceManager faceManager)
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var lightGo = new GameObject("Directional Light");
        var light = lightGo.AddComponent<Light>();
        light.type = LightType.Directional;
        lightGo.transform.rotation = Quaternion.Euler(50, -30, 0);

        bool s = EditorApplication.ExecuteMenuItem("GameObject/XR/AR Session");
        bool o = EditorApplication.ExecuteMenuItem("GameObject/XR/XR Origin (Mobile AR)");
        Debug.Log($"[FaceSceneBuilder] menu AR Session={s}, XR Origin (Mobile AR)={o}");

        var origin = Object.FindAnyObjectByType<Unity.XR.CoreUtils.XROrigin>();
        if (origin == null) throw new System.Exception("XR Origin was not created");
        faceManager = origin.gameObject.GetComponent<ARFaceManager>()
                      ?? origin.gameObject.AddComponent<ARFaceManager>();

        var cam = origin.Camera;
        var camManager = cam.GetComponent<ARCameraManager>() ?? cam.gameObject.AddComponent<ARCameraManager>();
        camManager.requestedFacingDirection = CameraFacingDirection.User;
        EditorUtility.SetDirty(camManager);
        Debug.Log("[FaceSceneBuilder] ARCameraManager facing direction = User");

        // template-specific interaction/plane components are not needed for face tracking
        foreach (var go in origin.gameObject.GetComponents<MonoBehaviour>())
        {
            if (go is ARPlaneManager || go is ARRaycastManager || go is ARAnchorManager)
                Object.DestroyImmediate(go);
        }
        return scene;
    }

    static void DumpScene(Scene scene, string name)
    {
        var sb = new System.Text.StringBuilder("# " + name + "\n");
        void Walk(Transform t, int d)
        {
            var comps = string.Join(", ", t.GetComponents<Component>().Where(c => c != null && !(c is Transform))
                .Select(c => c.GetType().Name));
            sb.AppendLine(new string(' ', d * 2) + t.name + "  [" + comps + "]  tag=" + t.tag);
            foreach (Transform c in t) Walk(c, d + 1);
        }
        foreach (var r in scene.GetRootGameObjects()) Walk(r.transform, 0);
        var dir = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "..", "src"));
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, "hierarchy-" + name + ".txt"), sb.ToString());
    }

    // ---------------------------------------------------------------- task 1

    [MenuItem("AR Lab/Build Basic Scene")]
    public static void BuildBasic()
    {
        var scene = NewFaceScene(out var faceManager);

        bool ok = EditorApplication.ExecuteMenuItem("GameObject/XR/AR Default Face");
        var face = Object.FindAnyObjectByType<ARFace>();
        Debug.Log($"[FaceSceneBuilder] menu AR Default Face={ok}, found={(face != null)}");
        if (face == null) throw new System.Exception("AR Default Face was not created");
        face.gameObject.name = "AR Default Face";

        var mat = AssetDatabase.LoadAssetAtPath<Material>(FaceMatPath);
        foreach (var r in face.GetComponentsInChildren<Renderer>(true)) r.sharedMaterial = mat;

        Directory.CreateDirectory(Path.Combine(ProjectRoot, "Assets/_BasicFaceFilter/Prefabs"));
        var prefab = PrefabUtility.SaveAsPrefabAsset(face.gameObject, BasicPrefabPath);
        Object.DestroyImmediate(face.gameObject);

        faceManager.facePrefab = prefab;
        EditorUtility.SetDirty(faceManager);

        EditorSceneManager.SaveScene(scene, BasicScenePath);
        DumpScene(scene, "Basic_Face_Filter");
        Debug.Log("[FaceSceneBuilder] saved " + BasicScenePath);
    }

    // ---------------------------------------------------------------- task 2

    static Material[] CreateColorMaterials()
    {
        Directory.CreateDirectory(Path.Combine(ProjectRoot, MatDir));
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        var result = new Material[3];
        for (int i = 0; i < 3; i++)
        {
            string path = $"{MatDir}/{ColorNames[i]}.mat";
            var m = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (m == null)
            {
                m = new Material(shader);
                AssetDatabase.CreateAsset(m, path);
            }
            m.SetColor("_BaseColor", Colors[i]);
            m.color = Colors[i];
            EditorUtility.SetDirty(m);
            result[i] = m;
        }
        AssetDatabase.SaveAssets();
        return result;
    }

    static GameObject CreateGlassesGroupPrefab(Material[] colors)
    {
        var root = new GameObject("GlassesGroup");
        root.AddComponent<ARFace>();
        var ctrl = root.AddComponent<GlassesGroupController>();
        ctrl.colorMaterials = colors;
        for (int i = 0; i < GlassesMeshes.Length; i++)
        {
            var mesh = AssetDatabase.LoadAssetAtPath<GameObject>(GlassesMeshes[i]);
            var inst = (GameObject)PrefabUtility.InstantiatePrefab(mesh, root.transform);
            PrefabUtility.UnpackPrefabInstance(inst, PrefabUnpackMode.Completely, InteractionMode.AutomatedAction);
            inst.name = Path.GetFileNameWithoutExtension(GlassesMeshes[i]);
            inst.tag = Tags[i];
            inst.transform.localPosition = Vector3.zero;
            foreach (var r in inst.GetComponentsInChildren<Renderer>(true))
            {
                r.enabled = false; // shown only by GlassesGroupController
                var mats = r.sharedMaterials;
                for (int k = 0; k < mats.Length; k++) mats[k] = colors[0];
                r.sharedMaterials = mats;
            }
        }
        Directory.CreateDirectory(Path.Combine(ProjectRoot, "Assets/_InteractiveFaceFilter/Prefabs"));
        var prefab = PrefabUtility.SaveAsPrefabAsset(root, GlassesPrefabPath);
        Object.DestroyImmediate(root);
        return prefab;
    }

    /// <summary>Wires AR_Canvas buttons to GlassesSelector, colors the color buttons, fixes the input module.</summary>
    static void PrepareCanvasPrefab(Material[] colors)
    {
        var root = PrefabUtility.LoadPrefabContents(CanvasPrefabPath);
        try
        {
            var selector = root.GetComponent<GlassesSelector>() ?? root.AddComponent<GlassesSelector>();

            // project uses the new Input System only -> StandaloneInputModule would fail
            foreach (var old in root.GetComponentsInChildren<StandaloneInputModule>(true))
            {
                var go = old.gameObject;
                Object.DestroyImmediate(old);
                if (go.GetComponent<InputSystemUIInputModule>() == null) go.AddComponent<InputSystemUIInputModule>();
            }

            // glasses icons: sub-sprites of the sliced UI_Icon_Glasses sheet (names as in the package, incl. its "Glases" typo)
            const string sheet = "Assets/_InteractiveFaceFilter/Sprites/UI_Icon_Glasses.png";
            string[] iconNames = { "UI_Icon_Glases_Cat", "UI_Icon_Glases_Stars", "UI_Icon_Glases_Mask" };
            var sprites = AssetDatabase.LoadAllAssetsAtPath(sheet).OfType<Sprite>().ToArray();

            // keep the glasses row above the color row (color row occupies the bottom 195 px of the 1080x1920 canvas)
            var gRow = (RectTransform)FindChild(root.transform, "Glasses Buttons");
            gRow.anchorMin = new Vector2(0f, 0.14f);
            gRow.anchorMax = new Vector2(1f, 0.26f);
            gRow.anchoredPosition = Vector2.zero;
            gRow.sizeDelta = Vector2.zero;

            var circle = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/_InteractiveFaceFilter/Sprites/UI_Icon_Circle.png");
            for (int i = 1; i <= 3; i++)
            {
                var gb = FindChild(root.transform, $"Glasses {i} Button").GetComponent<Button>();
                var icon = sprites.FirstOrDefault(sp => sp.name == iconNames[i - 1]);
                if (icon == null) throw new System.Exception("sprite not found: " + iconNames[i - 1]);
                var gImg = gb.GetComponent<Image>();
                gImg.sprite = icon;
                gImg.preserveAspect = true;
                ClearPersistent(gb);
                UnityEventTools.AddIntPersistentListener(gb.onClick, selector.SelectGlasses, i - 1);

                var mb = FindChild(root.transform, $"Material {i} Button");
                var img = mb.GetComponent<Image>();
                if (circle != null) img.sprite = circle;
                img.color = colors[i - 1].color;
                var btn = mb.GetComponent<Button>();
                ClearPersistent(btn);
                UnityEventTools.AddIntPersistentListener(btn.onClick, selector.SelectColor, i - 1);
            }
            PrefabUtility.SaveAsPrefabAsset(root, CanvasPrefabPath);
        }
        finally { PrefabUtility.UnloadPrefabContents(root); }
    }

    static void ClearPersistent(Button b)
    {
        for (int i = b.onClick.GetPersistentEventCount() - 1; i >= 0; i--)
            UnityEventTools.RemovePersistentListener(b.onClick, i);
    }

    static Transform FindChild(Transform root, string name) =>
        root.GetComponentsInChildren<Transform>(true).First(t => t.name == name);

    [MenuItem("AR Lab/Build Interactive Scenes")]
    public static void BuildInteractive()
    {
        EnsureTags();
        var colors = CreateColorMaterials();
        var glassesPrefab = CreateGlassesGroupPrefab(colors);
        PrepareCanvasPrefab(colors);
        var canvasPrefab = AssetDatabase.LoadAssetAtPath<GameObject>(CanvasPrefabPath);

        // --- build scene: face prefab is spawned by ARFaceManager, no test instance
        var scene = NewFaceScene(out var faceManager);
        faceManager.facePrefab = glassesPrefab;
        EditorUtility.SetDirty(faceManager);
        var canvas = (GameObject)PrefabUtility.InstantiatePrefab(canvasPrefab);
        canvas.name = "AR_Canvas";
        EditorSceneManager.SaveScene(scene, InteractiveScenePath);
        DumpScene(scene, "InteractiveFilter");
        Debug.Log("[FaceSceneBuilder] saved " + InteractiveScenePath);

        // --- editor-only test scene (face tracking is unavailable on Mac): plain camera, GlassesGroup at Z=0.4
        var test = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var camGo = new GameObject("Main Camera") { tag = "MainCamera" };
        var cam = camGo.AddComponent<Camera>();
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = new Color(0.25f, 0.28f, 0.33f);
        cam.nearClipPlane = 0.05f;
        var lightGo = new GameObject("Directional Light");
        lightGo.AddComponent<Light>().type = LightType.Directional;
        lightGo.transform.rotation = Quaternion.Euler(30, -20, 0);
        var inst = (GameObject)PrefabUtility.InstantiatePrefab(glassesPrefab);
        inst.name = "GlassesGroup (editor test)";
        inst.transform.position = new Vector3(0, 0, 0.4f);
        var c2 = (GameObject)PrefabUtility.InstantiatePrefab(canvasPrefab);
        c2.name = "AR_Canvas";
        EditorSceneManager.SaveScene(test, TestScenePath);
        DumpScene(test, "InteractiveFilter_EditorTest");
        Debug.Log("[FaceSceneBuilder] saved " + TestScenePath);
    }

    // ---------------------------------------------------------------- build

    static bool BuildApk(string scenePath, string apkName, string productName, string appId)
    {
        ConfigureAndroid(productName, appId);
        var outDir = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "build"));
        Directory.CreateDirectory(outDir);
        var apk = Path.Combine(outDir, apkName);
        var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
        {
            scenes = new[] { scenePath },
            locationPathName = apk,
            target = BuildTarget.Android,
            options = BuildOptions.None,
        });
        Debug.Log($"[FaceSceneBuilder] build {apkName}: {report.summary.result}, size={report.summary.totalSize}");
        return report.summary.result == BuildResult.Succeeded;
    }

    [MenuItem("AR Lab/Build All (scenes + 2 APK)")]
    public static void BuildAll()
    {
        bool ok = false;
        try
        {
            BuildBasic();
            BuildInteractive();
            AssetDatabase.SaveAssets();
            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(BasicScenePath, true),
                new EditorBuildSettingsScene(InteractiveScenePath, true),
            };
            ok = BuildApk(BasicScenePath, "AR_Lab7_BasicFaceFilter.apk", "AR Lab7 Basic Face Filter", "com.lab.arlab7a")
                 & BuildApk(InteractiveScenePath, "AR_Lab7_InteractiveFilter.apk", "AR Lab7 Interactive Filter", "com.lab.arlab7b");
        }
        catch (System.Exception e) { Debug.LogError("[FaceSceneBuilder] " + e); }
        Debug.Log("[FaceSceneBuilder] " + (ok ? "Build succeeded" : "Build FAILED"));
        if (Application.isBatchMode) EditorApplication.Exit(ok ? 0 : 1);
    }

    /// <summary>Scenes only, no APK.</summary>
    public static void PrepareScenes()
    {
        try { BuildBasic(); BuildInteractive(); AssetDatabase.SaveAssets(); }
        catch (System.Exception e) { Debug.LogError("[FaceSceneBuilder] " + e); EditorApplication.Exit(1); return; }
        if (Application.isBatchMode) EditorApplication.Exit(0);
    }

    // ---------------------------------------------------------------- Play Mode helpers

    [MenuItem("AR Lab/Click Glasses 1")] static void ClickG1() => Click("Glasses 1 Button");
    [MenuItem("AR Lab/Click Glasses 2")] static void ClickG2() => Click("Glasses 2 Button");
    [MenuItem("AR Lab/Click Glasses 3")] static void ClickG3() => Click("Glasses 3 Button");
    [MenuItem("AR Lab/Click Color 1")] static void ClickC1() => Click("Material 1 Button");
    [MenuItem("AR Lab/Click Color 2")] static void ClickC2() => Click("Material 2 Button");
    [MenuItem("AR Lab/Click Color 3")] static void ClickC3() => Click("Material 3 Button");

    static void Click(string buttonName)
    {
        var btn = Object.FindObjectsByType<Button>(FindObjectsInactive.Include)
            .FirstOrDefault(b => b.name == buttonName);
        if (btn == null || EventSystem.current == null)
        {
            Debug.LogWarning($"[FaceSceneBuilder] button '{buttonName}' or EventSystem not found (enter Play Mode with AR_Canvas)");
            return;
        }
        ExecuteEvents.Execute(btn.gameObject, new PointerEventData(EventSystem.current), ExecuteEvents.pointerClickHandler);
        Debug.Log("[FaceSceneBuilder] clicked " + buttonName);
    }

    [MenuItem("AR Lab/Open Editor Test Scene")]
    static void OpenTest() => EditorSceneManager.OpenScene(TestScenePath);

    /// <summary>Batch helper: renders the test scene camera to a PNG for visual verification.</summary>
    public static void RenderTestShots()
    {
        EditorSceneManager.OpenScene(TestScenePath);
        var cam = Camera.main;
        var dir = Path.GetFullPath(Path.Combine(ProjectRoot, "..", "..", "src", "shots"));
        Directory.CreateDirectory(dir);
        var ctrl = Object.FindAnyObjectByType<GlassesGroupController>();
        for (int g = 0; g < 3; g++)
        {
            PlayerPrefs.SetInt(GlassesSelector.GlassesKey, g);
            PlayerPrefs.SetInt(GlassesSelector.ColorKey, g);
            ctrl.Apply();
            var rt = new RenderTexture(540, 960, 24);
            cam.targetTexture = rt;
            cam.Render();
            RenderTexture.active = rt;
            var tex = new Texture2D(540, 960, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, 540, 960), 0, 0);
            File.WriteAllBytes(Path.Combine(dir, $"glasses{g + 1}.png"), tex.EncodeToPNG());
            cam.targetTexture = null;
            RenderTexture.active = null;
        }
        PlayerPrefs.DeleteKey(GlassesSelector.GlassesKey);
        PlayerPrefs.DeleteKey(GlassesSelector.ColorKey);
        if (Application.isBatchMode) EditorApplication.Exit(0);
    }
}
