import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/widgets/spotbook_video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL or SUPABASE_ANON_KEY is empty.\n'
      'Run with: flutter run --dart-define-from-file=.env.json',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox('settings');

  await SpotbookVideoPlayer.initAudioState();

  runApp(const ProviderScope(child: SpotbookApp()));
}
