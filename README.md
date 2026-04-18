# StudySpot 📚

> Find your perfect study spot at Mahidol University

A Flutter mobile app that helps students discover, review, and save the best
study locations on campus.

## ✨ Features

- 🗺️ **Map View** — Browse all study spots on an interactive Google Map
- 🔍 **Smart Filter** — Filter by WiFi, plugs, quiet level, and opening hours
- ⭐ **Reviews** — Rate and review spots with detailed criteria
- 🔖 **Save Places** — Bookmark your favorite study spots
- 📸 **Add Spots** — Submit new study locations with photos
- 👤 **Profile** — View your review history and saved places

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Image Storage | Cloudinary |
| Maps | Google Maps Flutter |
| State Management | Provider |

## 👥 Team

| Member | Role |
|--------|------|
| **Mhiu** | Backend — Firebase services, data models, auth logic |
| **Nana** | Frontend — UI screens, components, user experience |

## 📁 Project Structure

```
lib/
├── main.dart
├── models/
│   └── models.dart
├── services/
│   ├── auth_provider.dart
│   ├── firebase_service.dart
│   └── cloudinary_service.dart
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── main_shell.dart
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── place_detail_screen.dart
│   ├── add_place_screen.dart
│   ├── add_review_screen.dart
│   ├── my_reviews_screen.dart
│   ├── saved_places_screen.dart
│   └── profile_screen.dart
└── utils/
    └── app_theme.dart
```