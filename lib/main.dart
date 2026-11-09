import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/reminder_service.dart';
import 'core/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgSurface1,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RecallApp());

  // On-device study reminders. Runs after the first frame so startup is never blocked.
  unawaited(ReminderService.instance.initialize());
}
