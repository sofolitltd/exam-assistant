<p align="center">
  <img src="https://img.icons8.com/fluency/96/school.png" alt="Exam Assistant" width="80"/>
</p>

<h1 align="center">Exam Assistant</h1>

<p align="center">
  <strong>A Flutter-based exam preparation platform for BCS and competitive exams in Bangladesh</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.12-blue?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Integrated-orange?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
</p>

---

## ✨ Features

- **📝 Live Exams** — Timer-based exam sessions with instant results
- **🧮 LaTeX Math Rendering** — Mathematical expressions rendered inline with `tex_text`
- **📊 Performance Tracking** — View stats (total exams, highest score, average) with trajectory chart
- **🔐 Firebase Authentication** — Email/password and Google sign-in
- **👤 Profile Management** — Edit profile, view exam history
- **🛠️ Admin Panel** — Create/manage exams, import questions via JSON, view results
- **📱 Responsive Design** — Works on mobile, tablet, and web

## 📸 Screenshots

*(Add screenshots here)*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Firebase project with Authentication, Firestore, and Storage enabled

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/exam_assistant.git
cd exam_assistant

# Install dependencies
flutter pub get

# Configure Firebase
# Place your google-services.json (Android) and GoogleService-Info.plist (iOS)
# in the respective platform directories (already gitignored)

# Run the app
flutter run
```

### Firebase Setup

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Enable **Email/Password** and **Google** sign-in in Authentication
3. Create a Firestore database with the following collections:
   - `users` — User profiles and stats
   - `exams` — Exam metadata
   - `questions` — Exam questions
   - `exam_results` — User exam results
4. Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
5. Run `flutterfire configure` or manually update `lib/firebase_options.dart`

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/        # App constants (Firestore collection names, etc.)
│   ├── router/           # GoRouter configuration
│   ├── theme/            # App theme & colors
│   └── widgets/          # Reusable widgets (ResponsiveWrapper, etc.)
├── features/
│   ├── admin/            # Admin panel (manage exams, questions, results)
│   │   └── views/
│   ├── auth/             # Authentication & profile
│   │   ├── controllers/
│   │   ├── data/         # Services, models
│   │   └── views/
│   ├── dashboard/        # Main navigation hub & profile view
│   │   ├── controllers/
│   │   └── views/
│   └── exam/             # Exam listing, live exam, results
│       ├── controllers/
│       ├── data/
│       └── views/
└── main.dart
```

## 🧪 Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform UI framework |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | NoSQL database |
| **Riverpod** | State management |
| **GoRouter** | Declarative routing |
| **fl_chart** | Performance trajectory charts |
| **tex_text** | LaTeX math rendering |
| **Google Fonts** | Typography |

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ for BCS and competitive exam aspirants in Bangladesh
</p>
