import 'dart:convert';
import 'package:http/http.dart' as http;

class TwilioService {
  // আপনার Twilio ড্যাশবোর্ড থেকে এই তথ্যগুলো নিন
  final String accountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  final String authToken = 'YOUR_TWILIO_AUTH_TOKEN';
  final String twilioNumber = 'YOUR_TWILIO_PHONE_NUMBER';

  Future<bool> sendSms(String toNumber, String message) async {
    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
        },
        body: {
          'From': twilioNumber,
          'To': toNumber,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Twilio Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Twilio Exception: $e");
      return false;
    }
  }
}