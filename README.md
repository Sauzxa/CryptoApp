# Crypto Immobilier App

A Flutter application for crypto real estate management with call log functionality.

## 🐳 Docker Setup (Recommended)

This project includes a complete Docker setup with all necessary dependencies including:
- **Java 17 JDK** - Required for Android development
- **Android SDK** - Complete Android development environment
- **Kotlin** - Latest version for Android development
- **Flutter SDK** - Latest stable version
- **Gradle** - Build system for Android

### Quick Start with Docker

#### 1. Using Docker Compose (Recommended)

```bash
# Build and run the production web app
docker-compose up --build

# Access the app at http://localhost:8080
```

For development with hot reload:
```bash
# Run development server with hot reload
docker-compose --profile dev up crypto-immobilier-dev --build

# Access the dev server at http://localhost:8081
```

#### 2. Using Docker directly

```bash
# Build the Docker image
docker build -t crypto-immobilier-app .

# Run the container
docker run -p 8080:8080 crypto-immobilier-app

# Access the app at http://localhost:8080
```

### Docker Commands for Different Platforms

#### Web Development
```bash
# Build and serve web app
docker run -p 8080:8080 crypto-immobilier-app

# Development with hot reload
docker run -p 8080:8080 -v $(pwd):/app crypto-immobilier-app flutter run --web-port 8080 --web-hostname 0.0.0.0 --hot
```

#### Android Development
```bash
# Build APK
docker run -v $(pwd):/app crypto-immobilier-app flutter build apk --release

# Build App Bundle
docker run -v $(pwd):/app crypto-immobilier-app flutter build appbundle --release

# Run tests
docker run -v $(pwd):/app crypto-immobilier-app flutter test
```

#### Interactive Development
```bash
# Enter container shell for development
docker run -it -v $(pwd):/app crypto-immobilier-app bash

# Inside container, you can run:
flutter doctor
flutter pub get
flutter run
flutter build web
flutter test
```

### Environment Requirements

The Docker container includes:
- **Ubuntu 22.04** base system
- **Java 17 JDK** (`/usr/lib/jvm/java-17-openjdk-amd64`)
- **Android SDK** with API levels 33 & 34
- **Flutter SDK** version 3.24.3
- **Kotlin** version 1.9.20
- **Gradle** version 8.4
- **Android NDK** version 25.1.8937393

### Docker Files

- `Dockerfile` - Main container configuration
- `docker-compose.yml` - Service orchestration
- `.dockerignore` - Excludes unnecessary files from build context

## 🛠️ Local Development (Alternative)

If you prefer local development without Docker:

### Prerequisites

- Flutter SDK (3.24.3 or later)
- Java 17 JDK
- Android SDK
- Kotlin

### Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Check your setup:
```bash
flutter doctor
```

3. Run the app:
```bash
# Web
flutter run -d web-server --web-port 8080

# Android (with device connected)
flutter run

# Build for production
flutter build web --release
```

## 📱 Features

- Call log access and management
- URL launcher integration
- Permission handling
- Cross-platform support (Web, Android, iOS, Windows, macOS, Linux)

## 🧪 Testing

```bash
# Run tests locally
flutter test

# Run tests in Docker
docker run -v $(pwd):/app crypto-immobilier-app flutter test
```

## 📦 Dependencies

Key dependencies include:
- `call_log: ^6.0.1` - Call log access
- `permission_handler: ^12.0.1` - Permission management  
- `url_launcher: ^6.3.2` - URL handling
- `intl: ^0.20.2` - Internationalization

## 🚀 Deployment

### Web Deployment
The Docker container serves the built web app on port 8080. You can deploy this container to any cloud platform that supports Docker.

### Android Deployment
Build APK or App Bundle using the Docker container and deploy to Google Play Store.

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Docker Documentation](https://docs.docker.com/)
- [Android Development](https://developer.android.com/)
