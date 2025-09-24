# MongoDB Database Schema

## Collection Schemas with Validation and Indexes

### 1. users (Agents Collection)
```javascript
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["email", "password", "role", "profile"],
      properties: {
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
          description: "must be a valid email and is required"
        },
        password: {
          bsonType: "string",
          minLength: 6,
          description: "must be a string with at least 6 characters and is required"
        },
        role: {
          bsonType: "string",
          enum: ["commercial", "field", "admin"],
          description: "must be one of the enum values and is required"
        },
        profile: {
          bsonType: "object",
          required: ["firstName", "lastName", "phone"],
          properties: {
            firstName: {
              bsonType: "string",
              description: "must be a string and is required"
            },
            lastName: {
              bsonType: "string",
              description: "must be a string and is required"
            },
            phone: {
              bsonType: "string",
              pattern: "^[+]?[0-9\\s\\-\\(\\)]+$",
              description: "must be a valid phone number and is required"
            },
            avatar: {
              bsonType: "string",
              description: "must be a string URL"
            },
            isActive: {
              bsonType: "bool",
              description: "must be a boolean"
            },
            schedule: {
              bsonType: "array",
              items: {
                bsonType: "object",
                required: ["dayOfWeek", "startTime", "endTime", "isAvailable"],
                properties: {
                  dayOfWeek: {
                    bsonType: "int",
                    minimum: 0,
                    maximum: 6,
                    description: "must be an integer from 0-6 (Sunday-Saturday)"
                  },
                  startTime: {
                    bsonType: "string",
                    pattern: "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$",
                    description: "must be in HH:MM format"
                  },
                  endTime: {
                    bsonType: "string",
                    pattern: "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$",
                    description: "must be in HH:MM format"
                  },
                  isAvailable: {
                    bsonType: "bool",
                    description: "must be a boolean"
                  }
                }
              }
            }
          }
        },
        createdAt: {
          bsonType: "date",
          description: "must be a date"
        },
        updatedAt: {
          bsonType: "date",
          description: "must be a date"
        }
      }
    }
  }
});

// Indexes
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "role": 1 });
db.users.createIndex({ "profile.isActive": 1 });
```

### 2. calls Collection
```javascript
db.createCollection("calls", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["agentId", "clientInfo", "callType", "status", "createdAt"],
      properties: {
        agentId: {
          bsonType: "objectId",
          description: "must be a valid ObjectId and is required"
        },
        clientInfo: {
          bsonType: "object",
          required: ["name", "phone"],
          properties: {
            name: {
              bsonType: "string",
              description: "must be a string and is required"
            },
            phone: {
              bsonType: "string",
              pattern: "^[+]?[0-9\\s\\-\\(\\)]+$",
              description: "must be a valid phone number and is required"
            },
            email: {
              bsonType: "string",
              pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
              description: "must be a valid email"
            }
          }
        },
        callType: {
          bsonType: "string",
          enum: ["incoming", "outgoing"],
          description: "must be either incoming or outgoing"
        },
        duration: {
          bsonType: "int",
          minimum: 0,
          description: "must be a non-negative integer (seconds)"
        },
        status: {
          bsonType: "string",
          enum: ["answered", "missed", "rejected"],
          description: "must be one of the enum values"
        },
        notes: {
          bsonType: "string",
          description: "must be a string"
        },
        followUpRequired: {
          bsonType: "bool",
          description: "must be a boolean"
        },
        createdAt: {
          bsonType: "date",
          description: "must be a date and is required"
        }
      }
    }
  }
});

// Indexes
db.calls.createIndex({ "agentId": 1 });
db.calls.createIndex({ "createdAt": -1 });
db.calls.createIndex({ "clientInfo.phone": 1 });
db.calls.createIndex({ "followUpRequired": 1 });
```

### 3. visits Collection
```javascript
db.createCollection("visits", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["visitNumber", "clientInfo", "commercialAgentId", "projectId", "appointmentDate", "status"],
      properties: {
        visitNumber: {
          bsonType: "string",
          description: "must be a unique string and is required"
        },
        clientInfo: {
          bsonType: "object",
          required: ["name", "phone"],
          properties: {
            name: {
              bsonType: "string",
              description: "must be a string and is required"
            },
            phone: {
              bsonType: "string",
              pattern: "^[+]?[0-9\\s\\-\\(\\)]+$",
              description: "must be a valid phone number and is required"
            },
            email: {
              bsonType: "string",
              pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
              description: "must be a valid email"
            },
            preferences: {
              bsonType: "string",
              description: "must be a string"
            }
          }
        },
        commercialAgentId: {
          bsonType: "objectId",
          description: "must be a valid ObjectId and is required"
        },
        fieldAgentId: {
          bsonType: "objectId",
          description: "must be a valid ObjectId"
        },
        projectId: {
          bsonType: "objectId",
          description: "must be a valid ObjectId and is required"
        },
        appointmentDate: {
          bsonType: "date",
          description: "must be a date and is required"
        },
        status: {
          bsonType: "string",
          enum: ["scheduled", "operational", "completed", "cancelled"],
          description: "must be one of the enum values and is required"
        },
        location: {
          bsonType: "object",
          properties: {
            address: {
              bsonType: "string",
              description: "must be a string"
            },
            coordinates: {
              bsonType: "object",
              properties: {
                lat: {
                  bsonType: "double",
                  minimum: -90,
                  maximum: 90,
                  description: "must be a valid latitude"
                },
                lng: {
                  bsonType: "double",
                  minimum: -180,
                  maximum: 180,
                  description: "must be a valid longitude"
                }
              }
            }
          }
        },
        notes: {
          bsonType: "string",
          description: "must be a string"
        },
        report: {
          bsonType: "string",
          description: "must be a string"
        },
        createdAt: {
          bsonType: "date",
          description: "must be a date"
        },
        updatedAt: {
          bsonType: "date",
          description: "must be a date"
        }
      }
    }
  }
});

// Indexes
db.visits.createIndex({ "visitNumber": 1 }, { unique: true });
db.visits.createIndex({ "commercialAgentId": 1 });
db.visits.createIndex({ "fieldAgentId": 1 });
db.visits.createIndex({ "projectId": 1 });
db.visits.createIndex({ "appointmentDate": 1 });
db.visits.createIndex({ "status": 1 });
db.visits.createIndex({ "clientInfo.phone": 1 });
```

### 4. projects Collection
```javascript
db.createCollection("projects", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "location", "isActive"],
      properties: {
        name: {
          bsonType: "string",
          description: "must be a string and is required"
        },
        description: {
          bsonType: "string",
          description: "must be a string"
        },
        location: {
          bsonType: "object",
          required: ["address", "city"],
          properties: {
            address: {
              bsonType: "string",
              description: "must be a string and is required"
            },
            city: {
              bsonType: "string",
              description: "must be a string and is required"
            },
            coordinates: {
              bsonType: "object",
              properties: {
                lat: {
                  bsonType: "double",
                  minimum: -90,
                  maximum: 90,
                  description: "must be a valid latitude"
                },
                lng: {
                  bsonType: "double",
                  minimum: -180,
                  maximum: 180,
                  description: "must be a valid longitude"
                }
              }
            }
          }
        },
        files: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["fileName", "filePath", "fileType", "uploadedBy", "uploadedAt"],
            properties: {
              fileName: {
                bsonType: "string",
                description: "must be a string and is required"
              },
              filePath: {
                bsonType: "string",
                description: "must be a string and is required"
              },
              fileType: {
                bsonType: "string",
                enum: ["image", "pdf", "document"],
                description: "must be one of the enum values and is required"
              },
              uploadedBy: {
                bsonType: "objectId",
                description: "must be a valid ObjectId and is required"
              },
              uploadedAt: {
                bsonType: "date",
                description: "must be a date and is required"
              }
            }
          }
        },
        permissions: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["userId", "role"],
            properties: {
              userId: {
                bsonType: "objectId",
                description: "must be a valid ObjectId and is required"
              },
              role: {
                bsonType: "string",
                enum: ["viewer", "editor"],
                description: "must be either viewer or editor and is required"
              }
            }
          }
        },
        isActive: {
          bsonType: "bool",
          description: "must be a boolean and is required"
        },
        createdAt: {
          bsonType: "date",
          description: "must be a date"
        },
        updatedAt: {
          bsonType: "date",
          description: "must be a date"
        }
      }
    }
  }
});

// Indexes
db.projects.createIndex({ "name": 1 });
db.projects.createIndex({ "isActive": 1 });
db.projects.createIndex({ "location.city": 1 });
db.projects.createIndex({ "permissions.userId": 1 });
```

### 5. messages Collection
```javascript
db.createCollection("messages", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["senderId", "receiverId", "message", "messageType", "isRead", "createdAt"],
      properties: {
        senderId: {
          bsonType: "objectId",
          description: "must be a valid ObjectId and is required"
        },
        receiverId: {
          bsonType: "objectId",
          description: "must be a valid ObjectId and is required"
        },
        message: {
          bsonType: "string",
          description: "must be a string and is required"
        },
        messageType: {
          bsonType: "string",
          enum: ["text", "file", "system"],
          description: "must be one of the enum values and is required"
        },
        fileUrl: {
          bsonType: "string",
          description: "must be a string URL"
        },
        isRead: {
          bsonType: "bool",
          description: "must be a boolean and is required"
        },
        createdAt: {
          bsonType: "date",
          description: "must be a date and is required"
        }
      }
    }
  }
});

// Indexes
db.messages.createIndex({ "senderId": 1 });
db.messages.createIndex({ "receiverId": 1 });
db.messages.createIndex({ "createdAt": -1 });
db.messages.createIndex({ "isRead": 1, "receiverId": 1 });
db.messages.createIndex({ 
  "senderId": 1, 
  "receiverId": 1, 
  "createdAt": -1 
}, { name: "conversation_index" });
```

### 6. notifications Collection
```javascript
db.createCollection("notifications", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "type", "title", "message", "isRead", "createdAt"],
      properties: {
        userId: {
          bsonType: "objectId",
          description: "must be a valid ObjectId and is required"
        },
        type: {
          bsonType: "string",
          enum: ["visit_reminder", "message", "system"],
          description: "must be one of the enum values and is required"
        },
        title: {
          bsonType: "string",
          description: "must be a string and is required"
        },
        message: {
          bsonType: "string",
          description: "must be a string and is required"
        },
        data: {
          bsonType: "object",
          description: "additional data object"
        },
        isRead: {
          bsonType: "bool",
          description: "must be a boolean and is required"
        },
        scheduledFor: {
          bsonType: "date",
          description: "must be a date"
        },
        createdAt: {
          bsonType: "date",
          description: "must be a date and is required"
        }
      }
    }
  }
});

// Indexes
db.notifications.createIndex({ "userId": 1 });
db.notifications.createIndex({ "isRead": 1, "userId": 1 });
db.notifications.createIndex({ "scheduledFor": 1 });
db.notifications.createIndex({ "createdAt": -1 });
db.notifications.createIndex({ "type": 1, "userId": 1 });
```

## Data Relationships

### Foreign Key References
- `calls.agentId` → `users._id`
- `visits.commercialAgentId` → `users._id`
- `visits.fieldAgentId` → `users._id`
- `visits.projectId` → `projects._id`
- `projects.files.uploadedBy` → `users._id`
- `projects.permissions.userId` → `users._id`
- `messages.senderId` → `users._id`
- `messages.receiverId` → `users._id`
- `notifications.userId` → `users._id`

### Aggregation Pipelines Examples

#### Get Agent Statistics
```javascript
db.calls.aggregate([
  {
    $match: {
      agentId: ObjectId("agent_id"),
      createdAt: {
        $gte: ISODate("2024-01-01"),
        $lt: ISODate("2024-02-01")
      }
    }
  },
  {
    $group: {
      _id: "$agentId",
      totalCalls: { $sum: 1 },
      answeredCalls: {
        $sum: { $cond: [{ $eq: ["$status", "answered"] }, 1, 0] }
      },
      totalDuration: { $sum: "$duration" }
    }
  }
]);
```

#### Get Visits with Agent Info
```javascript
db.visits.aggregate([
  {
    $lookup: {
      from: "users",
      localField: "commercialAgentId",
      foreignField: "_id",
      as: "commercialAgent"
    }
  },
  {
    $lookup: {
      from: "users",
      localField: "fieldAgentId",
      foreignField: "_id",
      as: "fieldAgent"
    }
  },
  {
    $lookup: {
      from: "projects",
      localField: "projectId",
      foreignField: "_id",
      as: "project"
    }
  }
]);
```

## Initialization Scripts

### Create Default Admin User
```javascript
db.users.insertOne({
  email: "admin@cryptoimmobilier.com",
  password: "$2b$10$hashedPassword", // Hash with bcrypt
  role: "admin",
  profile: {
    firstName: "System",
    lastName: "Administrator",
    phone: "+1234567890",
    isActive: true,
    schedule: []
  },
  createdAt: new Date(),
  updatedAt: new Date()
});
```

### Sample Data Insertion
```javascript
// Insert sample projects
db.projects.insertMany([
  {
    name: "Résidence Les Jardins",
    description: "Luxury apartments with garden view",
    location: {
      address: "123 Rue de la Paix",
      city: "Paris",
      coordinates: { lat: 48.8566, lng: 2.3522 }
    },
    files: [],
    permissions: [],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Tour Horizon",
    description: "Modern high-rise residential complex",
    location: {
      address: "456 Avenue des Champs",
      city: "Lyon",
      coordinates: { lat: 45.7640, lng: 4.8357 }
    },
    files: [],
    permissions: [],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);
```