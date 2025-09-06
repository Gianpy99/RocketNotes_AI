// ==========================================
// lib/data/services/cost_monitoring_service.dart
// ==========================================
import 'package:hive/hive.dart';
import '../models/usage_monitoring_model.dart';
import '../../features/rocketbook/ai_analysis/ai_service.dart';
import 'package:flutter/foundation.dart';

class CostMonitoringService {
  static const String _monitoringBoxName = 'usage_monitoring';
  static const String _usageKey = 'usage_data';
  
  Box<UsageMonitoringModel>? _monitoringBox;
  
  static final CostMonitoringService _instance = CostMonitoringService._internal();
  factory CostMonitoringService() => _instance;
  CostMonitoringService._internal();

  Box<UsageMonitoringModel> get monitoringBox {
    if (_monitoringBox == null || !_monitoringBox!.isOpen) {
      try {
        _monitoringBox = Hive.box<UsageMonitoringModel>(_monitoringBoxName);
      } catch (e) {
        throw Exception('Usage monitoring box not found. Make sure Hive is properly initialized: $e');
      }
    }
    return _monitoringBox!;
  }

  // Initialize the service
  Future<void> initialize() async {
    try {
      // The box is already opened in main.dart, just verify it exists
      final _ = monitoringBox; // This will throw if not available
      debugPrint('✅ Cost Monitoring Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Cost Monitoring Service: $e');
      rethrow;
    }
  }

  // Get current usage monitoring data
  Future<UsageMonitoringModel> getUsageData() async {
    try {
      final data = monitoringBox.get(_usageKey);
      return data ?? UsageMonitoringModel.defaults();
    } catch (e) {
      debugPrint('Error getting usage data: $e');
      return UsageMonitoringModel.defaults();
    }
  }

  // Save usage monitoring data
  Future<void> saveUsageData(UsageMonitoringModel data) async {
    try {
      await monitoringBox.put(_usageKey, data);
    } catch (e) {
      debugPrint('Error saving usage data: $e');
      throw Exception('Failed to save usage data: $e');
    }
  }

  // Record a new API request
  Future<void> recordApiRequest({
    required String provider,
    required String modelId,
    required int inputTokens,
    required int outputTokens,
    bool isGroundingRequest = false,
  }) async {
    try {
      final usageData = await getUsageData();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final usageKey = '${provider}_$today';
      
      // Get current day usage
      final currentUsage = usageData.getTodayUsage(provider);
      
      // Calculate cost
      final cost = _calculateCost(provider, modelId, inputTokens, outputTokens);
      
      // Update model usage
      final updatedModelUsage = Map<String, int>.from(currentUsage.modelUsage);
      updatedModelUsage[modelId] = (updatedModelUsage[modelId] ?? 0) + 1;
      
      // Create updated daily usage
      final updatedDailyUsage = currentUsage.copyWith(
        requestCount: currentUsage.requestCount + 1,
        tokenUsage: currentUsage.tokenUsage + inputTokens + outputTokens,
        estimatedCost: currentUsage.estimatedCost + cost,
        groundingRequests: isGroundingRequest ? 
          currentUsage.groundingRequests + 1 : currentUsage.groundingRequests,
        modelUsage: updatedModelUsage,
      );
      
      // Update monthly spending
      final now = DateTime.now();
      final monthlyKey = '${provider}_${now.year}_${now.month}';
      final currentMonthly = usageData.getCurrentMonthSpending(provider);
      
      final updatedModelCosts = Map<String, double>.from(currentMonthly.modelCosts);
      updatedModelCosts[modelId] = (updatedModelCosts[modelId] ?? 0.0) + cost;
      
      final updatedMonthlySpending = currentMonthly.copyWith(
        totalCost: currentMonthly.totalCost + cost,
        modelCosts: updatedModelCosts,
        totalRequests: currentMonthly.totalRequests + 1,
      );
      
      // Update the main usage data
      final updatedDailyUsageMap = Map<String, DailyUsage>.from(usageData.dailyUsage);
      updatedDailyUsageMap[usageKey] = updatedDailyUsage;
      
      final updatedMonthlySpendingMap = Map<String, MonthlySpending>.from(usageData.monthlySpending);
      updatedMonthlySpendingMap[monthlyKey] = updatedMonthlySpending;
      
      final updatedUsageData = usageData.copyWith(
        dailyUsage: updatedDailyUsageMap,
        monthlySpending: updatedMonthlySpendingMap,
      );
      
      await saveUsageData(updatedUsageData);
      
      debugPrint('📊 API request recorded: $provider/$modelId - Cost: \$${cost.toStringAsFixed(4)}');
    } catch (e) {
      debugPrint('Error recording API request: $e');
    }
  }

  // Calculate cost for a request
  double _calculateCost(String provider, String modelId, int inputTokens, int outputTokens) {
    final models = AIModelConfig.getModelsForProvider(provider);
    final model = models.firstWhere(
      (m) => m['id'] == modelId,
      orElse: () => <String, dynamic>{},
    );
    
    if (model.isEmpty) return 0.0;
    
    double cost = 0.0;
    
    // Handle different pricing structures
    if (provider.toLowerCase() == 'gemini') {
      // Check if it's free tier
      if (model['isFree'] == true) {
        return 0.0; // Free tier
      }
      
      // Handle audio models with different pricing
      if (model.containsKey('textInputPrice')) {
        cost += (inputTokens / 1000000) * (model['textInputPrice'] ?? 0.0);
        cost += (outputTokens / 1000000) * (model['textOutputPrice'] ?? 0.0);
      } else {
        // Standard pricing
        final inputPrice = model['paidInputPrice'] ?? model['inputPrice'] ?? 0.0;
        final outputPrice = model['paidOutputPrice'] ?? model['outputPrice'] ?? 0.0;
        
        cost += (inputTokens / 1000000) * inputPrice;
        cost += (outputTokens / 1000000) * outputPrice;
      }
    } else {
      // OpenAI pricing
      final inputPrice = model['inputPrice'] ?? 0.0;
      final outputPrice = model['outputPrice'] ?? 0.0;
      
      cost += (inputTokens / 1000000) * inputPrice;
      cost += (outputTokens / 1000000) * outputPrice;
    }
    
    return cost;
  }

  // Get optimal model considering cost constraints
  Future<String> getOptimalModel({
    required String provider,
    bool requiresVision = false,
    bool requiresAudio = false,
    String tier = 'flex',
  }) async {
    try {
      final usageData = await getUsageData();
      
      // If cost optimization is enabled and we should switch to free tier
      if (provider.toLowerCase() == 'gemini' && usageData.shouldSwitchToFreeTier(provider)) {
        return _getBestFreeGeminiModel(requiresVision: requiresVision, requiresAudio: requiresAudio);
      }
      
      // Check Gemini free tier limits
      if (provider.toLowerCase() == 'gemini' && usageData.preferFreeTier) {
        final freeModel = _getBestFreeGeminiModel(requiresVision: requiresVision, requiresAudio: requiresAudio);
        if (usageData.isWithinGeminiFreeLimit(freeModel)) {
          return freeModel;
        }
      }
      
      // Default to regular optimal model selection
      return AIModelConfig.getOptimalModel(
        provider,
        requiresVision: requiresVision,
        tier: tier,
      );
    } catch (e) {
      debugPrint('Error getting optimal model: $e');
      return 'gpt-5-mini'; // Safe fallback
    }
  }

  // Get best free Gemini model
  String _getBestFreeGeminiModel({bool requiresVision = false, bool requiresAudio = false}) {
    if (requiresAudio) {
      return 'gemini-2.5-flash'; // Supports audio and is free
    }
    
    if (requiresVision) {
      return 'gemini-2.5-flash-lite'; // Most cost-effective with vision
    }
    
    return 'gemini-2.5-flash-lite'; // Default free option
  }

  // Get cost summary for dashboard
  Future<Map<String, dynamic>> getCostSummary() async {
    try {
      final usageData = await getUsageData();
      final dailyCost = usageData.calculateDailyCost();
      final monthlyCost = usageData.calculateMonthlyCost();
      
      // Calculate remaining budget
      final dailyRemaining = usageData.dailySpendingLimit - dailyCost;
      final monthlyRemaining = usageData.monthlySpendingLimit - monthlyCost;
      
      // Get usage by provider
      final geminiUsage = usageData.getTodayUsage('gemini');
      final openaiUsage = usageData.getTodayUsage('openai');
      
      return {
        'dailyCost': dailyCost,
        'monthlyCost': monthlyCost,
        'dailyLimit': usageData.dailySpendingLimit,
        'monthlyLimit': usageData.monthlySpendingLimit,
        'dailyRemaining': dailyRemaining,
        'monthlyRemaining': monthlyRemaining,
        'dailyPercentage': (dailyCost / usageData.dailySpendingLimit * 100).clamp(0, 100),
        'monthlyPercentage': (monthlyCost / usageData.monthlySpendingLimit * 100).clamp(0, 100),
        'geminiRequests': geminiUsage.requestCount,
        'geminiGrounding': geminiUsage.groundingRequests,
        'geminiFreeLimitRemaining': 25 - geminiUsage.requestCount, // RPD limit
        'geminiGroundingRemaining': 1500 - geminiUsage.groundingRequests,
        'openaiRequests': openaiUsage.requestCount,
        'totalRequests': geminiUsage.requestCount + openaiUsage.requestCount,
        'isNearDailyLimit': dailyCost > (usageData.dailySpendingLimit * 0.8),
        'isNearMonthlyLimit': monthlyCost > (usageData.monthlySpendingLimit * 0.8),
        'shouldSwitchToFree': usageData.shouldSwitchToFreeTier('gemini'),
      };
    } catch (e) {
      debugPrint('Error getting cost summary: $e');
      return {
        'dailyCost': 0.0,
        'monthlyCost': 0.0,
        'dailyLimit': 5.0,
        'monthlyLimit': 100.0,
        'error': true,
      };
    }
  }

  // Update spending limits
  Future<void> updateSpendingLimits({
    double? dailyLimit,
    double? monthlyLimit,
  }) async {
    try {
      final usageData = await getUsageData();
      final updatedData = usageData.copyWith(
        dailySpendingLimit: dailyLimit ?? usageData.dailySpendingLimit,
        monthlySpendingLimit: monthlyLimit ?? usageData.monthlySpendingLimit,
      );
      await saveUsageData(updatedData);
    } catch (e) {
      debugPrint('Error updating spending limits: $e');
      throw Exception('Failed to update spending limits: $e');
    }
  }

  // Update optimization settings
  Future<void> updateOptimizationSettings({
    bool? enableCostOptimization,
    bool? preferFreeTier,
  }) async {
    try {
      final usageData = await getUsageData();
      final updatedData = usageData.copyWith(
        enableCostOptimization: enableCostOptimization ?? usageData.enableCostOptimization,
        preferFreeTier: preferFreeTier ?? usageData.preferFreeTier,
      );
      await saveUsageData(updatedData);
    } catch (e) {
      debugPrint('Error updating optimization settings: $e');
      throw Exception('Failed to update optimization settings: $e');
    }
  }

  // Reset usage data (for testing or manual reset)
  Future<void> resetUsageData() async {
    try {
      await saveUsageData(UsageMonitoringModel.defaults());
      debugPrint('✅ Usage data reset successfully');
    } catch (e) {
      debugPrint('Error resetting usage data: $e');
      throw Exception('Failed to reset usage data: $e');
    }
  }
}
