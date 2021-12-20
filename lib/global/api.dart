import 'package:qqnotificationreply/services/msgbean.dart';

class API {
  static String userHeader(int id) =>
      "http://q1.qlogo.cn/g?b=qq&nk=$id&s=100&t=";

  static String groupHeader(int id) => "http://p.qlogo.cn/gh/$id/$id/100";

  /// 如果是群组，则是群组头像；
  /// 如果是用户，则是好友头像
  static String chatObjHeader(MsgBean msg) {
    if (msg.isGroup()) {
      return groupHeader(msg.groupId);
    } else if (msg.isPrivate()) {
      return userHeader(msg.friendId);
    } else {
      return '';
    }
  }
}
