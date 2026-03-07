import 'dart:convert';
import 'package:flutter/material.dart';

class ColoredTextController extends TextEditingController {
  List<Color?> _charColors = [];
  Color? _pendingColor;

  static const String _separator = '\u200B\u200B\u200BCOLOR_SPANS:';

  static String extractPlainText(String encodedText) {
    final idx = encodedText.indexOf(_separator);
    return idx != -1 ? encodedText.substring(0, idx) : encodedText;
  }

  ColoredTextController({String? encodedText}) {
    if (encodedText != null) {
      deserializeContent(encodedText);
    }
  }

  void colorSelection(Color? color) {
    if (selection.isValid && !selection.isCollapsed) {
      for (int i = selection.start; i < selection.end; i++) {
        if (i >= 0 && i < _charColors.length) {
          _charColors[i] = color;
        }
      }
      notifyListeners();
    } else if (selection.isValid && selection.isCollapsed) {
      _pendingColor = color;
    }
  }

  bool _isDeserializing = false;

  // Parses encoded content and populates text and styles
  void deserializeContent(String encodedText) {
    _isDeserializing = true;
    try {
      final idx = encodedText.indexOf(_separator);
      if (idx != -1) {
        final textPart = encodedText.substring(0, idx);
        final jsonPart = encodedText.substring(idx + _separator.length);
        
        final List<dynamic> list = jsonDecode(jsonPart);
        _charColors = [];
        for (final item in list) {
          int length = item['l'] as int;
          int? c = item['c'] as int?;
          Color? color = c != null ? Color(c) : null;
          _charColors.addAll(List.generate(length, (_) => color));
        }
        
        if (_charColors.length != textPart.length) {
          if (_charColors.length > textPart.length) {
            _charColors.length = textPart.length;
          } else {
            _charColors.addAll(List.generate(textPart.length - _charColors.length, (_) => null));
          }
        }
        
        value = value.copyWith(text: textPart, selection: const TextSelection.collapsed(offset: 0), composing: TextRange.empty);
      } else {
        value = value.copyWith(text: encodedText, selection: const TextSelection.collapsed(offset: 0), composing: TextRange.empty);
        _charColors = List.filled(encodedText.length, null);
      }
    } catch (e) {
      String textPart = encodedText;
      final idx = encodedText.indexOf(_separator);
      if (idx != -1) {
        textPart = encodedText.substring(0, idx);
      }
      value = value.copyWith(text: textPart, selection: const TextSelection.collapsed(offset: 0), composing: TextRange.empty);
      _charColors = List.filled(textPart.length, null);
    } finally {
      _isDeserializing = false;
    }
  }

  // Generates encoded text for DB
  String get serializedContent {
    if (_charColors.isEmpty || !_charColors.any((c) => c != null)) {
      return text;
    }

    // Run length encode colors
    final List<Map<String, dynamic>> spans = [];
    if (_charColors.isNotEmpty) {
      Color? currentColor = _charColors.first;
      int currentLength = 1;

      for (int i = 1; i < _charColors.length; i++) {
        if (_charColors[i] == currentColor) {
          currentLength++;
        } else {
          spans.add({'l': currentLength, 'c': currentColor?.value});
          currentColor = _charColors[i];
          currentLength = 1;
        }
      }
      spans.add({'l': currentLength, 'c': currentColor?.value});
    }

    final jsonStr = jsonEncode(spans);
    return text + _separator + jsonStr;
  }

  @override
  set value(TextEditingValue newValue) {
    if (_isDeserializing) {
      super.value = newValue;
      return;
    }

    final oldText = value.text;
    final newText = newValue.text;

    if (oldText != newText) {
      int prefixLen = 0;
      while (prefixLen < oldText.length && prefixLen < newText.length && oldText[prefixLen] == newText[prefixLen]) {
        prefixLen++;
      }
      int suffixLen = 0;
      while (suffixLen < oldText.length - prefixLen && suffixLen < newText.length - prefixLen && oldText[oldText.length - 1 - suffixLen] == newText[newText.length - 1 - suffixLen]) {
        suffixLen++;
      }

      int removedCount = oldText.length - prefixLen - suffixLen;
      int addedCount = newText.length - prefixLen - suffixLen;

      if (prefixLen <= _charColors.length) {
         if (removedCount > 0) {
            _charColors.removeRange(prefixLen, prefixLen + removedCount);
         }
         
         Color? newCharColor;
         if (_pendingColor != null) {
            newCharColor = _pendingColor;
         } else if (prefixLen > 0 && prefixLen <= _charColors.length) {
            newCharColor = _charColors[prefixLen - 1]; // inherit previous char color
         }
         
         if (addedCount > 0) {
            _charColors.insertAll(prefixLen, List.filled(addedCount, newCharColor));
         }
      } else {
         // Fallback if mismatch
         _charColors = List.filled(newText.length, null);
      }
    }
    
    // Reset pending color if selection changes or we typed
    if (value.selection != newValue.selection || oldText != newText) {
       _pendingColor = null;
    }

    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (text.isEmpty) return TextSpan(style: style, text: '');
    
    // Fallback if mismatch safely
    if (_charColors.length != text.length) {
      return TextSpan(style: style, text: text);
    }

    List<TextSpan> spans = [];
    int currentChunkStart = 0;
    Color? currentChunkColor = _charColors.first;

    for (int i = 1; i < text.length; i++) {
       if (_charColors[i] != currentChunkColor) {
           spans.add(TextSpan(
               text: text.substring(currentChunkStart, i),
               style: currentChunkColor != null ? style?.copyWith(color: currentChunkColor) : style,
           ));
           currentChunkStart = i;
           currentChunkColor = _charColors[i];
       }
    }
    
    if (currentChunkStart < text.length) {
       spans.add(TextSpan(
           text: text.substring(currentChunkStart, text.length),
           style: currentChunkColor != null ? style?.copyWith(color: currentChunkColor) : style,
       ));
    }

    return TextSpan(children: spans, style: style);
  }
}
