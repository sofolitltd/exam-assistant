<p align="center">
  <img src="https://img.icons8.com/fluency/96/school.png" alt="Exam Assistant" width="80"/>
</p>

<h1 align="center">Exam Assistant</h1>

<p align="center">
  <strong>A Flutter-based exam preparation platform for BCS and competitive exams in Bangladesh</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.7-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.13.5-blue?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Database-Neon_Postgres-00E699?logo=neon" alt="Neon Postgres"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
</p>

---

## ✨ Features

- **📝 Live Exams** — Timer-based exam sessions with instant results
- **🧮 LaTeX Math Rendering** — Mathematical expressions rendered inline with `tex_text`
- **📊 Performance Tracking** — View stats (total exams, highest score, average) with trajectory chart
- **🔐 Account security** — Email/password authentication through the Go API, with bcrypt hashes in Postgres and secure device-side session storage
- **👤 Profile Management** — Edit profile, view exam history
- **Admin tools** — Use the separate Next.js admin application in `../exam_assistant_admin`
- **Dynamic syllabi** — Browse BCS, NCTB, bank, and other configured programs and practice by syllabus topic
- **🗓️ Routine tracking** — Build a personal daily routine (or clone a published template), check in on adherence twice a day, and review a weekly per-block summary of where you're slipping
- **📱 Responsive Design** — Works on mobile, tablet, and web

## 📸 Screenshots

*(Add screenshots here)*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.47.7 (Dart 3.13.5)
- The Exam Assistant Go API connected to Neon for authentication and app data

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/exam_assistant.git
cd exam_assistant

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Make targets

From the Flutter project directory, use `make run-web` to run in Chrome or
`make run-android` to run on the first connected Android device/emulator.
`make setup`, `make analyze`, and `make build-web` install dependencies, analyze
the app, and build the web target respectively.

The app uses the Go API for registration, login, profiles, exam content,
notices, results, leaderboard, and syllabus browsing. Passwords are hashed
with bcrypt by the API; the app stores only the opaque session token in secure
storage. Set `API_BASE_URL` at build/run time when the API is not reachable at
`http://localhost:8080`, for example:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

Firebase Authentication, Cloud Firestore, and Cloud Storage are not used by the
app. Firebase Core remains initialized for future Firebase Cloud Messaging
integration only. All current user and exam data is served by the Go API from
Neon Postgres.

### Routine tracking

The routine feature (`lib/features/routine/`) lets a user build a day
timetable of blocks (study, prayer, meal, rest, other), each with a time
range and the days of the week it applies to. Users either start from a
published template (admin-managed, see `exam_assistant_admin`) or build one
from scratch, then edit it any time from the routine tab.

Reminders are scheduled entirely on-device with `flutter_local_notifications`
(`lib/features/routine/services/routine_notification_service.dart`) — there is
no server-side push. Deliberately capped at three notifications a day (two
check-ins, one weekly summary) to avoid alert fatigue; there is no per-block
notification. Check-ins are logged through `PUT /v1/routine` and
`POST /v1/routine/logs` on the Go API, and the weekly summary is fetched (not
computed client-side) from `GET /v1/routine/summary`.

For a physical Android device using the local API, connect the phone and
computer to the same network, set `API_ADDR=:8080` in
`../exam_assistant_api/.env`, and restart the API. Then run `make run-r-l` from
the Flutter app directory. This target uses the computer's Wi-Fi IP instead of
`localhost` and checks API reachability before launching the app. Local HTTP is
allowed only in Android debug builds; use HTTPS for release builds.

### Firebase configuration

Firebase is not required for authentication or app data. Firebase Core is kept
for planned FCM support; configure `lib/firebase_options.dart` and the platform
Firebase app files only if using that integration.

Configure the Go API and apply its Neon migrations before running the app.
Accounts created by the previous Firebase Authentication flow do not have
Postgres passwords; users should register new accounts for this fresh start.

## 🏗️ Project Structure

```
lib/
├── core/
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
│   ├── exam/             # Exam listing, live exam, results
│   │   ├── controllers/
│   │   ├── data/
│   │   └── views/
│   └── routine/          # Routine builder, daily check-in, weekly summary
│       ├── controllers/
│       ├── data/         # Models, RoutineApiService
│       ├── services/     # Local notification scheduling
│       └── views/
└── main.dart
```

## 🧪 Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform UI framework |
| **Neon Postgres** | Accounts, exam content, notices, results, and statistics via the Go API |
| **bcrypt** | Password hashing in the Go API |
| **flutter_secure_storage** | Opaque API session token storage |
| **Riverpod** | State management |
| **GoRouter** | Declarative routing |
| **fl_chart** | Performance trajectory charts |
| **tex_text** | LaTeX math rendering |
| **Google Fonts** | Typography |
| **flutter_local_notifications** | On-device routine check-in and weekly summary reminders |

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ for BCS and competitive exam aspirants in Bangladesh
</p>
