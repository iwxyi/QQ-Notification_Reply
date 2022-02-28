import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/utils/string_util.dart';
import 'package:url_launcher/url_launcher.dart';

import 'msgbean.dart';

class NotificationController {
  static void initializeNotificationsPlugin() {
    AwesomeNotifications().initialize(
      'resource://drawable/notification_icon',
      [
        NotificationChannel(
            channelKey: 'app_notification',
            channelName: '程序通知',
            channelDescription: '程序消息',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white),
        NotificationChannel(
            channelKey: 'notices',
            channelName: '交互通知',
            channelDescription: '交互消息',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white),
        NotificationChannel(
            channelKey: 'private_chats',
            channelName: '私聊通知',
            channelDescription: '私聊消息',
            channelShowBadge: true,
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white),
        NotificationChannel(
            channelKey: 'special_chats',
            channelName: '特别关注通知',
            channelDescription: '特别关注的好友消息',
            channelShowBadge: true,
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.green,
            importance: NotificationImportance.High),
        NotificationChannel(
            channelKey: 'normal_group_chats',
            channelName: '普通群组通知',
            channelDescription: '普通群组消息',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white),
        NotificationChannel(
            channelKey: 'important_group_chats',
            channelName: '重要群组通知',
            channelDescription: '标为重要的群组消息、@与回复自己的消息',
            channelShowBadge: true,
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.green,
            importance: NotificationImportance.High),
      ],
    );
  }

  /// Use this method to detect when a new notification or a schedule is created
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect every time that a new notification is displayed
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect if the user dismissed a notification
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // 同步移除未读消息
    if (G.st.removeUnreadOnDismissNotification) {
      int keyId = int.parse(receivedAction.payload['id']);
      G.ac.unreadMessageCount.remove(keyId);
    }
    // 取消 badge
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    int keyId = int.parse(receivedAction.payload['id']);
    print(
        'notification action: chatId=$keyId, keyButton=${receivedAction.buttonKeyPressed}, keyInput=${receivedAction.buttonKeyInput}');
    if (StringUtil.isNotEmpty(receivedAction.buttonKeyInput)) {
      // 输入
      onNotificationReply(keyId, receivedAction.buttonKeyInput);
    } else if (StringUtil.isNotEmpty(receivedAction.buttonKeyPressed)) {
      int groupId = -keyId;
      GroupInfo group = G.ac.groupList[groupId];
      // 点击动作按钮（输入也会触发）
      switch (receivedAction.buttonKeyPressed) {
        case 'CLOSE_SMART_FOCUS':
          // 关闭智能聚焦
          print('关闭智能聚焦：$groupId');
          group.focusAsk = false;
          group.focusAt = null;
          break;
        case 'CLOSE_DYNAMIC_IMPORTANCE':
          // 关闭动态重要性
          print('关闭动态重要性：$keyId');
          G.ac.messageMyTimes.remove(keyId);
          break;
      }
    } else {
      // 点击通知本身
      print('点击通知');
      onSelectNotification(keyId);
    }
  }

  static Future<void> receiveButtonInputText(
      ReceivedAction receivedAction) async {
    print('Input Button Message: "${receivedAction.buttonKeyInput}"');
  }

  /// 通知栏回复
  static void onNotificationReply(int keyId, String text) {
    MsgBean msg;
    if (G.ac.allMessages.containsKey(keyId))
      msg = G.ac.allMessages[keyId].last ?? null;
    if (msg == null) {
      print('未找到payload:$keyId');
      return;
    }

    G.cs.sendMsg(msg, text);
  }

  /// 点击通知
  static Future<dynamic> onSelectNotification(int keyId) async {
    MsgBean msg;
    if (G.ac.allMessages.containsKey(keyId))
      msg = G.ac.allMessages[keyId].last ?? null;
    if (msg == null) {
      print('未找到payload:$keyId');
      return;
    }

    G.ac.clearUnread(msg);

    // 打开会话
    if (!G.st.notificationLaunchQQ) {
      // 后台通知打开的聊天界面，则在左上角显示一个叉，直接退出程序
      G.rt.showChatPage(msg, directlyClose: !G.rt.runOnForeground);
    } else {
      String url;
      // android 和 ios 的 QQ 启动 url scheme 是不同的
      if (msg.isPrivate()) {
        url = 'mqq://im/chat?chat_type=wpa&uin=' +
            msg.friendId.toString() +
            '&version=1&src_type=web';
        // &web_src=qq.com
      } else {
        url = 'mqq://im/chat?chat_type=group&uin=' +
            msg.groupId.toString() +
            '&version=1&src_type=web';
      }
      //      G.ac.unreadMessages[msg.keyId()].clear();

      // 打开我的资料卡：mqqapi://card/show_pslcard?src_type=internal&source=sharecard&version=1&uin=1600631528
      // QQ群资料卡：mqqapi://card/show_pslcard?src_type=internal&version=1&card_type=group&source=qrcode&uin=123456

      if (url == null || url.isEmpty) {
        print('没有可打开URL');
        return;
      }

      // 确认一下url是否可启动
      const forceTry = true;
      if (await canLaunch(url) || forceTry) {
        print('打开URL: ' + url);
        try {
          await launch(url); // 启动QQ
        } catch (e) {
          print('打开URL失败：' + e.toString());
          Fluttertoast.showToast(
            msg: "打开URL失败：" + url,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
          );
        }
      } else {
        // 自己封装的一个 Toast
        print('无法打开URL: ' + url);
        Fluttertoast.showToast(
          msg: "无法打开URL：" + url,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
        );
      }
    }
  }

  static Future<void> receiveStandardNotificationAction(
      ReceivedAction receivedAction) async {}

  static Future<void> receiveMediaNotificationAction(
      ReceivedAction receivedAction) async {}

  static Future<void> receiveChatNotificationAction(
      ReceivedAction receivedAction) async {}

  static Future<void> receiveAlarmNotificationAction(
      ReceivedAction receivedAction) async {}

  static Future<void> receiveCallNotificationAction(
      ReceivedAction receivedAction) async {}
}
