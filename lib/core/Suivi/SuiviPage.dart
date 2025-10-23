import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/ReservationModel.dart';
import '../../models/RoomModel.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../services/socket_service.dart';
import '../messagerie/MessageRoom.dart';
import '../../utils/snackbar_utils.dart';

class SuiviPage extends StatefulWidget {
  const SuiviPage({Key? key}) : super(key: key);

  @override
  State<SuiviPage> createState() => _SuiviPageState();
}

class _SuiviPageState extends State<SuiviPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReservations();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _removeSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socket = socketService.socket;
    if (socket == null) return;

    // Listen for agent becoming available again
    socket.on('agent:available_again', (data) {
      debugPrint('📥 Agent available again: $data');
      _loadReservations();
    });

    // Listen for agent still unavailable
    socket.on('agent:still_unavailable', (data) {
      debugPrint('📥 Agent still unavailable: $data');
      _loadReservations();
    });

    // Listen for reservation updates
    socket.on('reservation:updated', (data) {
      debugPrint('📥 Reservation updated: $data');
      _loadReservations();
    });

    // Listen for new reservation assigned
    socket.on('reservation:assigned', (data) {
      debugPrint('📥 New reservation assigned: $data');
      _loadReservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Nouveau rendez-vous assigné'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });

    // NEW: Listen for reservation rejected
    socketService.onReservationRejected((data) {
      debugPrint('📥 Reservation rejected: $data');
      _loadReservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Réservation rejetée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });

    // NEW: Listen for reservation reassigned
    socketService.onReservationReassigned((data) {
      debugPrint('📥 Reservation reassigned: $data');
      _loadReservations();
    });

    // NEW: Listen for rapport submitted
    socketService.onRapportSubmitted((data) {
      debugPrint('📥 Rapport submitted: $data');
      _loadReservations();
    });

    // NEW: Listen for availability toggle enabled
    socketService.onAvailabilityToggleEnabled((data) {
      debugPrint('📥 Availability toggle enabled: $data');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Vous pouvez modifier votre disponibilité',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    // NEW: Listen for commercial action
    socketService.onCommercialAction((data) {
      debugPrint('📥 Commercial action: $data');
      _loadReservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Action commerciale effectuée'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });

    // NEW: Listen for reservation rescheduled
    socketService.onReservationRescheduled((data) {
      debugPrint('📥 Reservation rescheduled: $data');
      _loadReservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Rendez-vous reprogrammé'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  void _removeSocketListeners() {
    final socket = socketService.socket;
    if (socket == null) return;

    socket.off('agent:available_again');
    socket.off('agent:still_unavailable');
    socket.off('reservation:updated');
    socket.off('reservation:assigned');
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Session expirée';
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('🔄 Loading reservations for agent terrain...');
      final response = await apiClient.getReservations(token);
      debugPrint(
        '📥 API Response - Success: ${response.success}, Data: ${response.data?.length ?? 0} reservations',
      );

      if (response.success && response.data != null) {
        // Backend already filters by agentTerrainId for field agents
        // No need to filter again on frontend
        if (mounted) {
          setState(() {
            _reservations = response.data!;
            _isLoading = false;
          });
          debugPrint('✅ Loaded ${_reservations.length} reservations');
        }
      } else {
        debugPrint('❌ Failed to load reservations: ${response.message}');
        if (mounted) {
          setState(() {
            _errorMessage = response.message ?? 'Erreur de chargement';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Exception loading reservations: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<ReservationModel> _filterByState(String state) {
    if (state == 'all') return _reservations;
    if (state == 'terminated') {
      // Terminés includes both completed and cancelled
      return _reservations
          .where((r) => r.state == 'completed' || r.state == 'cancelled')
          .toList();
    }
    return _reservations.where((r) => r.state == state).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Rendez-vous'),
        backgroundColor: const Color(0xFF6366F1),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Assignés'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReservations,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReservationList(_filterByState('all')),
                _buildReservationList(_filterByState('assigned')),
                _buildReservationList(_filterByState('in_progress')),
                _buildReservationList(_filterByState('terminated')),
              ],
            ),
    );
  }

  Widget _buildReservationList(List<ReservationModel> reservations) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun rendez-vous',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(reservations[index]);
        },
      ),
    );
  }

  Widget _buildReservationCard(ReservationModel reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to details or chat
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStateColor(
                        reservation.state,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _getStateColor(reservation.state),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      reservation.stateDisplayName,
                      style: TextStyle(
                        color: _getStateColor(reservation.state),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(reservation.reservedAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Client Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.clientFullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reservation.clientPhone,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Call Direction
              if (reservation.callDirection != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reservation.callDirection == 'client_to_agent'
                            ? Icons.call_received
                            : Icons.call_made,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.blue.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reservation.callDirectionDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.8)
                              : Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Agent Commercial Info
              if (reservation.agentCommercial != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(
                          reservation.agentCommercial!.name
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agent Commercial',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reservation.agentCommercial!.name ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.grey.shade800,
                              ),
                            ),
                            if (reservation.agentCommercial!.phone != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                reservation.agentCommercial!.phone!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Message
              if (reservation.message != null &&
                  reservation.message!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.message,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reservation.message!,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              const SizedBox(height: 16),
              Column(
                children: [
                  // Show Rejeter + Commencer ONLY when state is 'assigned'
                  if (reservation.isAssigned) ...[
                    // Rejeter Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRejectConfirmation(reservation),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Commencer Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateReservationState(
                          reservation.id!,
                          'in_progress',
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Commencer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],

                  // Show Message Button ONLY when state is 'in_progress'
                  if (reservation.isInProgress) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openChatRoom(reservation),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      case 'missed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateReservationState(
    String reservationId,
    String newState,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      // Call API to update state
      await apiClient.updateReservationState(reservationId, newState, token);

      // Reload reservations
      await _loadReservations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Statut mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openChatRoom(ReservationModel reservation) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final messagingProvider = Provider.of<MessagingProvider>(
        context,
        listen: false,
      );
      final token = authProvider.token;
      final currentUserId = authProvider.currentUser?.id;

      if (token == null || currentUserId == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );

      // Load rooms to find the reservation room
      await messagingProvider.fetchRooms(token);

      print(
        '🔍 Looking for reservation room for reservation: ${reservation.id}',
      );
      print('🔍 Current user ID: $currentUserId');
      print('🔍 Total rooms fetched: ${messagingProvider.rooms.length}');

      late RoomModel room;

      // Find reservation room - backend now returns all rooms we have access to
      try {
        room = messagingProvider.rooms.firstWhere(
          (r) =>
              r.roomType == 'reservation' && r.reservationId == reservation.id,
        );

        print('✅ Found reservation room: ${room.id}');
        print('✅ Room name: ${room.name}');
      } catch (e) {
        // Room not found - might be a timing issue, try once more
        print('⚠️ Room not found, retrying...');
        await Future.delayed(const Duration(milliseconds: 500));
        await messagingProvider.fetchRooms(token);

        try {
          room = messagingProvider.rooms.firstWhere(
            (r) =>
                r.roomType == 'reservation' &&
                r.reservationId == reservation.id,
          );
          print('✅ Found room on retry: ${room.id}');
        } catch (e2) {
          throw Exception(
            'Salle de conversation non trouvée. '
            'Veuillez réessayer ou contacter l\'administrateur.',
          );
        }
      }

      // Close loading indicator
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to chat room
      if (mounted) {
        print('🚀 Navigating to reservation room: ${room.id}');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MessageRoomPage(room: room)),
        );
      }
    } catch (e) {
      print('❌ Error opening chat room: $e');

      // Close loading indicator if still open
      if (mounted) {
        Navigator.pop(context);
        SnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _showRejectConfirmation(ReservationModel reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le rendez-vous'),
        content: Text(
          'Êtes-vous sûr de vouloir rejeter ce rendez-vous avec ${reservation.clientFullName} ?\n\n'
          'Il sera réassigné à un autre agent disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _rejectReservation(reservation.id!);
    }
  }

  Future<void> _rejectReservation(String reservationId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      setState(() => _isLoading = true);

      final response = await apiClient.rejectReservation(reservationId, token);

      if (response.success) {
        await _loadReservations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? 'Réservation rejetée avec succès',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Erreur lors du rejet'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
