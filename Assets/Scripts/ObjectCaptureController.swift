import SwiftUI
import RealityKit
import QuickLook

// MARK: - CaptureState Extension
@available(iOS 17.0, *)
extension ObjectCaptureSession.CaptureState {
  var label: String {
    switch self {
    case .initializing:
      return "initializing"
    case .ready:
      return "ready"
    case .detecting:
      return "detecting"
    case .capturing:
      return "capturing"
    case .finishing:
      return "finishing"
    case .completed:
      return "completed"
    case .failed(let error):
      return "failed: \(String(describing: error))"
    @unknown default:
      fatalError("unknown default: \(self)")
    }
  }
}

// MARK: - Create Button
@available(iOS 17.0, *)
@MainActor
struct CreateButton: View {
  let session: ObjectCaptureSession

  var body: some View {
    Button(action: {
      performAction()
    }, label: {
      Text(label)
        .foregroundStyle(.white)
        .padding()
        .background(.tint)
        .clipShape(Capsule())
    })
  }

  private var label: LocalizedStringKey {
    if session.state == .ready {
      return "Start detecting"
    } else if session.state == .detecting {
      return "Start capturing"
    } else {
      return "Undefined"
    }
  }

  private func performAction() {
    if session.state == .ready {
      let isDetecting = session.startDetecting()
      print(isDetecting ? "▶️Start detecting" : "😨Not start detecting")
    } else if session.state == .detecting {
      session.startCapturing()
    } else {
      print("Undefined")
    }
  }
}

// MARK: - AR QuickLook View
@available(iOS 17.0, *)
struct ARQuickLookView: View {
  let modelFile: URL
  let onDismiss: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack {
        QuickLookPreview(url: modelFile)

        Button("Close") {
          dismiss()
          onDismiss()
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
      }
    }
  }
}

@available(iOS 17.0, *)
struct QuickLookPreview: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> QLPreviewController {
    let controller = QLPreviewController()
    controller.dataSource = context.coordinator
    return controller
  }

  func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, QLPreviewControllerDataSource {
    let parent: QuickLookPreview

    init(_ parent: QuickLookPreview) {
      self.parent = parent
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      return parent.url as QLPreviewItem
    }
  }
}

// MARK: - Main View
@available(iOS 17.0, *)
public struct ObjectCaptureSimpleView: View {
  @State private var session: ObjectCaptureSession?
  @State private var imageFolderPath: URL?
  @State private var photogrammetrySession: PhotogrammetrySession?
  @State private var modelFolderPath: URL?
  @State private var isProgressing = false
  @State private var quickLookIsPresented = false
  @Environment(\.dismiss) private var dismiss

  var modelPath: URL? {
    return modelFolderPath?.appending(path: "model.usdz")
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      if let session {
        ObjectCaptureView(session: session)

        VStack(spacing: 16) {
          if session.state == .ready || session.state == .detecting {
            CreateButton(session: session)
          }

          HStack {
            Text(session.state.label)
              .bold()
              .foregroundStyle(.yellow)
              .padding(.bottom)
          }
        }
      }

      if isProgressing {
        Color.black.opacity(0.4)
          .overlay {
            VStack {
              ProgressView()
            }
          }
      }
    }
    .task {
      guard let directory = createNewScanDirectory() else { return }
      session = ObjectCaptureSession()

      modelFolderPath = directory.appending(path: "Models/")
      imageFolderPath = directory.appending(path: "Images/")
      guard let imageFolderPath else { return }
      session?.start(imagesDirectory: imageFolderPath)
    }
    .onChange(of: session?.userCompletedScanPass) { _, newValue in
      if let newValue, newValue {
        // This time, I've completed one scan pass.
        // However, Apple recommends that the scan pass should be done three times.
        session?.finish()
      }
    }
    .onChange(of: session?.state) { _, newValue in
      if newValue == .completed {
        session = nil

        Task {
          await startReconstruction()
        }
      }
    }
    .sheet(isPresented: $quickLookIsPresented) {
      if let modelPath {
        ARQuickLookView(modelFile: modelPath) {
          guard let directory = createNewScanDirectory() else { return }
          quickLookIsPresented = false
          // Restart ObjectCapture
          session = ObjectCaptureSession()

          modelFolderPath = directory.appending(path: "Models/")
          let newImageFolderPath = directory.appending(path: "Images/")
          self.imageFolderPath = newImageFolderPath
          session?.start(imagesDirectory: newImageFolderPath)
        }
      }
    }
  }

  private func startReconstruction() async {
    guard let imageFolderPath,
          let modelPath else { return }
    isProgressing = true
    do {
      photogrammetrySession = try PhotogrammetrySession(input: imageFolderPath)
      guard let photogrammetrySession else { return }
      try photogrammetrySession.process(requests: [.modelFile(url: modelPath)])
      for try await output in photogrammetrySession.outputs {
        switch output {
        case .requestError, .processingCancelled:
          isProgressing = false
          self.photogrammetrySession = nil
          // Restart ObjectCapture
          guard let directory = createNewScanDirectory() else { return }
          session = ObjectCaptureSession()
          modelFolderPath = directory.appending(path: "Models/")
          let newImageFolderPath = directory.appending(path: "Images/")
          self.imageFolderPath = newImageFolderPath
          session?.start(imagesDirectory: newImageFolderPath)
        case .processingComplete:
          isProgressing = false
          self.photogrammetrySession = nil
          quickLookIsPresented = true
        default:
          break
        }
      }
    } catch {
      print("error", error)
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
