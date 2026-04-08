import 'package:flutter/material.dart';
import '../providers/language_provider.dart';

class Translations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'EcoSched',
      'experience_ecosched': 'Experience EcoSched',
      'select_location_begin': 'Select your location to begin',
      'waste_collector': 'Waste Collector?',
      'collector_sign_in': 'Collector Sign In',
      'select': 'Select',
      'victoria': 'Victoria',
      'dayo_an': 'Dayo-an',
      'access_schedules_victoria': 'Access local schedules for Victoria',
      'access_schedules_dayo_an': 'Access local schedules for Dayo-an',
      'dashboard': 'Dashboard',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'history': 'History',
      'today': 'Today',
      'upcoming': 'Upcoming',
      'no_collection_today': 'No collection scheduled today',
      'start_route': 'Start Route',
      'good_morning': 'Good Morning!',
      'good_afternoon': 'Good Afternoon!',
      'good_evening': 'Good Evening!',
      'search': 'Search',
      'logout': 'Logout',
      'language': 'Language',
      'english': 'English',
      'bisaya': 'Bisaya',
      'switch_to_bisaya': 'Switch to Bisaya',
      'switch_to_english': 'Switch to English',
      'zone': 'Zone',
      'review_schedules': 'Review schedules & follow safety protocols.',
      'collector_dashboard': 'Collector Dashboard',
      'live_scan': 'Live Scan',
      'switch_light_mode': 'Switch to light mode',
      'switch_dark_mode': 'Switch to dark mode',
      'route_started_updated': 'Route started! {} collection(s) updated.',
      'route_started_notifs': 'Route started! notifications sent.',
      'home': 'Home',
      'feedback': 'Feedback',
      'scan': 'Scan',
      'special': 'Special',
      'alerts': 'Alerts',
      'mark_all_read': 'Mark All Read',
      'upcoming_collection': 'Upcoming Collection',
      'collection_rescheduled': 'Collection Rescheduled',
      'date': 'Date',
      'time': 'Time',
      'days': 'days',
      'day': 'day',
      'reason': 'Reason',
      'bin_location': 'Bin Location',
      'just_now': 'Just now',
      'minutes_ago': '{} minutes ago',
      'hours_ago': '{} hours ago',
      'days_ago': '{} days ago',
      'no_notifications': 'All clear! No notifications at this time.',
      'collector_access': 'Collector Access',
      'welcome_back': 'Welcome Back',
      'authorized_personnel_only':
          'Authorized personnel only. Please sign in to access your dashboard.',
      'sign_in_to_manage': 'Sign in to manage your EcoSched account',
      'email_address': 'Email Address',
      'security_password': 'Security Password',
      'stay_signed_in': 'Stay signed in',
      'reset_password': 'Reset Password?',
      'authenticating': 'Authenticating...',
      'sign_in_to_dashboard': 'Sign In to Dashboard',
      'enter_email': 'Please enter your registered email',
      'enter_password': 'Please enter your password',
      'password_short': 'Password must be at least 6 characters',
      'welcome_back_ecosched': 'Welcome back to EcoSched!',
      'login_failed': 'Login failed. Please try again.',
      'password_recovery_admin':
          'Password recovery is currently managed by administrators.',
      'collector_incoming': 'Collector is Incoming! 🚚',
      'collection_starting_now': 'Collection Starting Now 🚛',
    },
    'ceb': {
      'app_title': 'EcoSched',
      'experience_ecosched': 'Masinati ang EcoSched',
      'select_location_begin': 'Pilia ang imong lokasyon aron magsugod',
      'waste_collector': 'Kolektor sa Basura?',
      'collector_sign_in': 'Pag-sign in sa Kolektor',
      'select': 'Pilia',
      'victoria': 'Victoria',
      'dayo_an': 'Dayo-an',
      'access_schedules_victoria':
          'Pag-access sa lokal nga mga iskedyul para sa Victoria',
      'access_schedules_dayo_an':
          'Pag-access sa lokal nga mga iskedyul para sa Dayo-an',
      'dashboard': 'Dashboard',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notipikasyon',
      'history': 'Kasaysayan',
      'today': 'Karong Adlawa',
      'upcoming': 'Umaabot',
      'no_collection_today': 'Walay koleksyon nga naka-iskedyul karon',
      'start_route': 'Sugdi ang Ruta',
      'good_morning': 'Maayong Buntag!',
      'good_afternoon': 'Maayong Hapon!',
      'good_evening': 'Maayong Gabii!',
      'search': 'Pangitaa',
      'logout': 'Log-out',
      'language': 'Pinulongan',
      'english': 'Ingles',
      'bisaya': 'Bisaya',
      'switch_to_bisaya': 'Ibalhin sa Bisaya',
      'switch_to_english': 'Ibalhin sa Ingles',
      'zone': 'Sona',
      'review_schedules':
          'Ribyuha ang mga iskedyul ug sunda ang mga protocol sa kaluwasan.',
      'collector_dashboard': 'Dashboard sa Kolektor',
      'live_scan': 'Live Scan',
      'switch_light_mode': 'Ibalhin sa light mode',
      'switch_dark_mode': 'Ibalhin sa dark mode',
      'route_started_updated':
          'Nagsugod na ang rota! {} ka koleksyon ang na-update.',
      'route_started_notifs':
          'Nagsugod na ang rota! gipadala ang mga notipikasyon.',
      'home': 'Balay',
      'feedback': 'Feedback',
      'scan': 'I-scan',
      'special': 'Espesyal',
      'alerts': 'Alerto',
      'mark_all_read': 'Markahi Tanan nga Nabasa na',
      'upcoming_collection': 'Umaabot nga Koleksyon',
      'collection_rescheduled': 'Ang Koleksyon Nausab ang Iskedyul',
      'date': 'Petsa',
      'time': 'Oras',
      'days': 'ka adlaw',
      'day': 'ka adlaw',
      'reason': 'Rason',
      'bin_location': 'Lokasyon sa Labayanan',
      'just_now': 'Karon pa lang',
      'minutes_ago': '{} ka minuto ang milabay',
      'hours_ago': '{} ka oras ang milabay',
      'days_ago': '{} ka adlaw ang milabay',
      'no_notifications':
          'Hapsay ang tanan! Walay mga notipikasyon niining panahona.',
      'collector_access': 'Collector Access',
      'welcome_back': 'Maayong Pagbalik',
      'authorized_personnel_only':
          'Para lamang sa awtorisadong personahe. Palihog pag-sign in aron maka-access sa imong dashboard.',
      'sign_in_to_manage': 'Sign in aron madumala ang imong EcoSched account',
      'email_address': 'Email Address',
      'security_password': 'Security Password',
      'stay_signed_in': 'Pabilin nga naka-sign in',
      'reset_password': 'I-reset ang Password?',
      'authenticating': 'Nag-authenticate...',
      'sign_in_to_dashboard': 'Sign In sa Dashboard',
      'enter_email': 'Palihog isulod ang imong narehistro nga email',
      'enter_password': 'Palihog isulod ang imong password',
      'password_short': 'Ang password kinahanglan labing menos 6 ka karakter',
      'welcome_back_ecosched': 'Maayong pagbalik sa EcoSched!',
      'login_failed': 'Napakyas ang pag-login. Palihog sulayi pag-usab.',
      'password_recovery_admin':
          'Ang pagbawi sa password kasamtangang gidumala sa mga admin.',
      'collector_incoming': 'Ang Kolektor Padulong Na! 🚚',
      'collection_starting_now': 'Nagsugod Na Ang Koleksyon 🚛',
    },
  };

  static String translate(String key, String locale, {List<String>? args}) {
    String translation = _localizedValues[locale]?[key] ?? key;
    if (args != null && args.isNotEmpty) {
      for (var arg in args) {
        translation = translation.replaceFirst('{}', arg);
      }
    }
    return translation;
  }

  static String translateStatic(String key,
      {String locale = 'ceb', List<String>? args}) {
    return translate(key, locale, args: args);
  }

  static String getBilingualText(String englishText) {
    // Try to find a key that matches the English text
    String? key;
    _localizedValues['en']?.forEach((k, v) {
      if (v.toLowerCase() == englishText.toLowerCase()) {
        key = k;
      }
    });

    if (key != null) {
      final bisaya = translateStatic(key!, locale: 'ceb');
      if (bisaya != englishText) {
        return '$englishText\n($bisaya)';
      }
    }

    // Fallback for common patterns if no exact key
    if (englishText.contains('rescheduled')) {
      return '$englishText\n(Ang koleksyon gi-usab ang iskedyul.)';
    }
    if (englishText.toLowerCase() == 'collection tomorrow') {
      return '$englishText\n(Koleksyon Ugma)';
    }
    if (englishText.toLowerCase() == 'collection today!') {
      return '$englishText\n(Koleksyon Karong Adlawa!)';
    }
    if (englishText.toLowerCase() == 'truck en route!') {
      return '$englishText\n(Ang Trak Padulong Na!)';
    }
    if (englishText.toLowerCase() == 'truck coming soon!') {
      return '$englishText\n(Ang Trak Moabot Na Sa Dili Madugay!)';
    }
    if (englishText.toLowerCase() == 'new collection scheduled!') {
      return '$englishText\n(Naka-iskedyul Na Ang Bag-ong Koleksyon!)';
    }
    if (englishText.toLowerCase().contains('starting now')) {
      return '$englishText\n(Nagsugod Na Ang Koleksyon karon.)';
    }
    if (englishText.toLowerCase().contains('incoming') ||
        englishText.toLowerCase().contains('on the way')) {
      return '$englishText\n(Ang kolektor padulong na sa inyong dapit.)';
    }

    if (englishText.contains('Prepare your garbage')) {
      return '$englishText\n(Andama inyong mga basura! Ugma mao ang adlaw sa koleksyon.)';
    }
    if (englishText.contains('Heads up! Your eco collection')) {
      return '$englishText\n(Pahibalo! Ang inyong eco collection naka-iskedyul karong adlawa.)';
    }
    if (englishText.contains('Truck is now starting')) {
      return '$englishText\n(Ang trak nagsugod na sa pagkolekta. Andama na inyong mga basura!)';
    }
    if (englishText.contains('scheduled in 2 hours')) {
      return '$englishText\n(Ang koleksyon naka-iskedyul sulod sa 2 ka oras.)';
    }
    if (englishText.contains('has been added')) {
      return '$englishText\n(Adunay bag-ong koleksyon nga gidugang.)';
    }

    if (englishText.contains('Approved')) {
      return '$englishText\n(Gi-aprobahan na ang imong account.)';
    }
    if (englishText.contains('Special Collection')) {
      return '$englishText\n(Adunay Bag-ong Espesyal nga Koleksyon.)';
    }

    return englishText;
  }
}

extension TranslationExtension on BuildContext {
  String tr(String key, {List<String>? args}) {
    final locale = LanguageProvider.of(this).currentLocale;
    return Translations.translate(key, locale, args: args);
  }
}
