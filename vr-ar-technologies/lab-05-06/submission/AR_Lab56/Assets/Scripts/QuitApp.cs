using UnityEngine;

/// <summary>Quits the application when Escape is pressed.</summary>
public class QuitApp : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKey("escape")) Application.Quit();
    }
}
