# MedMinder Architecture & Data Models

This document provides a comprehensive technical overview of the MedMinder iOS application. It is designed to help anyone (or any AI) quickly understand the project structure, data models, and core business logic.

## 🏗 Project Architecture

MedMinder follows **Clean Architecture** principles, separated into three main layers:

### 1. Domain Layer (`/Domain`)
The core of the application, containing business logic and entity definitions. It is independent of any external frameworks or UI.
- **Entities**: Plain data models (`Profile`, `Treatment`, `Medication`, `DoseLog`).
- **Interfaces**: Protocol definitions for repositories.
- **UseCases**: Business logic orchestrators (e.g., `MedicationUseCases`).
- **Utils**: Shared pure logic (e.g., `TreatmentProgressCalculator`).

### 2. Data Layer (`/Data`)
Handles data persistence and external integrations.
- **Repositories**: Practical implementations of Domain protocols (e.g., `LocalMedicationRepository`).
- **DataSources**: Low-level storage handlers (e.g., `FileStorageService` for JSON persistence).

### 3. Presentation Layer (`/Presentation`)
The UI layer, built with **SwiftUI** and following the **MVVM** pattern.
- **Modules**: Feature-specific views and ViewModels (e.g., `Home`, `Treatments`, `Medications`).
- **Common**: Shared UI components (`DoseLogRow`, `ProfileAvatar`) and extensions.

---

## 📊 Data Models

### Profile
Represents a user or a person being tracked.
```swift
struct Profile: Identifiable, Codable {
    let id: UUID
    var name: String
    var age: Int
    var imageName: String? // Path to profile image
}
```

### Treatment
A container for a set of related medications.
```swift
struct Treatment: Identifiable, Codable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var profileId: UUID? // Optional association with a Profile
}
```

### Medication
Specific medication details and scheduling rules.
```swift
struct Medication: Identifiable, Codable {
    let id: UUID
    var treatmentId: UUID
    var name: String
    var dosage: String
    var type: MedicationType // pill, syrup, injection, etc.
    var color: MedicationColor // UI theme color
    var initialTime: Date // Start of the schedule
    var frequencyHours: Int // Interval between doses
    var durationDays: Int // How long the medication lasts
}
```

### DoseLog
A record of a specific dose action.
```swift
struct DoseLog: Identifiable, Codable {
    let id: UUID        // Auto-generated
    let medicationId: UUID
    let scheduledTime: Date
    let takenTime: Date?
    let status: DoseStatus // .pending, .taken, .skipped
}
```

---

## ⚙️ Core Logic & Calculations

### 1. Unified Progress Calculation (`TreatmentProgressCalculator`)
Progress is **dose-based**, not time-based.
- **Medication Progress**: `loggedDoses (taken+skipped) / totalExpectedDoses`.
- **Treatment Progress**: Average of all associated medication progress scores.
- **Completion**: A medication is "Completed" only when `loggedDoses == totalExpectedDoses`.

### 2. Dose Generation Logic
- **Upcoming Doses**: Calculated by iterating from `initialTime` with `frequencyHours` until `durationDays` is reached, skipping slots that already have a `DoseLog`.
- **History (Dose Registry)**: Displays all actual `DoseLog` entries. If a scheduled slot has no log and is in the past, it is displayed as "Missed" (Pending).

### 3. Persistence
- **FileStorageService**: Saves and loads data from Local Documents directory as JSON files.
- **Refresh Policy**: ViewModels typically fetch data on `onAppear` or through Combine publishers when a save/update action completes.

---

---

## 💾 Data Persistence (JSON Examples)

The app saves data in the Local Documents directory. Below are examples of how these models are represented in JSON.

### Profile (`profiles.json`)
```json
[
  {
    "id": "A1B2C3D4-E5F6-4A5B-8C9D-0E1F2G3H4I5J",
    "name": "Mario Tatis",
    "age": 30,
    "imageName": "profile_mario.jpg"
  }
]
```

### Treatment (`treatments.json`)
```json
[
  {
    "id": "T1U2V3W4-X5Y6-4Z7A-8B9C-0D1E2F3G4H5I",
    "name": "Post-Surgery Recovery",
    "startDate": "2025-12-20T08:00:00Z",
    "profileId": "A1B2C3D4-E5F6-4A5B-8C9D-0E1F2G3H4I5J"
  }
]
```

### Medication (`medications.json`)
```json
[
  {
    "id": "M1E2D3I4-C5A6-4T7I-8O9N-0S1E2N3S4E5D",
    "treatmentId": "T1U2V3W4-X5Y6-4Z7A-8B9C-0D1E2F3G4H5I",
    "name": "Amoxicillin",
    "dosage": "500mg",
    "type": "pill",
    "color": "blue",
    "initialTime": "2025-12-20T08:00:00Z",
    "frequencyHours": 8,
    "durationDays": 7
  }
]
```

### DoseLog (`doselogs.json`)
```json
[
  {
    "id": "L1O2G3S4-A5B6-4C7D-8E9F-0A1B2C3D4E5F",
    "medicationId": "M1E2D3I4-C5A6-4T7I-8O9N-0S1E2N3S4E5D",
    "scheduledTime": "2025-12-20T08:00:00Z",
    "takenTime": "2025-12-20T08:05:00Z",
    "status": "taken"
  },
  {
    "id": "L2O3G4S5-B6C7-4D8E-9F0A-1B2C3D4E5F6A",
    "medicationId": "M1E2D3I4-C5A6-4T7I-8O9N-0S1E2N3S4E5D",
    "scheduledTime": "2025-12-20T16:00:00Z",
    "takenTime": null,
    "status": "skipped"
  },
  {
    "id": "L3O4G5S6-C7D8-4E9F-0A1B-2C3D4E5F6A7B",
    "medicationId": "M1E2D3I4-C5A6-4T7I-8O9N-0S1E2N3S4E5D",
    "scheduledTime": "2025-12-21T00:00:00Z",
    "takenTime": null,
    "status": "pending"
  }
]
```

---

## 🌍 Timezone & Date Normalization

Time management is critical to ensure doses are calculated correctly across local time changes.

- **Storage**: Dates are stored in **UTC (ISO8601)**.
- **Normalization**: All scheduled times are normalized to **zero seconds** (`ss:00`) to prevent millisecond mismatches during lookups.
- **DST Handling**: The app uses `Calendar.current.date(byAdding: .hour, ...)` which correctly accounts for Daylight Savings Transitions.
- **Minute Precision**: When matching a `DoseLog` to a scheduled slot, the app ignores the seconds component to account for slight persistence variations.

---

## 🛠 Domain Services & Utils

### Notification Service (`NotificationService`)
Handles local push notifications for reminders.
- **Trigger Window**: Reminders are scheduled **5 minutes before** the `scheduledTime`.
- **Immediate Trigger**: If an action window is already active but the 5-minute lead has passed, a notification is fired immediately (5-second delay).
- **Identifier**: Custom ID format `MedicationID-Timestamp` allows for precise cancellation of specific dose reminders.
- **Maintenance**: Notifications are rescheduled whenever a medication is added, edited, or marked as taken/skipped early.

### Progress Calculator (`TreatmentProgressCalculator`)
Centralized logic for status reporting.
- **Dose-Centric**: Progress is calculate as `(Logged Doses) / (Total Expected Doses)`.
- **Status Sync**: "Completed" status is strictly tied to `progress == 100%`.

---

## 🕒 Dose Action Windows

The app controls when "Mark as Taken" and "Mark as Skipped" buttons appear to ensure data integrity.

- **Lead Time (Customizable)**: Users can select a lead time window (from 30 minutes to 4 hours) in Settings. Action buttons appear before the `scheduledTime` based on this selection. This allows users to log doses they take slightly ahead of schedule.
- **Lag Time (24 Hours)**: Action buttons remain visible for **24 hours after** the `scheduledTime`. This provides a "grace period" for logging forgotten doses before they are considered fully missed.
- **Logic Location**: This is centralized in the `isWithinActionWindow` property within `HomeViewModel.MedicationDose` and `TreatmentMedicationDetailViewModel`, referencing `@AppStorage("actionWindowHours")`.

---

## ✅ Completion & Progress Logic

The transition to a "Completed" state is strictly governed by the following rules:

### 1. Medication Completion
- **Rule**: A medication is marked as `isCompleted = true` if and only if **Logged Doses == Total Expected Doses**.
- **Logged Doses**: Any `DoseLog` with status `.taken` or `.skipped`.
- **Expected Doses**: The total count of doses scheduled from `initialTime` until the end of `durationDays` based on `frequencyHours`.

### 2. Treatment Completion
- **Rule**: A treatment is `isCompleted = true` if and only if **ALL associated medications** are completed.
- **Progress**: The treatment's overall progress is the **arithmetic mean** of the progress percentages of its medications.

### 3. Visual Feedback
- **Progress Bar**: Increments immediately upon logging a dose (Taken/Skipped), providing instant gratification.
- **Completed Badge**: Automatically appears on cards and headers once the 100% threshold is reached.

---

## 🎨 Common Components Logic

Reusable UI elements that encapsulate shared behavior:

- **IntervalDatePicker**: Wraps `UIDatePicker` to enforce specific snap intervals.
  - Setup: **15-minute** interval for faster entry.
  - Logging: **1-minute** interval for precise tracking.
- **DoseLogRow**: A reactive row component.
  - Automatically displays "Missed Dose" actions (Mark as Taken/Skipped) if the `scheduledTime` is in the past and status is `pending`.
  - Uses `MissedDoseActionsView` to trigger the actual logging logic.
- **ProfileFilter**: Encapsulates the logic for filtering medication lists by `profileId`, maintaining a consistent visual "Selected" state across the dashboard.
