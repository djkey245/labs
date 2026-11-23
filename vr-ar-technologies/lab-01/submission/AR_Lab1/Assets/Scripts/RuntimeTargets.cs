using System;
using System.Collections.Generic;
using UnityEngine;
using Vuforia;

/// <summary>
/// Creates Vuforia image targets at runtime from textures (no Target Manager database needed)
/// and attaches augmentation content (prefab and/or textured overlay quad) to each of them.
/// </summary>
public class RuntimeTargets : MonoBehaviour
{
    [Serializable]
    public class TargetEntry
    {
        public string name = "Target";
        public Texture2D marker;
        [Tooltip("Physical width of the printed/displayed target in meters")]
        public float widthMeters = 0.2f;
        [Tooltip("Optional 3D prefab placed on the target (scaled to a height of half the target width)")]
        public GameObject contentPrefab;
        [Tooltip("Optional texture shown on a quad covering the whole target")]
        public Texture2D overlayTexture;
        [Tooltip("Material for the overlay quad (asset reference keeps the shader in the build)")]
        public Material overlayMaterial;
    }

    public List<TargetEntry> targets = new List<TargetEntry>();

    bool _created;

    void OnEnable()
    {
        if (VuforiaApplication.Instance != null)
            VuforiaApplication.Instance.OnVuforiaStarted += CreateTargets;
    }

    void OnDestroy()
    {
        if (VuforiaApplication.Instance != null)
            VuforiaApplication.Instance.OnVuforiaStarted -= CreateTargets;
    }

    void CreateTargets()
    {
        if (_created) return;
        _created = true;

        foreach (var entry in targets)
        {
            if (entry == null || entry.marker == null)
            {
                Debug.LogWarning("RuntimeTargets: entry skipped, marker texture is missing.");
                continue;
            }

            var target = VuforiaBehaviour.Instance.ObserverFactory.CreateImageTarget(
                entry.marker, entry.widthMeters, entry.name);
            if (target == null)
            {
                Debug.LogError($"RuntimeTargets: CreateImageTarget failed for '{entry.name}'.");
                continue;
            }

            Debug.Log($"RuntimeTargets: '{entry.name}' created, size={target.GetSize()}, " +
                      $"localScale={target.transform.localScale}");

            // Children must exist BEFORE the handler is added (handler toggles renderers of children).
            var content = new GameObject("Content");
            content.transform.SetParent(target.transform, false);
            // Keeps the content's local unit equal to 1 meter regardless of target scale convention.
            content.AddComponent<MeterSpace>();

            var aspect = entry.marker.height / (float)entry.marker.width;

            if (entry.overlayTexture != null || entry.overlayMaterial != null)
                CreateOverlay(content.transform, entry, aspect);

            if (entry.contentPrefab != null)
                CreatePrefab(content.transform, entry);

            target.gameObject.AddComponent<DefaultObserverEventHandler>();
        }
    }

    static void CreateOverlay(Transform parent, TargetEntry entry, float aspect)
    {
        var quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
        quad.name = "Overlay";
        var col = quad.GetComponent<Collider>();
        if (col != null) Destroy(col);

        quad.transform.SetParent(parent, false);
        // Quad faces -Z by default; rotating 90 deg about X lays it flat facing up (+Y of target space).
        quad.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
        quad.transform.localPosition = new Vector3(0f, 0.001f, 0f);
        quad.transform.localScale = new Vector3(entry.widthMeters, entry.widthMeters * aspect, 1f);

        // Prefer the material asset: Shader.Find alone fails in a player build if the shader was stripped.
        var mat = entry.overlayMaterial != null
            ? entry.overlayMaterial
            : new Material(Shader.Find("Unlit/Texture")) { mainTexture = entry.overlayTexture };
        quad.GetComponent<Renderer>().sharedMaterial = mat;
    }

    static void CreatePrefab(Transform parent, TargetEntry entry)
    {
        // Measure at scale 1 outside the hierarchy, then reparent and scale.
        var go = Instantiate(entry.contentPrefab);
        go.name = entry.contentPrefab.name;
        var renderers = go.GetComponentsInChildren<Renderer>();
        float scale = 1f;
        float bottom = 0f;
        if (renderers.Length > 0)
        {
            var b = renderers[0].bounds;
            foreach (var r in renderers) b.Encapsulate(r.bounds);
            if (b.size.y > 1e-5f) scale = entry.widthMeters * 0.5f / b.size.y;
            bottom = (b.min.y - go.transform.position.y) * scale;
        }
        go.transform.SetParent(parent, false);
        go.transform.localRotation = Quaternion.identity;
        go.transform.localScale = Vector3.one * scale;
        go.transform.localPosition = new Vector3(0f, -bottom, 0f); // feet on the target plane
    }
}

/// <summary>
/// Makes this object's local space metric: local scale = 1 / parent's lossy scale.
/// Works whether the Vuforia target's transform is normalized or already in meters.
/// </summary>
public class MeterSpace : MonoBehaviour
{
    void LateUpdate()
    {
        var p = transform.parent;
        if (p == null) return;
        var s = p.lossyScale;
        if (s.x > 1e-6f && s.y > 1e-6f && s.z > 1e-6f)
            transform.localScale = new Vector3(1f / s.x, 1f / s.y, 1f / s.z);
    }
}
