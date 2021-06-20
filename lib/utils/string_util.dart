class StringUtil {
  static String toXml(String str, String tag) {
    return '<' + tag + '>' + str + '</' + tag + '>';
  }

  static String getXml(String str, String tag) {
    int left = str.indexOf('<' + tag + '>');
    if (left == -1) return '';
    int right = str.indexOf('</' + tag + '>');
    if (right == -1) return '';
    return str.substring(left + 2 + tag.length, right).trim();
  }
  
  static int getXmlInt(String str, String tag) {
    String text = getXml(str, tag);
    if (text.trim().isEmpty)
      return 0;
    return int.parse(text);
  }

  static String listToUrlParam(List<String> params) {
    String full = '';
    for (int i = 0; i < params.length; i++) {
      if (i % 2 == 0) {
        // 奇数项，名字
        if (i > 0) {
          full += '&';
        }
      } else {
        full += '=';
      }
      full += params[i];
    }
    return full;
  }
}
