import 'package:flutter/material.dart';
import 'package:sugenix/services/language_service.dart';

/// A widget that automatically updates when language changes
class TranslatedText extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallback;

  const TranslatedText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: LanguageService.currentLanguageStream,
      initialData: 'en',
      builder: (context, snapshot) {
        // If stream hasn't emitted yet, use default
        if (!snapshot.hasData) {
          return FutureBuilder<String>(
            future: LanguageService.getSelectedLanguage(),
            builder: (context, futureSnapshot) {
              final langCode = futureSnapshot.data ?? 'en';
              final translated = LanguageService.translate(translationKey, langCode);
              final displayText = translated == translationKey && fallback != null
                  ? fallback!
                  : translated;
              return Text(
                displayText,
                style: style,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: overflow,
              );
            },
          );
        }
        
        final languageCode = snapshot.data ?? 'en';
        final translated = LanguageService.translate(translationKey, languageCode);
        final displayText = translated == translationKey && fallback != null
            ? fallback!
            : translated;
        
        return Text(
          displayText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// A widget builder that rebuilds when language changes
class LanguageBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, String languageCode) builder;

  const LanguageBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: LanguageService.currentLanguageStream,
      builder: (context, snapshot) {
        final languageCode = snapshot.data ?? 'en';
        return builder(context, languageCode);
      },
    );
  }
}

/// Helper widget for AppBar titles that update with language
class TranslatedAppBarTitle extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final String? fallback;

  const TranslatedAppBarTitle(
    this.translationKey, {
    super.key,
    this.style,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: LanguageService.currentLanguageStream,
      builder: (context, snapshot) {
        final languageCode = snapshot.data ?? 'en';
        final translated = LanguageService.translate(translationKey, languageCode);
        final title = translated == translationKey && fallback != null
            ? fallback!
            : translated;
        return Text(
          title,
          style: style ?? const TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}

