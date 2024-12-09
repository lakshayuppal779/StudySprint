import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E), // Matching project colors
        title: Text(
          'Terms of Service',
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFF1C1C1E), // Matching project colors
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terms text scroll view
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Introduction:',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Welcome to our app! By using this app, you agree to the following terms and conditions...',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '1. Acceptance of Terms:',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'By accessing or using the app, you agree to comply with the terms outlined in this document...',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '2. Privacy Policy:',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your privacy is important to us. Please read our privacy policy to understand how we collect, use, and protect your data...',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '3. User Responsibilities:',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You agree not to misuse the app in any way, including, but not limited to, violating laws or infringing on others’ rights...',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    // Add more terms and conditions sections here
                    SizedBox(height: 20),
                    Text(
                      '4. Changes to Terms:',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'We reserve the right to modify these terms at any time. Please check back for any updates...',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Accept Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle the acceptance of terms, e.g., navigate to the next screen
                  _acceptTerms(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // Your project primary color
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'I Accept',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _acceptTerms(BuildContext context) {
    // Simulate acceptance of terms, e.g., navigate to home screen
    Navigator.pop(context); // Close the Terms of Service screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You have accepted the Terms of Service.',
          style: TextStyle(color: Colors.white), // Ensures text is readable on green background
        ),
        backgroundColor: Colors.green, // Set the green color for the SnackBar
      ),
    );
  }

}
