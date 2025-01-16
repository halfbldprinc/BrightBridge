import 'dart:convert';
import 'package:http/http.dart' as http;

class AppTime {
  static DateTime? _currentTime;

  // Fetch the time from the API
  static Future<void> fetchCurrentTime() async {
    try {
      final response = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/Etc/UTC'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String apiTime =
            data['datetime']; // Get datetime field from the API response

        // Convert the API datetime (ISO 8601) string to DateTime object
        _currentTime = DateTime.parse(apiTime);
      } else {
        print(
            'Failed to load time from API. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching time: $e');
    }
  }

  // Retrieve the current time
  static DateTime? getCurrentTime() {
    return _currentTime;
  }
}
