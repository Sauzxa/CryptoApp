# 📱 Real Estate Rental Management App - Project Documentation

## 📋 Project Overview

**App Name**: Crypto Immobilier  
**Platform**: Android (Flutter)  
**Backend**: Express.js with TypeScript  
**Database**: MongoDB  
**Current Status**: Basic Flutter project initialized  

### 🎭 Actors
1. **Commercial Agent** (Sales Agent)
2. **Field Agent** (Operational Agent) - extends Commercial Agent
3. **Admin** (System Agent) - Web dashboard (existing)

---

## 🏗️ System Architecture

### Frontend
- **Mobile App**: Flutter (Android only)
- **Admin Dashboard**: Web (already built, needs extensions)

### Backend
- **API Server**: Express.js with TypeScript
- **Database**: MongoDB
- **Real-time**: WebSocket for messaging and notifications

---

## 📊 Database Schema (MongoDB Collections)

### 1. Users/Agents Collection
```javascript
{
  _id: ObjectId,
  email: String,
  password: String (hashed),
  role: String, // 'commercial', 'field', 'admin'
  profile: {
    firstName: String,
    lastName: String,
    phone: String,
    avatar: String,
    isActive: Boolean,
    schedule: [
      {
        dayOfWeek: Number, // 0-6 (Sunday-Saturday)
        startTime: String, // "09:00"
        endTime: String,   // "18:00"
        isAvailable: Boolean
      }
    ]
  },
  createdAt: Date,
  updatedAt: Date
}
```

### 2. Calls Collection
```javascript
{
  _id: ObjectId,
  agentId: ObjectId, // ref to Users
  clientInfo: {
    name: String,
    phone: String,
    email: String
  },
  callType: String, // 'incoming', 'outgoing'
  duration: Number, // seconds
  status: String, // 'answered', 'missed', 'rejected'
  notes: String,
  followUpRequired: Boolean,
  createdAt: Date
}
```

### 3. Visits Collection
```javascript
{
  _id: ObjectId,
  visitNumber: String, // auto-generated unique identifier
  clientInfo: {
    name: String,
    phone: String,
    email: String,
    preferences: String
  },
  commercialAgentId: ObjectId, // ref to Users
  fieldAgentId: ObjectId, // ref to Users (optional)
  projectId: ObjectId, // ref to Projects
  appointmentDate: Date,
  status: String, // 'scheduled', 'operational', 'completed', 'cancelled'
  location: {
    address: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  notes: String,
  report: String, // visit report
  createdAt: Date,
  updatedAt: Date
}
```

### 4. Projects Collection
```javascript
{
  _id: ObjectId,
  name: String,
  description: String,
  location: {
    address: String,
    city: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  files: [
    {
      fileName: String,
      filePath: String,
      fileType: String, // 'image', 'pdf', 'document'
      uploadedBy: ObjectId, // ref to Users
      uploadedAt: Date
    }
  ],
  permissions: [
    {
      userId: ObjectId, // ref to Users
      role: String // 'viewer', 'editor'
    }
  ],
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

### 5. Messages Collection
```javascript
{
  _id: ObjectId,
  senderId: ObjectId, // ref to Users
  receiverId: ObjectId, // ref to Users
  message: String,
  messageType: String, // 'text', 'file', 'system'
  fileUrl: String, // if messageType is 'file'
  isRead: Boolean,
  createdAt: Date
}
```

### 6. Notifications Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId, // ref to Users
  type: String, // 'visit_reminder', 'message', 'system'
  title: String,
  message: String,
  data: Object, // additional data (visitId, etc.)
  isRead: Boolean,
  scheduledFor: Date,
  createdAt: Date
}
```

---

## 🎨 Mobile App Structure (Flutter)

### Navigation Structure
```
Bottom Navigation:
├── Home (Dashboard)
├── Calls (Call History & Management)
├── Visits (Calendar & Visit Management)
├── Messages (In-app Chat)
└── Profile (User Settings)
```

### Screen Hierarchy
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   ├── utils/
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── notification_service.dart
│   │   └── websocket_service.dart
│   └── models/
│       ├── user.dart
│       ├── call.dart
│       ├── visit.dart
│       ├── project.dart
│       └── message.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   ├── dashboard/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   ├── calls/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   ├── visits/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   ├── messages/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── bloc/
│   └── profile/
│       ├── screens/
│       ├── widgets/
│       └── bloc/
└── shared/
    ├── widgets/
    └── themes/
```

---

## 🔧 Required Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # HTTP & API
  dio: ^5.3.2
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # UI/UX
  table_calendar: ^3.0.9
  flutter_local_notifications: ^16.3.0
  image_picker: ^1.0.4
  file_picker: ^6.1.1
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Utils
  intl: ^0.18.1
  url_launcher: ^6.2.1
  permission_handler: ^11.1.0
  
  # WebSocket
  socket_io_client: ^2.0.3
  
  # Icons & Fonts
  cupertino_icons: ^1.0.6
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.4
  hive_generator: ^2.0.1
```

---

## 🔗 Backend API Endpoints

### Authentication
- `POST /auth/login` - Agent login
- `POST /auth/refresh` - Refresh token
- `POST /auth/logout` - Logout

### Commercial Agent Endpoints
- `GET /calls` - Get call history
- `POST /calls` - Log new call
- `PUT /calls/:id` - Update call
- `GET /visits` - Get agent's visits
- `POST /visits` - Create new visit
- `PUT /visits/:id` - Update visit
- `GET /projects` - Get available projects
- `GET /projects/:id/files` - Get project files
- `GET /agents/availability` - Check agent availability

### Field Agent Endpoints (extends Commercial)
- `PUT /visits/:id/operational` - Update visit to operational

### Admin Endpoints (Web Dashboard Extensions)
- `GET /admin/agents` - Get all agents
- `PUT /admin/agents/:id/role` - Update agent role
- `GET /admin/appointments` - Get all appointments
- `GET /admin/statistics` - Get agent statistics
- `POST /admin/projects/folders` - Create project folder
- `PUT /admin/projects/:id/permissions` - Update file permissions

### Messages
- `GET /messages` - Get conversations
- `POST /messages` - Send message
- `PUT /messages/:id/read` - Mark as read

### WebSocket Events
- `message:new` - New message received
- `visit:reminder` - Visit reminder
- `agent:status` - Agent status change

---

## 📱 Feature Requirements by Actor

### Commercial Agent Features
✅ **Call Management**
- [ ] Log incoming/outgoing calls
- [ ] View call history with filters
- [ ] Add call notes and follow-ups

✅ **Client Interaction**
- [ ] Create client profiles from calls
- [ ] Send rental procedures to clients
- [ ] Auto-insert client data to visits

✅ **Appointment Scheduling**
- [ ] Calendar view for scheduling
- [ ] Visit number generation
- [ ] Push notifications for reminders

✅ **Resources Access**
- [ ] Browse project photos and catalogs
- [ ] View/download project files
- [ ] Check agent availability

✅ **Communication**
- [ ] In-app messaging system
- [ ] Real-time chat with other agents

### Field Agent Features (Commercial + Additional)
✅ **Visit Status Management**
- [ ] Update visit status to "Operational"
- [ ] Add operational notes and reports

### Admin Features (Web Dashboard Extensions)
✅ **Role Management**
- [ ] Assign/change agent roles
- [ ] User management interface

✅ **Appointment Management**
- [ ] View all scheduled appointments
- [ ] Calendar overview for all agents

✅ **File Management**
- [ ] Create project folders
- [ ] Upload/manage files
- [ ] Assign viewer/editor permissions

✅ **Statistics & Reports**
- [ ] Daily/weekly call statistics
- [ ] Conversion rate charts
- [ ] Agent performance metrics

✅ **Data Views**
- [ ] Visits sheet view with sorting/filtering
- [ ] Calls sheet view with export options
- [ ] Follow-ups management

---

## 🚀 Development Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Set up Flutter project structure
- [ ] Implement authentication system
- [ ] Create base UI components and theme
- [ ] Set up backend Express.js project
- [ ] Design and implement MongoDB schemas

### Phase 2: Core Features (Week 3-5)
- [ ] Implement call management system
- [ ] Create visit scheduling with calendar
- [ ] Develop basic messaging system
- [ ] Build dashboard with statistics
- [ ] Implement file/project management

### Phase 3: Advanced Features (Week 6-7)
- [ ] Add real-time WebSocket functionality
- [ ] Implement push notifications
- [ ] Create admin dashboard extensions
- [ ] Add role-based access control
- [ ] Implement agent availability system

### Phase 4: Polish & Testing (Week 8-9)
- [ ] UI/UX improvements and polish
- [ ] Performance optimization
- [ ] Unit and integration testing
- [ ] Bug fixes and refinements
- [ ] Documentation completion

### Phase 5: Deployment (Week 10)
- [ ] Prepare production builds
- [ ] Set up deployment pipeline
- [ ] Final testing and QA
- [ ] App store preparation
- [ ] Go-live support

---

## 🔧 Technical Considerations

### State Management
- Use **Flutter Bloc** for state management
- Implement repository pattern for data layer
- Cache frequently accessed data locally

### Performance
- Implement lazy loading for large lists
- Use image caching for project photos
- Optimize database queries with proper indexing

### Security
- JWT token authentication
- Role-based access control
- Input validation and sanitization
- Secure file upload handling

### Real-time Features
- WebSocket connection for messaging
- Local notifications for reminders
- Offline support with sync capability

---

## 📝 Notes

### Current Project Status
- Basic Flutter project initialized
- No existing features implemented
- Clean slate for development

### Next Immediate Steps
1. Update pubspec.yaml with required dependencies
2. Set up project folder structure
3. Create authentication screens
4. Initialize backend Express.js project
5. Set up MongoDB connection and models

### Considerations
- Focus on Android-only deployment initially
- Ensure responsive design for different screen sizes
- Implement offline-first approach where possible
- Plan for future iOS support if needed