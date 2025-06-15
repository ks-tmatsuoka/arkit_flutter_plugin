# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an ARKit Flutter plugin that provides a Flutter interface to Apple's ARKit framework for iOS. The plugin enables AR functionality in Flutter apps including 3D object placement, plane detection, face tracking, body tracking, and more.

**Important**: ARKit is iOS-only and requires devices with A9+ processors (iPhone 6s and newer) running iOS 12.0+. Body tracking requires iOS 13.0+.

## Architecture

### Flutter-Native Bridge Architecture
- **Flutter Layer** (`lib/`): Dart API with extensive type definitions and serialization
- **iOS Native Layer** (`ios/Classes/`): Swift implementation using ARKit and SceneKit
- **Method Channel**: Communication bridge named "arkit" for platform views

### Key Components

**Flutter Side**:
- `ARKitSceneView`: Main Flutter widget wrapping ARSCNView
- `ARKitController`: Dart controller for managing AR scenes
- `ARKitNode`: Base class for 3D objects in AR scenes
- Generated serialization code (`.g.dart` files) for Flutter-iOS communication

**iOS Side**:
- `FlutterArkitView`: Main iOS view controller managing ARSCNView
- `SwiftArkitPlugin`: Plugin registration and method channel handling
- Configuration builders for different AR tracking modes
- Geometry builders for 3D shapes and materials

### Code Generation
The project uses `json_serializable` for automatic serialization code generation. Files ending in `.g.dart` are auto-generated and should not be manually edited.

## Common Development Commands

### Code Generation
```bash
# Generate serialization code after modifying model classes
flutter packages pub run build_runner build

# Watch for changes and regenerate automatically
flutter packages pub run build_runner watch
```

### Linting
```bash
# Run Flutter lints (configured with flutter_lints package)
flutter analyze
```

### Example App Development
```bash
# Run the example app (iOS device/simulator required)
cd example
flutter run

# Specific iOS device
flutter run -d <device-id>
```

### iOS Development
```bash
# Install iOS dependencies
cd example/ios
pod install

# Open iOS project in Xcode for native debugging
open example/ios/Runner.xcworkspace
```

## Development Requirements

### iOS Setup Requirements
- **Minimum iOS**: 12.0 (body tracking requires 13.0)
- **Podfile configuration**: Must set `platform :ios, '12.0'` or higher
- **Info.plist**: Must include `NSCameraUsageDescription` for camera permissions

### TrueDepth API Handling
If not using face tracking features, add to `ios/Podfile` post_install hook:
```ruby
config.build_settings['OTHER_SWIFT_FLAGS'] = '-DDISABLE_TRUEDEPTH_API'
```

## File Organization

### Flutter Library Structure
- `lib/arkit_plugin.dart`: Main export file
- `lib/src/`: Core implementation
  - `widget/`: AR scene view and configuration
  - `geometries/`: 3D shapes (box, sphere, plane, etc.)
  - `hit/`: Touch interaction and hit testing
  - `light/`: Lighting and light estimation
  - `physics/`: Physics bodies and collision detection
  - `utils/`: Utilities and extensions

### iOS Native Structure
- `ios/Classes/`: Swift implementation
  - `FlutterArkitView*.swift`: Main view controller (split across extensions)
  - `ConfigurationBuilders/`: AR session configuration
  - `GeometryBuilders/`: 3D geometry creation
  - `Serializers/`: Data serialization between Flutter and iOS
  - `Utils/`: Helper utilities

## Testing

Currently no automated tests exist. The example app in `example/lib/` serves as comprehensive integration testing with 20+ demo scenes covering all major features.

To run example scenarios:
```bash
cd example
flutter run
# Navigate through the example app's feature list
```

## Key Dependencies

- `vector_math`: 3D mathematics (vectors, matrices, quaternions)
- `json_annotation`/`json_serializable`: Automatic serialization
- `meta`: Annotations for static analysis
- `build_runner`: Code generation tool