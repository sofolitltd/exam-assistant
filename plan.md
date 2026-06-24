```markdown
# 📑 Project Blueprint & Architecture Plan (`plan.md`)
**Project Name:** Exam Assistant  
**Target Audience:** BCS & Competitive Exam Candidates (Bangladesh)  
**Tech Stack:** Flutter, Flutter Riverpod, Firebase Suite (Auth & Firestore)  
**Architecture:** Feature-First Layered Architecture (Clean Architecture Principles)  

---

## 🏛️ 1. Technical Architecture (Senior Architect Perspective)

### 🧱 Architectural Pattern: Feature-First Layering
To ensure scalability, code isolation, and a seamless future migration to a custom PostgreSQL/Go/Hono API, the codebase is strictly separated by **Features**, and sub-layered by **Layers (Data ──► Controller ──► Presentation)**.



### 📂 Directory & Folder Structure
```text
lib/
├── main.dart                     # App entry point & initialization (Firebase, Riverpod)
├── core/                         # Global & shared configurations
│   ├── theme/                    # Design tokens, color palettes, typographies
│   ├── constants/                # Asset paths, Firebase collection names, global keys
│   └── widgets/                  # Shared UI components (Custom Buttons, Shimmers, Loaders)
└── features/                     # Self-contained modules per feature
    ├── auth/                     # Authentication Module
    │   ├── data/models/          # user_model.dart
    │   ├── data/services/        # firebase_auth_service.dart
    │   ├── controllers/          # auth_controller.dart, auth_state.dart
    │   └── views/                # login_screen.dart, register_screen.dart
    ├── quiz/                     # Core Quiz & Exam Engine
    │   ├── data/models/          # exam_model.dart, question_model.dart
    │   ├── data/services/        # firestore_quiz_service.dart
    │   ├── controllers/          # quiz_state_controller.dart, timer_controller.dart
    │   └── views/                # exam_list_screen.dart, live_quiz_screen.dart, result_screen.dart
    └── dashboard/                # Analytics & Community Rankings
        ├── data/models/          # user_stats_model.dart
        ├── controllers/          # leaderboard_controller.dart, stats_controller.dart
        └── views/                # main_navigation_hub.dart, leaderboard_view.dart, profile_view.dart

```

### 🗄️ Database Schema Design (Firestore NoSQL to Relational Blueprint)

#### 1. `users` Collection

* **Path:** `/users/{uid}`
* **Purpose:** Stores profile metadata and denormalized aggregates to eliminate expensive real-time queries for dashboards.
* **Fields:**
```json
{
  "uid": "String",
  "name": "String",
  "email": "String",
  "totalExamsAttended": "int",
  "highestScore": "double",
  "averageScore": "double",
  "updatedAt": "Timestamp"
}

```



#### 2. `master_questions` Collection

* **Path:** `/master_questions/{questionId}`
* **Purpose:** The central data bank for granular analysis, search, and future contextual exam generation.
* **Fields:**
```json
{
  "id": "String",
  "questionText": "String",
  "subject": "String",
  "options": {
    "A": "String",
    "B": "String",
    "C": "String",
    "D": "String"
  },
  "correctOption": "String (A/B/C/D)",
  "createdAt": "Timestamp"
}

```



#### 3. `exams` Collection

* **Path:** `/exams/{examId}`
* **Purpose:** Atomic document per exam. Pre-packs full question data arrays into a single doc read to slash Firebase Read Costs and optimize network egress.
* **Fields:**
```json
{
  "examId": "String",
  "title": "String",
  "durationSeconds": "int",
  "negativeMarks": "double",
  "questionIds": ["String"],
  "questions": [
    {
      "questionText": "String",
      "options": {"A": "String", "B": "String", "C": "String", "D": "String"},
      "correctOption": "String"
    }
  ]
}

```



---

## 🎨 2. Product & UI/UX Guidelines (Product Designer Perspective)

### 👁️ User Journey Flow

```
[ Splash/Auth ] ──► [ Home / Category Matrix ] ──► [ Exam Overview Pre-Sheet ]
                                                              │
[ Leaderboard/Rank ] ◄── [ Instant Score Card ] ◄── [ Live Quiz Screen (Timer) ]

```

### ⚡ Critical UX Directives

1. **Authentication Friction Reduction:** B2C educational app conversion hinges on speed. Prioritize One-Tap **Google Sign-In** over manual forms.
2. **The Pre-Exam Buffer Sheet:** Never launch users straight into a countdown. Provide a declarative modal/bottom sheet detailing parameters: *Time Limit, Negative Marking rules, and Question Count* before confirming initiation.
3. **Immersive Quiz Interface:**
* **The Dynamic Timer:** Positioned persistently at the top. Shifts color semantics (Teal to Crimson) in the final 10 minutes to nudge urgency safely.
* **Safe State Persistence:** Options selected must resolve to local Riverpod memory instantly. Users should be able to alter responses or skip fluidly without lag.


4. **Post-Exam Catharsis (Result Card):** Display an immediate breakdown of *Correct, Incorrect, and Net Marks* followed by a color-coded review list (Green backdrops for correct choices, Crimson tags for mistakes).

### 🎨 Design Tokens & Semantics

* **Primary Branding Color:** `Deep Teal (#005C53)` or `Classic Indigo (#1A237E)` – project authority, focus, and stability.
* **Semantic Feedback:** Success State: `Emerald Green (#2E7D32)`, Error/Wrong State: `Crimson Red (#C62828)`.
* **Typography Focus:** Primary cross-platform Bangla rendering: **Hind Siliguri** or **Kalpurush**. Minimum question text sizing must be `16sp` with an optimized line height of `1.5` for high legibility under timed stress.

---

## 🛠️ 3. Implementation Checklist & Tech Dependencies (Flutter Developer Perspective)

### 📦 Mandatory Pubspec Dependencies
riverpod 3, anotation, generarotor, firebase_core, firebase_auth, cloud_firestore, google_sign_in, google_fonts, fl_chart, uuid


### 🛠️ Developer SOP & Implementation Steps

#### Phase 1: Core Foundation & Shared Shells

* [ ] Initialize Firebase Multi-Platform projects (Android/iOS).
* [ ] Configure `core/theme` utilizing assigned Design Tokens.
* [ ] Set up global Riverpod scopes and structure core route structures.

#### Phase 2: Feature - Auth & Registration

* [ ] Code `FirebaseAuthService` isolating native credential calls.
* [ ] Write `authProvider` to cleanly stream explicit User States across the UI.
* [ ] Deliver the high-fidelity Google One-Tap UI login workflow.

#### Phase 3: Feature - Admin Interface & AI Parsing Pipeline

* [ ] **The Admin Pipeline:** Create an isolated view containing a raw text field.
* [ ] Paste the structured clean JSON outputs fetched straight via the **Gemini AI Studio prompt**.
* [ ] Execute `Firestore WriteBatch` routines to pipe questions seamlessly into both `master_questions` and `exams` collections inside a single safe execution block.

#### Phase 4: Feature - Live Quiz Engine

* [ ] Set up `quizStateProvider` to safely retain selected user options on active sessions.
* [ ] Implement a highly accurate recursive `Ticker` controller for the countdown timer.
* [ ] Build the local client-side evaluation function (`Net Score = Correct - (Wrong * NegativeMarking)`).

#### Phase 5: Feature - Leaderboards & Analytics

* [ ] Deploy query filters limiting leaderboard snapshots to top-tier records.
* [ ] Populate user profile summaries utilizing `fl_chart` to render performance trajectory graphs.

```

---

## 🚀 Future Migration Disclaimer (Architect Note)
Because we are utilizing **Riverpod Controllers** as an intermediary layer, the UI views never interact with Firebase references directly. They consume generic data models (`Exam`, `Question`, `UserStats`). 

When migrating to **PostgreSQL** or a **Go/Hono REST API** later, developers will *only* replace the files inside `features/*/data/services/` with a clean `Http/Dio` network client mapping data from JSON. The presentation layer, local timer calculations, and core state mechanics will remain untouched.

```