// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FilmCameraApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .iOSApplication(
            name: "FilmCameraApp",
            targets: ["FilmCameraApp"],
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .camera),
            accentColor: .presetColor(.yellow),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            infoPlist: .extendingDefault(with: [
                "NSCameraUsageDescription": "We need access to your camera to take film photos.",
                "NSPhotoLibraryUsageDescription": "We need access to save the filtered photos to your library.",
                "NSPhotoLibraryAddUsageDescription": "We need access to save the filtered photos to your library."
            ])
        )
    ],
    targets: [
        .executableTarget(
            name: "FilmCameraApp",
            path: "FilmCameraApp",
            resources: [
                .process("LUTs")
            ]
        )
    ]
)
