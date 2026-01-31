import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

/// Shows a "Coming soon" dialog with OK button. Respects AR/ENG locale.
void showComingSoonDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final isRTL = Localizations.localeOf(context).languageCode == 'ar';
  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        title: Text(l10n.comingSoon),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    ),
  );
}
