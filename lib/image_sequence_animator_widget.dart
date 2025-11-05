import 'package:flutter/material.dart';

class ImageSequenceAnimator extends StatefulWidget {
  final String folderName;
  final String fileName;
  final int suffixStart;
  final int suffixCount;
  final String fileFormat;
  final int frameCount;
  final int fps;
  final bool isLooping;
  final bool isBoomerang;
  final bool isAutoPlay;
  final int frame;

  const ImageSequenceAnimator(
      this.folderName,
      this.fileName,
      this.suffixStart,
      this.suffixCount,
      this.fileFormat,
      this.frameCount, {
        this.fps = 60,
        this.isLooping = false,
        this.isBoomerang = true,
        this.isAutoPlay = false,
        this.frame = 0,
        Key? key,
      }) : super(key: key);

  @override
  State<ImageSequenceAnimator> createState() => _ImageSequenceAnimatorState();
}

class _ImageSequenceAnimatorState extends State<ImageSequenceAnimator> {
  final Map<int, ImageProvider> _imageCache = {};
  int _lastFrame = 1;

  @override
  void initState() {
    super.initState();
    // Delay preloading until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure we start with a valid frame (minimum 1)
        int startFrame = widget.frame <= 0 ? 1 : widget.frame;
        _preloadNearbyImages(startFrame);
      }
    });
  }

  @override
  void didUpdateWidget(ImageSequenceAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frame != oldWidget.frame) {
      _preloadNearbyImages(widget.frame);
    }
  }

  void _preloadNearbyImages(int currentFrame) {
    // Ensure current frame is valid
    currentFrame = currentFrame <= 0 ? 1 : currentFrame.clamp(1, widget.frameCount);

    // Preload current frame and nearby frames for smooth playback
    final framesToPreload = [
      currentFrame,
      (currentFrame - 1).clamp(1, widget.frameCount),
      (currentFrame + 1).clamp(1, widget.frameCount),
      (currentFrame - 2).clamp(1, widget.frameCount),
      (currentFrame + 2).clamp(1, widget.frameCount),
    ];

    for (final frame in framesToPreload) {
      if (!_imageCache.containsKey(frame)) {
        final imagePath = _getImagePath(frame);
        final imageProvider = AssetImage(imagePath);
        _imageCache[frame] = imageProvider;

        // Precache in background
        precacheImage(imageProvider, context).catchError((_) {});
      }
    }
  }

  String _getImagePath(int frameNumber) {
    // Format frame number with leading zeros (0001, 0002, etc.)
    String frameStr = frameNumber.toString().padLeft(4, '0');
    return '${widget.folderName}/$frameStr.${widget.fileFormat}';
  }

  @override
  Widget build(BuildContext context) {
    // Clamp frame to valid range (1 to frameCount, never 0)
    int currentFrame = widget.frame <= 0 ? 1 : widget.frame.clamp(1, widget.frameCount);

    // Get or create image provider
    if (!_imageCache.containsKey(currentFrame)) {
      final imagePath = _getImagePath(currentFrame);
      _imageCache[currentFrame] = AssetImage(imagePath);
    }

    final imageProvider = _imageCache[currentFrame]!;

    return Image(
      image: imageProvider,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Error loading frame $currentFrame',
                style: TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _imageCache.clear();
    super.dispose();
  }
}