import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/models/recycling_unit.dart';
import '../../core/utils/dialogs.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

/// Shows information about the recycling unit and unit owner (read-only).
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  static String _unitTypeLabel(UnitType? type, AppLocalizations l10n) {
    if (type == null) return l10n.translate('bulking_station');
    switch (type) {
      case UnitType.press:
        return l10n.translate('unit_type_press');
      case UnitType.shredder:
        return l10n.translate('unit_type_shredder');
      case UnitType.washingLine:
        return l10n.translate('unit_type_washing_line');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final authProvider = Provider.of<AuthProvider>(context);
    final unit = authProvider.recyclingUnit;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(localizations.personalInformation),
        ),
        body: unit == null
            ? Center(child: Text(localizations.noData))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoCard(
                      children: [
                        _InfoRow(
                          label: localizations.unitName,
                          value: unit.unitName,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: localizations.translate('unit_type'),
                          value: _unitTypeLabel(unit.unitType, localizations),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: localizations.phoneNumber,
                          value: unit.phoneNumber,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: localizations.unitOwnerName,
                          value: unit.unitOwnerName,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            switch (index) {
              case 0:
                context.push('/dashboard');
                break;
              case 1:
                context.push('/shipments');
                break;
              case 2:
                showComingSoonDialog(context);
                break;
              case 3:
                context.push('/settings');
                break;
            }
          },
          isRTL: isRTL,
          supplyRequestsLabel: localizations.supplyRequests,
        ),
      ),
    );
  }

}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
