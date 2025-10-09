import 'package:flutter/material.dart';
import '../auth/SingUp.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    // Responsive sizing
    final double titleFontSize =
        screenWidth * 0.18; // ~18% of screen width - bigger
    final double subtitleFontSize =
        screenWidth * 0.048; // ~4.8% of screen width - bigger
    final double buttonFontSize = screenWidth * 0.038; // ~3.8% of screen width
    final double horizontalPadding = screenWidth * 0.06; // 6% padding

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/CryptoBackground.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay for better text visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  // Top spacing - increased to move header down
                  SizedBox(height: screenHeight * 0.05),

                  // Top bar with CryptoApp text and logo - centered
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // "CryptoApp" text - bigger
                      Text(
                        'CryptoApp',
                        style: TextStyle(
                          fontSize: screenWidth * 0.065,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(width: screenWidth * 0.025),

                      // Logo next to text - bigger
                      Image.asset(
                        'lib/assets/CryptoLogo.png',
                        height: screenHeight * 0.06,
                        width: screenHeight * 0.06,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),

                  // Flexible spacer to center content vertically
                  const Spacer(flex: 2),

                  // Main title "Salut !"
                  Text(
                    'Salut !',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),

                  // Spacing between title and subtitle
                  SizedBox(height: screenHeight * 0.03),

                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                    ),
                    child: Text(
                      'Entrez vos informations personnelles\npour votre compte employé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Spacer to push buttons to bottom
                  const Spacer(flex: 3),

                  // Buttons row at the bottom (side by side)
                  Row(
                    children: [
                      // "Se connecter" button (Login) - Transparent with background showing
                      Expanded(
                        child: Container(
                          height: screenHeight * 0.065,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // TODO: Navigate to login screen
                                print('Navigate to Login');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: screenWidth * 0.04),

                      // "S'inscrire" button (Sign up) - White background
                      Expanded(
                        child: Container(
                          height: screenHeight * 0.065,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'S\'inscrire',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom spacing
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
