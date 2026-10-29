enum AudioCodec {
  opus,
  aac,
  mp3,
  flac,
}

class AudioStreamDescriptor {
  final String streamUrl;
  final AudioCodec codec;
  final int bitrateKbps;
  final bool isLossless;
  final bool isHls;
  final Map<String, String> httpHeaders;

  const AudioStreamDescriptor({
    required this.streamUrl,
    required this.codec,
    required this.bitrateKbps,
    this.isLossless = false,
    this.isHls = false,
    this.httpHeaders = const {},
  });
}

class VideoStreamDescriptor {
  final String streamUrl;
  final int width;
  final int height;
  final int fps;
  final int bitrateKbps;
  final String mimeType;

  const VideoStreamDescriptor({
    required this.streamUrl,
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrateKbps,
    required this.mimeType,
  });
}
