# Hafiz Pro 📖

**Master the Quran, one Ayah at a time**

A Flutter application designed to help Muslims test and improve their Quran memorization skills through interactive audio-based testing.

## 🌟 Features

### Core Functionality
- **Random Verse Testing**: Generate random verses from random chapters and complete them where the reciter stops
- **Multiple Test Modes**:
  - Test by Surah (Chapter)
  - Test by Juz (Part)
  - Random testing across the entire Quran
- **Audio Playback**: High-quality audio recitation with multiple reciters
- **Progress Tracking**: Save and continue from your last read position
- **User Guide**: Interactive showcase to help new users navigate the app

### Audio Features
- **Multiple Reciters**: Choose from various renowned Quran reciters
- **Playback Controls**: Play, pause, seek, and adjust playback speed
- **Background Playback**: Continue listening while using other apps
- **Loop Modes**: Repeat verses for better memorization

### User Experience
- **Beautiful UI**: Modern, intuitive interface with Arabic typography
- **Responsive Design**: Optimized for different screen sizes
- **Settings Management**: Customize reciter, autoplay, and other preferences
- **Last Read Card**: Quick access to continue from where you left off

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.4.0)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator (iOS support available)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/bynalab/hafiz_test.git
   cd hafiz_test
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Internationalization**
   ```bash
   flutter gen-l10n
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## 🏗️ Project Structure

```
lib/
├── data/                    # Static data files
│   ├── juz_list.dart       # Juz (Part) definitions
│   ├── reciters.dart       # Available reciters
│   └── surah_list.dart     # Surah (Chapter) list
├── enum/                   # Enumerations
│   └── surah_select_action.dart
├── extension/              # Dart extensions
│   ├── collection.dart
│   └── quran_extension.dart
├── juz/                    # Juz-related screens
├── model/                  # Data models
│   ├── ayah.model.dart
│   ├── reciter.model.dart
│   └── surah.model.dart
├── quran/                  # Quran-related functionality
├── services/               # Business logic services
│   ├── audio_services.dart
│   ├── ayah.services.dart
│   ├── network.services.dart
│   ├── storage/            # Storage implementations
│   └── surah.services.dart
├── surah/                  # Surah-related screens
├── util/                   # Utility classes
├── widget/                 # Reusable UI components
├── locator.dart           # Dependency injection setup
├── main.dart              # App entry point
├── main_menu.dart         # Main menu screen
├── settings_dialog.dart   # Settings configuration
└── splash_screen.dart     # App splash screen
```

## 🧪 Testing

The project includes comprehensive test coverage:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Test Structure
- **Unit Tests**: Service layer testing with mocked dependencies
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end user flow testing

### Test Files
- `test/services/` - Service layer tests
- `test/widget_test.dart` - Widget tests
- `test/test_helper.dart` - Test utilities and mocks

## 🔧 Configuration

### Dependencies

#### Core Dependencies
- **flutter**: UI framework
- **dio**: HTTP client for API calls
- **just_audio**: Audio playback functionality
- **shared_preferences**: Local data storage
- **get_it**: Dependency injection

#### UI Dependencies
- **google_fonts**: Typography
- **shimmer**: Loading animations
- **flutter_svg**: SVG support
- **showcaseview**: User onboarding

#### Development Dependencies
- **flutter_test**: Testing framework
- **mocktail**: Mocking library
- **flutter_lints**: Code quality

### Environment Setup

1. **API Configuration**: The app uses external APIs for Quran data and audio
2. **Storage**: Local preferences for user settings and progress
3. **Audio**: Background audio support with notification controls

## 📱 Screenshots

*Add screenshots of the app here*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Quran API**: For providing Quran text and audio data
- **Reciters**: All the talented Quran reciters whose audio is used
- **Flutter Community**: For the excellent packages and support
- **Open Source Contributors**: For their valuable contributions

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/bynalab/hafiz_test/issues) page
2. Create a new issue with detailed information
3. Contact the development team

## 🔄 Version History

- **v25.09.03+12**: Current version with comprehensive testing and UI improvements
- **Previous versions**: See [CHANGELOG](CHANGELOG.md) for detailed history

---

**May Allah bless this effort and make it beneficial for all Muslims seeking to memorize His words. Ameen.** 🤲