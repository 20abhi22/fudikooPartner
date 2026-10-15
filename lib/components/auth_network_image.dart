import 'package:flutter/material.dart';
import 'package:fudiko/utils/tokens.dart';

/// Image.network that sends the stored Bearer token with the request.
class AuthNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  const AuthNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
  });

  @override
  State<AuthNetworkImage> createState() => _AuthNetworkImageState();
}

class _AuthNetworkImageState extends State<AuthNetworkImage> {
  late final Future<String?> _token = getToken();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(width: widget.width, height: widget.height);
        }
        final token = snap.data;
        return Image.network(
          widget.url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            'Accept': 'image/*',
          },
          errorBuilder: (context, error, stack) {
            debugPrint('Image load failed: ${widget.url} -> $error');
            return widget.errorBuilder?.call(context, error, stack) ??
                const SizedBox.shrink();
          },
        );
      },
    );
  }
}
