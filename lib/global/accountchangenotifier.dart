import 'package:flutter/cupertino.dart';
import 'package:qqnotificationreply/global/g.dart';

class AccountChangeNotifier extends ChangeNotifier {
	int get _qqId => G.ac.myId;
	
	@override
	void notifyListeners() {
		super.notifyListeners();
	}
}