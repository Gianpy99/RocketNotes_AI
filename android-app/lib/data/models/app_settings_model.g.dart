// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 1;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      defaultMode: fields[0] as String,
      themeMode: fields[1] as int,
      enableNotifications: fields[2] as bool,
      enableNfc: fields[3] as bool,
      autoBackup: fields[4] as bool,
      lastBackupDate: fields[5] as DateTime?,
      backupLocation: fields[6] as String?,
      enableAi: fields[7] as bool,
      fontSize: fields[8] as double,
      enableBiometric: fields[9] as bool,
      pinnedTags: (fields[10] as List).cast<String>(),
      showStats: fields[11] as bool,
      ocrProvider: fields[12] as String?,
      aiProvider: fields[13] as String?,
      textSummarizationModel: fields[14] as String?,
      imageAnalysisModel: fields[15] as String?,
      openAIServiceTier: fields[16] as String?,
      audioTranscriptionModel: fields[17] as String?,
      autoQuickCaptureAI: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.defaultMode)
      ..writeByte(1)
      ..write(obj.themeMode)
      ..writeByte(2)
      ..write(obj.enableNotifications)
      ..writeByte(3)
      ..write(obj.enableNfc)
      ..writeByte(4)
      ..write(obj.autoBackup)
      ..writeByte(5)
      ..write(obj.lastBackupDate)
      ..writeByte(6)
      ..write(obj.backupLocation)
      ..writeByte(7)
      ..write(obj.enableAi)
      ..writeByte(8)
      ..write(obj.fontSize)
      ..writeByte(9)
      ..write(obj.enableBiometric)
      ..writeByte(10)
      ..write(obj.pinnedTags)
      ..writeByte(11)
      ..write(obj.showStats)
      ..writeByte(12)
      ..write(obj.ocrProvider)
      ..writeByte(13)
      ..write(obj.aiProvider)
      ..writeByte(14)
      ..write(obj.textSummarizationModel)
      ..writeByte(15)
      ..write(obj.imageAnalysisModel)
      ..writeByte(16)
      ..write(obj.openAIServiceTier)
      ..writeByte(17)
      ..write(obj.audioTranscriptionModel)
      ..writeByte(18)
      ..write(obj.autoQuickCaptureAI);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
