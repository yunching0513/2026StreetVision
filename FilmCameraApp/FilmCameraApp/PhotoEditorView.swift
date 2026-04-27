import SwiftUI
import Photos

struct PhotoEditorView: View {
    let originalImage: UIImage
    @Binding var isPresented: Bool
    @Binding var parentImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var activeFilter: String = "None"
    @State private var showSaveAlert = false

    // CoreImage
    private let context = CIContext()
    private let luts: [String: CIFilter]
    let filters = ["None", "Japan", "Netherlands", "Taiwan", "Germany", "France"]

    init(image: UIImage, luts: [String: CIFilter], isPresented: Binding<Bool>, parentImage: Binding<UIImage?>) {
        self.originalImage = image
        self.luts = luts
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
                    ForEach(filters, id: \.self) { filter in
                        Button(action: {
                            activeFilter = filter
                            applyFilter()
                        }) {
                            Text(filter)
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
        guard activeFilter != "None" else {
            processedImage = originalImage
            return
        }

        // Ensure orientation is preserved correctly when converting back and forth from CIImage
        guard let ciImage = CIImage(image: originalImage),
              let filter = luts[activeFilter] else { return }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            // Restore scale and orientation properties lost during CoreImage rendering
            processedImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
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
