// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Sales Dashboard',
      'netChange': 'Net Change',
      'receivable': 'Receivable',
      'payable': 'Payable',
      'features': 'Features',
      'customers': 'Customers',
      'vendors': 'Vendors',
      'products': 'Products',
      'reports': 'Reports',
      'all': 'All',
      'today': 'Today',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'custom': 'Custom',
      'startDate': 'Start Date',
      'endDate': 'End Date',
    },
    'ml': {
      'appTitle': 'ഡാഷ്ബോർഡ്',
      'netChange': 'മൊത്തം മാറ്റം',
      'receivable': 'കിട്ടാനുള്ളത്',
      'payable': 'കൊടുക്കാനുള്ളത്',
      'features': 'സവിശേഷതകൾ',
      'customers': 'കസ്റ്റമർ',
      'vendors': 'വെൻഡർ',
      'products': 'സാധനങ്ങൾ',
      'reports': 'റിപ്പോർട്ടുകൾ',
      'all': 'എല്ലാം',
      'today': 'ഇന്ന്',
      'thisWeek': 'ഈ ആഴ്ച',
      'thisMonth': 'ഈ മാസം',
      'custom': 'Date സെലക്ട്‌ ചെയ്യൂ',
      'startDate': 'തുടക്ക തീയതി',
      'endDate': 'അവസാന തീയതി',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get netChange => _localizedValues[locale.languageCode]!['netChange']!;
  String get receivable =>
      _localizedValues[locale.languageCode]!['receivable']!;
  String get payable => _localizedValues[locale.languageCode]!['payable']!;
  String get features => _localizedValues[locale.languageCode]!['features']!;
  String get customers => _localizedValues[locale.languageCode]!['customers']!;
  String get vendors => _localizedValues[locale.languageCode]!['vendors']!;
  String get products => _localizedValues[locale.languageCode]!['products']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;
  String get all => _localizedValues[locale.languageCode]!['all']!;
  String get today => _localizedValues[locale.languageCode]!['today']!;
  String get thisWeek => _localizedValues[locale.languageCode]!['thisWeek']!;
  String get thisMonth => _localizedValues[locale.languageCode]!['thisMonth']!;
  String get custom => _localizedValues[locale.languageCode]!['custom']!;
  String get startDate => _localizedValues[locale.languageCode]!['startDate']!;
  String get endDate => _localizedValues[locale.languageCode]!['endDate']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ml'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
