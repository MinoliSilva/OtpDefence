import 'package:uuid/uuid.dart';

enum RiskLevel { safe, spam, warning, highRisk }

class AnalyzedOtp {
  final String id;
  final String sender;
  final String message;
  final int riskScore;
  final RiskLevel riskLevel;
  final List<String> triggeredRules;
  final DateTime timestamp;
  final bool isStarred;
  final bool isDeleted;
  final bool isVaulted;
  final String? extractedCode;

  AnalyzedOtp({
    String? id,
    required this.sender,
    required this.message,
    required this.riskScore,
    required this.riskLevel,
    required this.triggeredRules,
    required this.timestamp,
    this.extractedCode,
    this.isStarred = false,
    this.isDeleted = false,
    this.isVaulted = false,
  }) : id = id ?? const Uuid().v4();

  bool get hasCode => extractedCode != null && extractedCode!.isNotEmpty;

  AnalyzedOtp copyWith({
    String? sender,
    String? message,
    int? riskScore,
    RiskLevel? riskLevel,
    List<String>? triggeredRules,
    DateTime? timestamp,
    bool? isStarred,
    bool? isDeleted,
    bool? isVaulted,
    String? extractedCode,
  }) {
    return AnalyzedOtp(
      id: id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      triggeredRules: triggeredRules ?? this.triggeredRules,
      timestamp: timestamp ?? this.timestamp,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      isVaulted: isVaulted ?? this.isVaulted,
      extractedCode: extractedCode ?? this.extractedCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'riskScore': riskScore,
      'riskLevel': riskLevel.index,
      'triggeredRules': triggeredRules,
      'timestamp': timestamp.toIso8601String(),
      'isStarred': isStarred,
      'isDeleted': isDeleted,
      'isVaulted': isVaulted,
      'extractedCode': extractedCode,
    };
  }

  factory AnalyzedOtp.fromJson(Map<String, dynamic> json) {
    return AnalyzedOtp(
      id: json['id'] as String?,
      sender: json['sender'] as String,
      message: json['message'] as String,
      riskScore: json['riskScore'] as int? ?? 0,
      riskLevel: RiskLevel.values[json['riskLevel'] as int? ?? 0],
      triggeredRules: (json['triggeredRules'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      isStarred: json['isStarred'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isVaulted: json['isVaulted'] as bool? ?? false,
      extractedCode: json['extractedCode'] as String?,
    );
  }
}
