import 'package:flutter/foundation.dart';

class VerifiedSender {
  final String id;
  final String name;
  final String category;
  final bool isOfficial;

  const VerifiedSender({
    required this.id,
    required this.name,
    required this.category,
    this.isOfficial = true,
  });
}

class BankRegistryService {
  static const List<VerifiedSender> _verifiedSenders = [
    // Banks
    VerifiedSender(id: 'SAMPATH', name: 'Sampath Bank', category: 'Finance'),
    VerifiedSender(id: 'SampathBank', name: 'Sampath Bank', category: 'Finance'),
    VerifiedSender(id: 'COMBANK', name: 'Commercial Bank', category: 'Finance'),
    VerifiedSender(id: 'ComBank', name: 'Commercial Bank', category: 'Finance'),
    VerifiedSender(id: 'HNB', name: 'Hatton National Bank', category: 'Finance'),
    VerifiedSender(id: 'NSB', name: 'National Savings Bank', category: 'Finance'),
    VerifiedSender(id: 'PEOPLESBNK', name: 'People\'s Bank', category: 'Finance'),
    VerifiedSender(id: 'BOC', name: 'Bank of Ceylon', category: 'Finance'),
    VerifiedSender(id: 'SeylanBank', name: 'Seylan Bank', category: 'Finance'),
    VerifiedSender(id: '3040', name: 'Seylan Bank', category: 'Finance'),
    VerifiedSender(id: 'AmanaBank', name: 'Amana Bank', category: 'Finance'),
    VerifiedSender(id: 'SDBbank', name: 'SDB Bank', category: 'Finance'),
    VerifiedSender(id: 'HSBC', name: 'HSBC', category: 'Finance'),
    VerifiedSender(id: 'NTB', name: 'Nations Trust Bank', category: 'Finance'),
    VerifiedSender(id: 'NDB', name: 'NDB Bank', category: 'Finance'),
    VerifiedSender(id: 'DFCC', name: 'DFCC Bank', category: 'Finance'),
    VerifiedSender(id: 'PanAsia', name: 'Pan Asia Bank', category: 'Finance'),

    // Telecoms
    VerifiedSender(id: 'Dialog', name: 'Dialog Axiata', category: 'Telecom'),
    VerifiedSender(id: 'Mobitel', name: 'SLT-Mobitel', category: 'Telecom'),
    VerifiedSender(id: 'Hutch', name: 'Hutchison Lanka', category: 'Telecom'),
    VerifiedSender(id: 'Airtel', name: 'Airtel Sri Lanka', category: 'Telecom'),
    VerifiedSender(id: 'SLTMobitel', name: 'SLT-Mobitel', category: 'Telecom'),
    VerifiedSender(id: '4848', name: 'Mobitel Services', category: 'Telecom'),

    // Utilities & Govt
    VerifiedSender(id: 'CEB', name: 'Ceylon Electricity Board', category: 'Utility'),
    VerifiedSender(id: 'NWSDB', name: 'National Water Supply Board', category: 'Utility'),
    VerifiedSender(id: 'FuelPass', name: 'National Fuel Pass', category: 'Govt'),
    VerifiedSender(id: 'NatFuelPass', name: 'National Fuel Pass', category: 'Govt'),
    VerifiedSender(id: 'DMT', name: 'Dept. of Motor Traffic', category: 'Govt'),
    VerifiedSender(id: 'SLPost', name: 'Sri Lanka Post', category: 'Govt'),
    
    // Services
    VerifiedSender(id: 'PickMe', name: 'PickMe Sri Lanka', category: 'Service'),
    VerifiedSender(id: 'Uber', name: 'Uber Sri Lanka', category: 'Service'),
    VerifiedSender(id: 'Daraz', name: 'Daraz Online Shopping', category: 'Service'),
    VerifiedSender(id: 'KOKO', name: 'Koko Pay', category: 'Finance'),
  ];

  static VerifiedSender? getVerifiedSender(String senderId) {
    if (senderId.isEmpty) return null;
    
    final cleanId = senderId.toUpperCase().replaceAll(' ', '');
    
    try {
      return _verifiedSenders.firstWhere(
        (s) => s.id.toUpperCase().replaceAll(' ', '') == cleanId
      );
    } catch (_) {
      return null;
    }
  }

  static bool isVerified(String senderId) {
    return getVerifiedSender(senderId) != null;
  }
}
