# Poll Station

A secure, Flutter-based online voting platform featuring real-time results, biometric authentication, and comprehensive candidate profiles.

## Features
- **Secure Portals**: Separate, authenticated access for Students and Administrators.
- **Biometric Security**: Supports Fingerprint and Face ID for secure student login.
- **Rich Candidate Profiles**: Candidates include Full Name, Program of Study, Level, and Profile Pictures.
- **Real-time Results**: Live progress bars showing vote counts per category as they happen.
- **Flexible Management**: Admins can create categories, manage candidates with photos, and schedule election windows.
- **Digital Ballot Preview**: Preview exactly what voters will see before publishing the election.
- **Automatic Winner Announcement**: Displays final winners once the voting period ends.
- **Modern UI**: Responsive design with smooth transitions and a clean aesthetic.

## Tech Stack
- **Flutter**: Cross-platform UI framework.
- **Shared Preferences**: Local data persistence for users and election data.
- **Local Auth**: Biometric authentication implementation.
- **Image Picker**: For managing candidate profile photos.

## Getting Started
1. Ensure you have Flutter installed.
2. Run `flutter pub get` to install dependencies.
3. Use `flutter run` to launch the application.

*Note: Admin credentials default to `admin` / `admin123`.*
