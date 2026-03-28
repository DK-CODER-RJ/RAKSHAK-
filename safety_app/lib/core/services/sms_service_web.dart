import 'package:url_launcher/url_launcher.dart';

class SmsService {
  Future<void> sendEmergencySms(List<String> recipients, String message) async {
    // Web implementation: Launch SMS app with pre-filled message
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: recipients.join(','),
      queryParameters: <String, String>{
        'body': message,
      },
    );
    if (!await launchUrl(smsLaunchUri)) {
      throw 'Could not launch $smsLaunchUri';
    }
  }
}
