import SwiftUI

struct ContentView: View {
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var navigateToEditor = false
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Film Camera App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationLink(destination: CameraView(cameraManager: cameraManager)) {
                    Text("Live Camera")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Button(action: {
                    showingImagePicker = true
                }) {
                    Text("Edit Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                }

                // Navigation link triggered by state variable
                NavigationLink(destination: getEditorView(), isActive: $navigateToEditor) {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoPicker(selectedImage: $inputImage)
            }
            .onChange(of: inputImage) { newImage in
                if newImage != nil {
                    navigateToEditor = true
                }
            }
        }
    }

    @ViewBuilder
    private func getEditorView() -> some View {
        if let inputImage = inputImage {
            PhotoEditorView(image: inputImage, isPresented: $navigateToEditor, parentImage: $inputImage)
        } else {
            EmptyView()
        }
    }
}
