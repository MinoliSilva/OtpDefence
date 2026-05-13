import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/services/grok_analysis_service.dart';
import 'package:otp_defense/services/bank_registry_service.dart';
import 'package:otp_defense/services/supabase_service.dart';

class EngineResult {
  final int score;
  final RiskLevel level;
  final List<String> signals;
  final String provider; // 'deterministic', 'heuristic', or 'ai'

  EngineResult({
    required this.score,
    required this.level,
    required this.signals,
    required this.provider,
  });
}

class HybridRiskEngine {
  static final RegExp _otpRegex = RegExp(r'\b\d{4,8}\b');
  static final RegExp _urlRegex = RegExp(r'https?:\/\/[^\s]+');

  /// Smarter OTP extraction that ignores currency amounts, dates, and decimals
  static String? extractOtp(String message) {
    // 1. Find all 4 to 8 digit numbers
    final matches = _otpRegex.allMatches(message);
    if (matches.isEmpty) return null;

    for (final match in matches) {
      final code = match.group(0)!;
      int index = match.start;

      // Ensure it's not a decimal by checking what's immediately after it
      bool hasDecimal = false;
      if (index + code.length < message.length) {
        if (message[index + code.length] == '.') {
          // If the next char after the dot is a digit, it's a decimal number
          if (index + code.length + 1 < message.length && 
              RegExp(r'\d').hasMatch(message[index + code.length + 1])) {
            hasDecimal = true;
          }
        }
      }

      // Ensure it's not preceded by a currency symbol or word like Rs
      bool isCurrency = false;
      int startPre = index > 15 ? index - 15 : 0;
      String preContext = message.substring(startPre, index).toLowerCase();
      if (RegExp(r'(rs\.?|lkr|\$|usd|eur|amount|bal)\s*$').hasMatch(preContext)) {
        isCurrency = true;
      }
      
      // Also ignore if it looks like a part of an account number or something similar
      if (RegExp(r'(a\/c no|acct|account).{0,5}$').hasMatch(preContext)) {
         isCurrency = true;
      }

      if (!hasDecimal && !isCurrency) {
        // The first match that survives these filters is considered the OTP
        return code;
      }
    }

    return null;
  }

  /// Layer 1: Deterministic Scan
  /// High-confidence matching for known entities and common spam.
  EngineResult? _deterministicScan(String sender, String message) {
    final hasOtp = extractOtp(message) != null;

    // 1. Check our Local Verified Registry (Sri Lanka Focused)
    final verified = BankRegistryService.getVerifiedSender(sender);
    if (verified != null) {
       // If it's a verified sender and has an OTP, it's safe.
       // If no OTP, it might be a promo from a verified number (Spam level)
       if (hasOtp || verified.category == 'Finance') {
         return EngineResult(
           score: 0,
           level: RiskLevel.safe,
           signals: ['Verified ${verified.category}: ${verified.name}'],
           provider: 'deterministic',
         );
       } else {
         return EngineResult(
           score: 5,
           level: RiskLevel.spam,
           signals: ['Official ${verified.category} Transactional/Promo'],
           provider: 'deterministic',
         );
       }
    }

    return null;
  }

  /// Layer 2: Heuristic Scan
  /// Scoring based on suspicious patterns and metadata.
  EngineResult _heuristicScan(String sender, String message) {
    int score = 30; // Base "Unknown" score
    List<String> signals = ['Unknown Sender Identity'];
    final lowerMessage = message.toLowerCase();
    final senderNorm = sender.trim();

    // Sender Analysis
    if (RegExp(r'^\+?\d{9,12}$').hasMatch(senderNorm)) {
      score += 25;
      signals.add('Sender is a private mobile number (High Risk)');
    }

    // Content Analysis
    if (_urlRegex.hasMatch(message)) {
      final urlMatch = _urlRegex.firstMatch(message)?.group(0) ?? '';
      
      // Check for commonly shared safe domains in group chats
      final safeDomains = [
        'facebook.com', 'zoom.us', 'forms.office.com', 'linkedin.com',
        'youtube.com', 'youtu.be', 'google.com', 'microsoft.com', 'github.com'
      ];
      
      bool isSafeDomain = safeDomains.any((domain) => urlMatch.contains(domain));
      
      if (isSafeDomain) {
        score += 5; // Minimal penalty for known safe standard domains
        signals.add('Contains web link (Recognized Platform)');
      } else {
        score += 30;
        signals.add('Contains external web link');
      }
    }

    // Semantic Sequence Check (e.g., Urgency followed by Account action)
    final urgencyRegex = RegExp(r'(urgent|immediately|action required|අත්හිටුවා|ප්‍රමාද)', caseSensitive: false);
    final accountRegex = RegExp(r'(account|login|verify|බැංකු|ගිණුම)', caseSensitive: false);
    
    if (urgencyRegex.hasMatch(lowerMessage) && accountRegex.hasMatch(lowerMessage)) {
      score += 20;
      signals.add('Semantic Threat: Urgency combined with Account action requested');
    }

    final suspiciousKeywords = {
      'blocked': 20,
      'suspended': 25,
      'verify': 10,
      'account': 5,
      'urgent': 15,
      'login': 20,
      'update': 10,
      'click': 15,
      'ලොගින්': 25,
      'අත්හිටුවා': 30,
      'නොමිලේ': 20, // Free
      'තෑගි': 20, // Gift
    };

    suspiciousKeywords.forEach((key, weight) {
      if (lowerMessage.contains(key)) {
        score += weight;
        signals.add('Suspicious keyword: $key');
      }
    });

    // Safe keywords reduce risk if there is no high-risk URL and no urgency
    final isHighlySuspicious = (_urlRegex.hasMatch(message) && !message.contains('facebook.com') && !message.contains('zoom.us') && !message.contains('forms.office.com')) || urgencyRegex.hasMatch(lowerMessage);
    if (!isHighlySuspicious) {
      final safeKeywords = {
        'bill payment': -30,
        'payment received': -25,
        'thank you': -10,
        'successful': -10,
        'credited': -10,
        'balance': -5,
      };

      safeKeywords.forEach((key, weight) {
        if (lowerMessage.contains(key)) {
          score += weight;
          signals.add('Safe structural keyword: $key');
        }
      });
      if (score < 0) score = 0;
    }

    // Final Level mapping for Heuristic
    RiskLevel level = RiskLevel.warning;
    if (score > 60) level = RiskLevel.highRisk;
    if (score < 15) level = RiskLevel.safe;

    return EngineResult(
      score: score > 100 ? 100 : score,
      level: level,
      signals: signals,
      provider: 'heuristic',
    );
  }

  /// Layer 3: AI Semantic Scan
  /// Deep analysis using LLM for final verdict on ambiguous cases.
  Future<EngineResult?> _aiScan(String sender, String message, EngineResult previous) async {
    try {
      final aiResult = await GrokAnalysisService.analyzeWithGrok(sender, message);
      if (aiResult != null) {
        final (aiScore, aiReason) = aiResult;
        
        // Blend AI insight with Heuristic findings
        int finalScore = (previous.score + aiScore) ~/ 2;
        
        RiskLevel level;
        if (finalScore > 65 || aiScore > 80) {
          level = RiskLevel.highRisk;
        } else if (finalScore > 40 || aiScore > 40) {
          level = RiskLevel.warning;
        } else if (aiScore < 10) {
          level = RiskLevel.safe;
        } else {
          level = previous.level;
        }

        return EngineResult(
          score: finalScore,
          level: level,
          signals: [...previous.signals, 'AI Verdict: $aiReason'],
          provider: 'ai',
        );
      }
    } catch (_) {}
    return null;
  }

  /// Core Engine Entry Point
  Future<AnalyzedOtp> analyze(String sender, String message) async {
    // 1. Try Deterministic Layer
    final det = _deterministicScan(sender, message);
    if (det != null) {
      return _wrapResult(sender, message, det);
    }

    // 1.5 Community Blacklist Layer
    // Check if this sender has been reported and verified as phishing by the community
    final isBlacklisted = await SupabaseService.isCommunityBlacklisted(sender);
    if (isBlacklisted) {
      return _wrapResult(sender, message, EngineResult(
        score: 95,
        level: RiskLevel.highRisk,
        signals: ['Community Alert: Reported as Phishing'],
        provider: 'community',
      ));
    }

    // 2. Run Heuristic Layer
    final heuristic = _heuristicScan(sender, message);

    // 3. Optional AI Layer (only if suspicious or unknown)
    if (heuristic.level == RiskLevel.warning || heuristic.level == RiskLevel.highRisk) {
      final ai = await _aiScan(sender, message, heuristic);
      if (ai != null) {
        return _wrapResult(sender, message, ai);
      }
    }

    return _wrapResult(sender, message, heuristic);
  }

  AnalyzedOtp _wrapResult(String sender, String message, EngineResult res) {
    // Extract code for quick actions using the smarter extraction logic
    final code = extractOtp(message);

    return AnalyzedOtp(
      sender: sender,
      message: message,
      riskScore: res.score,
      riskLevel: res.level,
      triggeredRules: res.signals,
      timestamp: DateTime.now(),
      extractedCode: code,
    );
  }
}
