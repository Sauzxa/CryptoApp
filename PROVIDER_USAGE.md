# Authentication Provider Usage Guide

## Overview
The app now uses Provider for state management, centralizing authentication data and making it accessible throughout the application.

## Architecture

### AuthProvider (`lib/providers/auth_provider.dart`)
The main authentication state manager that:
- Manages user authentication state (login, register, logout)
- Stores current user data and token
- Persists data using SharedPreferences
- Notifies listeners when state changes

### Key Features
- ✅ Centralized user data management
- ✅ Automatic state persistence
- ✅ Token validation
- ✅ Role-based access helpers
- ✅ Loading and error state management

## How to Use AuthProvider

### 1. Accessing User Data (Read-Only)

Use `Consumer` widget for widgets that need to rebuild when auth state changes:

```dart
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// In your widget:
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    final user = authProvider.currentUser;
    
    return Text('Welcome ${user?.name ?? "Guest"}');
  },
)
```

### 2. Accessing Auth Methods (Write Operations)

Use `Provider.of` with `listen: false` for one-time operations:

```dart
// In your method:
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Login
await authProvider.login(email, password);

// Register
await authProvider.register(userModel);

// Logout
await authProvider.logout();

// Refresh user data
await authProvider.refreshUser();
```

### 3. Checking Authentication Status

```dart
final authProvider = Provider.of<AuthProvider>(context);

if (authProvider.isAuthenticated) {
  // User is logged in
}

if (authProvider.isLoading) {
  // Show loading indicator
}

if (authProvider.errorMessage != null) {
  // Show error
}
```

### 4. Role-Based Access

```dart
final authProvider = Provider.of<AuthProvider>(context);

// Check specific roles
if (authProvider.isAdmin) {
  // Show admin features
}

if (authProvider.isCommercial) {
  // Show commercial agent features
}

if (authProvider.isField) {
  // Show field agent features
}

// Generic role check
if (authProvider.hasRole('admin')) {
  // Admin-only feature
}
```

### 5. User Profile Data

```dart
final authProvider = Provider.of<AuthProvider>(context);

// Quick access to common data
String userName = authProvider.userName; // Display name
String userEmail = authProvider.userEmail; // Email
String userRole = authProvider.userRole; // Role display name (French)
String availability = authProvider.availability; // Field agent availability

// Full user object
UserModel? user = authProvider.currentUser;
```

## Example: Profile Settings Screen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return const Center(child: Text('No user data'));
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${user.name}'),
                Text('Email: ${user.email}'),
                Text('Phone: ${user.phone}'),
                Text('Role: ${user.roleDisplayName}'),
                if (authProvider.isField)
                  Text('Availability: ${user.availabilityDisplayName}'),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () async {
                    await authProvider.refreshUser();
                    if (authProvider.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authProvider.errorMessage!)),
                      );
                    }
                  },
                  child: const Text('Refresh Data'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Example: Protected Route

```dart
class ProtectedScreen extends StatelessWidget {
  const ProtectedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Redirect if not authenticated
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const SizedBox();
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Screen')),
      body: Center(child: Text('Welcome ${authProvider.userName}!')),
    );
  }
}
```

## Example: Drawer Menu with User Info

```dart
Drawer(
  child: Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      return Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.userName),
            accountEmail: Text(authProvider.userEmail),
            currentAccountPicture: CircleAvatar(
              child: Text(authProvider.userName[0].toUpperCase()),
            ),
          ),
          ListTile(
            title: Text('Role: ${authProvider.userRole}'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.welcome,
                  (route) => false,
                );
              }
            },
          ),
        ],
      );
    },
  ),
)
```

## Best Practices

1. **Use Consumer for UI that needs updates**: When your widget needs to rebuild when auth state changes
2. **Use Provider.of with listen: false for actions**: When calling methods that change state
3. **Check loading state**: Show loading indicators during async operations
4. **Handle errors**: Check `errorMessage` after operations and display to user
5. **Don't pass user data through navigation**: Access it directly from Provider instead

## Current Implementation

The following screens have been updated to use AuthProvider:
- ✅ `main.dart` - Wraps app with ChangeNotifierProvider
- ✅ `SingUp.dart` - Uses AuthProvider for registration
- ✅ `LoginScreen.dart` - Uses AuthProvider for login
- ✅ `HomePage.dart` - Consumes user data from AuthProvider in drawer

## TODO: Update These Screens

If you have other screens that need user data, update them to use AuthProvider:
- Profile settings screen
- User settings screen
- Any screen that displays user information
- Any screen with role-based features

## Notes

- User data is automatically persisted to SharedPreferences
- Token validation happens on app startup
- Logout clears all stored data
- The Provider pattern eliminates prop drilling and makes state management predictable
