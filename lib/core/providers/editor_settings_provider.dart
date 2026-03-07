import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prnote/core/constants/app_constants.dart';

class EditorSettings {
  final String fontFamily;
  final double fontSize;
  final int autoSaveIntervalSeconds;
  final int? textColorValue;
  final double lineHeight;

  const EditorSettings({
    this.fontFamily = 'Inter',
    this.fontSize = 16.0,
    this.autoSaveIntervalSeconds = 3,
    this.textColorValue,
    this.lineHeight = 1.5,
  });

  Color? get textColor => textColorValue != null ? Color(textColorValue!) : null;

  EditorSettings copyWith({
    String? fontFamily,
    double? fontSize,
    int? autoSaveIntervalSeconds,
    int? textColorValue,
    bool clearTextColor = false,
    double? lineHeight,
  }) {
    return EditorSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      autoSaveIntervalSeconds: autoSaveIntervalSeconds ?? this.autoSaveIntervalSeconds,
      textColorValue: clearTextColor ? null : (textColorValue ?? this.textColorValue),
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  TextStyle getTextStyle({Color? color, FontWeight? fontWeight, double? height, double? letterSpacing, double? fontSizeOverride}) {
    final effectiveSize = fontSizeOverride ?? fontSize;
    final effectiveColor = color ?? textColor;
    final effectiveHeight = height ?? lineHeight;
    
    switch (fontFamily) {
      case 'Roboto':
        return GoogleFonts.roboto(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
      case 'Outfit':
        return GoogleFonts.outfit(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
      case 'Lora':
        return GoogleFonts.lora(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
      case 'Merriweather':
        return GoogleFonts.merriweather(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
      case 'Fira Code':
        return GoogleFonts.firaCode(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
      case 'JetBrains Mono':
        return GoogleFonts.jetBrainsMono(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
      case 'Inter':
      default:
        return GoogleFonts.inter(fontSize: effectiveSize, color: effectiveColor, fontWeight: fontWeight, height: effectiveHeight, letterSpacing: letterSpacing);
    }
  }

  static const List<String> availableFonts = [
    'Inter',
    'Roboto',
    'Outfit',
    'Lora',
    'Merriweather',
    'Playfair Display',
    'Fira Code',
    'JetBrains Mono',
  ];
}

class EditorSettingsNotifier extends StateNotifier<EditorSettings> {
  EditorSettingsNotifier() : super(const EditorSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final family = prefs.getString(AppConstants.prefEditorFontFamily) ?? 'Inter';
    final size = prefs.getDouble(AppConstants.prefEditorFontSize) ?? 16.0;
    final autoSave = prefs.getInt(AppConstants.prefAutoSaveInterval) ?? 3;
    final textColorVal = prefs.getInt(AppConstants.prefEditorTextColor);
    final lineHeightVal = prefs.getDouble(AppConstants.prefEditorLineHeight) ?? 1.5;
    
    state = EditorSettings(
      fontFamily: family,
      fontSize: size.clamp(12.0, 32.0),
      autoSaveIntervalSeconds: autoSave,
      textColorValue: textColorVal,
      lineHeight: lineHeightVal,
    );
  }

  Future<void> updateFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefEditorFontFamily, family);
  }

  Future<void> updateFontSize(double size) async {
    final clampedSize = size.clamp(12.0, 32.0);
    state = state.copyWith(fontSize: clampedSize);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefEditorFontSize, clampedSize);
  }

  Future<void> updateAutoSaveInterval(int seconds) async {
    state = state.copyWith(autoSaveIntervalSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefAutoSaveInterval, seconds);
  }

  Future<void> updateTextColor(Color? color) async {
    state = state.copyWith(
      textColorValue: color?.value,
      clearTextColor: color == null,
    );
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(AppConstants.prefEditorTextColor);
    } else {
      await prefs.setInt(AppConstants.prefEditorTextColor, color.value);
    }
  }

  Future<void> updateLineHeight(double height) async {
    final clampedHeight = height.clamp(1.0, 3.0);
    state = state.copyWith(lineHeight: clampedHeight);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefEditorLineHeight, clampedHeight);
  }
}

final editorSettingsProvider = StateNotifierProvider<EditorSettingsNotifier, EditorSettings>((ref) {
  return EditorSettingsNotifier();
});
