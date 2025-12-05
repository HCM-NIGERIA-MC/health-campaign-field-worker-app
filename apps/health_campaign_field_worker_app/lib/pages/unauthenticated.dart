import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../widgets/tablet_to_phone_view_wrapper.dart';

@RoutePage()
class UnauthenticatedPageWrapper extends StatelessWidget {
  const UnauthenticatedPageWrapper({super.key});

  @override
  Widget build(BuildContext context) =>
      const TabletToPhoneViewWrapper(child: AutoRouter());
}
