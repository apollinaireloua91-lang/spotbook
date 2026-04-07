import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_colors.dart';
import 'video_preview_screen.dart';

/// Max video duration — 5 minutes (300 seconds).
const _maxDuration = Duration(minutes: 5);

/// Gallery-based video picker for Pro video upload.
///
/// Accessible ONLY via the Pro shell camera FAB.
/// Opens the device gallery to pick an existing video,
/// then navigates to [VideoPreviewScreen] for metadata & publish.
class VideoCaptureScreen extends StatefulWidget {
  const VideoCaptureScreen({super.key});

  @override
  State<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen> {
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    // Auto-open gallery on first load
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFromGallery());
  }

  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final xFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: _maxDuration,
      );

      if (!mounted) return;

      if (xFile == null) {
        // User cancelled — go back to previous tab
        setState(() => _isPicking = false);
        return;
      }

      // Navigate to preview/publish screen
      context.push('/pro/publish', extra: File(xFile.path));
      setState(() => _isPicking = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPicking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load video: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanc),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.video_library_rounded,
                    color: AppColors.textOnPrimary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Upload a video',
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pick a video from your gallery to showcase your service. Max 5 minutes.',
                  style: TextStyle(
                    color: AppColors.gris,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Pick button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isPicking ? null : _pickFromGallery,
                    icon: _isPicking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.photo_library_rounded),
                    label: Text(
                      _isPicking ? 'Opening...' : 'Choose from Gallery',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      foregroundColor: AppColors.textOnPrimary,
                      disabledBackgroundColor: AppColors.violet.withAlpha(128),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
