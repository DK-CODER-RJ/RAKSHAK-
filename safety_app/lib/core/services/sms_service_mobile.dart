import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<void> sendEmergencySms(List<String> recipients, String message) async {
    if (Platform.isAndroid) {
      bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;

      if (permissionsGranted == true) {
        for (String number in recipients) {
          listener(SendStatus status) {
            // print("SMS Status to $number: $status");
          }

          await _telephony.sendSms(
            to: number,
            message: message,
            statusListener: listener,
          );
        }
      } else {
        await _launchSms(recipients, message);
      }
    } else {
      await _launchSms(recipients, message);
    }
  }

  Future<void> _launchSms(List<String> recipients, String message) async {
    String numbers = recipients.join(',');
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: numbers,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    if (!await launchUrl(smsLaunchUri)) {
      throw 'Could not launch $smsLaunchUri';
    }
  }
}
