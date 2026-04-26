import 'dart:convert';

enum PaymentSource { yape, plin, bcp, bbva, interbank, scotiabank, unknown }

@pragma('vm:entry-point')
class Payment {
  final String id;
  final String senderName;
  final double amount;
  final DateTime timestamp;
  final PaymentSource source;
  final String rawContent;
  final String? securityCode;

  Payment({
    required this.id,
    required this.senderName,
    required this.amount,
    required this.timestamp,
    required this.source,
    required this.rawContent,
    this.securityCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderName': senderName,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'source': source.index,
      'rawContent': rawContent,
      'securityCode': securityCode,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      senderName: map['senderName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      source: PaymentSource.values[map['source'] ?? PaymentSource.unknown.index],
      rawContent: map['rawContent'] ?? '',
      securityCode: map['securityCode'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Payment.fromJson(String source) => Payment.fromMap(json.decode(source));
}
