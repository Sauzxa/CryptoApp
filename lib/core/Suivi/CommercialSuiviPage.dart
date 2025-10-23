import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/ReservationModel.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../services/socket_service.dart';
import '../../utils/colors.dart';

class CommercialSuiviPage extends StatefulWidget {
  const CommercialSuiviPage({Key? key}) : super(key: key);

  @override
  State<CommercialSuiviPage> createState() => _CommercialSuiviPageState();
}

class _CommercialSuiviPageState extends State<CommercialSuiviPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<ReservationModel> _payeReservations = [];
  List<ReservationModel> _annuleReservations = [];
  List<ReservationModel> _enCoursReservations = [];
  Map<String, List<ReservationModel>> _calendarReservations = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    initializeDateFormatting('fr', null); // Initialize French locale
    _loadSuiviData();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    // Listen for rapport submitted
    socketService.onRapportSubmitted((data) {
      debugPrint('📥 Rapport submitted: $data');
      _loadSuiviData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Nouveau rapport reçu'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });

    // Listen for reservation reassigned
    socketService.onReservationReassigned((data) {
      debugPrint('📥 Reservation reassigned: $data');
      _loadSuiviData();
    });

    // Listen for commercial action
    socketService.onCommercialAction((data) {
      debugPrint('📥 Commercial action: $data');
      _loadSuiviData();
    });
  }

  Future<void> _loadSuiviData() async {
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

      debugPrint('🔄 Loading commercial suivi data...');
      final response = await apiClient.getCommercialSuivi(
        token,
        section: 'all',
      );

      if (response.success && response.data != null) {
        final sections = response.data!['sections'];

        if (mounted) {
          setState(() {
            // Parse paye section
            _payeReservations =
                (sections['paye']['reservations'] as List?)
                    ?.map((json) => ReservationModel.fromJson(json))
                    .toList() ??
                [];

            // Parse annule section
            _annuleReservations =
                (sections['annule']['reservations'] as List?)
                    ?.map((json) => ReservationModel.fromJson(json))
                    .toList() ??
                [];

            // Parse en_cours section
            _enCoursReservations =
                (sections['en_cours']['reservations'] as List?)
                    ?.map((json) => ReservationModel.fromJson(json))
                    .toList() ??
                [];

            _isLoading = false;
          });

          // Load calendar data
          await _loadCalendarData();

          debugPrint(
            '✅ Loaded suivi: Payé=${_payeReservations.length}, Annulé=${_annuleReservations.length}, En cours=${_enCoursReservations.length}',
          );
        }
      } else {
        debugPrint('❌ Failed to load suivi: ${response.message}');
        if (mounted) {
          setState(() {
            _errorMessage = response.message ?? 'Erreur de chargement';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Exception loading suivi: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCalendarData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final response = await apiClient.getCommercialCalendar(
        token,
        month: _focusedDay.month,
        year: _focusedDay.year,
      );

      if (response.success && response.data != null) {
        final groupedByDate =
            response.data!['groupedByDate'] as Map<String, dynamic>?;

        if (mounted && groupedByDate != null) {
          setState(() {
            _calendarReservations = groupedByDate.map((key, value) {
              final reservations = (value as List)
                  .map((json) => ReservationModel.fromJson(json))
                  .toList();
              return MapEntry(key, reservations);
            });
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading calendar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi Commercial'),
        backgroundColor: const Color(0xFF6366F1),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Payé'),
            Tab(text: 'Annulé'),
            Tab(text: 'En Cours'),
            Tab(text: 'Calendrier'),
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
                    onPressed: _loadSuiviData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReservationList(_payeReservations, 'Payé', Colors.green),
                _buildReservationList(
                  _annuleReservations,
                  'Annulé',
                  Colors.red,
                ),
                _buildReservationList(
                  _enCoursReservations,
                  'En Cours',
                  Colors.orange,
                ),
                _buildCalendarView(),
              ],
            ),
    );
  }

  Widget _buildReservationList(
    List<ReservationModel> reservations,
    String title,
    Color color,
  ) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune réservation $title',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuiviData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(reservations[index], color);
        },
      ),
    );
  }

  Widget _buildReservationCard(
    ReservationModel reservation,
    Color accentColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor),
                  ),
                  child: Text(
                    reservation.commercialActionDisplay.isNotEmpty
                        ? reservation.commercialActionDisplay
                        : reservation.stateDisplayName,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(reservation.reservedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Client info
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      Text(
                        reservation.clientPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Agent Terrain info
            if (reservation.agentTerrain != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCardBackground.withOpacity(0.7)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        reservation.agentTerrain!.name
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            'A',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agent Terrain',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            reservation.agentTerrain!.name ?? 'N/A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Rapport info
            if (reservation.rapportState != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCardBackground.withOpacity(0.7)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      reservation.rapportState == 'potentiel'
                          ? Icons.thumb_up
                          : Icons.thumb_down,
                      size: 16,
                      color: reservation.rapportState == 'potentiel'
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rapport: ${reservation.rapportStateDisplay}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.grey.shade800,
                            ),
                          ),
                          if (reservation.rapportMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              reservation.rapportMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey.shade700,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Month header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF6366F1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                    );
                  });
                  _loadCalendarData();
                },
              ),
              Text(
                DateFormat('MMMM yyyy', 'fr').format(_focusedDay),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                    );
                  });
                  _loadCalendarData();
                },
              ),
            ],
          ),
        ),

        // Simple calendar grid
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Day headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Calendar days grid
              _buildCalendarGrid(),
            ],
          ),
        ),

        const Divider(),
        Expanded(
          child: _selectedDay == null
              ? Center(
                  child: Text(
                    'Sélectionnez une date pour voir les rendez-vous',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                )
              : _buildDayReservations(_selectedDay!),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final hasReservations =
          _calendarReservations.containsKey(dateKey) &&
          _calendarReservations[dateKey]!.isNotEmpty;
      final isSelected =
          _selectedDay != null &&
          date.year == _selectedDay!.year &&
          date.month == _selectedDay!.month &&
          date.day == _selectedDay!.day;
      final isToday =
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : isToday
                  ? Colors.blue.withOpacity(0.2)
                  : null,
              shape: BoxShape.circle,
              border: hasReservations
                  ? Border.all(color: Colors.red, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                  fontWeight: hasReservations
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildDayReservations(DateTime day) {
    final dateKey = DateFormat('yyyy-MM-dd').format(day);
    final reservations = _calendarReservations[dateKey] ?? [];

    if (reservations.isEmpty) {
      return Center(
        child: Text(
          'Aucun rendez-vous ce jour',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.7)
                : Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        return _buildReservationCard(reservations[index], Colors.orange);
      },
    );
  }
}
