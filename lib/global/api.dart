import 'package:qqnotificationreply/services/msgbean.dart';

class API {
  static String userHeader(int id) =>
      "http://q1.qlogo.cn/g?b=qq&nk=$id&s=100&t=";

  static String groupHeader(int id) => "http://p.qlogo.cn/gh/$id/$id/100";

  static String header(MsgBean msg) {
    if (msg.isGroup()) {
      return groupHeader(msg.groupId);
    } else if (msg.isPrivate()) {
      return userHeader(msg.senderId);
    } else {
      return '';
    }
  }
}
