// import "package:injectable/injectable.dart";
// import "package:shared_preferences/shared_preferences.dart";

// @lazySingleton
// class StorageService {
//   StorageService(this._prefs);

//   final SharedPreferences _prefs;

//   Future<void> saveString(String key, String value) async {
//     await _prefs.setString(key, value);
//   }

//   String? getString(String key) {
//     return _prefs.getString(key);
//   }

//   Future<void> remove(String key) async {
//     await _prefs.remove(key);
//   }
// }
