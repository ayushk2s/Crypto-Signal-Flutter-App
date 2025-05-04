import 'dart:async';

import 'package:flutter/material.dart';

class TypewriterDeletingText extends StatefulWidget {
  final String fullText;
  final Duration typingDuration;
  final Duration pauseBeforeDelete;
  final Duration pauseBeforeTyping;

  const TypewriterDeletingText({
    super.key,
    required this.fullText,
    this.typingDuration = const Duration(milliseconds: 100),
    this.pauseBeforeDelete = const Duration(seconds: 2),
    this.pauseBeforeTyping = const Duration(seconds: 1),
  });

  @override
  State<TypewriterDeletingText> createState() => _TypewriterDeletingTextState();
}

class _TypewriterDeletingTextState extends State<TypewriterDeletingText> {
  String _displayText = '';
  bool _isTyping = true;
  int _charIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.typingDuration, (timer) {
      if (_isTyping) {
        if (_charIndex < widget.fullText.length) {
          setState(() {
            _displayText += widget.fullText[_charIndex];
            _charIndex++;
          });
        } else {
          timer.cancel();
          Future.delayed(widget.pauseBeforeDelete, _startDeleting);
        }
      }
    });
  }

  void _startDeleting() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.typingDuration, (timer) {
      if (!_isTyping) {
        if (_displayText.isNotEmpty) {
          setState(() {
            _displayText = _displayText.substring(1);
          });
        } else {
          timer.cancel();
          _charIndex = 0;
          _isTyping = true;
          Future.delayed(widget.pauseBeforeTyping, _startTyping);
        }
      }
    });
    _isTyping = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    );
  }
}