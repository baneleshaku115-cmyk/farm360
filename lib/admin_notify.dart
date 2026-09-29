import 'package:http/http.dart' as http;

class AdminNotify {
  static const topic = 'farm360-banele-0843150-1901';
  static Future<void> newDownload() async {
    try {
      await http.post(Uri.parse('https://ntfy.sh/$topic'),
        body: '🚀 NEW DOWNLOAD! Farm360 by Banele installed',
        headers: {'Title': 'Farm360 Installed'});
    } catch(e) {}
  }
  static Future<void> paidR29(String phone) async {
    try {
      await http.post(Uri.parse('https://ntfy.sh/$topic'),
        body: '💰 R29 PAID! $phone',
        headers: {'Title': 'R29 PAID!','Priority': 'high'});
    } catch(e) {}
  }
}
