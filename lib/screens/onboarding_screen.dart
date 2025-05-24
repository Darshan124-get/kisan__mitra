import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  void _skip() {
    _controller.jumpToPage(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (int index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          OnboardContent(
            imagePath: 'assets/images/onbord_1.png',
            title: 'Easily Upload\nImages or Videos',
            description:
            'Take a photo or record a video of your plant or animal showing signs of illness and let our AI handle the rest.',
            buttonText: 'Next',
            onNext: _nextPage,
            showSkip: true,
            onSkip: _skip,
            isLast: false,
          ),
          OnboardContent(
            imagePath: 'assets/images/onbord_2.png',
            title: 'Get Diagnosis and\nSolutions',
            description:
            'Get instant analysis of the problem and practical treatment steps—tailored to local needs for easy reach.',
            buttonText: 'Get Started!',
            onNext: () {
              Navigator.pushReplacementNamed(context, '/signup');
            },
            showSkip: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class OnboardContent extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onNext;
  final bool showSkip;
  final VoidCallback? onSkip;
  final bool isLast;

  const OnboardContent({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onNext,
    this.showSkip = false,
    this.onSkip,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox(height: 60),
          Image.asset(imagePath, height: 250),
          Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(buttonText),
              ),
              if (showSkip && onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: const Text("Skip"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
