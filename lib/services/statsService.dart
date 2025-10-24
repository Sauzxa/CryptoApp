import 'package:http/http.dart' as http;
import 'dart:convert';

class StatsService {
  static const String baseUrl = 'http://your-api-url/api';

  // Get daily stats for terrain agents
  static Future<DailyStatsModel> getTerrainDailyStats({
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final response = await http.get(
      Uri.parse('$baseUrl/reservations/statistics?type=daily&date=$dateStr'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DailyStatsModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Failed to load terrain daily stats: ${response.statusCode}',
      );
    }
  }

  // Get monthly stats for terrain agents
  static Future<DailyStatsModel> getTerrainMonthlyStats({
    required int month,
    required int day,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/reservations/statistics?type=monthly&month=$month&day=$day',
      ),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DailyStatsModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Failed to load terrain monthly stats: ${response.statusCode}',
      );
    }
  }

  // Get daily stats for commercial agents
  static Future<CommercialDailyStatsModel> getCommercialDailyStats({
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final response = await http.get(
      Uri.parse('$baseUrl/reservations/statistics?type=daily&date=$dateStr'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CommercialDailyStatsModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Failed to load commercial daily stats: ${response.statusCode}',
      );
    }
  }

  // Get monthly stats for commercial agents
  static Future<CommercialDailyStatsModel> getCommercialMonthlyStats({
    required int month,
    required int day,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/reservations/statistics?type=monthly&month=$month&day=$day',
      ),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CommercialDailyStatsModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Failed to load commercial monthly stats: ${response.statusCode}',
      );
    }
  }

  // Helper methods
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<String> _getToken() async {
    // TODO: Implement token retrieval from secure storage
    // This should get the JWT token from SharedPreferences or secure storage
    return 'your-jwt-token';
  }
}

// Data Models
class DailyStatsModel {
  final String type;
  final String date;
  final String agentType;
  final StatsSummary summary;
  final List<HourlyData> hourlyData;
  final PerformanceMetrics performance;

  DailyStatsModel({
    required this.type,
    required this.date,
    required this.agentType,
    required this.summary,
    required this.hourlyData,
    required this.performance,
  });

  factory DailyStatsModel.fromJson(Map<String, dynamic> json) {
    return DailyStatsModel(
      type: json['type'],
      date: json['date'],
      agentType: json['agentType'],
      summary: StatsSummary.fromJson(json['summary']),
      hourlyData: (json['hourlyData'] as List)
          .map((item) => HourlyData.fromJson(item))
          .toList(),
      performance: PerformanceMetrics.fromJson(json['performance']),
    );
  }
}

class CommercialDailyStatsModel {
  final String type;
  final String date;
  final String agentType;
  final CommercialStatsSummary summary;
  final List<HourlyData> hourlyData;
  final List<FieldAgentPerformance> fieldAgentPerformance;

  CommercialDailyStatsModel({
    required this.type,
    required this.date,
    required this.agentType,
    required this.summary,
    required this.hourlyData,
    required this.fieldAgentPerformance,
  });

  factory CommercialDailyStatsModel.fromJson(Map<String, dynamic> json) {
    return CommercialDailyStatsModel(
      type: json['type'],
      date: json['date'],
      agentType: json['agentType'],
      summary: CommercialStatsSummary.fromJson(json['summary']),
      hourlyData: (json['hourlyData'] as List)
          .map((item) => HourlyData.fromJson(item))
          .toList(),
      fieldAgentPerformance: (json['fieldAgentPerformance'] as List)
          .map((item) => FieldAgentPerformance.fromJson(item))
          .toList(),
    );
  }
}

class StatsSummary {
  final int totalAssigned;
  final int completed;
  final int rejected;
  final int potentiel;
  final int nonPotentiel;
  final double successRate;
  final double averageTimePerReservation;

  StatsSummary({
    required this.totalAssigned,
    required this.completed,
    required this.rejected,
    required this.potentiel,
    required this.nonPotentiel,
    required this.successRate,
    required this.averageTimePerReservation,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      totalAssigned: json['totalAssigned'],
      completed: json['completed'],
      rejected: json['rejected'],
      potentiel: json['potentiel'],
      nonPotentiel: json['nonPotentiel'],
      successRate: json['successRate'].toDouble(),
      averageTimePerReservation: json['averageTimePerReservation'].toDouble(),
    );
  }
}

class CommercialStatsSummary {
  final int totalCreated;
  final int paye;
  final int enCours;
  final int annulee;
  final double conversionRate;
  final double totalRevenue;

  CommercialStatsSummary({
    required this.totalCreated,
    required this.paye,
    required this.enCours,
    required this.annulee,
    required this.conversionRate,
    required this.totalRevenue,
  });

  factory CommercialStatsSummary.fromJson(Map<String, dynamic> json) {
    return CommercialStatsSummary(
      totalCreated: json['totalCreated'],
      paye: json['paye'],
      enCours: json['enCours'],
      annulee: json['annulee'],
      conversionRate: json['conversionRate'].toDouble(),
      totalRevenue: json['totalRevenue'].toDouble(),
    );
  }
}

class HourlyData {
  final int hour;
  final int assigned;
  final int completed;
  final int rejected;
  final int potentiel;
  final int nonPotentiel;
  final int created;
  final int paye;
  final int enCours;
  final int annulee;

  HourlyData({
    required this.hour,
    this.assigned = 0,
    this.completed = 0,
    this.rejected = 0,
    this.potentiel = 0,
    this.nonPotentiel = 0,
    this.created = 0,
    this.paye = 0,
    this.enCours = 0,
    this.annulee = 0,
  });

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hour: json['hour'],
      assigned: json['assigned'] ?? 0,
      completed: json['completed'] ?? 0,
      rejected: json['rejected'] ?? 0,
      potentiel: json['potentiel'] ?? 0,
      nonPotentiel: json['nonPotentiel'] ?? 0,
      created: json['created'] ?? 0,
      paye: json['paye'] ?? 0,
      enCours: json['enCours'] ?? 0,
      annulee: json['annulee'] ?? 0,
    );
  }
}

class PerformanceMetrics {
  final int? bestHour;
  final int? worstHour;
  final int totalWorkingHours;

  PerformanceMetrics({
    this.bestHour,
    this.worstHour,
    required this.totalWorkingHours,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      bestHour: json['bestHour'],
      worstHour: json['worstHour'],
      totalWorkingHours: json['totalWorkingHours'],
    );
  }
}

class FieldAgentPerformance {
  final String agentId;
  final String name;
  final String email;
  final int assigned;
  final int completed;
  final int potentiel;
  final int nonPotentiel;
  final double successRate;

  FieldAgentPerformance({
    required this.agentId,
    required this.name,
    required this.email,
    required this.assigned,
    required this.completed,
    required this.potentiel,
    required this.nonPotentiel,
    required this.successRate,
  });

  factory FieldAgentPerformance.fromJson(Map<String, dynamic> json) {
    return FieldAgentPerformance(
      agentId: json['agentId'],
      name: json['name'],
      email: json['email'],
      assigned: json['assigned'],
      completed: json['completed'],
      potentiel: json['potentiel'],
      nonPotentiel: json['nonPotentiel'],
      successRate: json['successRate'].toDouble(),
    );
  }
}
