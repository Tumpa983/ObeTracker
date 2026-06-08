# OBE Tracker — Flutter Frontend

BUP CO–PO Mapping & Attainment Tracking System  
Flutter 3.x · Riverpod · GoRouter · fl_chart · Dio

## Quick Start

```bash
flutter pub get
flutter run
```

## Configuration

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:3000/api/v1';
```

Change the host/port to match your backend.

## Demo credentials (after seeding the backend)

| Role    | Email                  | Password      |
|---------|------------------------|---------------|
| Admin   | admin@bup.edu.bd       | Admin@1234    |
| Faculty | faculty@bup.edu.bd     | Faculty@1234  |
| Student | student@bup.edu.bd     | Student@1234  |
