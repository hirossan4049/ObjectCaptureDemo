import SwiftUI
import RealityKit

@available(iOS 17.0, *)
public struct ObjectCaptureSimpleView: View {
    @State private var session = ObjectCaptureSession()
    @State private var imageFolderPath: URL?
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        ObjectCaptureView(session: session)
            .onAppear {
                if ObjectCaptureSession.isSupported {
                    guard let directory = createNewScanDirectory() else { return }
                    session = ObjectCaptureSession()
                    imageFolderPath = directory.appending(path: "Images/")
                    guard let imageFolderPath else { return }
                    session.start(imagesDirectory: imageFolderPath)
                } else {
                    print("[ObjectCapture] Device does not support Object Capture")
                }
            }
    }
}

@available(iOS 17.0, *)
@objc(ObjectCaptureViewController)
public class ObjectCaptureViewController: UIHostingController<ObjectCaptureSimpleView> {
    @objc public init() {
        super.init(rootView: ObjectCaptureSimpleView())
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
        let newCaptureDirectory = capturesFolder.appendingPathComponent(timestamp, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(
                atPath: newCaptureDirectory.path,
                withIntermediateDirectories: true
            )
        } catch {
            print("[ObjectCapture] Failed to create directory: \(error)")
            return nil
        }
        
        return newCaptureDirectory
    }
    
    private func getRootScansFolder() -> URL? {
        guard let documentFolder = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return nil }
        
        return documentFolder.appendingPathComponent("Scans/", isDirectory: true)
    }
}
