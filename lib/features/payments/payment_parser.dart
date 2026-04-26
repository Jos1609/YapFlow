import '../../core/models/payment.dart';

@pragma('vm:entry-point')
class PaymentParser {
  static Payment? parse(String packageName, String title, String content) {
    if (packageName.toLowerCase().contains('yape')) {
      return _parseYape(content);
    } else if (packageName.contains('bcp') || packageName.contains('bbva') || packageName.contains('interbank') || packageName.contains('scotiabank')) {
      return _parseGenericBank(packageName, content);
    }
    return null;
  }

  static Payment? _parseYape(String content) {
    // Patterns:
    // 1. "¡Yapeaste! Te enviaron S/ 20.00 de Juan Perez"
    // 2. "Juan Perez te yapeó S/ 10.00"
    // 3. "Jose Qui* te envió un pago por S/ 0.1. El cód. de seguridad es: 674"
    
    final regex1 = RegExp(r'(?:Te yapearon|enviaron|yapeó) S/\s*(\d+(?:\.\d+)?)\s*(?:de|por)?\s*(.*)', caseSensitive: false);
    final regex2 = RegExp(r'(.*) te (?:ha yapeado|yapeó) S/\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    final regex3 = RegExp(r'S/\s*(\d+(?:\.\d+)?)\s*de\s*(.*)', caseSensitive: false);
    final regex4 = RegExp(r'Pago recibido de (.*) por S/\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    final regex5 = RegExp(r'(.*) te envió un pago por S/\s*(\d+(?:\.\d+)?)', caseSensitive: false);

    if (regex5.hasMatch(content)) {
      final match = regex5.firstMatch(content)!;
      final sender = match.group(1)?.trim() ?? 'Desconocido';
      final amount = double.tryParse(match.group(2) ?? '0') ?? 0.0;
      return _createPayment(sender, amount, content, PaymentSource.yape);
    } else if (regex1.hasMatch(content)) {
      final match = regex1.firstMatch(content)!;
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      final sender = match.group(2)?.trim() ?? 'Desconocido';
      return _createPayment(sender, amount, content, PaymentSource.yape);
    } else if (regex2.hasMatch(content)) {
      final match = regex2.firstMatch(content)!;
      final sender = match.group(1)?.trim() ?? 'Desconocido';
      final amount = double.tryParse(match.group(2) ?? '0') ?? 0.0;
      return _createPayment(sender, amount, content, PaymentSource.yape);
    } else if (regex3.hasMatch(content)) {
      final match = regex3.firstMatch(content)!;
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      final sender = match.group(2)?.trim() ?? 'Desconocido';
      return _createPayment(sender, amount, content, PaymentSource.yape);
    } else if (regex4.hasMatch(content)) {
      final match = regex4.firstMatch(content)!;
      final sender = match.group(1)?.trim() ?? 'Desconocido';
      final amount = double.tryParse(match.group(2) ?? '0') ?? 0.0;
      return _createPayment(sender, amount, content, PaymentSource.yape);
    }
    
    return null;
  }

  static Payment? _parseGenericBank(String packageName, String content) {
    final amountRegex = RegExp(r'S/\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    if (!amountRegex.hasMatch(content)) return null;

    final amountMatch = amountRegex.firstMatch(content)!;
    final amount = double.tryParse(amountMatch.group(1) ?? '0') ?? 0.0;

    PaymentSource source = PaymentSource.unknown;
    if (packageName.contains('bcp')) source = PaymentSource.bcp;
    if (packageName.contains('bbva')) source = PaymentSource.bbva;
    if (packageName.contains('interbank')) source = PaymentSource.interbank;
    if (packageName.contains('scotiabank')) source = PaymentSource.scotiabank;
    if (content.toLowerCase().contains('plin')) source = PaymentSource.plin;

    return _createPayment('Remitente bancario', amount, content, source);
  }

  static Payment _createPayment(String sender, double amount, String content, PaymentSource source) {
    // Extract security code if present (e.g., "El cód. de seguridad es: 262")
    final codeRegex = RegExp(r'seguridad\s*es:\s*(\d+)', caseSensitive: false);
    final securityCode = codeRegex.firstMatch(content)?.group(1);

    return Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: sender,
      amount: amount,
      timestamp: DateTime.now(),
      source: source,
      rawContent: content,
      securityCode: securityCode,
    );
  }
}
