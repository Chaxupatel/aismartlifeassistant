import 'package:flutter_riverpod/flutter_riverpod.dart';

bool adsEnabled = false;

class AdsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  set state(bool value) => super.state = value;
}

final adsEnabledProvider = NotifierProvider<AdsEnabledNotifier, bool>(AdsEnabledNotifier.new);
