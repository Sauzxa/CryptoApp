# Backend API Specification - Express.js with TypeScript

## 🏗️ Backend Architecture

### Tech Stack
- **Framework**: Express.js with TypeScript
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **Real-time**: Socket.IO for WebSocket connections
- **File Upload**: Multer middleware
- **Validation**: Joi or class-validator
- **Documentation**: Swagger/OpenAPI 3.0

### Project Structure
```
backend/
├── src/
│   ├── app.ts                          # Express app configuration
│   ├── server.ts                       # Server entry point
│   ├── config/
│   │   ├── database.ts                 # MongoDB connection
│   │   ├── jwt.ts                      # JWT configuration
│   │   ├── multer.ts                   # File upload configuration
│   │   └── socket.ts                   # Socket.IO configuration
│   ├── controllers/
│   │   ├── auth.controller.ts          # Authentication endpoints
│   │   ├── calls.controller.ts         # Call management endpoints
│   │   ├── visits.controller.ts        # Visit management endpoints
│   │   ├── projects.controller.ts      # Project management endpoints
│   │   ├── messages.controller.ts      # Message endpoints
│   │   ├── admin.controller.ts         # Admin dashboard endpoints
│   │   └── upload.controller.ts        # File upload endpoints
│   ├── middleware/
│   │   ├── auth.middleware.ts          # JWT authentication
│   │   ├── role.middleware.ts          # Role-based access control
│   │   ├── validation.middleware.ts    # Request validation
│   │   ├── error.middleware.ts         # Error handling
│   │   └── logging.middleware.ts       # Request logging
│   ├── models/
│   │   ├── User.model.ts               # User/Agent schema
│   │   ├── Call.model.ts               # Call schema
│   │   ├── Visit.model.ts              # Visit schema
│   │   ├── Project.model.ts            # Project schema
│   │   ├── Message.model.ts            # Message schema
│   │   └── Notification.model.ts       # Notification schema
│   ├── routes/
│   │   ├── auth.routes.ts              # Authentication routes
│   │   ├── calls.routes.ts             # Call routes
│   │   ├── visits.routes.ts            # Visit routes
│   │   ├── projects.routes.ts          # Project routes
│   │   ├── messages.routes.ts          # Message routes
│   │   ├── admin.routes.ts             # Admin routes
│   │   └── upload.routes.ts            # Upload routes
│   ├── services/
│   │   ├── auth.service.ts             # Authentication business logic
│   │   ├── calls.service.ts            # Calls business logic
│   │   ├── visits.service.ts           # Visits business logic
│   │   ├── messages.service.ts         # Messages business logic
│   │   ├── notification.service.ts     # Notification service
│   │   └── file.service.ts             # File handling service
│   ├── utils/
│   │   ├── jwt.utils.ts                # JWT utility functions
│   │   ├── password.utils.ts           # Password hashing utilities
│   │   ├── date.utils.ts               # Date formatting utilities
│   │   ├── validation.utils.ts         # Validation helpers
│   │   └── response.utils.ts           # Response formatting
│   ├── types/
│   │   ├── auth.types.ts               # Authentication type definitions
│   │   ├── api.types.ts                # API response types
│   │   └── socket.types.ts             # Socket event types
│   └── socket/
│       ├── socket.handler.ts           # Main socket handler
│       ├── message.handler.ts          # Message socket events
│       └── notification.handler.ts     # Notification socket events
├── uploads/                            # File uploads directory
├── tests/                              # Test files
├── docs/                               # API documentation
├── package.json
├── tsconfig.json
└── .env                                # Environment variables
```

---

## 🔐 Authentication Endpoints

### POST `/auth/login`
**Description**: Agent login  
**Access**: Public  

**Request Body**:
```json
{
  "email": "string",
  "password": "string"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "string",
      "email": "string",
      "role": "commercial|field|admin",
      "profile": {
        "firstName": "string",
        "lastName": "string",
        "phone": "string",
        "avatar": "string",
        "isActive": "boolean"
      }
    },
    "tokens": {
      "accessToken": "string",
      "refreshToken": "string"
    }
  }
}
```

### POST `/auth/refresh`
**Description**: Refresh access token  
**Access**: Public  

**Request Body**:
```json
{
  "refreshToken": "string"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "accessToken": "string",
    "refreshToken": "string"
  }
}
```

### POST `/auth/logout`
**Description**: Logout user  
**Access**: Authenticated  
**Headers**: `Authorization: Bearer {token}`

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 📞 Call Management Endpoints

### GET `/api/calls`
**Description**: Get call history for authenticated agent  
**Access**: Commercial Agent, Field Agent  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `status` (optional): Filter by call status
- `startDate` (optional): Filter from date
- `endDate` (optional): Filter to date

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "calls": [
      {
        "id": "string",
        "clientInfo": {
          "name": "string",
          "phone": "string",
          "email": "string"
        },
        "callType": "incoming|outgoing",
        "duration": "number",
        "status": "answered|missed|rejected",
        "notes": "string",
        "followUpRequired": "boolean",
        "createdAt": "string (ISO date)"
      }
    ],
    "pagination": {
      "currentPage": "number",
      "totalPages": "number",
      "totalItems": "number"
    }
  }
}
```

### POST `/api/calls`
**Description**: Log a new call  
**Access**: Commercial Agent, Field Agent  
**Headers**: `Authorization: Bearer {token}`

**Request Body**:
```json
{
  "clientInfo": {
    "name": "string",
    "phone": "string",
    "email": "string (optional)"
  },
  "callType": "incoming|outgoing",
  "duration": "number",
  "status": "answered|missed|rejected",
  "notes": "string (optional)",
  "followUpRequired": "boolean"
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "visitNumber": "string (auto-generated if followUpRequired)"
  }
}
```

### PUT `/api/calls/:id`
**Description**: Update an existing call  
**Access**: Commercial Agent, Field Agent  
**Headers**: `Authorization: Bearer {token}`

**Request Body**: Same as POST `/api/calls`

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "message": "Call updated successfully"
  }
}
```

---

## 🏠 Visit Management Endpoints

### GET `/api/visits`
**Description**: Get visits for authenticated agent  
**Access**: Commercial Agent, Field Agent  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `page` (optional): Page number
- `limit` (optional): Items per page
- `status` (optional): Filter by visit status
- `startDate` (optional): Filter from date
- `endDate` (optional): Filter to date

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "visits": [
      {
        "id": "string",
        "visitNumber": "string",
        "clientInfo": {
          "name": "string",
          "phone": "string",
          "email": "string",
          "preferences": "string"
        },
        "commercialAgent": {
          "id": "string",
          "firstName": "string",
          "lastName": "string"
        },
        "fieldAgent": {
          "id": "string",
          "firstName": "string",
          "lastName": "string"
        },
        "project": {
          "id": "string",
          "name": "string",
          "location": "string"
        },
        "appointmentDate": "string (ISO date)",
        "status": "scheduled|operational|completed|cancelled",
        "location": {
          "address": "string",
          "coordinates": {
            "lat": "number",
            "lng": "number"
          }
        },
        "notes": "string",
        "report": "string",
        "createdAt": "string (ISO date)",
        "updatedAt": "string (ISO date)"
      }
    ],
    "pagination": {
      "currentPage": "number",
      "totalPages": "number",
      "totalItems": "number"
    }
  }
}
```

### POST `/api/visits`
**Description**: Create a new visit/appointment  
**Access**: Commercial Agent, Field Agent  
**Headers**: `Authorization: Bearer {token}`

**Request Body**:
```json
{
  "clientInfo": {
    "name": "string",
    "phone": "string",
    "email": "string (optional)",
    "preferences": "string (optional)"
  },
  "projectId": "string",
  "fieldAgentId": "string (optional)",
  "appointmentDate": "string (ISO date)",
  "location": {
    "address": "string",
    "coordinates": {
      "lat": "number",
      "lng": "number"
    }
  },
  "notes": "string (optional)"
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "visitNumber": "string",
    "message": "Visit scheduled successfully"
  }
}
```

### PUT `/api/visits/:id`
**Description**: Update visit details  
**Access**: Commercial Agent, Field Agent (own visits)  
**Headers**: `Authorization: Bearer {token}`

**Request Body**: Same as POST `/api/visits`

### PUT `/api/visits/:id/operational`
**Description**: Update visit status to operational  
**Access**: Field Agent only  
**Headers**: `Authorization: Bearer {token}`

**Request Body**:
```json
{
  "report": "string",
  "notes": "string (optional)"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Visit status updated to operational"
}
```

---

## 🏢 Project Management Endpoints

### GET `/api/projects`
**Description**: Get available projects  
**Access**: Commercial Agent, Field Agent, Admin  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `page` (optional): Page number
- `limit` (optional): Items per page
- `isActive` (optional): Filter by active status

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "projects": [
      {
        "id": "string",
        "name": "string",
        "description": "string",
        "location": {
          "address": "string",
          "city": "string",
          "coordinates": {
            "lat": "number",
            "lng": "number"
          }
        },
        "filesCount": "number",
        "permissions": [
          {
            "userId": "string",
            "role": "viewer|editor"
          }
        ],
        "isActive": "boolean",
        "createdAt": "string (ISO date)"
      }
    ]
  }
}
```

### GET `/api/projects/:id`
**Description**: Get project details  
**Access**: Commercial Agent, Field Agent, Admin  
**Headers**: `Authorization: Bearer {token}`

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "name": "string",
    "description": "string",
    "location": {
      "address": "string",
      "city": "string",
      "coordinates": {
        "lat": "number",
        "lng": "number"
      }
    },
    "files": [
      {
        "id": "string",
        "fileName": "string",
        "filePath": "string",
        "fileType": "image|pdf|document",
        "uploadedBy": {
          "id": "string",
          "firstName": "string",
          "lastName": "string"
        },
        "uploadedAt": "string (ISO date)"
      }
    ],
    "permissions": [
      {
        "user": {
          "id": "string",
          "firstName": "string",
          "lastName": "string"
        },
        "role": "viewer|editor"
      }
    ]
  }
}
```

### GET `/api/projects/:id/files`
**Description**: Get project files  
**Access**: Commercial Agent, Field Agent, Admin (with permissions)  
**Headers**: `Authorization: Bearer {token}`

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "files": [
      {
        "id": "string",
        "fileName": "string",
        "filePath": "string",
        "fileType": "image|pdf|document",
        "fileSize": "number",
        "uploadedBy": {
          "id": "string",
          "firstName": "string",
          "lastName": "string"
        },
        "uploadedAt": "string (ISO date)"
      }
    ]
  }
}
```

---

## 👥 Agent Management Endpoints

### GET `/api/agents/availability`
**Description**: Check agent availability for scheduling  
**Access**: Commercial Agent, Field Agent  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `date`: Date to check availability (YYYY-MM-DD)
- `role` (optional): Filter by agent role

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "availableAgents": [
      {
        "id": "string",
        "firstName": "string",
        "lastName": "string",
        "role": "commercial|field",
        "schedule": {
          "startTime": "string (HH:MM)",
          "endTime": "string (HH:MM)",
          "isAvailable": "boolean"
        },
        "bookedSlots": [
          {
            "startTime": "string (ISO date)",
            "endTime": "string (ISO date)"
          }
        ]
      }
    ]
  }
}
```

---

## 💬 Message Management Endpoints

### GET `/api/messages/conversations`
**Description**: Get all conversations for authenticated user  
**Access**: Commercial Agent, Field Agent, Admin  
**Headers**: `Authorization: Bearer {token}`

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "conversations": [
      {
        "id": "string",
        "participant": {
          "id": "string",
          "firstName": "string",
          "lastName": "string",
          "avatar": "string"
        },
        "lastMessage": {
          "id": "string",
          "message": "string",
          "messageType": "text|file|system",
          "senderId": "string",
          "createdAt": "string (ISO date)",
          "isRead": "boolean"
        },
        "unreadCount": "number"
      }
    ]
  }
}
```

### GET `/api/messages/:userId`
**Description**: Get messages between authenticated user and specified user  
**Access**: Commercial Agent, Field Agent, Admin  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "id": "string",
        "senderId": "string",
        "receiverId": "string",
        "message": "string",
        "messageType": "text|file|system",
        "fileUrl": "string (optional)",
        "isRead": "boolean",
        "createdAt": "string (ISO date)"
      }
    ],
    "pagination": {
      "currentPage": "number",
      "totalPages": "number",
      "totalItems": "number"
    }
  }
}
```

### POST `/api/messages`
**Description**: Send a new message  
**Access**: Commercial Agent, Field Agent, Admin  
**Headers**: `Authorization: Bearer {token}`

**Request Body**:
```json
{
  "receiverId": "string",
  "message": "string",
  "messageType": "text|file",
  "fileUrl": "string (optional, required if messageType is file)"
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "message": "Message sent successfully"
  }
}
```

### PUT `/api/messages/:id/read`
**Description**: Mark message as read  
**Access**: Commercial Agent, Field Agent, Admin  
**Headers**: `Authorization: Bearer {token}`

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Message marked as read"
}
```

---

## 🔧 Admin Dashboard Endpoints

### GET `/api/admin/agents`
**Description**: Get all agents  
**Access**: Admin only  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `role` (optional): Filter by role
- `isActive` (optional): Filter by active status

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "agents": [
      {
        "id": "string",
        "email": "string",
        "role": "commercial|field|admin",
        "profile": {
          "firstName": "string",
          "lastName": "string",
          "phone": "string",
          "avatar": "string",
          "isActive": "boolean"
        },
        "statistics": {
          "totalCalls": "number",
          "totalVisits": "number",
          "conversionRate": "number"
        },
        "createdAt": "string (ISO date)"
      }
    ]
  }
}
```

### PUT `/api/admin/agents/:id/role`
**Description**: Update agent role  
**Access**: Admin only  
**Headers**: `Authorization: Bearer {token}`

**Request Body**:
```json
{
  "role": "commercial|field|admin"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Agent role updated successfully"
}
```

### GET `/api/admin/appointments`
**Description**: Get all appointments/visits  
**Access**: Admin only  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `startDate` (optional): Filter from date
- `endDate` (optional): Filter to date
- `agentId` (optional): Filter by agent
- `status` (optional): Filter by status

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "appointments": [
      {
        "id": "string",
        "visitNumber": "string",
        "clientInfo": {
          "name": "string",
          "phone": "string"
        },
        "commercialAgent": {
          "id": "string",
          "firstName": "string",
          "lastName": "string"
        },
        "fieldAgent": {
          "id": "string",
          "firstName": "string",
          "lastName": "string"
        },
        "project": {
          "id": "string",
          "name": "string"
        },
        "appointmentDate": "string (ISO date)",
        "status": "scheduled|operational|completed|cancelled"
      }
    ]
  }
}
```

### GET `/api/admin/statistics`
**Description**: Get agent statistics and analytics  
**Access**: Admin only  
**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
- `period`: daily|weekly|monthly
- `startDate` (optional): Start date for custom period
- `endDate` (optional): End date for custom period

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "overview": {
      "totalCalls": "number",
      "totalVisits": "number",
      "totalAgents": "number",
      "conversionRate": "number"
    },
    "callsData": [
      {
        "date": "string (YYYY-MM-DD)",
        "incoming": "number",
        "outgoing": "number",
        "answered": "number",
        "missed": "number"
      }
    ],
    "visitsData": [
      {
        "date": "string (YYYY-MM-DD)",
        "scheduled": "number",
        "operational": "number",
        "completed": "number",
        "cancelled": "number"
      }
    ],
    "agentPerformance": [
      {
        "agentId": "string",
        "firstName": "string",
        "lastName": "string",
        "totalCalls": "number",
        "totalVisits": "number",
        "conversionRate": "number"
      }
    ]
  }
}
```

### POST `/api/admin/projects/folders`
**Description**: Create project folder  
**Access**: Admin only  
**Headers**: `Authorization: Bearer {token}`

**Request Body**:
```json
{
  "name": "string",
  "description": "string",
  "location": {
    "address": "string",
    "city": "string",
    "coordinates": {
      "lat": "number",
      "lng": "number"
    }
  }
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "message": "Project folder created successfully"
  }
}
```

### PUT `/api/admin/projects/:id/permissions`
**Description**: Update project permissions  
**Access**: Admin only  
**Headers**: `Authorization: Bearer {token}`

**Request Body**:
```json
{
  "permissions": [
    {
      "userId": "string",
      "role": "viewer|editor"
    }
  ]
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Project permissions updated successfully"
}
```

---

## 📁 File Upload Endpoints

### POST `/api/upload/project/:projectId`
**Description**: Upload file to project  
**Access**: Admin, Field Agent (with editor permissions)  
**Headers**: `Authorization: Bearer {token}`, `Content-Type: multipart/form-data`

**Request Body** (Form Data):
- `file`: File to upload
- `fileType`: image|pdf|document

**Response Success (201)**:
```json
{
  "success": true,
  "data": {
    "fileId": "string",
    "fileName": "string",
    "filePath": "string",
    "fileUrl": "string"
  }
}
```

### DELETE `/api/upload/file/:fileId`
**Description**: Delete uploaded file  
**Access**: Admin, File uploader  
**Headers**: `Authorization: Bearer {token}`

**Response Success (200)**:
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

---

## 🔌 WebSocket Events

### Client-to-Server Events

#### `join_room`
**Description**: Join a conversation room  
**Data**:
```json
{
  "userId": "string"
}
```

#### `message:send`
**Description**: Send a message  
**Data**:
```json
{
  "receiverId": "string",
  "message": "string",
  "messageType": "text|file",
  "fileUrl": "string (optional)"
}
```

#### `message:typing`
**Description**: Indicate typing status  
**Data**:
```json
{
  "receiverId": "string",
  "isTyping": "boolean"
}
```

### Server-to-Client Events

#### `message:new`
**Description**: New message received  
**Data**:
```json
{
  "id": "string",
  "senderId": "string",
  "senderInfo": {
    "firstName": "string",
    "lastName": "string",
    "avatar": "string"
  },
  "message": "string",
  "messageType": "text|file|system",
  "fileUrl": "string (optional)",
  "createdAt": "string (ISO date)"
}
```

#### `message:typing`
**Description**: User typing status  
**Data**:
```json
{
  "userId": "string",
  "isTyping": "boolean"
}
```

#### `visit:reminder`
**Description**: Visit reminder notification  
**Data**:
```json
{
  "visitId": "string",
  "visitNumber": "string",
  "clientName": "string",
  "appointmentDate": "string (ISO date)",
  "location": "string"
}
```

#### `agent:status`
**Description**: Agent online/offline status  
**Data**:
```json
{
  "agentId": "string",
  "isOnline": "boolean",
  "lastSeen": "string (ISO date)"
}
```

---

## 📋 Error Response Format

All endpoints return errors in the following format:

**Error Response (4xx/5xx)**:
```json
{
  "success": false,
  "error": {
    "code": "string",
    "message": "string",
    "details": "string (optional)"
  }
}
```

**Common Error Codes**:
- `VALIDATION_ERROR`: Request validation failed
- `UNAUTHORIZED`: Authentication required
- `FORBIDDEN`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `CONFLICT`: Resource conflict (duplicate data)
- `INTERNAL_SERVER_ERROR`: Server error

---

## 🔒 Authentication & Authorization

### JWT Token Structure
```json
{
  "userId": "string",
  "email": "string",
  "role": "commercial|field|admin",
  "iat": "number",
  "exp": "number"
}
```

### Role-Based Access Control

**Commercial Agent**:
- Can manage own calls and visits
- Can view projects and files
- Can send/receive messages
- Cannot update visit status to operational

**Field Agent**:
- All Commercial Agent permissions
- Can update visit status to operational
- Can add operational reports

**Admin**:
- Full system access
- Can manage users and roles
- Can view all statistics and reports
- Can manage projects and permissions

---

## 📚 API Documentation

The API should include Swagger/OpenAPI documentation accessible at `/docs` endpoint with:
- Interactive API explorer
- Request/response schemas
- Authentication examples
- Error code references

This comprehensive backend specification provides all the necessary endpoints and real-time functionality for the Real Estate Rental Management App.