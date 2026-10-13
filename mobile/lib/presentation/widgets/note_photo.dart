import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class NotePhoto extends StatefulWidget {
  final String data;
  const NotePhoto({super.key, required this.data});
  @override
  State<NotePhoto> createState() => _NotePhotoState();
}

class _NotePhotoState extends State<NotePhoto> {
  Uint8List? _bytes;
  void _decode() {
    try {
      final data = widget.data;
      _bytes = base64Decode(
        data.startsWith('data:') ? data.substring(data.indexOf(',') + 1) : data,
      );
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(NotePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _decode();
  }

  Widget _error() => const SizedBox(
    height: 180,
    child: Center(child: Text('Photo cannot be displayed')),
  );
  @override
  Widget build(BuildContext context) {
    final url = Uri.tryParse(widget.data);
    if (url != null && ['http', 'https'].contains(url.scheme)) {
      return Image.network(
        widget.data,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => _error(),
      );
    }
    return _bytes == null
        ? _error()
        : Image.memory(
            _bytes!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => _error(),
          );
  }
}
