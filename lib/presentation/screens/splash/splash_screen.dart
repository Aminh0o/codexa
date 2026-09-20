import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../onboarding/onboarding_screen.dart';
import '../../navigation/main_navigation_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _videoInitialized = false;
  bool _navigating = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppConstants.splashFadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVideo();
    });
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/videos/splash_animation.mp4',
      );
      await _videoController!.initialize();
      _videoController!.setVolume(0);
      _videoController!.setLooping(false);
      _videoController!.play();
      if (mounted) setState(() => _videoInitialized = true);

      _videoController!.addListener(_onVideoProgress);

      _fallbackTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && !_navigating) _navigateToNext();
      });
    } catch (e) {
      _fallbackTimer = Timer(AppConstants.splashDuration, () {
        if (mounted && !_navigating) _navigateToNext();
      });
    }
  }

  void _onVideoProgress() {
    final controller = _videoController;
    if (controller == null) return;

    if (controller.value.isInitialized &&
        controller.value.position >= controller.value.duration &&
        !_navigating) {
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    if (_navigating) return;
    _navigating = true;

    // Dispose video immediately to free memory on low-end devices
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    _videoController = null;

    final onboardingComplete = ref.read(onboardingCompleteProvider);

    _fadeController.reverse().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return onboardingComplete
                ? const MainNavigationShell()
                : const OnboardingScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: AppConstants.splashFadeDuration,
        ),
      );
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox.expand(
          child: _videoInitialized && _videoController != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : Container(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                ),
        ),
      ),
    );
  }
}
