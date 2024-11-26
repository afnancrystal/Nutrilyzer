# 🍽️ Food Analysis App

## 📝 Overview

A cutting-edge Flutter mobile application for nutritional analysis and tracking, leveraging AI technologies to provide insights into your dietary habits.

## 🛠️ Prerequisites

### Development Environment

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.3.3+)
- [Dart SDK](https://dart.dev/get-dart) (Bundled with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- Git

### System Requirements

| Requirement | Minimum Specification |
|------------|------------------------|
| OS | Windows 10/macOS/Linux |
| RAM | 16 GB |
| Storage | 15 GB free disk space |
| Flutter | >=3.3.3 <4.0.0 |

## 📦 Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Core Framework |
| `image_picker` | ^1.1.2 | Device Image Selection |
| `http` | ^1.2.2 | Network Requests |
| `intl` | ^0.17.0 | Internationalization |
| `sqflite` | ^2.4.1 | Local SQLite Database |
| `fl_chart` | ^0.69.0 | Data Visualization |
| `shared_preferences` | ^2.0.10 | Local Key-Value Storage |
| `dio` | ^5.7.0 | Advanced HTTP Networking |
| `flutter_secure_storage` | ^9.2.2 | Secure Local Storage |
| `table_calendar` | ^3.0.8 | Calendar Widget |

### Development Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_launcher_icons` | ^0.14.1 | App Icon Generation |
| `flutter_lints` | ^3.0.0 | Code Linting |

## 🚀 Installation

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/food_analysis_app.git
cd food_analysis_app
```

### 2. Setup Flutter

```bash
# Verify Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons:main
```

### 3. Run Application

```bash
# List available devices
flutter devices

# Run on default device
flutter run
```

## 📂 Project Structure

```
food_analysis_app/
│
├── lib/             # Main application code
├── assets/          # Static resources
├── android/         # Android-specific configs
├── ios/             # iOS-specific configs
└── test/            # Unit and widget tests
```

## 🔧 Troubleshooting

<details>
<summary>Common Setup Issues</summary>

- **Dependency Conflicts**: Run `flutter pub upgrade`
- **SDK Errors**: Ensure Flutter and Dart SDKs are updated
- **Platform-Specific Issues**: Check `flutter doctor` output
</details>

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
   ```
   git checkout -b feature/AmazingFeature
   ```
3. Commit changes
   ```
   git commit -m 'Add some AmazingFeature'
   ```
4. Push to branch
   ```
   git push origin feature/AmazingFeature
   ```
5. Open a Pull Request

## 📋 TODO

- [ ] Implement features to add users' anthropometric data 
- [ ] Add profile picture feature
- [ ] Create comprehensive testing suite
- [ ] Optimize performance

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**Made with ❤️ and Flutter**
