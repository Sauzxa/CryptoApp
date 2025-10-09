import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ReservationModel.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ReservationModel> _allReservations = [];
  List<ReservationModel> _filteredReservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadReservations();
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Just trigger rebuild to update countdowns
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _countdownTimer?.cancel();
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
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          _isLoading = false;
        });
        return;
      }

      final response = await apiClient.getReservations(token);

      if (response.success && response.data != null) {
        setState(() {
          _allReservations = response.data!;
          _filteredReservations = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Erreur lors du chargement';
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

  void _filterReservations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredReservations = _allReservations;
      } else {
        _filteredReservations = _allReservations.where((reservation) {
          final nameLower = reservation.clientFullName.toLowerCase();
          final phoneLower = reservation.clientPhone.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              phoneLower.contains(queryLower);
        }).toList();
      }
    });
  }

  String _getTimeRemaining(DateTime reservedAt) {
    final now = DateTime.now();
    final twentyFourHoursAfter = reservedAt.add(const Duration(hours: 24));
    final difference = twentyFourHoursAfter.difference(now);

    if (difference.isNegative) {
      return 'Expiré';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    return '${hours}h ${minutes}m ${seconds}s';
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'pending':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String state) {
    switch (state) {
      case 'pending':
        return Icons.access_time;
      case 'done':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Réservations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterReservations,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou téléphone...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          _filterReservations('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadReservations,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _filteredReservations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Aucune réservation'
                              : 'Aucun résultat trouvé',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReservations,
                    color: const Color(0xFF6366F1),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredReservations.length,
                      itemBuilder: (context, index) {
                        final reservation = _filteredReservations[index];
                        return _buildReservationCard(reservation);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(ReservationModel reservation) {
    final timeRemaining = _getTimeRemaining(reservation.reservedAt);
    final isExpired = timeRemaining == 'Expiré';
    final stateColor = _getStateColor(reservation.state);
    final stateIcon = _getStateIcon(reservation.state);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stateColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with state badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(stateIcon, color: stateColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  reservation.stateDisplayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: stateColor,
                  ),
                ),
                const Spacer(),
                if (!isExpired && reservation.state == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: stateColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: stateColor),
                        const SizedBox(width: 4),
                        Text(
                          timeRemaining,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: stateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content - 2 columns, 2 rows layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Row 1: Name and Phone
                Row(
                  children: [
                    // Column 1: Name
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reservation.clientFullName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Column 2: Phone
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reservation.clientPhone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Date and Message/Agent
                Row(
                  children: [
                    // Column 1: Date
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'dd/MM/yyyy à HH:mm',
                              ).format(reservation.reservedAt),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Column 2: Message or Agent
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            reservation.message != null &&
                                    reservation.message!.isNotEmpty
                                ? Icons.message
                                : Icons.person_outline,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reservation.message != null &&
                                      reservation.message!.isNotEmpty
                                  ? reservation.message!
                                  : reservation.agentName ?? 'N/A',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontStyle:
                                    reservation.message != null &&
                                        reservation.message!.isNotEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
