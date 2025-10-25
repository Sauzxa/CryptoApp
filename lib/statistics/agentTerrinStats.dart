import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:CryptoApp/api/api_client.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import 'package:CryptoApp/widgets/chartWidgets.dart';
import 'package:CryptoApp/utils/colors.dart';

class AgentTerrinStats extends StatefulWidget {
  const AgentTerrinStats({Key? key}) : super(key: key);

  @override
  State<AgentTerrinStats> createState() => _AgentTerrinStatsState();
}

class _AgentTerrinStatsState extends State<AgentTerrinStats>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _errorMessage = '';

  // Data variables
  Map<String, dynamic>? _dailyStats;
  Map<String, dynamic>? _monthlyStats;

  // Chart data
  List<ChartData> _assignedVsCompletedData = [];
  List<ChartData> _agentPerformanceData = [];

  // Date selection
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedDay = DateTime.now().day;
  bool _isMonthlyView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isMonthlyView = _tabController.index == 1;
        });
      }
    });
    _loadDailyStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Token d\'authentification manquant';
          _isLoading = false;
        });
        return;
      }

      final response = await apiClient.getTerrainDailyStats(
        token,
        _selectedDate,
        allAgents: true, // Get all agents for daily view
      );

      if (response.success && response.data != null) {
        setState(() {
          _dailyStats = response.data;
          _processStatsData(response.data!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Erreur lors du chargement des statistiques';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthlyStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Token d\'authentification manquant';
          _isLoading = false;
        });
        return;
      }

      final response = await apiClient.getTerrainMonthlyStats(
        token,
        _selectedMonth,
        _selectedDay,
      );

      if (response.success && response.data != null) {
        setState(() {
          _monthlyStats = response.data;
          _processStatsData(response.data!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Erreur lors du chargement des statistiques';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _processStatsData(Map<String, dynamic> statsData) {
    final summary = statsData['summary'] as Map<String, dynamic>;

    // Create assigned vs completed bar chart data
    _assignedVsCompletedData = [
      ChartData(
        'Assignées',
        summary['totalAssigned']?.toDouble() ?? 0,
        Colors.blue,
      ),
      ChartData(
        'Terminées',
        summary['completed']?.toDouble() ?? 0,
        Colors.green,
      ),
      ChartData('Rejetées', summary['rejected']?.toDouble() ?? 0, Colors.red),
    ];

    // Create agent performance chart data if available
    final agentBreakdown = statsData['agentBreakdown'] as List<dynamic>?;
    if (agentBreakdown != null && agentBreakdown.isNotEmpty) {
      _agentPerformanceData = agentBreakdown.take(10).map((agent) {
        return ChartData(
          agent['name'] ?? 'Unknown',
          agent['potentiel']?.toDouble() ??
              0, // Changed to show potential clients instead of assignments
          Colors.blue,
        );
      }).toList();
    } else {
      _agentPerformanceData = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Statistiques Agent Terrain',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark
            ? AppColors.darkCardBackground
            : Colors.purple[700],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Vue Quotidienne', icon: Icon(Icons.today)),
            Tab(text: 'Vue Mensuelle', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Selector Section
          _buildDateSelector(),

          // Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDailyView(), _buildMonthlyView()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isMonthlyView ? null : _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                ),
              ),
              if (_isMonthlyView) ...[
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (index) => index + 1)
                      .map(
                        (month) => DropdownMenuItem(
                          value: month,
                          child: Text(
                            DateFormat('MMMM').format(DateTime(2024, month)),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                      _selectedDay = 1; // Reset day when month changes
                    });
                  },
                ),
                DropdownButton<int>(
                  value: _selectedDay,
                  items:
                      List.generate(
                            DateTime(2024, _selectedMonth + 1, 0).day,
                            (index) => index + 1,
                          )
                          .map(
                            (day) => DropdownMenuItem(
                              value: day,
                              child: Text('Day $day'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value!;
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isMonthlyView ? _loadMonthlyStats : _loadDailyStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Appliquer le Filtre'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyStats,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_dailyStats == null) {
      return const Center(
        child: Text(
          'Aucune donnée disponible. Veuillez sélectionner une date et appliquer le filtre.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(_dailyStats!['summary']),
          const SizedBox(height: 20),

          // Bar Chart - Assigned vs Completed vs Rejected
          _buildBarChart(
            title: 'Aperçu des Réservations',
            data: _assignedVsCompletedData,
          ),
          const SizedBox(height: 20),

          // Enhanced Top Agent Performance Chart
          if (_agentPerformanceData.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Agents les Plus Performants',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Basé sur les clients potentiels générés',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBarChart(title: '', data: _agentPerformanceData),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('Top 3', Colors.green),
                      _buildLegendItem('Niveau Moyen', Colors.orange),
                      _buildLegendItem('Autres', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'L\'axe Y affiche le nombre de clients potentiels',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMonthlyStats,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_monthlyStats == null) {
      return const Center(
        child: Text(
          'Aucune donnée disponible. Veuillez sélectionner le mois/jour et appliquer le filtre.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(_monthlyStats!['summary']),
          const SizedBox(height: 20),

          // Monthly charts would go here
          // Bar Chart - Assigned vs Completed vs Rejected
          _buildBarChart(
            title: 'Aperçu des Réservations',
            data: _assignedVsCompletedData,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Assigné',
            value: summary['totalAssigned'].toString(),
            icon: Icons.assignment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Terminé',
            value: summary['completed'].toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Taux de Réussite',
            value: '${summary['successRate'].toString()}%',
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardBackground.withOpacity(0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required String title,
    required List<ChartData> data,
  }) {
    return CustomBarChart(title: title, data: data);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
