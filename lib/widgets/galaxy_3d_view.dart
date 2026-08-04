import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/mood_entry.dart';

class Galaxy3DView extends StatefulWidget {
  final List<MoodEntry> entries;
  final Function(String entryId) onBeadSelected;

  const Galaxy3DView({
    Key? key,
    required this.entries,
    required this.onBeadSelected,
  }) : super(key: key);

  @override
  State<Galaxy3DView> createState() => _Galaxy3DViewState();
}

class _Galaxy3DViewState extends State<Galaxy3DView> {
  late final WebViewController _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121212))
      ..addJavaScriptChannel(
        'MoodSphereChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final entryId = message.message;
          widget.onBeadSelected(entryId);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoaded = true;
            });
            _updateBeadsInWebView();
          },
        ),
      )
      ..loadFlutterAsset('assets/three_sphere.html');
  }

  @override
  void didUpdateWidget(covariant Galaxy3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLoaded && oldWidget.entries != widget.entries) {
      _updateBeadsInWebView();
    }
  }

  void _updateBeadsInWebView() {
    if (!_isLoaded) return;

    final jsonEntries = widget.entries.map((e) {
      // Format color int to CSS hex string #RRGGBB
      final hexColor =
          '#${(e.colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      return {
        'id': e.id,
        'color': hexColor,
        'date': e.date.toIso8601String(),
        'note': e.note ?? '',
      };
    }).toList();

    final jsonString = jsonEncode(jsonEntries);
    _controller.runJavaScript('updateBeads($jsonString)');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (!_isLoaded)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            ),
        ],
      ),
    );
  }
}
