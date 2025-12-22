import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({
    Key? key,
    required this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _truckController;
  late AnimationController _bottleController;
  late AnimationController _recycleController;
  late AnimationController _fadeController;

  late Animation<double> _truckAnimation;
  late Animation<double> _bottleAnimation;
  late Animation<double> _recycleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Truck animation - moves from left to right
    _truckController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Bottle animation - bounces
    _bottleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Recycle symbol animation - rotates
    _recycleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Fade animation for logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _truckAnimation = Tween<double>(begin: -200, end: 400).animate(
      CurvedAnimation(
        parent: _truckController,
        curve: Curves.easeInOut,
      ),
    );

    _bottleAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _bottleController,
        curve: Curves.easeInOut,
      ),
    );

    _recycleAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _recycleController,
        curve: Curves.linear,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Start animations
    _truckController.forward();
    _fadeController.forward();

    // Complete after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _truckController.dispose();
    _bottleController.dispose();
    _recycleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                ],
              ),
            ),
          ),

          // Animated elements
          AnimatedBuilder(
            animation: _truckAnimation,
            builder: (context, child) {
              return Positioned(
                left: _truckAnimation.value,
                bottom: size.height * 0.25,
                child: _buildTruck(),
              );
            },
          ),

          // Bottles on the truck
          AnimatedBuilder(
            animation: Listenable.merge([_truckAnimation, _bottleAnimation]),
            builder: (context, child) {
              return Positioned(
                left: _truckAnimation.value + 40,
                bottom: size.height * 0.25 + 30 + _bottleAnimation.value,
                child: _buildBottles(),
              );
            },
          ),

          // Recycled products icons
          AnimatedBuilder(
            animation: Listenable.merge([_truckAnimation, _recycleAnimation]),
            builder: (context, child) {
              return Positioned(
                left: _truckAnimation.value + 80,
                bottom: size.height * 0.25 + 25,
                child: Transform.rotate(
                  angle: _recycleAnimation.value,
                  child: _buildRecycleIcon(),
                ),
              );
            },
          ),

          // More bottles scattered
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _bottleAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 50.0 + (index * 100.0),
                  bottom: size.height * 0.15 + _bottleAnimation.value * (index % 2 == 0 ? 1 : -1),
                  child: _buildSingleBottle(),
                );
              },
            );
          }),

          // Logo in center
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dawar',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recycling Unit App',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruck() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Truck body
          Positioned(
            left: 0,
            top: 10,
            child: Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
          // Truck cabin
          Positioned(
            right: 0,
            top: 5,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
          // Window
          Positioned(
            right: 5,
            top: 10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Wheels
          Positioned(
            left: 10,
            bottom: -5,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 15,
            bottom: -5,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottles() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSingleBottle(),
        const SizedBox(width: 5),
        _buildSingleBottle(),
        const SizedBox(width: 5),
        _buildSingleBottle(),
      ],
    );
  }

  Widget _buildSingleBottle() {
    return Container(
      width: 12,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.green.shade400,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.green.shade600, width: 1),
      ),
      child: Stack(
        children: [
          // Bottle neck
          Positioned(
            top: 0,
            left: 3,
            child: Container(
              width: 6,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
            ),
          ),
          // Label
          Positioned(
            top: 6,
            left: 2,
            child: Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecycleIcon() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.recycling,
        color: Colors.green.shade700,
        size: 20,
      ),
    );
  }
}
