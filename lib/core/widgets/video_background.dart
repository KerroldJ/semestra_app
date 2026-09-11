import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// A full-bleed, muted, looping background video loaded from an asset.
///
/// The video is scaled with [BoxFit.cover] so it always fills the available
/// space regardless of aspect ratio. While the controller initialises (or if
/// it fails to load) a solid [placeholderColor] is shown, so callers can safely
/// stack content on top without a flash of un-themed background.
class VideoBackground extends StatefulWidget {
  final String asset;
  final Color placeholderColor;
  final BoxFit fit;

  const VideoBackground({
    super.key,
    required this.asset,
    this.placeholderColor = Colors.black,
    this.fit = BoxFit.cover,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  Player? _player;
  VideoController? _controller;

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    final player = Player();
    _player = player;
    _controller = VideoController(player);
    _init(player);
  }

  Future<void> _init(Player player) async {
    try {
      await player.setPlaylistMode(PlaylistMode.loop);
      await player.setVolume(0.0);
      final path = widget.asset.startsWith('asset://')
          ? widget.asset
          : 'asset:///${widget.asset.replaceFirst(RegExp(r"^/+"), "")}';
      await player.open(Media(path));
    } catch (_) {
      // Leave the placeholder color in place if the asset can't be played.
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return ColoredBox(color: widget.placeholderColor);
    }
    return ColoredBox(
      color: widget.placeholderColor,
      child: Video(
        controller: controller,
        controls: NoVideoControls,
        fit: widget.fit,
        fill: widget.placeholderColor,
      ),
    );
  }
}
