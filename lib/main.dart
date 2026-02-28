import 'package:flutter/material.dart';
import 'package:cleansl_complaint_module/features/complaint/presentation/pages/camera_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1C11),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const ComplaintScreen(),
    );
  }
}

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C11),
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () {
              // Back action or exit module
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          "Raise Complaint",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                "Select Complaint Type",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Choose the category that best fits your\ncurrent issue",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),

              // Garbage Collection Card
              _buildComplaintCard(
                context: context,
                icon: Icons.delete_sweep,
                iconBackgroundColor: const Color(0xFF165228),
                iconColor: const Color(0xFF26D15B),
                title: "Garbage Collection",
                subtitle: "My garbage wasn't collected",
                subtitleColor: const Color(0xFF26D15B),
                backgroundColor: const Color(0xFF102616),
                borderColor: const Color(0xFF1A3A22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Other Issue Card
              _buildComplaintCard(
                context: context,
                icon: Icons.more_horiz,
                iconBackgroundColor: const Color(0xFF243026),
                iconColor: const Color(0xFF8B9890),
                title: "Other Issue",
                subtitle: "Report any other concern",
                subtitleColor: const Color(0xFF5E6D63),
                backgroundColor: const Color(0xFF151E18),
                borderColor: const Color(0xFF28362B),
                onTap: () {},
              ),

              const Spacer(),

              // Soundwave Decor
              Center(
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBar(12, const Color(0xFF26D15B).withOpacity(0.2)),
                      _buildBar(20, const Color(0xFF26D15B).withOpacity(0.5)),
                      _buildBar(35, const Color(0xFF26D15B).withOpacity(0.8)),
                      _buildBar(20, const Color(0xFF26D15B).withOpacity(0.5)),
                      _buildBar(12, const Color(0xFF26D15B).withOpacity(0.2)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Contact Support
              Center(
                child: Column(
                  children: [
                    Text(
                      "NEED IMMEDIATE HELP?",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162218),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF2A362B)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.support_agent,
                              color: Color(0xFF26D15B),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Contact Support",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade700,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: height,
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
