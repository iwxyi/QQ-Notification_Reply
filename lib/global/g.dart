import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'appruntime.dart';
import 'useraccount.dart';
import 'usersettings.dart';

class G {
  static String APP_NAME = "QQ通知回复"; // ignore: non_constant_identifier_names
  static String APP_VERSION = "0.0.1"; // ignore: non_constant_identifier_names

  static AppRuntime rt;
  static UserSettings st;
  static UserAccount ac;

  static Future init() async {
    // 需要权限
    //    rt = new AppRuntime(
    //        dataPath: (await getApplicationDocumentsDirectory()).path + '/data/',
    //        cachePath: (await getTemporaryDirectory()).path + '/',
    //        storagePath: (await getExternalStorageDirectory()).path + '/');
    rt = new AppRuntime(
        dataPath: '',
        cachePath: '',
        storagePath: '');
    st = new UserSettings(iniPath: rt.dataPath + 'settings.ini');
    ac = new UserAccount();
  }
}
