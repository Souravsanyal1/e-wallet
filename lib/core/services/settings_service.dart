import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  late SharedPreferences _prefs;

  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;
  final Rx<Locale> locale = const Locale('en', 'US').obs;

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString('theme_mode') ?? 'dark';
    if (savedTheme == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (savedTheme == 'system') {
      themeMode.value = ThemeMode.system;
    } else {
      themeMode.value = ThemeMode.dark;
    }

    final savedLang = _prefs.getString('language') ?? 'en';
    if (savedLang == 'bn') {
      locale.value = const Locale('bn', 'BD');
    } else {
      locale.value = const Locale('en', 'US');
    }
    return this;
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    _prefs.setString('theme_mode', mode.name);
  }

  void setLocale(Locale newLocale) {
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    _prefs.setString('language', newLocale.languageCode);
  }
}
