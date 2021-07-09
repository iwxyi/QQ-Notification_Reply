import 'package:event_bus/event_bus.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class UserAccount {
	String nickname = ''; // QQ昵称
	int qqId = 0; // QQ ID
	int connectState = 0; // 连接状态：0未连接，1已连接，-1已断开
	
	Map<int, String> friendNames = {};
	Map<int, String> groupNames = {};
	Map<int, Map<int, String>> groupMemberNames = {};
	List<MsgBean> allMessages = [];
	
	EventBus eventBus = new EventBus(); // 事件总线
	
	String selfInfo() => nickname + ' (' + qqId.toString() + ')';
	
	MsgBean getMsgById(int msgId) {
		int index = allMessages.indexWhere((element) => element.messageId == msgId);
		if (index == -1) {
			print('未找到的MessageId: ' + msgId.toString());
			return null;
		}
		return allMessages[index];
	}
}
