// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_monitoring_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsageMonitoringModelAdapter extends TypeAdapter<UsageMonitoringModel> {
  @override
  final int typeId = 3;

  @override
  UsageMonitoringModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsageMonitoringModel(
      lastResetDate: fields[0] as DateTime,
      dailyUsage: (fields[1] as Map).cast<String, DailyUsage>(),
      monthlySpending: (fields[2] as Map).cast<String, MonthlySpending>(),
      dailySpendingLimit: fields[3] as double,
      monthlySpendingLimit: fields[4] as double,
      enableCostOptimization: fields[5] as bool,
      preferFreeTier: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UsageMonitoringModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.lastResetDate)
      ..writeByte(1)
      ..write(obj.dailyUsage)
      ..writeByte(2)
      ..write(obj.monthlySpending)
      ..writeByte(3)
      ..write(obj.dailySpendingLimit)
      ..writeByte(4)
      ..write(obj.monthlySpendingLimit)
      ..writeByte(5)
      ..write(obj.enableCostOptimization)
      ..writeByte(6)
      ..write(obj.preferFreeTier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageMonitoringModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyUsageAdapter extends TypeAdapter<DailyUsage> {
  @override
  final int typeId = 4;

  @override
  DailyUsage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyUsage(
      provider: fields[0] as String,
      date: fields[1] as String,
      requestCount: fields[2] as int,
      tokenUsage: fields[3] as int,
      estimatedCost: fields[4] as double,
      groundingRequests: fields[5] as int,
      modelUsage: (fields[6] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyUsage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.provider)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.requestCount)
      ..writeByte(3)
      ..write(obj.tokenUsage)
      ..writeByte(4)
      ..write(obj.estimatedCost)
      ..writeByte(5)
      ..write(obj.groundingRequests)
      ..writeByte(6)
      ..write(obj.modelUsage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MonthlySpendingAdapter extends TypeAdapter<MonthlySpending> {
  @override
  final int typeId = 5;

  @override
  MonthlySpending read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlySpending(
      provider: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      totalCost: fields[3] as double,
      modelCosts: (fields[4] as Map).cast<String, double>(),
      totalRequests: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlySpending obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.provider)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.totalCost)
      ..writeByte(4)
      ..write(obj.modelCosts)
      ..writeByte(5)
      ..write(obj.totalRequests);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlySpendingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
