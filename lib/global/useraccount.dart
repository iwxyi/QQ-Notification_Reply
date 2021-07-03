class UserAccount {
	String nickname; // QQ昵称
	int qqId; // QQ ID
	int linkState; // 连接状态：0未连接，1已连接，-1已断开
	
	Map<int, String> friendNames = {};
	Map<int, String> groupNames = {};
	Map<int, Map<int, String>> groupMemberNames = {};
}
