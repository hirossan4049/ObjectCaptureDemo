import SwiftUI
import RealityKit
import Foundation

@available(iOS 14.0, *)
@MainActor
final class ObjectCaptureCoordinator: ObservableObject {
  static let shared = ObjectCaptureCoordinator()

  @Published var isPresented = false
  @Published var latestModelURL: URL?

  func startCapture() {
    isPresented = true
  }

  func handleResult(_ result: Result<URL, Error>) {
    switch result {
    case .success(let output):
      latestModelURL = output
    case .failure:
      break
    }
    isPresented = false
  }
}

@available(iOS 14.0, *)
struct ObjectCaptureRootView: View {
  @StateObject private var coordinator = ObjectCaptureCoordinator.shared

  var body: some View {
    Color.clear
      .sheet(isPresented: $coordinator.isPresented) {
        // TODO: Integrate the proper RealityKit Object Capture UI when available.
        // For now, simulate returning a URL or dismissing on failure.
        VStack(spacing: 16) {
          Text("Object Capture Placeholder")
          Button("Simulate Success") {
            // Replace with the real model file URL from Object Capture API when integrating.
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("CapturedObject.usdz")
            coordinator.handleResult(.success(tempURL))
          }
          Button("Simulate Failure") {
            coordinator.handleResult(.failure(NSError(domain: "ObjectCapture", code: -1)))
          }
        }
      }
  }
}
