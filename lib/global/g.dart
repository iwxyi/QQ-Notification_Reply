import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appruntime.dart';
import 'useraccount.dart';
import 'usersettings.dart';

class G {
  static String APP_NAME = "QQ通知回复"; // ignore: non_constant_identifier_names
  static String APP_VERSION = "0.0.1"; // ignore: non_constant_identifier_names

  static AppRuntime rt;
  static UserSettings st;
  static UserAccount ac;

  static SharedPreferences _prefs;

  static bool get isRelease =>
      bool.fromEnvironment("dart.vm.product"); // 是否是release版

  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
    var _profile = _prefs.getString("profile");
    if (_profile != null) {
      try {} catch (e) {
        print(e);
      }

      rt = new AppRuntime(
          dataPath: (await getApplicationDocumentsDirectory()).path + '/data/',
          cachePath: (await getTemporaryDirectory()).path + '/',
          storagePath: (await getExternalStorageDirectory()).path + '/');
      print('data path: ' + rt.dataPath);
      st = new UserSettings(iniPath: rt.dataPath + 'settings.ini');
      ac = new UserAccount();
    }
  }
}
