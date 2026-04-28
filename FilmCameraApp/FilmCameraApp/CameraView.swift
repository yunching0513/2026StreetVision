import SwiftUI

struct CameraView: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                // Camera Preview
                if let frame = cameraManager.currentFrame {
                    Image(frame, scale: 1.0, orientation: .up, label: Text("Camera Preview"))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Loading Camera...")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Filter Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(FilmStyle.allCases, id: \.self) { filter in
                            Button(action: {
                                cameraManager.activeFilter = filter
                            }) {
                                Text(filter.rawValue)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(cameraManager.activeFilter == filter ? Color.yellow : Color.gray.opacity(0.5))
                                    .foregroundColor(cameraManager.activeFilter == filter ? .black : .white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.8))

                // Capture Button
                Button(action: {
                    cameraManager.takePhoto()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitle("Camera", displayMode: .inline)
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}
