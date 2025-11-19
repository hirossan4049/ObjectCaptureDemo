import SwiftUI
import RealityKit
import Foundation

@available(iOS 17.0, *)
public struct ObjectCaptureSimpleView: View {
  @State private var session = ObjectCaptureSession()
  @State private var imageFolderPath: URL? // 画像保存先
  @Environment(\.dismiss) private var dismiss
  
  public var body: some View {
    ObjectCaptureView(session: session)
      .onAppear {
        print("[ObjectCapture-Swift] View appeared")
        if ObjectCaptureSession.isSupported {
          print("[ObjectCapture-Swift] Object capture is supported")
          guard let directory = createNewScanDirectory() else { return }
          session = ObjectCaptureSession()
          imageFolderPath = directory.appending(path: "Images/")
          guard let imageFolderPath else { return }
          // セッションを開始
          session.start(imagesDirectory: imageFolderPath)
        } else {
          print("[ObjectCapture-Swift] Object capture is NOT supported on this device")
        }
      }
  }
}

// Objective-C compatible wrapper
@available(iOS 17.0, *)
@objc(ObjectCaptureViewController)
public class ObjectCaptureViewController: UIHostingController<ObjectCaptureSimpleView> {
  @objc public init() {
    super.init(rootView: ObjectCaptureSimpleView())
    print("[ObjectCapture-Swift] ObjectCaptureViewController initialized")
  }
  
  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


@available(iOS 17.0, *)
extension ObjectCaptureSimpleView {
  func createNewScanDirectory() -> URL? {
    guard let capturesFolder = getRootScansFolder() else { return nil }
    
    let formatter = ISO8601DateFormatter()
    let timestamp = formatter.string(from: Date())
    let newCaptureDirectory = capturesFolder.appendingPathComponent(timestamp,
                                                                    isDirectory: true)
    print("▶️ Start creating capture path: \(newCaptureDirectory)")
    let capturePath = newCaptureDirectory.path
    do {
      try FileManager.default.createDirectory(atPath: capturePath,
                                              withIntermediateDirectories: true)
    } catch {
      print("😨Failed to create capture path: \(capturePath) with error: \(String(describing: error))")
    }
    
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: capturePath,
                                                isDirectory: &isDirectory)
    guard exists, isDirectory.boolValue else { return nil }
    print("🎉 New capture path was created")
    return newCaptureDirectory
  }
  
  private func getRootScansFolder() -> URL? {
    guard let documentFolder = try? FileManager.default.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
    else { return nil }
    return documentFolder.appendingPathComponent("Scans/", isDirectory: true)
  }
}
