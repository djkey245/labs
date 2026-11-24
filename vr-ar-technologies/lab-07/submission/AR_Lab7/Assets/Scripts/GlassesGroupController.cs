using UnityEngine;

/// <summary>
/// Lives on the GlassesGroup face prefab. Finds the glasses by tag, shows only the selected pair
/// (MeshRenderer on/off) and applies the selected color material to every pair.
/// </summary>
public class GlassesGroupController : MonoBehaviour
{
    public static readonly string[] GlassesTags = { "cat", "stars", "mask" };

    [Tooltip("Color materials, in the same order as the color buttons.")]
    public Material[] colorMaterials;

    void OnEnable()
    {
        GlassesSelector.Changed += Apply;
        Apply();
    }

    void OnDisable() => GlassesSelector.Changed -= Apply;

    public void Apply()
    {
        int glassesIndex = GlassesSelector.GlassesIndex;
        int colorIndex = GlassesSelector.ColorIndex;
        Material color = colorMaterials != null && colorIndex >= 0 && colorIndex < colorMaterials.Length
            ? colorMaterials[colorIndex] : null;

        foreach (Transform child in transform)
        {
            int tagIndex = System.Array.FindIndex(GlassesTags, t => child.CompareTag(t));
            if (tagIndex < 0) continue;
            foreach (var r in child.GetComponentsInChildren<Renderer>(true))
            {
                r.enabled = tagIndex == glassesIndex;
                if (color == null) continue;
                var mats = r.sharedMaterials;
                for (int i = 0; i < mats.Length; i++) mats[i] = color;
                r.sharedMaterials = mats;
            }
        }
    }
}
