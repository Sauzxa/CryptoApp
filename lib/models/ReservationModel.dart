class ProfilePhoto {
  final String? url;
  final String? cloudinaryId;

  ProfilePhoto({this.url, this.cloudinaryId});

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(url: json['url'], cloudinaryId: json['cloudinaryId']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'cloudinaryId': cloudinaryId};
  }
}

class ReservationAgent {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final ProfilePhoto? profilePhoto;

  ReservationAgent({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.profilePhoto,
  });

  factory ReservationAgent.fromJson(Map<String, dynamic> json) {
    return ReservationAgent(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      profilePhoto: json['profilePhoto'] != null
          ? (json['profilePhoto'] is Map<String, dynamic>
                ? ProfilePhoto.fromJson(json['profilePhoto'])
                : null)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profilePhoto': profilePhoto?.toJson(),
    };
  }
}

class ReservationModel {
  final String? id;
  final String? agentCommercialId;
  final String? agentTerrainId;
  final ReservationAgent? agentCommercial;
  final ReservationAgent? agentTerrain;
  final String clientFullName;
  final String clientPhone;
  final String? message;
  final DateTime reservedAt;
  final String
  state; // 'pending', 'assigned', 'in_progress', 'completed', 'cancelled', 'missed'
  final String? callDirection; // 'client_to_agent', 'agent_to_client'
  final String? rapportMessage;
  final String? rapportState; // 'potentiel', 'non_potentiel'
  final String? commercialAction; // 'paye', 'en_cours', 'annulee'
  final String? commercialActionMessage; // Message from commercial action form
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final DateTime? rapportSentAt;
  final DateTime? rescheduledAt;
  final bool? agentCanToggleAvailability;
  final bool notificationSent3h;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    this.id,
    this.agentCommercialId,
    this.agentTerrainId,
    this.agentCommercial,
    this.agentTerrain,
    required this.clientFullName,
    required this.clientPhone,
    this.message,
    required this.reservedAt,
    this.state = 'pending',
    this.callDirection,
    this.rapportMessage,
    this.rapportState,
    this.commercialAction,
    this.commercialActionMessage,
    this.assignedAt,
    this.completedAt,
    this.rapportSentAt,
    this.rescheduledAt,
    this.agentCanToggleAvailability,
    this.notificationSent3h = false,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating ReservationModel from JSON (API response)
  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['_id'] ?? json['id'],
      agentCommercialId: json['agentCommercialId'] is String
          ? json['agentCommercialId']
          : (json['agentCommercialId'] is Map
                ? json['agentCommercialId']['_id']
                : null),
      agentTerrainId: json['agentTerrainId'] is String
          ? json['agentTerrainId']
          : (json['agentTerrainId'] is Map
                ? json['agentTerrainId']['_id']
                : null),
      agentCommercial: json['agentCommercialId'] is Map<String, dynamic>
          ? ReservationAgent.fromJson(json['agentCommercialId'])
          : null,
      agentTerrain: json['agentTerrainId'] is Map<String, dynamic>
          ? ReservationAgent.fromJson(json['agentTerrainId'])
          : null,
      clientFullName: json['clientFullName'] ?? '',
      clientPhone: json['clientPhone'] ?? '',
      message: json['message'],
      reservedAt: DateTime.parse(json['reservedAt']),
      state: json['state'] ?? 'pending',
      callDirection: json['callDirection'],
      rapportMessage: json['rapportMessage'],
      rapportState: json['rapportState'],
      commercialAction: json['commercialAction'],
      commercialActionMessage: json['commercialActionMessage'],
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      rapportSentAt: json['rapportSentAt'] != null
          ? DateTime.parse(json['rapportSentAt'])
          : null,
      rescheduledAt: json['rescheduledAt'] != null
          ? DateTime.parse(json['rescheduledAt'])
          : null,
      agentCanToggleAvailability: json['agentCanToggleAvailability'],
      notificationSent3h: json['notificationSent3h'] ?? false,
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

    if (message != null && message!.isNotEmpty) {
      data['message'] = message;
    }
    if (callDirection != null) {
      data['callDirection'] = callDirection;
    }

    return data;
  }

  // Method to create a copy of the reservation with updated fields
  ReservationModel copyWith({
    String? id,
    String? agentCommercialId,
    String? agentTerrainId,
    ReservationAgent? agentCommercial,
    ReservationAgent? agentTerrain,
    String? clientFullName,
    String? clientPhone,
    String? message,
    DateTime? reservedAt,
    String? state,
    String? callDirection,
    String? rapportMessage,
    String? rapportState,
    String? commercialAction,
    String? commercialActionMessage,
    DateTime? assignedAt,
    DateTime? completedAt,
    DateTime? rapportSentAt,
    DateTime? rescheduledAt,
    bool? agentCanToggleAvailability,
    bool? notificationSent3h,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      agentCommercialId: agentCommercialId ?? this.agentCommercialId,
      agentTerrainId: agentTerrainId ?? this.agentTerrainId,
      agentCommercial: agentCommercial ?? this.agentCommercial,
      agentTerrain: agentTerrain ?? this.agentTerrain,
      clientFullName: clientFullName ?? this.clientFullName,
      clientPhone: clientPhone ?? this.clientPhone,
      message: message ?? this.message,
      reservedAt: reservedAt ?? this.reservedAt,
      state: state ?? this.state,
      callDirection: callDirection ?? this.callDirection,
      rapportMessage: rapportMessage ?? this.rapportMessage,
      rapportState: rapportState ?? this.rapportState,
      commercialAction: commercialAction ?? this.commercialAction,
      commercialActionMessage:
          commercialActionMessage ?? this.commercialActionMessage,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      rapportSentAt: rapportSentAt ?? this.rapportSentAt,
      rescheduledAt: rescheduledAt ?? this.rescheduledAt,
      agentCanToggleAvailability:
          agentCanToggleAvailability ?? this.agentCanToggleAvailability,
      notificationSent3h: notificationSent3h ?? this.notificationSent3h,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // State helpers
  bool get isPending => state == 'pending';
  bool get isAssigned => state == 'assigned';
  bool get isInProgress => state == 'in_progress';
  bool get isCompleted => state == 'completed';
  bool get isCancelled => state == 'cancelled';
  bool get isMissed => state == 'missed';

  String get stateDisplayName {
    switch (state) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'Assigné';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      case 'missed':
        return 'Manqué';
      default:
        return state;
    }
  }

  String? get agentCommercialName => agentCommercial?.name;
  String? get agentTerrainName => agentTerrain?.name;

  bool get hasRapport => rapportState != null && rapportMessage != null;

  // Rapport state helpers
  bool get hasPotentielRapport => rapportState == 'potentiel';
  bool get hasNonPotentielRapport => rapportState == 'non_potentiel';
  bool get isRescheduled => rescheduledAt != null;

  String get rapportStateDisplay {
    if (rapportState == 'potentiel') {
      return 'Potentiel';
    } else if (rapportState == 'non_potentiel') {
      return 'Non Potentiel';
    }
    return '';
  }

  String get callDirectionDisplay {
    if (callDirection == 'client_to_agent') {
      return 'Client a appelé';
    } else if (callDirection == 'agent_to_client') {
      return 'Agent a appelé';
    }
    return '';
  }

  String get commercialActionDisplay {
    if (commercialAction == 'paye') {
      return 'Payé';
    } else if (commercialAction == 'en_cours') {
      return 'En Cours';
    } else if (commercialAction == 'annulee') {
      return 'Annulé';
    }
    return '';
  }

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
  pending('pending', 'En attente'),
  assigned('assigned', 'Assigné'),
  inProgress('in_progress', 'En cours'),
  completed('completed', 'Terminé'),
  cancelled('cancelled', 'Annulé'),
  missed('missed', 'Manqué');

  const ReservationState(this.value, this.displayName);
  final String value;
  final String displayName;

  static ReservationState fromString(String state) {
    switch (state.toLowerCase()) {
      case 'pending':
        return ReservationState.pending;
      case 'assigned':
        return ReservationState.assigned;
      case 'in_progress':
        return ReservationState.inProgress;
      case 'completed':
        return ReservationState.completed;
      case 'cancelled':
        return ReservationState.cancelled;
      case 'missed':
        return ReservationState.missed;
      default:
        return ReservationState.pending;
    }
  }
}
