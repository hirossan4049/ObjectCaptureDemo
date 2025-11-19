using System.IO;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;

public class ObjectCapturePostProcessBuild
{
    [PostProcessBuild]
    public static void OnPostProcessBuild(BuildTarget buildTarget, string pathToBuiltProject)
    {
        if (buildTarget != BuildTarget.iOS) return;
        
        // Info.plistにカメラ権限を追加
        var plistPath = pathToBuiltProject + "/Info.plist";
        var plist = new PlistDocument();
        plist.ReadFromString(File.ReadAllText(plistPath));

        var rootDict = plist.root;
        
        // Object Captureに必要な権限を追加
        rootDict.SetString("NSCameraUsageDescription", "This app uses the camera for Object Capture to create 3D models");
        rootDict.SetString("NSPhotoLibraryUsageDescription", "This app saves captured 3D models to your photo library");
        rootDict.SetString("NSPhotoLibraryAddUsageDescription", "This app saves captured 3D models to your photo library");
        
        File.WriteAllText(plistPath, plist.WriteToString());
        
        UnityEngine.Debug.Log("[ObjectCapture] PostProcessBuild: Added camera permissions to Info.plist");
    }
}