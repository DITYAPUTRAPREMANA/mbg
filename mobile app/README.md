# MBG Mobile App 📱

A modern Flutter application designed for nutrition tracking and food scanning, integrated with Supabase for backend services and a custom AI model for food detection.

## 🚀 Features

- **Food Scanning**: Capture or upload photos of your meals to get instant nutritional information.
- **Onboarding**: Seamless introduction to the app's core functionalities.
- **Authentication**: Secure login and registration powered by Supabase.
- **History**: Track your previous scans and nutritional intake over time.
- **Profile Management**: Manage your personal information and preferences.
- **Real-time Detection**: Integration with specialized models for accurate food identification.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Backend**: [Supabase](https://supabase.com/)
- **Networking**: [HTTP](https://pub.dev/packages/http) & [Supabase Flutter](https://pub.dev/packages/supabase_flutter)
- **Icons**: [Lucide Icons](https://pub.dev/packages/lucide_icons) & [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
- **Environment**: [Flutter Dotenv](https://pub.dev/packages/flutter_dotenv)

## 📂 Project Structure

```text
lib/
├── features/          # Feature-based modules
│   ├── auth/          # Authentication screens & logic
│   ├── history/       # Scan history & records
│   ├── home/          # Main dashboard
│   ├── onboarding/    # Introduction screens
│   ├── profile/       # User profile & settings
│   └── scan/          # Food scanning & AI integration
├── services/          # Core services (Supabase, API, etc.)
└── main.dart          # Entry point
```

## ⚙️ Setup & Installation

### Prerequisites

- Flutter SDK (latest stable version)
- A Supabase project
- A `.env` file in the root of the `mobile app` folder

### Environment Configuration

Create a `.env` file in the `mobile app/` directory:

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
API_URL=YOUR_MODEL_API_URL
```

### Getting Started

1. Clone the repository
2. Navigate to the mobile app directory:
   ```bash
   cd "mobile app"
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## 📸 Screenshots

*(Add screenshots here after implementation)*

---

Developed as part of the MBG Project.
