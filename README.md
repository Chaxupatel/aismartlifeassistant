# AI Smart Life Assistant 🧠✨

AI Smart Life Assistant is an ultra-premium, state-of-the-art Flutter application designed to automate and simplify daily schedules, tasks, and reminders. The app leverages a gorgeous iOS-inspired glassmorphic design system layered with advanced offline/online database synchronisation, smart mobile ads, and AI task parsing.

---

## 🎨 Premium Design Aesthetics
* **iOS-Style Glassmorphism**: Utilises custom-engineered `GlassContainer` overlays featuring layered linear translucent gradients, specular light highlights, and glowing outlines.
* **Responsive Bottom Capsule Nav**: Replaces default bottom navigation bars with a floating stack capsule bar that displays content rolling beneath its blurred window.
* **Intelligent GPU Optimization**: Automatically bypasses expensive `BackdropFilter` shaders on static elements to guarantee **60/120 FPS scrolling**, reserving heavy blurs only for active modal overlays and floating bars.

---

## 🚀 Key Upgraded Features

### 1. Smart Mobile Monetisation
* **Adaptive App Open Ads**: Dynamically preloads and presents full-screen App Open Ads on startup to monetise launching cycles.
* **Glassmorphic Native Ads**: Seamlessly integrates AdMob **Native Templates** inline in scrollable feeds (Reminders list every 5th item) and dashboard cards. Styled locally to blend natively into the app's visual identity.

### 2. Firestore-Linked Version Checker
* **Live Update Prompts**: Compares local version metrics (`package_info_plus`) with Firestore configurations to check for updates.
* **Force Update Controls**: Allows admins to mark updates as critical, triggering a non-dismissible dialog that locks the app until updated.
* **Release Notes Delivery**: Renders custom release log bullet points fetched directly from the database before redirecting to App/Play Store.

### 3. Firebase Remote Config
* **Over-the-Air Feature Flags**: Remotely toggles components (like AI recommendations or voice inputs) or adjusts ad frequencies dynamically from the Firebase Console without pushing new app store builds.

### 4. Interactive Help & Support
* **Glassmorphic FAQ Accordeons**: Animated FAQ questions that expand smoothly.
* **Direct Firestore Feedback logger**: Feedback submissions write directly to the database with a 4-second timeout to prevent infinite spinner hangs if offline.
* **Support Email Copying**: Support panel with copy-to-clipboard actions (support email: `caxu2003@gmail.com`).

---

## 📂 Project Directory Structure
The app adheres to a clean, **Feature-First Architecture** for maximum scalability and decoupling:

```text
lib/
├── core/
│   ├── constants/    # App constants (colors, sizes, strings)
│   ├── router/       # GoRouter routes and shells
│   ├── services/     # Global plugins (AdMob, Remote Config, Notifications)
│   ├── theme/        # HSL-driven light and dark themes
│   └── widgets/      # Reusable widgets (GlassContainer, buttons, etc.)
├── features/
│   ├── ai_assistant/ # AI natural language chat and reminder parsing
│   ├── auth/         # Email/Google OAuth authentication flows
│   ├── calendar/     # Events & calendar grid layout views
│   ├── home/         # Dashboard & main navigation layouts
│   ├── profile/      # User profile, display updates, and support center
│   ├── reminders/    # Tasks, category filters, and Hive offline storage
│   └── settings/     # Tone adjusters, theme pickers, & updates checker
└── main.dart         # Entry point & app initialisation sequence
```

---

## ⚙️ Backend Configurations (Firebase Console)

To ensure the version checks and remote settings execute correctly, populate your Firebase Console as follows:

### A. Firestore Collections

#### 1. `app_config` (Collection) ➡️ `version` (Document)
Create this document to control app version checking:
* `latest_version` (`string`): e.g., `1.1.0`
* `force_update` (`boolean`): e.g., `false`
* `update_url` (`string`): e.g., `https://play.google.com/store/apps/details?id=com.chaxu.ai_smart_life_assistant`
* `release_notes` (`string`): e.g., `* Added inline native ads\n* Implemented Firestore-linked update checks\n* Fixed scrolling lag`

#### 2. `feedbacks` (Collection)
Created automatically when users submit feedback forms. Contains fields:
* `email` (`string`)
* `feedback` (`string`)
* `submittedAt` (`timestamp`)

---

### B. Firebase Remote Config Parameters

Add the following keys in your Firebase Remote Config Console to toggle feature options:

| Parameter Key | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `enable_ai_suggestions` | `boolean` | `true` | Show/hide AI recommendations on the home dashboard. |
| `enable_voice_input` | `boolean` | `false` | Enable or disable voice input prompts on the AI screen. |
| `ad_interval_reminders` | `number` | `5` | Set the number of items between inline native ads. |
| `support_email` | `string` | `caxu2003@gmail.com` | Target support contact address. |

---

## 🛠️ Getting Started

1. **Clone and get packages**:
   ```bash
   flutter pub get
   ```
2. **Clean build files (if updating dependencies)**:
   ```bash
   flutter clean
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```
