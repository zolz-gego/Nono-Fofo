import 'package:flutter/widgets.dart';

/// Phones have a short side under 600 logical px (tablets and computers are
/// bigger), in either orientation.
bool isPhone(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide < 600;
