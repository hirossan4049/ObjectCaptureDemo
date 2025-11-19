using System.Runtime.InteropServices;
using UnityEngine;

public static class ObjectCaptureBridge
{
#if UNITY_IOS && !UNITY_EDITOR
  [DllImport("__Internal")]
  private static extern void StartObjectCaptureNative();
#else
  private static void StartObjectCaptureNative() {}
#endif

  public static void StartObjectCapture()
  {
    StartObjectCaptureNative();
  }
}
