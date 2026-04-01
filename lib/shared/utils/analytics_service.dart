import 'package:hive_flutter/hive_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const _boxName = 'app_prefs';
  static const _consentKey = 'analytics_consent';
  static const _initKey = 'analytics_initialized';

  bool _isInitialized = false;

  Future<Box<dynamic>> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<bool?> getConsent() async {
    final b = await _box();
    final value = b.get(_consentKey);
    if (value is bool) return value;
    return null;
  }

  Future<void> setConsent(bool value) async {
    final b = await _box();
    await b.put(_consentKey, value);
    if (value) {
      await initializeIfConsented();
    } else {
      if (_isInitialized) {
        await Posthog().disable();
      }
      _isInitialized = false;
      await b.put(_initKey, false);
    }
  }

  Future<void> initializeIfConsented() async {
    final b = await _box();
    final consent = b.get(_consentKey) == true;
    if (!consent || _isInitialized) return;

    final apiKey = const String.fromEnvironment('POSTHOG_API_KEY');
    if (apiKey.isEmpty) return;
    final host = const String.fromEnvironment('POSTHOG_HOST');

    final config = PostHogConfig(apiKey);
    if (host.isNotEmpty) config.host = host;
    config.captureApplicationLifecycleEvents = false;
    await Posthog().setup(config);
    _isInitialized = true;
    await b.put(_initKey, true);
  }

  Future<void> capture(String eventName, {Map<String, Object>? properties}) async {
    await initializeIfConsented();
    if (!_isInitialized) return;
    await Posthog().capture(eventName: eventName, properties: properties);
  }
}
