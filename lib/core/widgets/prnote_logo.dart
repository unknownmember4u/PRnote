import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PRnoteLogo extends StatelessWidget {
  final double fontSize;
  final bool showSlogan;
  final MainAxisAlignment alignment;

  const PRnoteLogo({
    super.key,
    this.fontSize = 28.0,
    this.showSlogan = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final noteTextColor = theme.textTheme.displayLarge?.color ?? Colors.black;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment == MainAxisAlignment.center 
          ? CrossAxisAlignment.center 
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: fontSize * 0.35, vertical: fontSize * 0.15),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(fontSize * 0.4),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: isLight ? 0.3 : 0.15),
                    blurRadius: fontSize * 0.5,
                    offset: Offset(0, fontSize * 0.15),
                  ),
                ],
              ),
              child: Text(
                'PR',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: fontSize * 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
            SizedBox(width: fontSize * 0.15),
            Text(
              'note',
              style: GoogleFonts.montserrat(
                fontSize: fontSize * 1.1,
                fontWeight: FontWeight.w800,
                color: noteTextColor,
                letterSpacing: -1.5,
                height: 1.1,
              ),
            ),
          ],
        ),
        if (showSlogan) ...[
          SizedBox(height: fontSize * 0.7),
          Text(
            'Your notes, your way',
            style: GoogleFonts.inter(
              fontSize: fontSize * 0.42,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              letterSpacing: 2.5,
            ),
            textAlign: TextAlign.center,
          ),
        ]
      ],
    );
  }
}
