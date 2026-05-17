import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class IntroFlashScreen extends StatefulWidget {
  final String nextRouteName;

  const IntroFlashScreen({
    Key? key,
    this.nextRouteName = '/directory',
  }) : super(key: key);

  @override
  State<IntroFlashScreen> createState() => _IntroFlashScreenState();
}

class _IntroFlashScreenState extends State<IntroFlashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.nextRouteName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/images/artisan_directory.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
