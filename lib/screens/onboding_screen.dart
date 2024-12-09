import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' as rive;
import 'package:studyscheduler/screens/animated_btn.dart';
import 'package:studyscheduler/screens/custom_sign_in.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isSignInDialogShown = false;
  late rive.RiveAnimationController _btnAnimationController;

  @override
  void initState() {
    _btnAnimationController = rive.OneShotAnimation("active", autoplay: false);
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,  // Set background to dark
      body: Stack(
        children: [
          // Background image with blur effect
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            bottom: 200,
            left: 100,
            child: Image.asset(
              'assets/Backgrounds/Spline.png',
              color: Colors.grey.withOpacity(0.1),  // Adjust opacity for subtle background
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
            ),
          ),
          // Shapes animation
          const rive.RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),
          // Main content section with better organization
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            top: isSignInDialogShown ? -50 : 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Title Section
                    const SizedBox(
                      width: 300,  // Adjust the width for better text alignment
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,  // Align the text to the left
                        children: [
                          Text(
                            "Master Your Study Journey",
                            style: TextStyle(
                              fontSize: 55,  // Adjusted font size
                              fontWeight: FontWeight.bold,  // Make the text bold
                              fontFamily: "Poppins",
                              height: 1.2,
                              color: Colors.white,  // Text color for dark mode
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Achieve your academic goals with Study Sprint. Manage your study schedule, track progress, and stay motivated with personalized notifications.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,  // Lighter text color
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Animated Button
                    AnimatedBtn(
                      btnAnimationController: _btnAnimationController,
                      press: () {
                        _btnAnimationController.isActive = true;
                        Future.delayed(const Duration(milliseconds: 800), () {
                          setState(() {
                            isSignInDialogShown = true;
                          });
                          customSigninDialog(context, onClosed: (_) {
                            setState(() {
                              isSignInDialogShown = false;
                            });
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 24),  // Add spacing below the button
                    // Additional Information
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "Get access to personalized study plans, detailed progress tracking, and reminders for your upcoming tasks and exams.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,  // Text color for dark mode
                          height: 1.5,  // Line height for better readability
                        ),
                        textAlign: TextAlign.left,  // Align text to be justified
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
