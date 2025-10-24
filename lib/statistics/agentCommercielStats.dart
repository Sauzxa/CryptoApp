import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:CryptoApp/api/api_client.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import 'package:CryptoApp/widgets/chartWidgets.dart';

class AgentCommercielStats extends StatefulWidget {
  const AgentCommercielStats({Key? key}) : super(key: key);

  @override
  State<AgentCommercielStats> createState() => _AgentCommercielStatsState();
}

class _AgentCommercielStatsState extends State<AgentCommercielStats>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _errorMessage = '';

  // Data variables
  Map<String, dynamic>? _dailyStats;
  Map<String, dynamic>? _monthlyStats;

  // Chart data
  List<ChartData> _commercialActionData = [];
  List<ChartData> _reservationsCreatedData = [];
  List<LineChartSpot> _hourlyLineData = [];

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

      final response = await apiClient.getCommercialDailyStats(
        token,
        _selectedDate,
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

      final response = await apiClient.getCommercialMonthlyStats(
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

    // Create commercial action bar chart data
    _commercialActionData = [
      ChartData('Payé', summary['paye']?.toDouble() ?? 0, Colors.green),
      ChartData('En Cours', summary['enCours']?.toDouble() ?? 0, Colors.orange),
      ChartData('Annulée', summary['annulee']?.toDouble() ?? 0, Colors.red),
    ];

    // Create reservations created bar chart data
    _reservationsCreatedData = [
      ChartData(
        'Créées',
        summary['totalCreated']?.toDouble() ?? 0,
        Colors.blue,
      ),
    ];

    // Create hourly line chart data
    final hourlyLineData = statsData['hourlyData'] as List<dynamic>;
    _hourlyLineData = hourlyLineData.map((hour) {
      return LineChartSpot(hour['hour'].toDouble(), hour['created'].toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Agent Commercial Statistics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daily View', icon: Icon(Icons.today)),
            Tab(text: 'Monthly View', icon: Icon(Icons.calendar_month)),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  backgroundColor: Colors.blue[600],
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
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Apply Filter'),
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dailyStats == null) {
      return const Center(
        child: Text(
          'No data available. Please select a date and apply filter.',
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

          // Bar Chart - Payé vs En Cours vs Annulée
          _buildBarChart(
            title: 'Commercial Actions Overview',
            data: _commercialActionData,
          ),
          const SizedBox(height: 20),

          // Bar Chart - Created vs Completed
          _buildBarChart(
            title: 'Reservations Created',
            data: _reservationsCreatedData,
          ),
          const SizedBox(height: 20),

          // Line Chart - Hourly Activity
          _buildLineChart(
            title: 'Hourly Reservation Creation',
            data: _hourlyLineData,
          ),
          const SizedBox(height: 20),

          // Field Agent Performance
          _buildFieldAgentPerformance(),
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_monthlyStats == null) {
      return const Center(
        child: Text(
          'No data available. Please select month/day and apply filter.',
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
          // Bar Chart - Payé vs En Cours vs Annulée
          _buildBarChart(
            title: 'Commercial Actions Overview',
            data: _commercialActionData,
          ),
          const SizedBox(height: 20),

          // Bar Chart - Created vs Completed
          _buildBarChart(
            title: 'Reservations Created',
            data: _reservationsCreatedData,
          ),
          const SizedBox(height: 20),

          // Line Chart - Hourly Activity
          _buildLineChart(
            title: 'Hourly Reservation Creation',
            data: _hourlyLineData,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Created',
            value: summary['totalCreated'].toString(),
            icon: Icons.add_circle,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Payé',
            value: summary['paye'].toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Conversion Rate',
            value: '${summary['conversionRate'].toString()}%',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildLineChart({
    required String title,
    required List<LineChartSpot> data,
  }) {
    return CustomLineChart(title: title, data: data);
  }

  Widget _buildFieldAgentPerformance() {
    final fieldAgents = _dailyStats!['fieldAgentPerformance'] ?? [];

    if (fieldAgents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No field agent performance data available'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Field Agent Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...fieldAgents
              .map<Widget>(
                (agent) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              agent['email'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${agent['successRate']}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: agent['successRate'] >= 80
                                    ? Colors.green
                                    : agent['successRate'] >= 60
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                            const Text(
                              'Success Rate',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${agent['assigned']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Assigned',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${agent['completed']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
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
}
