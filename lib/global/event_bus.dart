import 'package:event_bus/event_bus.dart';

EventBus eventBus = new EventBus();

enum Event {
  loginSuccess, // 账号密码登录成功（未获取到信息）
  loginInfo, // 登录成功后的信息
  loginOffline, // 断开连接
  logout, // 退出登录
  friendList,
  groupList,
  messageRaw, // 获取到消息本身
  refreshState, // 刷新界面
  groupMember, // 群成员
  messageRecall
}

class EventFn {
  Event event;
  dynamic data;

  EventFn(this.event, this.data);
}
