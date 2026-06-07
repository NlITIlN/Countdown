import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/usage_store.dart';
import '../screens/analytics_screen.dart';

class AnalyticsSheet extends StatelessWidget {
  const AnalyticsSheet({
    super.key,
    required this.strings,
    required this.usageStore,
  });

  final S strings;
  final UsageStore usageStore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: AnalyticsScreen(
        strings: strings,
        usageStore: usageStore,
      ),
    );
  }
}
