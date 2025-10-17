import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/ReservationModel.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../messagerie/MessageRoom.dart';

class SuiviPage extends StatefulWidget {
  const SuiviPage({Key? key}) : super(key: key);

  @override
  State<SuiviPage> createState() => _SuiviPageState();
}

class _SuiviPageState extends State<SuiviPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Session expirée';
          _isLoading = false;
        });
        return;
      }

      final response = await apiClient.getReservations(token);

      if (response.success && response.data != null) {
        // Filter only reservations assigned to current agent terrain
        final currentUserId = authProvider.currentUser?.id;
        final myReservations = response.data!
            .where((r) => r.agentTerrainId == currentUserId)
            .toList();

        setState(() {
          _reservations = myReservations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Erreur de chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<ReservationModel> _filterByState(String state) {
    if (state == 'all') return _reservations;
    if (state == 'terminated') {
      // Terminés includes both completed and cancelled
      return _reservations.where((r) => r.state == 'completed' || r.state == 'cancelled').toList();
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
              style: TextStyle(color: Colors.grey.shade600),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to details or chat
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStateColor(reservation.state).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStateColor(reservation.state)),
                    ),
                    child: Text(
                      reservation.stateDisplayName,
                      style: TextStyle(
                        color: _getStateColor(reservation.state),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(reservation.reservedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Client Info
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.clientFullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          reservation.clientPhone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Call Direction
              if (reservation.callDirection != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      reservation.callDirection == 'client_to_agent'
                          ? Icons.call_received
                          : Icons.call_made,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reservation.callDirectionDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Agent Commercial Info
              if (reservation.agentCommercial != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(
                          reservation.agentCommercial!.name?.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agent Commercial',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              reservation.agentCommercial!.name ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (reservation.agentCommercial!.phone != null)
                              Text(
                                reservation.agentCommercial!.phone!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Message
              if (reservation.message != null && reservation.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.message, size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservation.message!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Action Buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  if (reservation.isAssigned) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateReservationState(reservation.id!, 'in_progress'),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Commencer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (reservation.isInProgress) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Open chat to submit rapport
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ouvrez le chat pour soumettre le rapport'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.description, size: 18),
                        label: const Text('Rapport'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChatRoom(reservation),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
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

  Future<void> _updateReservationState(String reservationId, String newState) async {
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
      final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) return;
      
      // Load rooms to find the reservation room
      await messagingProvider.fetchRooms(token);
      
      // Find room by reservation ID
      final room = messagingProvider.rooms.firstWhere(
        (r) => r.reservationId == reservation.id,
        orElse: () => throw Exception('Salle de discussion non trouvée'),
      );
      
      // Navigate to chat room
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageRoomPage(room: room),
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
}
