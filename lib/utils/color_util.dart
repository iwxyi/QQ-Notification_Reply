import 'dart:math';

import 'package:flutter/widgets.dart';

class ColorUtil {
  /// 修改明度，0.0 ~ 1.0
  static Color modifyLight(Color c, double delta) {
    final hslColor = HSLColor.fromColor(c);
    final lightness = max(min(hslColor.lightness + delta, 1.0), 0.0);
    return hslColor.withLightness(lightness).toColor();
  }

  /// 修改明度，0.0 ~ 1.0
  static Color rangeLight(Color c, double mini, double maxi) {
    final hslColor = HSLColor.fromColor(c);
    final lightness = max(min(hslColor.lightness, maxi), mini);
    return hslColor.withLightness(lightness).toColor();
  }

  static Color fixedLight(Color c, double light) {
    final hslColor = HSLColor.fromColor(c);
    return hslColor.withLightness(light).toColor();
  }
}
