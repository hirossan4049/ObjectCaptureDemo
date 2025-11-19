using UnityEngine;

public class ObjectCaptureButton : MonoBehaviour
{
    public void OnClick()
    {
        Debug.Log("Starting Object Capture...");
        ObjectCaptureBridge.StartObjectCapture();
    }
}
