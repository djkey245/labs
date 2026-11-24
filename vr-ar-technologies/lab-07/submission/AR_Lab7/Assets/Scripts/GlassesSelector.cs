using System;
using UnityEngine;

/// <summary>
/// UI side of the interactive face filter (C# equivalent of the Visual Scripting graph from the Unity Learn guide).
/// Lives on AR_Canvas; the buttons call SelectGlasses / SelectColor via persistent onClick listeners.
/// The selection is stored in PlayerPrefs and restored on start. The face prefab (GlassesGroup)
/// is spawned by ARFaceManager at runtime, so it listens to the static Changed event.
/// </summary>
public class GlassesSelector : MonoBehaviour
{
    public const string GlassesKey = "SelectedGlasses";
    public const string ColorKey = "SelectedColor";

    /// <summary>Raised whenever the selected glasses or color changes.</summary>
    public static event Action Changed;

    public static int GlassesIndex => PlayerPrefs.GetInt(GlassesKey, 0);
    public static int ColorIndex => PlayerPrefs.GetInt(ColorKey, 0);

    void Start() => Changed?.Invoke();

    public void SelectGlasses(int index)
    {
        PlayerPrefs.SetInt(GlassesKey, index);
        PlayerPrefs.Save();
        Debug.Log("[GlassesSelector] glasses = " + index);
        Changed?.Invoke();
    }

    public void SelectColor(int index)
    {
        PlayerPrefs.SetInt(ColorKey, index);
        PlayerPrefs.Save();
        Debug.Log("[GlassesSelector] color = " + index);
        Changed?.Invoke();
    }
}
