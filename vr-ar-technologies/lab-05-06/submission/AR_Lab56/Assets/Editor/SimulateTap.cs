using UnityEditor;
using UnityEngine;
using Vuforia;

/// <summary>Editor-only: simulates a screen tap (the Play Mode webcam emulator cannot deliver it reliably).</summary>
public static class SimulateTap
{
    [MenuItem("AR Lab/Simulate Tap")]
    public static void Tap()
    {
        if (!Application.isPlaying) return;
        var pos = new Vector2(Screen.width / 2f, Screen.height / 2f);
        foreach (var l in Object.FindObjectsByType<AnchorInputListenerBehaviour>(FindObjectsSortMode.None))
            l.OnInputReceivedEvent?.Invoke(pos);
        Debug.Log("[SimulateTap] tap at " + pos);
    }
}
