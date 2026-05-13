import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otp_defense/services/hybrid_risk_engine.dart';

class GrokAnalysisService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<(int, String)?> analyzeWithGrok(String sender, String message) async {
    final extractedOtp = HybridRiskEngine.extractOtp(message);
    final sanitized = extractedOtp != null 
        ? message.replaceAll(extractedOtp, '[OTP_HIDDEN]')
        : message;

    final prompt = '''
You are a cybersecurity expert analyzing an SMS message from Sri Lanka.
Sender: "$sender"
Message: "$sanitized"

Context: Sri Lanka has telecom providers (Dialog, Mobitel, Hutch, SLT) that send frequent promotional bulk SMS. These are NOT threats — they are normal marketing spam. Banks like ComBank, Sampath, BOC, HNB send legitimate OTP codes.

Your task: determine if this is a PHISHING or SPOOFING attack targeting user credentials or OTP codes.

Rules:
- Telecom promotional messages (offers, data packs, discounts) = risk_score 5–10
- Legitimate bank OTP with no suspicious elements = risk_score 0–15
- Unknown phone number sending OTP-style message = risk_score 70+
- Message containing a suspicious URL + urgency = risk_score 60+
- Message claiming account is suspended from unknown sender = risk_score 80+

Respond ONLY with valid JSON:
{"risk_score": <0-100>, "reason": "<one sentence>"}
''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gemma2-9b-it',
          'messages': [
            {'role': 'system', 'content': 'You are a strict cybersecurity JSON-only API.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.1,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentStr = data['choices'][0]['message']['content'] as String;
        final jsonResponse = jsonDecode(contentStr);
        final int score = jsonResponse['risk_score'] as int? ?? 0;
        final String reason = jsonResponse['reason'] as String? ?? 'Analysis complete.';
        return (score, reason);
      }
    } catch (_) {}
    return null;
  }
}
