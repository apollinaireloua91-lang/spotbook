import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/video_repository.dart';
import '../../domain/video_model.dart';

class MyVideosScreen extends ConsumerStatefulWidget {
  const MyVideosScreen({super.key});

  @override
  ConsumerState<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends ConsumerState<MyVideosScreen> {
  List<VideoModel>? _videos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final videos = await ref.read(videoRepositoryProvider).getMyVideos();
    if (mounted) setState(() => _videos = videos);
  }

  Future<void> _delete(String videoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete video?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(videoRepositoryProvider).deleteVideo(videoId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(backgroundColor: AppColors.fond, title: const Text('My Videos'), centerTitle: true),
      body: _videos == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.blanc))
          : _videos!.isEmpty
              ? const Center(child: Text('No videos yet', style: TextStyle(color: AppColors.gris, fontSize: 15)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: _videos!.length,
                  itemBuilder: (context, index) {
                    final v = _videos![index];
                    return _VideoCard(video: v, onDelete: () => _delete(v.id));
                  },
                ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, required this.onDelete});
  final VideoModel video;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(height: 180, width: double.infinity,
            child: video.thumbnailUrl != null
                ? CachedNetworkImage(imageUrl: video.thumbnailUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.surfaceAlt))
                : Container(color: AppColors.surfaceAlt, child: const Icon(Icons.videocam, color: AppColors.gris, size: 40))),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(video.title, style: const TextStyle(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w600))),
            _StatusBadge(status: video.status),
          ]),
          if (video.status == 'rejected' && video.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text('Reason: ${video.rejectionReason}', style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Row(children: [
            _Stat(Icons.visibility, video.viewsCount), const SizedBox(width: 16),
            _Stat(Icons.favorite, video.likesCount), const SizedBox(width: 16),
            _Stat(Icons.chat_bubble_outline, video.commentsCount), const Spacer(),
            GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20)),
          ]),
        ])),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'approved' => (AppColors.success.withAlpha(26), AppColors.success, 'Published'),
      'pending_review' => (AppColors.warning.withAlpha(26), AppColors.warning, 'In Review'),
      'rejected' => (AppColors.error.withAlpha(26), AppColors.error, 'Rejected'),
      'flagged' => (AppColors.warning.withAlpha(26), AppColors.warning, 'Flagged'),
      _ => (AppColors.gris.withAlpha(26), AppColors.gris, status),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)));
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.count);
  final IconData icon; final int count;
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: AppColors.gris, size: 16), const SizedBox(width: 4), Text(count.toString(), style: const TextStyle(color: AppColors.gris, fontSize: 12))]);
  }
}
