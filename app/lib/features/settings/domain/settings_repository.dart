import 'app_settings.dart';

abstract interface class SettingsRepository {
  AppSettings read();
  Future<void> save(AppSettings settings);
}
