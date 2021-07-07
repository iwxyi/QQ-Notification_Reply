class UserAccount {
	String nickname = ''; // QQ昵称
	int qqId = 0; // QQ ID
	int connectState = 0; // 连接状态：0未连接，1已连接，-1已断开
	
	Map<int, String> friendNames = {};
	Map<int, String> groupNames = {};
	Map<int, Map<int, String>> groupMemberNames = {};
	
	String selfInfo() => nickname + '(' + qqId.toString() + ')';
}
