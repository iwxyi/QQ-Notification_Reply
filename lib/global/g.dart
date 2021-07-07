import 'package:path_provider/path_provider.dart';
import 'package:qqnotificationreply/services/cqhttpservice.dart';

import 'appruntime.dart';
import 'useraccount.dart';
import 'usersettings.dart';

class G {
  static String APP_NAME = "QQ通知回复"; // ignore: non_constant_identifier_names
  static String APP_VERSION = "0.0.1"; // ignore: non_constant_identifier_names

  static AppRuntime rt;
  static UserSettings st;
  static UserAccount ac;
  static CqhttpService cs;

  static bool get isRelease =>
      bool.fromEnvironment("dart.vm.product"); // 是否是release版

  static Future<String> init() async {
    if (rt != null) return 'OK';
    ac = new UserAccount();
    rt = new AppRuntime(
        dataPath: (await getApplicationDocumentsDirectory()).path + '/data/',
        cachePath: (await getTemporaryDirectory()).path + '/',
        storagePath: (await getExternalStorageDirectory()).path + '/');
    st = new UserSettings(iniPath: rt.dataPath + 'settings.ini');
    cs = new CqhttpService(rt: rt, st: st);
    return 'init successed';
  }
}
