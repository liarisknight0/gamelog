// lib/models/donation_log.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class DonationLogEntry {
  final String date;
  final String totalDonations;
  final String charityAmount;
  final String charityName;
  final String? receiptUrl; // Optional link to a receipt

  DonationLogEntry({
    required this.date,
    required this.totalDonations,
    required this.charityAmount,
    required this.charityName,
    this.receiptUrl,
  });

  // Factory constructor to create an instance from a JSON map
  factory DonationLogEntry.fromJson(Map<String, dynamic> json) {
    return DonationLogEntry(
      date: json['date'],
      totalDonations: json['totalDonations'],
      charityAmount: json['charityAmount'],
      charityName: json['charityName'],
      receiptUrl: json['receiptUrl'],
    );
  }
}

// A helper class to load and parse the JSON from our assets
class DonationLogService {
  Future<List<DonationLogEntry>> loadLog() async {
    // Load the JSON string from the asset file
    final String jsonString = await rootBundle.loadString('assets/data/donation_log.json');
    // Decode the JSON string into a list of dynamic objects
    final List<dynamic> jsonList = json.decode(jsonString);
    // Map each JSON object to a DonationLogEntry instance
    return jsonList.map((json) => DonationLogEntry.fromJson(json)).toList();
  }
}