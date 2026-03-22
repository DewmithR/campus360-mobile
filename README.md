# campus360

 About
Campus 360 is a student utility mobile application built exclusively for NSBM Green University students. It centralises the essential day-to-day campus activities into a single, seamless experience — from reserving study spaces to tracking events, connecting with peers, and providing feedback to the university.
The app is built with Flutter and backed by Firebase, delivering real-time data across all features. It works in tandem with the Campus 360 Admin Web App, which university administrators use to manage content, respond to feedback, and oversee study room usage.

 Features
<br/>
 FeatureDescription AuthenticationNSBM email-only registration, login, and email verification flow DashboardPersonalised welcome, daily study streak, and quick-access feature grid Study RoomsBrowse rooms by faculty, view live occupancy, and check in/out in real time LeaderboardStudy streak rankings with a podium-style top-3 display EventsBrowse upcoming university events, view details, and manage bookings ChatReal-time messaging between students FeedbackSubmit categorised feedback anonymously or openly, and receive admin replies AccountView profile, change password, and manage account settings

Tech Stack
LayerTechnologyFrameworkFlutter (Dart)AuthenticationFirebase Auth — email/password with domain enforcementDatabaseCloud Firestore — real-time streamsArchitectureFeature-based (lib/features/)State ManagementStreamBuilder with live Firestore streamsUI SystemMaterial 3 with custom NSBM color palette

Project Structure
campus360-mobile/
└── lib/
    ├── core/
    │   ├── models/
    │   │   └── app_user.dart               # Shared user model
    │   └── services/
    │       ├── auth_service.dart           # Firebase Auth logic
    │       ├── user_service.dart           # User profile operations
    │       ├── chat_service.dart           # Chat & messaging logic
    │       └── event_service.dart          # Events & bookings logic
    │
    ├── features/
    │   ├── auth/
    │   │   ├── auth_wrapper.dart           # Auth state router
    │   │   ├── login_screen.dart
    │   │   ├── register_screen.dart
    │   │   └── email_verification_screen.dart
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart
    │   ├── study_rooms/
    │   │   ├── study_rooms_page.dart       # Faculty selection
    │   │   ├── faculty_rooms_page.dart     # Room listing with live occupancy
    │   │   └── room_details_page.dart      # Check-in/out & room info
    │   ├── leaderboard/
    │   │   └── leaderboard_page.dart
    │   ├── events/
    │   │   ├── events_page.dart
    │   │   ├── event_details_page.dart
    │   │   └── my_bookings_page.dart
    │   ├── chat/
    │   │   ├── chat_list_page.dart
    │   │   └── chat_room_page.dart
    │   ├── feedback/
    │   │   └── feedback_page.dart
    │   └── account/
    │       └── account_page.dart
    │
    ├── theme/
    │   ├── app_theme.dart                  # NSBM palette, spacing, Material 3 theme
    │   └── status_badge.dart               # Shared status badge widget
    │
    └── main.dart

Firestore Data Structure
users/{uid}
admins/{email}
feedbacks/{feedbackId}
events/{eventId}
bookings/{bookingId}
chats/{chatId}
    └── messages/{messageId}
faculties/{facultyName}
    └── rooms/{roomId}
            └── bookings/{bookingId}

The mobile app and the admin web app share the same Firebase project and Firestore database. Changes made through the admin panel (e.g., adding events, replying to feedback) reflect instantly in the mobile app.


Getting Started
Prerequisites

Flutter SDK >= 3.0.0
Firebase CLI installed
FlutterFire CLI installed
Access to the Campus 360 Firebase project

License
This project was developed as part of a university module at NSBM Green University. All rights reserved by the development team.