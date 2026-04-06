import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../chat/data/chat_repository.dart';
import '../../../reviews/domain/review_model.dart';
import '../../data/datasources/provider_profile_remote_datasource.dart';
import '../../data/profile_repository.dart';
import '../../domain/entities/provider_profile_data.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class PublicProviderProfileEvent extends Equatable {
  const PublicProviderProfileEvent();

  @override
  List<Object?> get props => [];
}

final class PublicProviderProfileStarted extends PublicProviderProfileEvent {
  const PublicProviderProfileStarted(this.providerId);

  final String providerId;

  @override
  List<Object?> get props => [providerId];
}

final class PublicProviderProfileRealtimeRefresh extends PublicProviderProfileEvent {
  const PublicProviderProfileRealtimeRefresh();
}

final class PublicProviderProfileToggleFollow extends PublicProviderProfileEvent {
  const PublicProviderProfileToggleFollow();
}

// ─── State ────────────────────────────────────────────────────────────────────

sealed class PublicProviderProfileState extends Equatable {
  const PublicProviderProfileState();

  @override
  List<Object?> get props => [];
}

final class PublicProviderProfileLoading extends PublicProviderProfileState {
  const PublicProviderProfileLoading();
}

final class PublicProviderProfileFailure extends PublicProviderProfileState {
  const PublicProviderProfileFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class PublicProviderProfileReady extends PublicProviderProfileState {
  const PublicProviderProfileReady({
    required this.data,
    required this.reviews,
    required this.isFollowedByMe,
    this.followBusy = false,
  });

  final ProviderProfileData data;
  final List<ReviewModel> reviews;
  final bool isFollowedByMe;
  final bool followBusy;

  PublicProviderProfileReady copyWith({
    ProviderProfileData? data,
    List<ReviewModel>? reviews,
    bool? isFollowedByMe,
    bool? followBusy,
  }) {
    return PublicProviderProfileReady(
      data: data ?? this.data,
      reviews: reviews ?? this.reviews,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      followBusy: followBusy ?? this.followBusy,
    );
  }

  @override
  List<Object?> get props => [data, reviews, isFollowedByMe, followBusy];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class PublicProviderProfileBloc
    extends Bloc<PublicProviderProfileEvent, PublicProviderProfileState> {
  PublicProviderProfileBloc({
    required ProviderProfileRemoteDatasource profileDatasource,
    required ProfileRepository profileRepository,
    required ChatRepository chatRepository,
    required SupabaseClient supabase,
  })  : _datasource = profileDatasource,
        _profileRepo = profileRepository,
        _chatRepo = chatRepository,
        _supabase = supabase,
        super(const PublicProviderProfileLoading()) {
    on<PublicProviderProfileStarted>(_onStarted);
    on<PublicProviderProfileRealtimeRefresh>(_onRealtimeRefresh);
    on<PublicProviderProfileToggleFollow>(_onToggleFollow);
  }

  final ProviderProfileRemoteDatasource _datasource;
  final ProfileRepository _profileRepo;
  final ChatRepository _chatRepo;
  final SupabaseClient _supabase;

  String? _providerId;
  RealtimeChannel? _channel;
  Timer? _debounce;

  /// Last loaded provider ID (used by "Retry" in the UI).
  String? get providerId => _providerId;

  Future<void> _onStarted(
    PublicProviderProfileStarted event,
    Emitter<PublicProviderProfileState> emit,
  ) async {
    _providerId = event.providerId;
    emit(const PublicProviderProfileLoading());
    await _loadAndEmit(emit);
    _subscribeRealtime();
  }

  Future<void> _onRealtimeRefresh(
    PublicProviderProfileRealtimeRefresh event,
    Emitter<PublicProviderProfileState> emit,
  ) async {
    final cur = state;
    if (cur is! PublicProviderProfileReady) return;
    final id = _providerId;
    if (id == null || id.isEmpty) return;

    try {
      final data = await _datasource.getProviderProfileForPublicClientView(id);
      final reviews = await _datasource.fetchReviewsForPro(id);
      emit(
        cur.copyWith(
          data: data,
          reviews: reviews,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onToggleFollow(
    PublicProviderProfileToggleFollow event,
    Emitter<PublicProviderProfileState> emit,
  ) async {
    final cur = state;
    if (cur is! PublicProviderProfileReady || cur.followBusy) return;

    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final was = cur.isFollowedByMe;
    final delta = was ? -1 : 1;
    final newCount =
        (cur.data.provider.followersCount + delta).clamp(0, 9999999);

    emit(
      cur.copyWith(
        isFollowedByMe: !was,
        followBusy: true,
        data: cur.data.copyWith(
          provider: cur.data.provider.copyWith(followersCount: newCount),
        ),
      ),
    );

    try {
      if (was) {
        await _profileRepo.unfollowUser(cur.data.provider.id);
      } else {
        await _profileRepo.followUser(cur.data.provider.id);
        unawaited(_notifyProNewFollower(proId: cur.data.provider.id, followerId: uid));
      }
      final after = state;
      if (after is PublicProviderProfileReady) {
        emit(after.copyWith(followBusy: false));
      }
    } catch (_) {
      emit(cur);
    }
  }

  Future<void> _loadAndEmit(Emitter<PublicProviderProfileState> emit) async {
    final id = _providerId;
    if (id == null || id.isEmpty) {
      emit(const PublicProviderProfileFailure('Profile not found.'));
      return;
    }

    try {
      final data = await _datasource.getProviderProfileForPublicClientView(id);
      final reviews = await _datasource.fetchReviewsForPro(id);
      var followed = false;
      final uid = _supabase.auth.currentUser?.id;
      if (uid != null) {
        final row = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('follower_id', uid)
            .eq('following_id', id)
            .maybeSingle();
        followed = row != null;
      }

      emit(
        PublicProviderProfileReady(
          data: data,
          reviews: reviews,
          isFollowedByMe: followed,
        ),
      );
    } catch (e) {
      emit(PublicProviderProfileFailure(e.toString()));
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      add(const PublicProviderProfileRealtimeRefresh());
    });
  }

  void _subscribeRealtime() {
    final id = _providerId;
    if (id == null || id.isEmpty) return;

    _channel?.unsubscribe();
    _channel = _supabase.channel('public_client_profile_$id');

    void listen(String table, String column) {
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: id,
        ),
        callback: (_) => _scheduleRefresh(),
      );
    }

    listen('profiles_pro', 'id');
    listen('follows', 'following_id');
    listen('services', 'pro_id');
    listen('videos', 'pro_id');
    listen('events', 'pro_id');
    listen('reviews', 'pro_id');

    _channel!.subscribe();
  }

  Future<void> _notifyProNewFollower({
    required String proId,
    required String followerId,
  }) async {
    try {
      final u = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', followerId)
          .maybeSingle();
      final name = u?['full_name'] as String? ?? 'A client';
      await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'userId': proId,
          'actorId': followerId,
          'title': 'New follower',
          'body': '$name is now following you on Spotbook',
          'type': 'social',
          'data': {
            'route': '/pro/profile',
            'kind': 'new_follower',
          },
        },
      );
    } catch (_) {}
  }

  /// Get or create the client ↔ pro conversation.
  Future<String?> ensureConversationAndGetId() async {
    final id = _providerId;
    final uid = _supabase.auth.currentUser?.id;
    if (id == null || uid == null) return null;
    try {
      final conv = await _chatRepo.getOrCreateConversation(
        clientId: uid,
        proId: id,
      );
      return conv.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _channel?.unsubscribe();
    return super.close();
  }
}
