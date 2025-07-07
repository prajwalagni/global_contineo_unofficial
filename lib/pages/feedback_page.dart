import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For json encoding
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  int _stars = 0; // Rating out of 5 stars
  bool _isLoading = false; // To show loading indicator
  String _appVersion = 'N/A'; // To store the app version
  String _userUSN = 'N/A'; // New variable to store USN

  // Access environment variables here
  final String _telegramBotToken =
      dotenv.env['TELEGRAM_BOT_TOKEN'] ?? 'YOUR_TOKEN_NOT_FOUND';
  final String _telegramChatId =
      dotenv.env['TELEGRAM_CHAT_ID'] ?? 'YOUR_CHAT_ID_NOT_FOUND';

  // IMPORTANT: Replace these with your actual Telegram Bot Token and Chat ID
  // You can get your bot token from BotFather on Telegram.
  // To get your chat ID, send a message to your bot, then go to:
  // https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
  // Look for "chat": {"id": XXXXXXXX, ...}
  // final String _telegramBotToken = '__YOUR_TELEGRAM_BOT_TOKEN__';
  // final String _telegramChatId = '__YOUR_TELEGRAM_CHAT_ID__';

  @override
  void initState() {
    super.initState();
    _loadAppData(); // Load both app version and USN
  }

  Future<void> _loadAppData() async {
    // Load App Version
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });

    // Load USN from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userUSN = prefs.getString('usn') ?? 'Not Logged In / USN Not Found';
    });
  }

  // Helper function to escape MarkdownV2 reserved characters
  String _escapeMarkdownV2(String text) {
    const specialChars = r'_*[]()~`>#+-=|{}.!';
    final StringBuffer escapedText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (specialChars.contains(char)) {
        escapedText.write('\\');
      }
      escapedText.write(char);
    }
    return escapedText.toString();
  }

  Future<void> _sendFeedback() async {
    if (_feedbackController.text.isEmpty || _stars == 0) {
      _showMessage('Please enter feedback or select a rating.');
      return;
    }

    // Check if bot token or chat ID are missing
    if (_telegramBotToken == 'YOUR_TOKEN_NOT_FOUND' ||
        _telegramChatId == 'YOUR_CHAT_ID_NOT_FOUND') {
      _showMessage(
        'Error: Telegram bot token or chat ID not configured. Please check your .env file.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Escape the parts of the message that are dynamic or contain user input.
    final String escapedAppVersion = _escapeMarkdownV2(_appVersion);
    final String escapedUserUSN = _escapeMarkdownV2(_userUSN); // Escape USN
    final String escapedFeedbackText = _escapeMarkdownV2(
      _feedbackController.text,
    );
    // _stars is always a number (0-5), so it doesn't need escaping for MarkdownV2.

    // Construct the message.
    // For literal parentheses around the version, they also need to be escaped.
    // So `\\(v` and `\\)`
    final String message = 'Feedback from GAT Contineo App \\(v$escapedAppVersion\\):\n'
        'User USN: `$escapedUserUSN`\n\n' // Include USN, wrapped in backticks for code-like formatting in Telegram
        'Message: ${escapedFeedbackText.isEmpty ? _escapeMarkdownV2('No message provided.') : escapedFeedbackText}\n'
        'Rating: $_stars out of 5 stars';
    debugPrint(message);

    final Uri uri = Uri.parse(
      'https://api.telegram.org/bot$_telegramBotToken/sendMessage',
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': _telegramChatId,
          'text': message,
          'parse_mode': 'MarkdownV2', // Optional: for bold/italic in Telegram
        }),
      );

      if (response.statusCode == 200) {
        _showMessage('Feedback sent successfully!');
        _feedbackController.clear();
        setState(() {
          _stars = 0;
        });
      } else {
        _showMessage('Failed to send feedback. Please try again.');
        print('Telegram API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showMessage('An error occurred: $e');
      print('Error sending feedback: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Version: $_appVersion', // Display app version here
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Your USN: $_userUSN', // Display USN
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10.0),
            Text(
              'We appreciate your feedback! Please share your thoughts and rate the app.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Your Feedback',
                hintText: 'Enter your suggestions, bug reports, or comments...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Rate the App:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36.0,
                  ),
                  onPressed: () {
                    setState(() {
                      _stars = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 30.0),
            Center(
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                        onPressed: _sendFeedback,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Feedback'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Your feedback will be sent to the developer via Telegram.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
