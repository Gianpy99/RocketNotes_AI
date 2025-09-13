// ==========================================
// lib/data/models/family_member_model.dart
// ==========================================
import 'package:hive/hive.dart';

part 'family_member_model.g.dart';

// Gestione membri famiglia implementata

@HiveType(typeId: 2)
class FamilyMember extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? avatarPath; // Path to avatar image

  @HiveField(3)
  String relationship; // 'parent', 'child', 'spouse', 'grandparent', etc.

  @HiveField(4)
  DateTime? birthDate;

  @HiveField(5)
  String? phoneNumber;

  @HiveField(6)
  bool isEmergencyContact;

  @HiveField(7)
  List<String> permissions; // ['read', 'write', 'share', 'admin']

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  FamilyMember({
    required this.id,
    required this.name,
    this.avatarPath,
    this.relationship = 'family',
    this.birthDate,
    this.phoneNumber,
    this.isEmergencyContact = false,
    this.permissions = const ['read', 'write'],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  FamilyMember copyWith({
    String? name,
    String? avatarPath,
    String? relationship,
    DateTime? birthDate,
    String? phoneNumber,
    bool? isEmergencyContact,
    List<String>? permissions,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      relationship: relationship ?? this.relationship,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'relationship': relationship,
      'birthDate': birthDate?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'isEmergencyContact': isEmergencyContact,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatarPath'] as String?,
      relationship: json['relationship'] as String? ?? 'family',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      phoneNumber: json['phoneNumber'] as String?,
      isEmergencyContact: json['isEmergencyContact'] as bool? ?? false,
      permissions: List<String>.from(json['permissions'] as List? ?? ['read', 'write']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, relationship: $relationship)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
