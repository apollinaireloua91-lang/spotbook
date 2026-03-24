import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase: Supabase.instance.client);
});

class ProfileRepository {
  ProfileRepository({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  String? get _uid => _supabase.auth.currentUser?.id;

  static bool _isUniqueViolation(PostgrestException e) {
    final details = e.details?.toString() ?? '';
    return e.code == '23505' ||
        details.contains('23505') ||
        e.message.toLowerCase().contains('duplicate');
  }

  Future<void> upsertProProfile({
    required String businessName,
    required String category,
    required String city,
    required String bio,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    final existing = await _supabase
        .from('profiles_pro')
        .select('id')
        .eq('id', uid)
        .maybeSingle();

    final payload = {
      'business_name': businessName,
      'category': category,
      'description': bio,
    };

    if (existing == null) {
      try {
        await _supabase.from('profiles_pro').insert({
          'id': uid,
          ...payload,
        });
      } on PostgrestException catch (e) {
        if (_isUniqueViolation(e)) {
          await _supabase.from('profiles_pro').update(payload).eq('id', uid);
        } else {
          rethrow;
        }
      }
    } else {
      await _supabase.from('profiles_pro').update(payload).eq('id', uid);
    }

    await _supabase.from('users').update({'city': city}).eq('id', uid);
  }

  Future<String> uploadKycDocument(Uint8List bytes, String ext) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');
    final path = '$uid/id_document.$ext';
    await _supabase.storage
        .from('kyc-documents')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  Future<void> submitKycVerification(String phone) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    await _supabase.from('profiles_pro').update({
      'kyc_status': 'pending',
      'tel': phone,
    }).eq('id', uid);
  }

  Future<void> requestLocationAndSave() async {
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      ),
    );

    final uid = _uid;
    if (uid == null) return;
    try {
      await _supabase.from('users').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }).eq('id', uid);
    } catch (_) {
      // Colonnes latitude/longitude absentes ou RLS : ne pas bloquer la navigation.
    }
  }
}
