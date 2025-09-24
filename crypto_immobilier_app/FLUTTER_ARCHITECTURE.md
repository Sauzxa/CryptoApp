# Flutter App Architecture

## 🏗️ Project Structure

```
lib/
├── main.dart                           # App entry point
├── app/
│   ├── app.dart                        # Main App widget configuration
│   ├── routes.dart                     # App routing configuration
│   └── bloc_providers.dart             # Global BLoC providers
├── core/
│   ├── constants/
│   │   ├── api_constants.dart          # API endpoints and configs
│   │   ├── app_constants.dart          # App-wide constants
│   │   ├── storage_keys.dart           # Local storage keys
│   │   └── notification_constants.dart # Notification types/channels
│   ├── errors/
│   │   ├── exceptions.dart             # Custom exceptions
│   │   └── failures.dart               # Failure classes
│   ├── network/
│   │   ├── api_client.dart             # Dio HTTP client setup
│   │   ├── network_info.dart           # Network connectivity check
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart   # JWT token interceptor
│   │       └── logging_interceptor.dart # Request/response logging
│   ├── services/
│   │   ├── auth_service.dart           # Authentication service
│   │   ├── notification_service.dart   # Local notifications
│   │   ├── websocket_service.dart      # WebSocket connection
│   │   ├── file_service.dart           # File upload/download
│   │   └── storage_service.dart        # Local storage (SharedPrefs/Hive)
│   ├── utils/
│   │   ├── date_utils.dart             # Date formatting utilities
│   │   ├── validators.dart             # Form validation
│   │   ├── formatters.dart             # Text formatters
│   │   ├── permissions.dart            # Permission handling
│   │   └── file_utils.dart             # File handling utilities
│   └── models/
│       ├── user.dart                   # User model
│       ├── call.dart                   # Call model
│       ├── visit.dart                  # Visit model
│       ├── project.dart                # Project model
│       ├── message.dart                # Message model
│       ├── notification.dart           # Notification model
│       └── api_response.dart           # Generic API response wrapper
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── login_request.dart
│   │   │   │   └── auth_response.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── logout_usecase.dart
│   │   │       └── get_current_user_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── splash_page.dart
│   │       └── widgets/
│   │           ├── login_form.dart
│   │           └── auth_button.dart
│   ├── dashboard/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── dashboard_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── dashboard_stats.dart
│   │   │   └── repositories/
│   │   │       └── dashboard_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── dashboard_data.dart
│   │   │   ├── repositories/
│   │   │   │   └── dashboard_repository.dart
│   │   │   └── usecases/
│   │   │       └── get_dashboard_data_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── dashboard_bloc.dart
│   │       │   ├── dashboard_event.dart
│   │       │   └── dashboard_state.dart
│   │       ├── pages/
│   │       │   └── dashboard_page.dart
│   │       └── widgets/
│   │           ├── stats_card.dart
│   │           ├── quick_actions.dart
│   │           └── recent_activities.dart
│   ├── calls/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── calls_local_datasource.dart
│   │   │   │   └── calls_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── call_model.dart
│   │   │   │   └── call_request.dart
│   │   │   └── repositories/
│   │   │       └── calls_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── call_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── calls_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_calls_usecase.dart
│   │   │       ├── log_call_usecase.dart
│   │   │       └── update_call_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── calls_bloc.dart
│   │       │   ├── calls_event.dart
│   │       │   └── calls_state.dart
│   │       ├── pages/
│   │       │   ├── calls_page.dart
│   │       │   ├── call_detail_page.dart
│   │       │   └── log_call_page.dart
│   │       └── widgets/
│   │           ├── call_item.dart
│   │           ├── call_form.dart
│   │           └── call_filters.dart
│   ├── visits/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── visits_local_datasource.dart
│   │   │   │   └── visits_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── visit_model.dart
│   │   │   │   └── visit_request.dart
│   │   │   └── repositories/
│   │   │       └── visits_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── visit_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── visits_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_visits_usecase.dart
│   │   │       ├── create_visit_usecase.dart
│   │   │       ├── update_visit_usecase.dart
│   │   │       └── update_visit_status_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── visits_bloc.dart
│   │       │   ├── visits_event.dart
│   │       │   └── visits_state.dart
│   │       ├── pages/
│   │       │   ├── visits_page.dart
│   │       │   ├── visit_detail_page.dart
│   │       │   ├── create_visit_page.dart
│   │       │   └── calendar_page.dart
│   │       └── widgets/
│   │           ├── visit_item.dart
│   │           ├── visit_form.dart
│   │           ├── visit_calendar.dart
│   │           └── visit_status_chip.dart
│   ├── messages/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── messages_local_datasource.dart
│   │   │   │   └── messages_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── message_model.dart
│   │   │   │   └── conversation_model.dart
│   │   │   └── repositories/
│   │   │       └── messages_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── message_entity.dart
│   │   │   │   └── conversation_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── messages_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_conversations_usecase.dart
│   │   │       ├── get_messages_usecase.dart
│   │   │       ├── send_message_usecase.dart
│   │   │       └── mark_message_read_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── messages_bloc.dart
│   │       │   ├── messages_event.dart
│   │       │   └── messages_state.dart
│   │       ├── pages/
│   │       │   ├── conversations_page.dart
│   │       │   └── chat_page.dart
│   │       └── widgets/
│   │           ├── conversation_item.dart
│   │           ├── message_bubble.dart
│   │           └── chat_input.dart
│   └── profile/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── profile_remote_datasource.dart
│       │   ├── models/
│       │   │   └── profile_model.dart
│       │   └── repositories/
│       │       └── profile_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── profile_entity.dart
│       │   ├── repositories/
│       │   │   └── profile_repository.dart
│       │   └── usecases/
│       │       ├── get_profile_usecase.dart
│       │       └── update_profile_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── profile_bloc.dart
│           │   ├── profile_event.dart
│           │   └── profile_state.dart
│           ├── pages/
│           │   ├── profile_page.dart
│           │   └── edit_profile_page.dart
│           └── widgets/
│               ├── profile_header.dart
│               ├── profile_menu_item.dart
│               └── profile_form.dart
└── shared/
    ├── widgets/
    │   ├── custom_app_bar.dart
    │   ├── custom_button.dart
    │   ├── custom_text_field.dart
    │   ├── loading_widget.dart
    │   ├── error_widget.dart
    │   ├── empty_state_widget.dart
    │   ├── bottom_navigation.dart
    │   ├── notification_badge.dart
    │   └── file_picker_widget.dart
    ├── themes/
    │   ├── app_theme.dart
    │   ├── app_colors.dart
    │   ├── app_text_styles.dart
    │   └── app_dimensions.dart
    └── extensions/
        ├── date_extensions.dart
        ├── string_extensions.dart
        └── context_extensions.dart
```

## 🔄 State Management Architecture (BLoC Pattern)

### BLoC Structure
Each feature follows the BLoC pattern with:
- **Bloc**: Business logic component
- **Event**: User actions or external triggers
- **State**: UI state representation

### Example BLoC Implementation

#### Call Bloc Structure
```dart
// calls_event.dart
abstract class CallsEvent extends Equatable {
  const CallsEvent();
  
  @override
  List<Object> get props => [];
}

class LoadCallsEvent extends CallsEvent {}

class LogCallEvent extends CallsEvent {
  final CallRequest callRequest;
  
  const LogCallEvent(this.callRequest);
  
  @override
  List<Object> get props => [callRequest];
}

class UpdateCallEvent extends CallsEvent {
  final String callId;
  final CallRequest callRequest;
  
  const UpdateCallEvent(this.callId, this.callRequest);
  
  @override
  List<Object> get props => [callId, callRequest];
}

// calls_state.dart
abstract class CallsState extends Equatable {
  const CallsState();
  
  @override
  List<Object> get props => [];
}

class CallsInitial extends CallsState {}

class CallsLoading extends CallsState {}

class CallsLoaded extends CallsState {
  final List<Call> calls;
  
  const CallsLoaded(this.calls);
  
  @override
  List<Object> get props => [calls];
}

class CallsError extends CallsState {
  final String message;
  
  const CallsError(this.message);
  
  @override
  List<Object> get props => [message];
}
```

## 🎨 UI/UX Design System

### Color Palette
```dart
// app_colors.dart
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF388E3C);
  static const Color secondaryLight = Color(0xFF81C784);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
}
```

### Typography
```dart
// app_text_styles.dart
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}
```

## 📱 Navigation Structure

### Route Configuration
```dart
// routes.dart
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String calls = '/calls';
  static const String callDetail = '/calls/detail';
  static const String logCall = '/calls/log';
  static const String visits = '/visits';
  static const String visitDetail = '/visits/detail';
  static const String createVisit = '/visits/create';
  static const String calendar = '/visits/calendar';
  static const String messages = '/messages';
  static const String chat = '/messages/chat';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case calls:
        return MaterialPageRoute(builder: (_) => const CallsPage());
      // ... other routes
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
```

### Bottom Navigation
```dart
// bottom_navigation.dart
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.call),
          label: 'Appels',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Visites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
```

## 🔧 Core Services

### API Service
```dart
// api_client.dart
class ApiClient {
  late Dio _dio;
  static const String baseUrl = 'http://your-api-url.com/api';
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);
      
  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);
      
  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);
      
  Future<Response> delete(String path) =>
      _dio.delete(path);
}
```

### WebSocket Service
```dart
// websocket_service.dart
class WebSocketService {
  IO.Socket? _socket;
  static const String serverUrl = 'http://your-api-url.com';
  
  void connect(String token) {
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });
    
    _socket?.connect();
    
    _socket?.on('connect', (_) {
      print('Connected to WebSocket');
    });
    
    _socket?.on('message:new', (data) {
      // Handle new message
      _handleNewMessage(data);
    });
    
    _socket?.on('visit:reminder', (data) {
      // Handle visit reminder
      _handleVisitReminder(data);
    });
  }
  
  void sendMessage(Map<String, dynamic> messageData) {
    _socket?.emit('message:send', messageData);
  }
  
  void disconnect() {
    _socket?.disconnect();
  }
}
```

### Notification Service
```dart
// notification_service.dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    
    await _notifications.initialize(settings);
  }
  
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'crypto_immobilier_channel',
      'Crypto Immobilier Notifications',
      channelDescription: 'Notifications for the real estate app',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Implementation for scheduled notifications
  }
}
```

## 📊 Data Layer Architecture

### Repository Pattern
```dart
// calls_repository.dart (Domain layer)
abstract class CallsRepository {
  Future<List<Call>> getCalls();
  Future<Call> logCall(CallRequest request);
  Future<Call> updateCall(String id, CallRequest request);
}

// calls_repository_impl.dart (Data layer)
class CallsRepositoryImpl implements CallsRepository {
  final CallsRemoteDataSource remoteDataSource;
  final CallsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  CallsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<List<Call>> getCalls() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteCalls = await remoteDataSource.getCalls();
        await localDataSource.cacheCalls(remoteCalls);
        return remoteCalls;
      } catch (e) {
        return await localDataSource.getLastCachedCalls();
      }
    } else {
      return await localDataSource.getLastCachedCalls();
    }
  }
  
  @override
  Future<Call> logCall(CallRequest request) async {
    return await remoteDataSource.logCall(request);
  }
  
  @override
  Future<Call> updateCall(String id, CallRequest request) async {
    return await remoteDataSource.updateCall(id, request);
  }
}
```

## 📱 Screen-Specific Components

### Dashboard Screen Components
- **StatsCards**: Display key metrics (calls, visits, conversion rate)
- **QuickActions**: Shortcuts for common actions (log call, schedule visit)
- **RecentActivities**: Timeline of recent calls and visits
- **UpcomingVisits**: Calendar preview of scheduled visits

### Calendar Screen Components
- **CalendarView**: Monthly/weekly view with visit markers
- **VisitListView**: List view of visits for selected date
- **VisitFilters**: Filter by status, agent, project
- **VisitDetailsModal**: Quick view of visit details

### Messages Screen Components
- **ConversationsList**: List of all conversations
- **ChatBubbles**: Message bubbles with sender info
- **ChatInput**: Text input with attachment support
- **TypingIndicator**: Real-time typing status

## 🧪 Testing Architecture

### Testing Structure
```
test/
├── unit/
│   ├── core/
│   │   ├── services/
│   │   └── utils/
│   └── features/
│       ├── auth/
│       ├── calls/
│       ├── visits/
│       └── messages/
├── widget/
│   ├── shared/
│   └── features/
└── integration/
    └── app_test.dart
```

### Test Coverage Goals
- **Unit Tests**: 90%+ coverage for business logic
- **Widget Tests**: All custom widgets
- **Integration Tests**: Critical user flows

This architecture provides a solid foundation for the Real Estate Rental Management App with clean separation of concerns, maintainable code structure, and scalability for future features.