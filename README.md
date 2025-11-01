# 🏢 Crypto Immobilier App

Flutter mobile application for real estate management with real-time communication.

---

## ✨ Features

### 🔐 Authentication
- User registration and login
- JWT-based secure authentication
- Password reset via email (6-digit verification code) using resend
- Role-based access (Commercial Agent / Field Agent /admin)
- Persistent login sessions

### 👤 Profile Management
- Edit profile information (name, email, phone)
- Upload profile photo (Cloudinary integration third party api)
- Change password third api 
- View account details 
- Toggle availability status (Field Agents from availble to unavailble (bid))

### 💬 Real-Time Messaging
- Text messaging powerd by Socket.IO
- Voice message recording and playback using cloudinary 
- Audio waveform visualization
- Create and manage chat rooms
- Message read receipts
- Typing indicators
- Real-time message delivery
- Voice message cloud storage

### 📞 Call Management
- Access phone call history
- View incoming/outgoing calls
- Filter calls by type
- Search calls by name/number
- Direct calling from call logs
- Call timestamps and duration
- Contact information display

### 📅 Reservations
- Create client appointments
- Assign to available field agents
- Real-time reservation updates
- Countdown timers for appointments
- Search, View and filter reservations
- Track call direction (incoming/outgoing)
- Client information storage
- Reservation status management

### 📊 Suivi (Tracking) Page - Commercial Agents Only
- **Overview Dashboard**: View all reservations at a glance
- **Statistics Cards**:
  - En Cours (In Progress) - Active appointments
  - Terminée (Completed) - Successfully completed visits
  - Annulée (Cancelled) - Cancelled appointments
  - Missed (Missed) - Missed appointments
- **Calendar View**: Visual calendar with all reservations
- **Real-time Stats**: Live updating statistics
- **Filter by Status**: Quick filter reservations by status
- **Agent Performance**: Track field agent performance
- **Date Range Selection**: View stats for specific periods

### 🔔 Notifications
- Push notifications (Firebase Cloud Messaging)
- Local notifications
- Real-time alerts for messages
- Reservation notifications
- Notification history
- Badge counters

### 🎨 UI/UX
- Modern glass morphism design
- Dark/Light theme support
- Smooth animations
- Responsive layouts
- Custom navigation
- Loading states
- Error handling
- Pull-to-refresh

### 📱 Platform Support
- Android
- iOS  
- Web
- Windows
- macOS
- Linux

---

## 🛠️ Technology Stack

**Frontend:** Flutter 3.24.3  
**State Management:** Provider  
**Real-Time:** Socket.IO  
**Backend API:** Node.js + Express/ts  
**Database:** MongoDB  
**Storage:** Cloudinary  
**Notifications:** Firebase Cloud Messaging  
**Authentication:** JWT
**Sender:** third party email sender

---

## 🚀 Quick Start

### Run the app
```bash
flutter pub get
flutter run
```

### Build for production
```bash
flutter build apk --release        # Android
flutter build ios --release        # iOS
flutter build web --release        # Web
```

---

## 📧 Email Features

- Password reset via email
- 6-digit verification codes
- Custom domain: `noreply@crypto-immobilier.site`
- 15-minute code expiration
- Resend integration

---

**Built with Flutter** 💙

## 🛠️ Technical Architecture

### State Management
- **Provider Pattern**: Centralized state management using Provider package
- **AuthProvider**: Handles authentication state and user data
- **MessagingProvider**: Manages real-time messaging and room data
- **ThemeProvider**: Controls app theming and user preferences
- **NotificationProvider**: Handles notification state and management

### Backend Integration
- **RESTful API**: Complete API integration for all features
- **Socket.IO**: Real-time bidirectional communication
- **Cloudinary**: Image and voice message cloud storage
- **Firebase**: Push notifications and authentication
- **JWT Authentication**: Secure token-based authentication

### Key Dependencies
```yaml
# Core Flutter
flutter: sdk
cupertino_icons: ^1.0.8

# State Management
provider: ^6.1.5+1

# Networking & API
http: ^1.5.0
socket_io_client: ^3.1.2

# Authentication & Storage
shared_preferences: ^2.5.3
firebase_core: ^4.2.0
firebase_messaging: ^16.0.3

# Media & Recording
image_picker: ^1.2.0
record: ^6.1.2
audioplayers: ^6.5.1
audio_waveforms: ^1.3.0

# Call Management
call_log: ^6.0.1
permission_handler: ^12.0.1
url_launcher: ^6.3.2

# Notifications
awesome_notifications: ^0.10.1
flutter_local_notifications: ^19.4.2

# Utilities
intl: ^0.20.2
timeago: ^3.7.1
path_provider: ^2.1.5
```

## 🐳 Docker Setup (Recommended)

This project includes a complete Docker setup with all necessary dependencies:

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
- Java 21 JDK
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

## 📱 App Screens & Navigation

### Main Navigation Structure
- **Home Page**: Dashboard with quick access to all features
- **Messaging**: Real-time chat with voice message support
- **Call Management**: Call logs and direct calling functionality
- **Reservations**: Appointment booking and management
- **Suivi (Tracking)**: Statistics and calendar view (Commercial Agents only)
- **Profile Settings**: User profile editing and preferences

### Detailed Screen Features

#### 🏠 Home Page
- **Quick Actions**: Access to all major features
- **Availability Toggle**: Field agents can toggle availability status
- **Notification Center**: Real-time notification display
- **Reservation Alerts**: Active reservation notifications
- **User Status**: Current user information and role display

#### 💬 Messaging System
- **Room List**: All available chat rooms
- **Message Room**: Individual chat interface with:
  - Text message input with send button
  - Voice recording with waveform visualization
  - Message history with timestamps
  - Read receipts and delivery status
  - Typing indicators
  - Real-time message updates

#### 📞 Call Management
- **Call Log Display**: Complete call history with:
  - Call type indicators (incoming/outgoing)
  - Contact names and numbers
  - Call timestamps and duration
  - Search and filter functionality
- **Direct Calling**: One-tap calling from call logs
- **Permission Management**: Smart permission requests

#### 📅 Reservation System
- **Create Reservation**: 
  - Client information form
  - Date and time picker
  - Message/notes field
  - Call direction tracking
- **Reservation List**: 
  - All reservations with status
  - Countdown timers for upcoming appointments
  - Search and filter functionality
  - Real-time status updates

#### 📊 Suivi (Tracking) Page
- **Statistics Dashboard** (Commercial Agents only):
  - **En Cours Card**: Count of in-progress appointments
  - **Terminée Card**: Count of completed appointments
  - **Annulée Card**: Count of cancelled appointments
  - **Missed Card**: Count of missed appointments
- **Calendar Integration**:
  - Monthly calendar view
  - Color-coded reservation markers
  - Date selection for detailed view
  - Quick navigation between months
- **Detailed Views**:
  - Click on any stat card to filter reservations
  - View specific reservations for selected dates
  - Agent-specific performance tracking
  - Export capabilities for reporting

#### ⚙️ Profile Settings
- **Profile Information**: 
  - Name, email, phone editing
  - Profile photo upload with Cloudinary integration
  - Role and availability display
- **Account Management**: 
  - Password change functionality
  - Account preferences
  - Theme selection

## 🔧 Configuration & Setup

### Environment Variables
Create a `.env` file in the server directory with:
```env
# Database
MONGODB_URI=mongodb://localhost:27017/crypto-immobilier

# JWT
JWT_SECRET=your-jwt-secret

# Cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

### Firebase Setup
1. Create a Firebase project
2. Enable Cloud Messaging
3. Download `google-services.json` for Android
4. Configure iOS with `GoogleService-Info.plist`

### Cloudinary Setup
1. Create a Cloudinary account
2. Get your cloud name, API key, and API secret
3. Configure upload presets for images and voice messages

## 🧪 Testing

```bash
# Run tests locally
flutter test

# Run tests in Docker
docker run -v $(pwd):/app crypto-immobilier-app flutter test
```

## 🚀 Deployment

### Web Deployment
The Docker container serves the built web app on port 8080. You can deploy this container to any cloud platform that supports Docker.

### Android Deployment
Build APK or App Bundle using the Docker container and deploy to Google Play Store.

### iOS Deployment
Build iOS app using Xcode and deploy to App Store.

## 📚 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update profile

### Messaging Endpoints
- `GET /api/messages/rooms` - Get user rooms
- `POST /api/messages/rooms` - Create room
- `GET /api/messages/rooms/:id/messages` - Get room messages
- `POST /api/messages/rooms/:id/messages` - Send message (text/voice)

### Reservation Endpoints
- `POST /api/reservations` - Create reservation
- `GET /api/reservations` - Get user reservations
- `PUT /api/reservations/:id` - Update reservation
- `DELETE /api/reservations/:id` - Cancel reservation

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Role-Based Access Control**: Different permissions for different user types
- **Input Validation**: Comprehensive input validation on both client and server
- **File Upload Security**: Secure file upload with type validation
- **HTTPS Support**: All communications encrypted
- **Permission Management**: Smart permission requests for device features

## 🌟 Advanced Features

### Real-Time Communication
- **WebSocket Integration**: Socket.IO for real-time updates
- **Message Broadcasting**: Instant message delivery to all room members
- **Typing Indicators**: Real-time typing status
- **Online Status**: User availability tracking

### Voice Message System
- **High-Quality Recording**: Optimized audio recording settings
- **Waveform Visualization**: Visual representation of voice messages
- **Cloud Storage**: Secure cloud storage with Cloudinary
- **Playback Controls**: Full audio playback functionality

### Notification System
- **Push Notifications**: Firebase Cloud Messaging
- **Local Notifications**: In-app notification system
- **Real-Time Alerts**: Instant notifications for important events
- **Notification History**: Complete notification tracking

## 📊 Performance Optimizations

- **Lazy Loading**: Efficient data loading and caching
- **Image Optimization**: Compressed image uploads
- **Audio Optimization**: Optimized voice message recording and playback
- **Memory Management**: Efficient memory usage for large datasets
- **Network Optimization**: Optimized API calls and data transfer

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation for common issues

## 🔄 Version History

- **v1.0.0**: Initial release with core features
  - Authentication system
  - Real-time messaging
  - Voice message support
  - Call log management
  - Reservation system
  - Profile management
  - Cross-platform support

---

**Built with ❤️ using Flutter and modern web technologies**