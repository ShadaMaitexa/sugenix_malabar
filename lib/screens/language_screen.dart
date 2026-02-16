import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sugenix/services/app_localization_service.dart';
import 'package:sugenix/services/locale_notifier.dart';
import 'package:sugenix/l10n/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  Locale _selected = const Locale('en');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final savedLocale = await AppLocalizationService.getSavedLocale();
    if (mounted) {
      setState(() {
        _selected = savedLocale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeNotifier = Provider.of<LocaleNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: AppLocalizationService.getSupportedLanguages().length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final lang = AppLocalizationService.getSupportedLanguages()[index];
          final locale = Locale(lang['code']!);
          final name = lang['name']!;
          final flag = lang['flag'] ?? '';

          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Text(flag, style: const TextStyle(fontSize: 20)),
            title: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Radio<Locale>(
              value: locale,
              groupValue: _selected,
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _selected = v);
                await AppLocalizationService.saveLocale(v);
                localeNotifier.setLocale(v);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.language + ' updated')),
                );
                Navigator.pop(context, v);
              },
            ),
            onTap: () async {
              setState(() => _selected = locale);
              await AppLocalizationService.saveLocale(locale);
              localeNotifier.setLocale(locale);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.language + ' updated')),
              );
              Navigator.pop(context, locale);
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F6F8),
    );
  }
}
