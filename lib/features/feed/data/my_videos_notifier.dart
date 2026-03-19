import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/video_model.dart';
import 'video_repository.dart';

class MyVideosNotifier extends Notifier<List<VideoModel>?> {
  @override
  List<VideoModel>? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final videos = await ref.read(videoRepositoryProvider).getMyVideos();
    state = videos;
  }

  Future<void> deleteVideo(String videoId) async {
    await ref.read(videoRepositoryProvider).deleteVideo(videoId);
    _load();
  }
}

final myVideosProvider = NotifierProvider<MyVideosNotifier, List<VideoModel>?>(
  MyVideosNotifier.new,
  isAutoDispose: true,
);
