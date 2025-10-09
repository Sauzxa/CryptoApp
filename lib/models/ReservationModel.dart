class ReservationAgent {
  final String? id;
  final String? name;
  final String? email;
  final String? role;

  ReservationAgent({this.id, this.name, this.email, this.role});

  factory ReservationAgent.fromJson(Map<String, dynamic> json) {
    return ReservationAgent(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'email': email, 'role': role};
  }
}

class ReservationModel {
  final String? id;
  final String? agentId; // For creation request
  final ReservationAgent? agent; // For response with populated data
  final String clientFullName;
  final String clientPhone;
  final String? message;
  final DateTime reservedAt;
  final String state; // 'pending', 'done', 'missed'
  final bool notificationSent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    this.id,
    this.agentId,
    this.agent,
    required this.clientFullName,
    required this.clientPhone,
    this.message,
    required this.reservedAt,
    this.state = 'pending',
    this.notificationSent = false,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating ReservationModel from JSON (API response)
  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['_id'] ?? json['id'],
      agentId: json['agentId'] is String ? json['agentId'] : null,
      agent: json['agentId'] is Map<String, dynamic>
          ? ReservationAgent.fromJson(json['agentId'])
          : null,
      clientFullName: json['clientFullName'],
      clientPhone: json['clientPhone'],
      message: json['message'],
      reservedAt: DateTime.parse(json['reservedAt']),
      state: json['state'] ?? 'pending',
      notificationSent: json['notificationSent'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert ReservationModel to JSON (for API requests)
  // This is used when creating a new reservation
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'clientFullName': clientFullName,
      'clientPhone': clientPhone,
      'reservedAt': reservedAt.toIso8601String(),
    };

    // Include message if provided
    if (message != null && message!.isNotEmpty) {
      data['message'] = message;
    }

    return data;
  }

  // Method to create a copy of the reservation with updated fields
  ReservationModel copyWith({
    String? id,
    String? agentId,
    ReservationAgent? agent,
    String? clientFullName,
    String? clientPhone,
    String? message,
    DateTime? reservedAt,
    String? state,
    bool? notificationSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      agent: agent ?? this.agent,
      clientFullName: clientFullName ?? this.clientFullName,
      clientPhone: clientPhone ?? this.clientPhone,
      message: message ?? this.message,
      reservedAt: reservedAt ?? this.reservedAt,
      state: state ?? this.state,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for state checking
  bool get isPending => state == 'pending';
  bool get isDone => state == 'done';
  bool get isMissed => state == 'missed';

  // Helper method to get state display name in French
  String get stateDisplayName {
    switch (state) {
      case 'pending':
        return 'En attente';
      case 'done':
        return 'Terminé';
      case 'missed':
        return 'Manqué';
      default:
        return state;
    }
  }

  // Helper method to get agent name
  String? get agentName => agent?.name;

  @override
  String toString() {
    return 'ReservationModel{id: $id, clientFullName: $clientFullName, clientPhone: $clientPhone, reservedAt: $reservedAt, state: $state}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Enum for reservation states (for type safety)
enum ReservationState {
  pending('pending'),
  done('done'),
  missed('missed');

  const ReservationState(this.value);
  final String value;

  static ReservationState fromString(String state) {
    switch (state.toLowerCase()) {
      case 'pending':
        return ReservationState.pending;
      case 'done':
        return ReservationState.done;
      case 'missed':
        return ReservationState.missed;
      default:
        throw ArgumentError('Invalid state: $state');
    }
  }

  String toDisplayString() {
    switch (this) {
      case ReservationState.pending:
        return 'En attente';
      case ReservationState.done:
        return 'Terminé';
      case ReservationState.missed:
        return 'Manqué';
    }
  }
}
