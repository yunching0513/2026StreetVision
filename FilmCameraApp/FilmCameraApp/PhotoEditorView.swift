import SwiftUI
import Photos

struct PhotoEditorView: View {
    let originalImage: UIImage
    @Binding var isPresented: Bool
    @Binding var parentImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var activeFilter: FilmStyle = .none
    @State private var showSaveAlert = false

    // CoreImage
    private let context = CIContext()

    init(image: UIImage, isPresented: Binding<Bool>, parentImage: Binding<UIImage?>) {
        self.originalImage = image
        self._isPresented = isPresented
        self._parentImage = parentImage
        self._processedImage = State(initialValue: image)
    }

    var body: some View {
        VStack {
            Spacer()

            if let image = processedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(FilmStyle.allCases, id: \.self) { filter in
                        Button(action: {
                            activeFilter = filter
                            applyFilter()
                        }) {
                            Text(filter.rawValue)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(activeFilter == filter ? Color.yellow : Color.gray.opacity(0.5))
                                .foregroundColor(activeFilter == filter ? .black : .white)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.opacity(0.8))
        }
        .navigationBarTitle("Edit Photo", displayMode: .inline)
        .navigationBarItems(trailing: Button("Save") {
            savePhoto()
        })
        .onDisappear {
            parentImage = nil
            isPresented = false
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(title: Text("Saved!"), message: Text("The photo has been saved to your library."), dismissButton: .default(Text("OK")))
        }
    }

    private func applyFilter() {
        guard let ciImage = CIImage(image: originalImage) else { return }

        let processedCIImage = activeFilter.apply(to: ciImage) ?? ciImage

        if let cgImage = context.createCGImage(processedCIImage, from: processedCIImage.extent) {
            processedImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        } else {
            processedImage = originalImage
        }
    }

    private func savePhoto() {
        guard let imageToSave = processedImage else { return }

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: imageToSave)
                }) { success, error in
                    if success {
                        DispatchQueue.main.async {
                            showSaveAlert = true
                        }
                    }
                }
            }
        }
    }
}
