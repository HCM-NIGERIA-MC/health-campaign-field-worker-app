import 'package:digit_data_model/models/entities/household_type.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/models/RadioButtonModel.dart';
import 'package:digit_ui_components/services/location_bloc.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/theme/spacers.dart';
import 'package:digit_ui_components/widgets/atoms/text_block.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:digit_ui_components/widgets/scrollable_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_campaign_field_worker_app/blocs/registration_delivery/custom_beneficairy_registration.dart';
import 'package:health_campaign_field_worker_app/utils/registration_delivery/utils_smc.dart';

import 'package:reactive_forms/reactive_forms.dart';
import 'package:registration_delivery/blocs/household_overview/household_overview.dart';

import '../../router/app_router.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_back_navigation.dart';
import '../../widgets/localized.dart';
import 'package:registration_delivery/utils/i18_key_constants.dart' as i18;
import '../../utils/i18_key_constants.dart' as i18_local;
import 'package:digit_components/widgets/atoms/digit_dropdown.dart' as dropdown;

enum CaregiverConsentEnum {
  yes,
  no,
}

@RoutePage()
class CustomInterventionPointPage extends LocalizedStatefulWidget {
  const CustomInterventionPointPage({
    super.key,
    super.appLocalizations,
  });

  @override
  State<CustomInterventionPointPage> createState() =>
      _CustomInterventionPointPageState();
}

class _CustomInterventionPointPageState
    extends LocalizedState<CustomInterventionPointPage> {
  static const _point = 'point';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    final router = context.router;

    return Scaffold(
      body: BlocBuilder<HouseholdOverviewBloc, HouseholdOverviewState>(
        builder: (context, state) {
          return ReactiveFormBuilder(
            form: () => buildForm(state),
            builder: (context, form, child) => ScrollableContent(
              enableFixedDigitButton: true,
              header: const Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: spacer2),
                    child: CustomBackNavigationHelpHeaderWidget(
                      showHelp: true,
                    ),
                  ),
                ],
              ),
              footer: DigitCard(
                  margin: const EdgeInsets.only(top: spacer2),
                  children: [
                    BlocBuilder<LocationBloc, LocationState>(
                      builder: (context, locationState) {
                        return DigitButton(
                          label: localizations
                              .translate(i18.common.coreCommonSubmit),
                          type: DigitButtonType.primary,
                          size: DigitButtonSize.large,
                          mainAxisSize: MainAxisSize.max,
                          onPressed: () {
                            //TODO: testing
                            final data = form.control(_point).value as String;
                            router.push(
                                CustomHouseHoldDetailsRoute(pointType: data));
                            //router.push(CustomInterventionPointRoute());
                          },
                        );
                      },
                    ),
                  ]),
              slivers: [
                SliverToBoxAdapter(
                  child: DigitCard(
                      margin: const EdgeInsets.all(spacer2),
                      children: [
                        DigitTextBlock(
                          padding: EdgeInsets.zero,
                          heading: localizations.translate(i18_local
                              .interventionPoint.pointInterventionHeaderLabel),
                          headingStyle: textTheme.headingXl
                              .copyWith(color: theme.colorTheme.text.primary),
                        ),
                        dropdown.DigitDropdown<String>(
                          label: localizations.translate(
                            i18_local.interventionPoint.pointLabelText,
                          ),
                          valueMapper: (value) =>
                              localizations.translate(value),
                          initialValue: form.control(_point).value,
                          menuItems: Constants.interventionPointList,
                          formControlName: _point,
                          isRequired: true,
                          validationMessages: {
                            'required': (_) => localizations.translate(
                                  i18.common.corecommonRequired,
                                ),
                          },
                          onChanged: (value) {
                            // if (value != null && value.isNotEmpty) {
                            //   form.control(_genderKey).value = value;
                            // } else {
                            //   form.control(_genderKey).value = null;
                            //   form.control(_genderKey).setErrors({'': true});
                            // }
                          },
                        ),
                      ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  FormGroup buildForm(HouseholdOverviewState statep) {
    final value = (statep.householdMemberWrapper.household?.additionalFields !=
            null)
        ? getInterventionType(
            statep.householdMemberWrapper.household!.additionalFields!.fields)
        : Constants.interventionPointList[0];
    return fb.group(<String, Object>{
      _point: FormControl<String>(value: value),
    });
  }
}
