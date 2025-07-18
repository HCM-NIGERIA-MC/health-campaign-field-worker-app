import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:digit_ui_components/enum/app_enums.dart';
import 'package:digit_ui_components/widgets/atoms/digit_button.dart';
import 'package:digit_ui_components/widgets/molecules/panel_cards.dart';
import 'package:flutter/material.dart';

import 'package:registration_delivery/router/registration_delivery_router.gm.dart';
import 'package:registration_delivery/utils/i18_key_constants.dart' as i18;
import 'package:registration_delivery/widgets/localized.dart';

import '../../../router/app_router.dart';
import '../../../utils/app_enums.dart';

@RoutePage()
class CustomSplashAcknowledgementPage extends LocalizedStatefulWidget {
  final EligibilityAssessmentType eligibilityAssessmentType;
  final bool? enableBackToSearch;
  const CustomSplashAcknowledgementPage({
    super.key,
    super.appLocalizations,
    this.enableBackToSearch,
    required this.eligibilityAssessmentType,
  });

  @override
  State<CustomSplashAcknowledgementPage> createState() =>
      CustomSplashAcknowledgementPageState();
}

class CustomSplashAcknowledgementPageState
    extends LocalizedState<CustomSplashAcknowledgementPage> {
  @override
  void initState() {
    super.initState();
    if (widget.enableBackToSearch == false) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          try {
            context.router.push(CustomDoseAdministeredRoute(
              eligibilityAssessmentType: widget.eligibilityAssessmentType,
            ));
          } catch (e) {
            rethrow;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PanelCard(
        type: PanelType.success,
        actions: [
          DigitButton(
            label: localizations
                .translate(i18.acknowledgementSuccess.actionLabelText),
            type: DigitButtonType.primary,
            size: DigitButtonSize.large,
            onPressed: () {
              context.router.maybePop();
            },
          ),
        ],
        description: localizations.translate(
          i18.acknowledgementSuccess.acknowledgementDescriptionText,
        ),
        title: localizations
            .translate(i18.acknowledgementSuccess.acknowledgementLabelText),
      ),
    );
  }
}
