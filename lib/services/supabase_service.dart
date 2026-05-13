import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/services/bank_registry_service.dart';

class SupabaseService {
  static Future<void> initialize() async {
    // Replace these with actual project credentials from Supabase Dashboard
    const supabaseUrl = 'https://ssbplinfhfkrvygjigjc.supabase.co';
    const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzYnBsaW5maGZrcnZ5Z2ppZ2pjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NTk2MjAsImV4cCI6MjA4ODEzNTYyMH0.9_KYxlNttNxuWAV2eKitSCW2Az81sCu5muVEZqOGiZw';

    if (supabaseUrl == 'YOUR_SUPABASE_URL') {
      debugPrint('Supabase credentials not configured. Running in local mode.');
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Fetch trusted senders dynamically from DB
  static Future<List<String>> fetchTrustedSenders() async {
    try {
      final response = await Supabase.instance.client.from('trusted_senders').select('sender_id');
      return response.map<String>((row) => row['sender_id'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching trusted senders: $e');
      return [];
    }
  }

  // Report a suspicious sender to the community database
  static Future<bool> reportPhishing(String sender, String message, String reason) async {
    try {
      // 1. Client-side Verification Filter
      // We don't allow reporting of officially verified banks/services to prevent abuse
      // if someone tries to maliciously flag a real bank.
      if (BankRegistryService.isVerified(sender)) {
        debugPrint('Blocked reporting of a Verified Institution: $sender');
        return false; 
      }

      await Supabase.instance.client.from('phishing_reports').insert({
        'sender_id': sender,
        'message_snippet': message.length > 100 ? message.substring(0, 100) : message,
        'report_reason': reason,
        'reported_at': DateTime.now().toIso8601String(),
        'status': 'PENDING', // Will be upgraded to 'VERIFIED' by our backend/AI threshold
      });
      return true;
    } catch (e) {
      debugPrint('Error reporting phishing: $e');
      return false;
    }
  }

  // Check if a sender has been blacklisted by the community
  static Future<bool> isCommunityBlacklisted(String sender) async {
    try {
      final response = await Supabase.instance.client
          .from('phishing_reports')
          .select('id')
          .eq('sender_id', sender)
          .eq('status', 'VERIFIED')
          .limit(1)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Insert anonymized analytics payload
  static Future<void> logAnalytics(AnalyzedOtp otp) async {
    try {
      await Supabase.instance.client.from('analytics').insert({
        'device_id_hash': 'anonymous_device',
        'notification_type': 'SMS_OTP',
        'risk_score': otp.riskScore,
        'classification': otp.riskLevel.toString().split('.').last,
        'matched_rules': otp.triggeredRules,
      });
    } catch (e) {
      debugPrint('Error logging analytics: $e');
    }
  }
}
