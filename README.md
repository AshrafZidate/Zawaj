# Zawaj

A relationship compatibility app for couples exploring marriage. Built with SwiftUI and Firebase.

## Overview

Zawaj helps couples discover compatibility through daily questions covering key relationship topics:
- Religious values
- Family expectations
- Personality compatibility
- Lifestyle goals
- Finances and career
- Marriage roles
- Parenting views
- Conflict resolution

## Project Structure

```
Zawaj/
├── Components/          # Reusable UI components
├── Config/             # App configuration (dev mode, etc.)
├── Models/             # Data models (User, Question, etc.)
├── Services/           # Business logic (Auth, Firestore, Questions)
├── ViewModels/         # State management
├── Views/              # UI screens
│   ├── Onboarding/     # Welcome & signup flow
│   ├── Main/           # Dashboard & home
│   ├── Profile/        # Settings & profile
│   └── Debug/          # Development tools
└── Resources/          # Assets & data files

docs/                   # Documentation
├── DESIGN_SYSTEM.md    # UI/UX guidelines
└── FIREBASE_SETUP.md   # Firebase configuration
```

## Tech Stack

- **Frontend**: SwiftUI (iOS 18+)
- **Backend**: Firebase
  - Authentication (Email, Google, Apple Sign-In)
  - Firestore Database
  - Cloud Storage (future)
- **Architecture**: MVVM

## Current Status

### ✅ Completed
- Complete onboarding flow (5 screens)
- Authentication system (email, Google, Apple)
- Main dashboard with tab navigation
- Profile & settings screen
- Question bank (8 questions uploaded to Firestore)
- Development mode for testing

### 🚧 In Progress
- Question detail screen
- Answer submission flow
- Partner connection system

### 📋 Planned
- Questions list view
- History/archive of answers
- Partner search & requests
- Edit profile functionality
- Notifications

## Development Setup

### Prerequisites
- Xcode 15+
- macOS 14+
- Firebase project configured

### Getting Started

1. **Clone & Open**
   ```bash
   cd /Users/ashraf/Documents/Zawaj
   open Zawaj.xcodeproj
   ```

2. **Firebase Configuration**
   - Already configured with `GoogleService-Info.plist`
   - Questions uploaded to Firestore
   - See `docs/FIREBASE_SETUP.md` for details

3. **Run in Simulator**
   - Select iPhone 17 Pro (or any device)
   - Press ⌘R to run
   - Development mode is enabled (bypasses auth)

### Development Mode

Set in `Zawaj/Config/AppConfig.swift`:
```swift
static let isDevelopmentMode = true  // Skip auth, use mock data
```

**When enabled:**
- Skips onboarding to dashboard
- Loads mock user data
- Shows random questions from question bank

**Before production:**
```swift
static let isDevelopmentMode = false
```

## Key Features

### Dashboard
- Today's question card
- Partner status (when connected)
- Find partner button (when not connected)
- iOS HIG-compliant tab bar navigation

### Profile Settings
- Account info (email, phone)
- Profile details (gender, birthday, relationship)
- Relationship preferences
- Partner connection management
- Notification settings (6 granular controls)
- App preferences (theme, answer format)

### Question Bank
- 8 carefully crafted questions
- Multiple choice (7) and open-ended (1)
- Covers all major relationship topics
- Stored in Firestore at `/questions` collection

## Design System

See `docs/DESIGN_SYSTEM.md` for complete guidelines.

### Colors
- **Primary Gradient**: `#2e0d5a` → `#b7486f`
- **Accent**: `rgb(240, 66, 107)`
- **Text**: White with opacity variations

### Components
- Glassmorphic cards (`.regularMaterial`)
- iOS-standard buttons and inputs
- Consistent 24pt horizontal padding
- Zawaj brand elements

## Firebase Structure

### Collections

**users/**
```
{
  id, email, fullName, username,
  gender, birthday, relationshipStatus,
  marriageTimeline, topicPriorities,
  partnerId, partnerConnectionStatus,
  answerPreference, photoURL,
  createdAt, updatedAt
}
```

**questions/**
```
{
  id, questionText, questionType,
  options, topic, followUpPrompt,
  isActive, createdAt
}
```

**answers/** (planned)
```
{
  id, userId, questionId,
  answerText, selectedOption,
  answeredAt
}
```

## Git Workflow

**Important**: Changes are NOT auto-committed. Commits require explicit instruction.

```bash
# Check changes
git status
git diff

# Stage & commit (only when instructed)
git add .
git commit -m "Your message"
git push
```

## Documentation

- **Design System**: `docs/DESIGN_SYSTEM.md`
- **Firebase Setup**: `docs/FIREBASE_SETUP.md`
- **This README**: Project overview

## Next Steps (MVP)

1. **Question Detail Screen** - Answer questions
2. **Partner Connection** - Find and connect with partner
3. **Questions List** - Browse all questions
4. **History View** - Compare answers
5. **Polish & Testing** - Final MVP prep

## Notes

- Development user: Ashraf Zidate (@ashraf)
- Mock partner: Sarah Johnson (@sarah)
- Questions rotate randomly in dev mode
- Tab bar: Home, Questions, History, Profile

## Support

For questions or issues, check:
- Firebase Console for backend data
- Xcode console for app logs
- Documentation in `docs/` folder

---

**Version**: 1.0.0-beta
**Last Updated**: December 22, 2025
**Status**: Active Development
