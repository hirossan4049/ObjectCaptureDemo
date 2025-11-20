# Unity ObjectCapture Integration

このプロジェクトは、UnityからiOSのネイティブObjectCapture API (iOS 17+) を呼び出すための最小限の実装サンプルです。

## 概要

Unity (C#) から Objective-C++ を経由して Swift の `ObjectCaptureSession` を起動する仕組みになっています。

### 構成ファイル

連携に必要な主要ファイルは以下の通りです。

1.  **C# (Unity側)**: `Assets/Scripts/ObjectCaptureBridge.cs`
    *   Unityからネイティブプラグインを呼び出すインターフェース。
2.  **Objective-C++ (ブリッジ)**: `Assets/Scripts/UnityAppController+ObjectCapture.mm`
    *   Unityのライフサイクルにフックし、Cインターフェース (`StartObjectCaptureNative`) を提供。
    *   Swiftのクラスを動的にロードして表示します。
3.  **Swift (iOSネイティブ側)**: `Assets/Scripts/ObjectCaptureController.swift`
    *   SwiftUIで実装されたObjectCaptureのビューとロジック。

## 実装の詳細

### 1. C# (Unity)
`DllImport` を使用して、iOSの静的ライブラリ（`__Internal`）としてリンクされる関数を呼び出します。

```csharp
// Assets/Scripts/ObjectCaptureBridge.cs
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
```

### 2. Objective-C++ (Bridge)
`extern "C"` でC言語形式の関数を定義し、そこからSwiftのViewControllerを呼び出します。
`UnityAppController` のカテゴリとして実装することで、既存のUnityのAppControllerに干渉せずに機能を追加しています。

```objective-c
// Assets/Scripts/UnityAppController+ObjectCapture.mm (抜粋)
extern "C" {
    void StartObjectCaptureNative(void);
}

void StartObjectCaptureNative(void)
{
    // メインスレッドで実行
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 17.0, *)) {
            // Swiftのクラスを文字列から取得 (UnityFrameworkターゲットに含まれるためプレフィックスが必要な場合がある)
            Class captureViewControllerClass = NSClassFromString(@"ObjectCaptureViewController");
            if (!captureViewControllerClass) {
                captureViewControllerClass = NSClassFromString(@"UnityFramework.ObjectCaptureViewController");
            }
            
            if (captureViewControllerClass) {
                UIViewController *captureVC = [[captureViewControllerClass alloc] init];
                UIViewController *rootVC = UnityGetGLViewController();
                [rootVC presentViewController:captureVC animated:YES completion:nil];
            }
        }
    });
}
```

### 3. Swift (Native)
SwiftUIを使って `ObjectCaptureView` を表示する `UIViewController` を作成します。
`@objc` 属性を付けることで、Objective-Cランタイムからクラスを参照できるようにしています。

```swift
// Assets/Scripts/ObjectCaptureController.swift (抜粋)
import SwiftUI
import RealityKit

@available(iOS 17.0, *)
@objc(ObjectCaptureViewController) // Objective-Cからこの名前で参照可能にする
public class ObjectCaptureViewController: UIHostingController<ObjectCaptureSimpleView> {
    @objc public init() {
        super.init(rootView: ObjectCaptureSimpleView())
    }
    
    // ... (required initなど)
}

@available(iOS 17.0, *)
public struct ObjectCaptureSimpleView: View {
    // ObjectCaptureSessionの管理とUI表示
    public var body: some View {
        ObjectCaptureView(session: session)
            // ...
    }
}
```

## 使い方

1.  iOSビルド設定でTarget SDKをiOS 17.0以上に設定します。
2.  Unityから `ObjectCaptureBridge.StartObjectCapture()` を呼び出します。

```csharp
// 呼び出し例
public void OnClickStartButton()
{
    ObjectCaptureBridge.StartObjectCapture();
}
```
