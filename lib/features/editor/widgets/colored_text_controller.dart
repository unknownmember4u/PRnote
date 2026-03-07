import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CharStyle {
  final Color? color;
  final bool isItalic;
  final bool isUnderline;
  final String? font;
  final double? fontSize;

  const CharStyle({
    this.color,
    this.isItalic = false,
    this.isUnderline = false,
    this.font,
    this.fontSize,
  });

  CharStyle copyWith({
    ValueGetter<Color?>? color,
    bool? isItalic,
    bool? isUnderline,
    ValueGetter<String?>? font,
    ValueGetter<double?>? fontSize,
  }) {
    return CharStyle(
      color: color != null ? color() : this.color,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      font: font != null ? font() : this.font,
      fontSize: fontSize != null ? fontSize() : this.fontSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          isItalic == other.isItalic &&
          isUnderline == other.isUnderline &&
          font == other.font &&
          fontSize == other.fontSize;

  @override
  int get hashCode => Object.hash(color, isItalic, isUnderline, font, fontSize);

  bool get isDefault => color == null && !isItalic && !isUnderline && font == null && fontSize == null;
}

typedef ValueGetter<T> = T Function();

class ColoredTextController extends TextEditingController {
  List<CharStyle> _charStyles = [];
  CharStyle _pendingStyle = const CharStyle();

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

  void _updateSelection(CharStyle Function(CharStyle) updateFunc) {
    if (selection.isValid && !selection.isCollapsed) {
      for (int i = selection.start; i < selection.end; i++) {
        if (i >= 0 && i < _charStyles.length) {
          _charStyles[i] = updateFunc(_charStyles[i]);
        }
      }
      notifyListeners();
    } else if (selection.isValid && selection.isCollapsed) {
      // Determine what the current pending style should be.
      // If we are at the end of word or middle, we might already have a pending style,
      // or we derive it from the previous char.
      CharStyle current = _pendingStyle;
      if (selection.start > 0 && selection.start <= _charStyles.length) {
         // If we haven't typed yet, pressing italic should toggle from the char before cursor
         if (_pendingStyle == const CharStyle()) {
             current = _charStyles[selection.start - 1];
         }
      }
      _pendingStyle = updateFunc(current);
      notifyListeners();
    }
  }

  void colorSelection(Color? color) {
    _updateSelection((style) => style.copyWith(color: () => color));
  }

  void fontSelection(String? font) {
    _updateSelection((style) => style.copyWith(font: () => font));
  }

  void toggleItalic() {
    _updateSelection((style) => style.copyWith(isItalic: !style.isItalic));
  }

  void toggleUnderline() {
    _updateSelection((style) => style.copyWith(isUnderline: !style.isUnderline));
  }

  void fontSizeSelection(double? fontSize) {
    _updateSelection((style) => style.copyWith(fontSize: () => fontSize));
  }
  
  // Expose current styles at cursor to update UI toggles
  CharStyle get currentStyleAtCursor {
     if (!selection.isValid) return const CharStyle();
     if (!selection.isCollapsed) {
         // return the style of the first selected char
         if (selection.start < _charStyles.length) {
             return _charStyles[selection.start];
         }
         return const CharStyle();
     }
     
     if (_pendingStyle != const CharStyle()) {
         return _pendingStyle;
     }

     if (selection.start > 0 && selection.start <= _charStyles.length) {
         return _charStyles[selection.start - 1];
     }
     return const CharStyle();
  }

  bool _isDeserializing = false;

  void deserializeContent(String encodedText) {
    _isDeserializing = true;
    try {
      final idx = encodedText.indexOf(_separator);
      if (idx != -1) {
        final textPart = encodedText.substring(0, idx);
        final jsonPart = encodedText.substring(idx + _separator.length);
        
        final List<dynamic> list = jsonDecode(jsonPart);
        _charStyles = [];
        for (final item in list) {
          int length = item['l'] as int;
          int? c = item['c'] as int?;
          bool i = item['i'] == true;
          bool u = item['u'] == true;
          String? f = item['f'] as String?;
          double? s = (item['s'] as num?)?.toDouble();
          
          final style = CharStyle(
              color: c != null ? Color(c) : null,
              isItalic: i,
              isUnderline: u,
              font: f,
              fontSize: s,
          );
          _charStyles.addAll(List.generate(length, (_) => style));
        }
        
        if (_charStyles.length != textPart.length) {
          if (_charStyles.length > textPart.length) {
            _charStyles.length = textPart.length;
          } else {
            _charStyles.addAll(List.generate(textPart.length - _charStyles.length, (_) => const CharStyle()));
          }
        }
        
        value = value.copyWith(text: textPart, selection: const TextSelection.collapsed(offset: 0), composing: TextRange.empty);
      } else {
        value = value.copyWith(text: encodedText, selection: const TextSelection.collapsed(offset: 0), composing: TextRange.empty);
        _charStyles = List.filled(encodedText.length, const CharStyle(), growable: true);
      }
    } catch (e) {
      String textPart = encodedText;
      final idx = encodedText.indexOf(_separator);
      if (idx != -1) {
        textPart = encodedText.substring(0, idx);
      }
      value = value.copyWith(text: textPart, selection: const TextSelection.collapsed(offset: 0), composing: TextRange.empty);
      _charStyles = List.filled(textPart.length, const CharStyle(), growable: true);
    } finally {
      _isDeserializing = false;
    }
  }

  String get serializedContent {
    if (_charStyles.isEmpty || _charStyles.every((s) => s.isDefault)) {
      return text;
    }

    final List<Map<String, dynamic>> spans = [];
    if (_charStyles.isNotEmpty) {
      CharStyle currentStyle = _charStyles.first;
      int currentLength = 1;

      for (int i = 1; i < _charStyles.length; i++) {
        if (_charStyles[i] == currentStyle) {
          currentLength++;
        } else {
          _addSpan(spans, currentStyle, currentLength);
          currentStyle = _charStyles[i];
          currentLength = 1;
        }
      }
      _addSpan(spans, currentStyle, currentLength);
    }

    final jsonStr = jsonEncode(spans);
    return text + _separator + jsonStr;
  }

  void _addSpan(List<Map<String, dynamic>> spans, CharStyle style, int length) {
    var map = <String, dynamic>{'l': length};
    // ignore: deprecated_member_use
    if (style.color != null) map['c'] = style.color!.value;
    if (style.isItalic) map['i'] = true;
    if (style.isUnderline) map['u'] = true;
    if (style.font != null) map['f'] = style.font;
    if (style.fontSize != null) map['s'] = style.fontSize;
    spans.add(map);
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

      if (prefixLen <= _charStyles.length) {
         if (removedCount > 0) {
            _charStyles.removeRange(prefixLen, prefixLen + removedCount);
         }
         
         CharStyle newCharStyle = const CharStyle();
         if (_pendingStyle != const CharStyle()) {
            newCharStyle = _pendingStyle;
         } else if (prefixLen > 0 && prefixLen <= _charStyles.length) {
            newCharStyle = _charStyles[prefixLen - 1];
         }
         
         if (addedCount > 0) {
            _charStyles.insertAll(prefixLen, List.filled(addedCount, newCharStyle, growable: true));
         }
      } else {
         _charStyles = List.filled(newText.length, const CharStyle(), growable: true);
      }
    }
    
    // Only reset pending if selection moved not due to our typing taking the pending style
    if (value.selection != newValue.selection || oldText != newText) {
       // but wait, if oldText != newText, we just USED the pending style, so we want to keep it
       // so further typing uses the same pending style. It is naturally inherited from char before it.
       // So to be safe, we just reset it to const CharStyle() because the next char typed
       // will inherit from prefixLen-1 automatically!
       _pendingStyle = const CharStyle();
    }

    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (text.isEmpty) return TextSpan(style: style, text: '');
    
    if (_charStyles.length != text.length) {
      return TextSpan(style: style, text: text);
    }

    List<TextSpan> spans = [];
    int currentChunkStart = 0;
    CharStyle currentChunkStyle = _charStyles.first;

    for (int i = 1; i < text.length; i++) {
       if (_charStyles[i] != currentChunkStyle) {
           spans.add(_buildSpan(text.substring(currentChunkStart, i), currentChunkStyle, style));
           currentChunkStart = i;
           currentChunkStyle = _charStyles[i];
       }
    }
    
    if (currentChunkStart < text.length) {
       spans.add(_buildSpan(text.substring(currentChunkStart, text.length), currentChunkStyle, style));
    }

    return TextSpan(children: spans, style: style);
  }
  
  TextSpan _buildSpan(String textSegment, CharStyle charStyle, TextStyle? baseStyle) {
      TextStyle effectiveStyle = baseStyle ?? const TextStyle();
      
      if (charStyle.color != null) {
          effectiveStyle = effectiveStyle.copyWith(color: charStyle.color);
      }
      if (charStyle.fontSize != null) {
          effectiveStyle = effectiveStyle.copyWith(fontSize: charStyle.fontSize);
      }
      if (charStyle.isItalic) {
          effectiveStyle = effectiveStyle.copyWith(fontStyle: FontStyle.italic);
      }
      if (charStyle.isUnderline) {
          effectiveStyle = effectiveStyle.copyWith(decoration: TextDecoration.underline);
      }
      if (charStyle.font != null) {
          // Merge with google font style
          effectiveStyle = GoogleFonts.getFont(charStyle.font!, textStyle: effectiveStyle);
      }
      
      return TextSpan(text: textSegment, style: effectiveStyle);
  }
}
