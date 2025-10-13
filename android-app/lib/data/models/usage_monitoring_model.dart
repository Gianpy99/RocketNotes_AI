// ==========================================
// lib/data/models/usage_monitoring_model.dart
// ==========================================
import 'package:hive/hive.dart';

part 'usage_monitoring_model.g.dart';

@HiveType(typeId: 20)
class UsageMonitoringModel {
  @HiveField(0)
  final DateTime lastResetDate;

  @HiveField(1)
  final Map<String, DailyUsage> dailyUsage;

  @HiveField(2)
  final Map<String, MonthlySpending> monthlySpending;

  @HiveField(3)
  final double dailySpendingLimit;

  @HiveField(4)
  final double monthlySpendingLimit;

  @HiveField(5)
  final bool enableCostOptimization;

  @HiveField(6)
  final bool preferFreeTier;

  const UsageMonitoringModel({
    required this.lastResetDate,
    required this.dailyUsage,
    required this.monthlySpending,
    this.dailySpendingLimit = 5.0, // $5 per day default
    this.monthlySpendingLimit = 100.0, // $100 per month default
    this.enableCostOptimization = true,
    this.preferFreeTier = true,
  });

  // Factory constructor for defaults
  factory UsageMonitoringModel.defaults() {
    return UsageMonitoringModel(
      lastResetDate: DateTime.now(),
      dailyUsage: {},
      monthlySpending: {},
      dailySpendingLimit: 5.0,
      monthlySpendingLimit: 100.0,
      enableCostOptimization: true,
      preferFreeTier: true,
    );
  }

  // Copy with method
  UsageMonitoringModel copyWith({
    DateTime? lastResetDate,
    Map<String, DailyUsage>? dailyUsage,
    Map<String, MonthlySpending>? monthlySpending,
    double? dailySpendingLimit,
    double? monthlySpendingLimit,
    bool? enableCostOptimization,
    bool? preferFreeTier,
  }) {
    return UsageMonitoringModel(
      lastResetDate: lastResetDate ?? this.lastResetDate,
      dailyUsage: dailyUsage ?? this.dailyUsage,
      monthlySpending: monthlySpending ?? this.monthlySpending,
      dailySpendingLimit: dailySpendingLimit ?? this.dailySpendingLimit,
      monthlySpendingLimit: monthlySpendingLimit ?? this.monthlySpendingLimit,
      enableCostOptimization: enableCostOptimization ?? this.enableCostOptimization,
      preferFreeTier: preferFreeTier ?? this.preferFreeTier,
    );
  }

  // Get today's usage for provider
  DailyUsage getTodayUsage(String provider) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = '${provider}_$today';
    return dailyUsage[key] ?? DailyUsage.empty(provider, today);
  }

  // Get current month spending for provider
  MonthlySpending getCurrentMonthSpending(String provider) {
    final now = DateTime.now();
    final monthKey = '${provider}_${now.year}_${now.month}';
    return monthlySpending[monthKey] ?? MonthlySpending.empty(provider, now.year, now.month);
  }

  // Check if within free tier limits for Gemini
  bool isWithinGeminiFreeLimit(String modelId) {
    final todayUsage = getTodayUsage('gemini');
    
    // Check daily request limits for free tier
    if (modelId.contains('flash') || modelId.contains('flash-lite')) {
      return todayUsage.requestCount < 25; // RPD limit for free API
    }
    
    if (modelId.contains('pro')) {
      return todayUsage.groundingRequests < 1500; // Grounding limit
    }
    
    return true;
  }

  // Calculate estimated daily cost
  double calculateDailyCost() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    double totalCost = 0.0;
    
    for (final usage in dailyUsage.values) {
      if (usage.date == today) {
        totalCost += usage.estimatedCost;
      }
    }
    
    return totalCost;
  }

  // Calculate estimated monthly cost
  double calculateMonthlyCost() {
    final now = DateTime.now();
    double totalCost = 0.0;
    
    for (final spending in monthlySpending.values) {
      if (spending.year == now.year && spending.month == now.month) {
        totalCost += spending.totalCost;
      }
    }
    
    return totalCost;
  }

  // Check if should switch to free tier
  bool shouldSwitchToFreeTier(String provider) {
    if (!enableCostOptimization || !preferFreeTier) return false;
    
    final dailyCost = calculateDailyCost();
    final monthlyCost = calculateMonthlyCost();
    
    // Switch to free tier if approaching limits
    return dailyCost > (dailySpendingLimit * 0.8) || 
           monthlyCost > (monthlySpendingLimit * 0.8);
  }

  Map<String, dynamic> toJson() {
    return {
      'lastResetDate': lastResetDate.toIso8601String(),
      'dailyUsage': dailyUsage.map((k, v) => MapEntry(k, v.toJson())),
      'monthlySpending': monthlySpending.map((k, v) => MapEntry(k, v.toJson())),
      'dailySpendingLimit': dailySpendingLimit,
      'monthlySpendingLimit': monthlySpendingLimit,
      'enableCostOptimization': enableCostOptimization,
      'preferFreeTier': preferFreeTier,
    };
  }

  factory UsageMonitoringModel.fromJson(Map<String, dynamic> json) {
    return UsageMonitoringModel(
      lastResetDate: DateTime.parse(json['lastResetDate']),
      dailyUsage: (json['dailyUsage'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, DailyUsage.fromJson(v)),
      ),
      monthlySpending: (json['monthlySpending'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, MonthlySpending.fromJson(v)),
      ),
      dailySpendingLimit: json['dailySpendingLimit']?.toDouble() ?? 5.0,
      monthlySpendingLimit: json['monthlySpendingLimit']?.toDouble() ?? 100.0,
      enableCostOptimization: json['enableCostOptimization'] ?? true,
      preferFreeTier: json['preferFreeTier'] ?? true,
    );
  }
}

@HiveType(typeId: 4)
class DailyUsage {
  @HiveField(0)
  final String provider;

  @HiveField(1)
  final String date;

  @HiveField(2)
  final int requestCount;

  @HiveField(3)
  final int tokenUsage;

  @HiveField(4)
  final double estimatedCost;

  @HiveField(5)
  final int groundingRequests;

  @HiveField(6)
  final Map<String, int> modelUsage;

  const DailyUsage({
    required this.provider,
    required this.date,
    required this.requestCount,
    required this.tokenUsage,
    required this.estimatedCost,
    this.groundingRequests = 0,
    required this.modelUsage,
  });

  factory DailyUsage.empty(String provider, String date) {
    return DailyUsage(
      provider: provider,
      date: date,
      requestCount: 0,
      tokenUsage: 0,
      estimatedCost: 0.0,
      groundingRequests: 0,
      modelUsage: {},
    );
  }

  DailyUsage copyWith({
    int? requestCount,
    int? tokenUsage,
    double? estimatedCost,
    int? groundingRequests,
    Map<String, int>? modelUsage,
  }) {
    return DailyUsage(
      provider: provider,
      date: date,
      requestCount: requestCount ?? this.requestCount,
      tokenUsage: tokenUsage ?? this.tokenUsage,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      groundingRequests: groundingRequests ?? this.groundingRequests,
      modelUsage: modelUsage ?? this.modelUsage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'date': date,
      'requestCount': requestCount,
      'tokenUsage': tokenUsage,
      'estimatedCost': estimatedCost,
      'groundingRequests': groundingRequests,
      'modelUsage': modelUsage,
    };
  }

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      provider: json['provider'],
      date: json['date'],
      requestCount: json['requestCount'],
      tokenUsage: json['tokenUsage'],
      estimatedCost: json['estimatedCost']?.toDouble() ?? 0.0,
      groundingRequests: json['groundingRequests'] ?? 0,
      modelUsage: Map<String, int>.from(json['modelUsage'] ?? {}),
    );
  }
}

@HiveType(typeId: 5)
class MonthlySpending {
  @HiveField(0)
  final String provider;

  @HiveField(1)
  final int year;

  @HiveField(2)
  final int month;

  @HiveField(3)
  final double totalCost;

  @HiveField(4)
  final Map<String, double> modelCosts;

  @HiveField(5)
  final int totalRequests;

  const MonthlySpending({
    required this.provider,
    required this.year,
    required this.month,
    required this.totalCost,
    required this.modelCosts,
    required this.totalRequests,
  });

  factory MonthlySpending.empty(String provider, int year, int month) {
    return MonthlySpending(
      provider: provider,
      year: year,
      month: month,
      totalCost: 0.0,
      modelCosts: {},
      totalRequests: 0,
    );
  }

  MonthlySpending copyWith({
    double? totalCost,
    Map<String, double>? modelCosts,
    int? totalRequests,
  }) {
    return MonthlySpending(
      provider: provider,
      year: year,
      month: month,
      totalCost: totalCost ?? this.totalCost,
      modelCosts: modelCosts ?? this.modelCosts,
      totalRequests: totalRequests ?? this.totalRequests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'year': year,
      'month': month,
      'totalCost': totalCost,
      'modelCosts': modelCosts,
      'totalRequests': totalRequests,
    };
  }

  factory MonthlySpending.fromJson(Map<String, dynamic> json) {
    return MonthlySpending(
      provider: json['provider'],
      year: json['year'],
      month: json['month'],
      totalCost: json['totalCost']?.toDouble() ?? 0.0,
      modelCosts: Map<String, double>.from(json['modelCosts'] ?? {}),
      totalRequests: json['totalRequests'] ?? 0,
    );
  }
}
