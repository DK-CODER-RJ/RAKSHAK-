import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Telecom: sms_sender.dart
class SmsSender {
  static final Dio _dio = Dio();

  /// Sends an SMS via Twilio API
  static Future<bool> sendSms({required String to, required String message}) async {
    final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'];
    final authToken = dotenv.env['TWILIO_AUTH_TOKEN'];
    final twilioNumber = dotenv.env['TWILIO_PHONE_NUMBER'];

    if (accountSid == null || authToken == null || twilioNumber == null) {
      debugPrint('Twilio credentials missing in .env');
      return false;
    }

    final url = 'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json';
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}';

    try {
      final response = await _dio.post(
        url,
        data: {
          'To': to,
          'From': twilioNumber,
          'Body': message,
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 201) {
        debugPrint('SMS sent successfully to $to');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to send SMS: $e');
      return false;
    }
  }
}
