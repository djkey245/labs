using UnityEngine;

/// <summary>Rotates the object around a local axis (used for the aircraft propeller).</summary>
public class RotateScript : MonoBehaviour
{
    public Vector3 axis = Vector3.forward;
    public float speed = 720f; // degrees per second

    void Update()
    {
        transform.Rotate(axis, speed * Time.deltaTime);
    }
}
