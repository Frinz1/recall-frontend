import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgSurface1,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RecallApp());
}
