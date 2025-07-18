import 'package:auto_route/auto_route.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/widgets/atoms/digit_action_card.dart';
import 'package:digit_ui_components/widgets/atoms/menu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:survey_form/survey_form.dart';

import 'package:survey_form/router/survey_form_router.gm.dart';
import 'package:survey_form/utils/constants.dart';
import 'package:survey_form/utils/i18_key_constants.dart' as i18;
import 'package:survey_form/widgets/back_navigation_help_header.dart';
import 'package:survey_form/widgets/localized.dart';
import 'package:survey_form/widgets/no_result_card.dart';

import '../../router/app_router.dart';

@RoutePage()
class CustomSurveyformPage extends LocalizedStatefulWidget {
  const CustomSurveyformPage({
    Key? key,
    super.appLocalizations,
  }) : super(key: key);

  @override
  State<CustomSurveyformPage> createState() => CustomSurveyFormPageState();
}

class CustomSurveyFormPageState extends State<CustomSurveyformPage> {
  ServiceDefinitionModel? selectedServiceDefinition;

  @override
  Widget build(BuildContext context) {
    final localizations = SurveyFormLocalization.of(context);

    return Scaffold(
      body: ScrollableContent(
        header: const Column(children: [
          BackNavigationHelpHeaderWidget(),
        ]),
        children: [
          BlocBuilder<ServiceDefinitionBloc, ServiceDefinitionState>(
            builder: (context, state) {
              return state.map(
                empty: (value) => Text(
                  localizations.translate(
                    i18.surveyForm.noSurveyFormFound,
                  ),
                ),
                isloading: (value) => const Center(
                  child: CircularProgressIndicator(),
                ),
                serviceDefinitionFetch:
                    (ServiceDefinitionServiceFetchedState value) {
                  final values = value.serviceDefinitionList.where((item) =>
                      !SurveyFormSingleton()
                          .roles
                          .indexOf(
                            item.code!.split('.').lastOrNull!,
                          )
                          .isNegative &&
                      !item.code!
                          .contains(Constants.healthFacilitySurveyFormPrefix) &&
                      !item.code!.contains(Constants.iecSurveyFormPrefix) &&
                      !item.code!
                          .contains(Constants.eligibilitySurveyFormPrefix) &&
                      (item.code ?? '')
                          .contains(SurveyFormSingleton().projectName));

                  if (values.isEmpty) {
                    return Column(
                      children: [
                        NoResultCard(
                          align: Alignment.center,
                          label: localizations.translate(
                            i18.common.noResultsFound,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: values
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(
                                  left: spacer4, right: spacer4, top: spacer4),
                              child: MenuCard(
                                icon: Icons.article,
                                heading: localizations.translate('${e.code}'),
                                onTap: () {
                                  context
                                      .read<ServiceDefinitionBloc>()
                                      .add(ServiceDefinitionSelectionEvent(
                                        serviceDefinition: e,
                                      ));

                                  showDialog(
                                    context: context,
                                    builder: (ctx) => DigitActionCard(
                                      onOutsideTap: () {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop();
                                      },
                                      actions: [
                                        DigitButton(
                                          label: localizations.translate(i18
                                              .surveyForm
                                              .surveyFormCreateActionLabel),
                                          onPressed: () {
                                            context.router.push(
                                              CustomSurveyFormBoundaryViewRoute(),
                                            );
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pop();
                                          },
                                          type: DigitButtonType.secondary,
                                          size: DigitButtonSize.large,
                                          prefixIcon: Icons.edit_calendar,
                                        ),
                                        DigitButton(
                                          label: localizations.translate(i18
                                              .surveyForm
                                              .surveyFormViewActionLabel),
                                          onPressed: () {
                                            context.read<ServiceBloc>().add(
                                                  ServiceSearchEvent(
                                                    serviceSearchModel:
                                                        ServiceSearchModel(
                                                      id: e.id,
                                                    ),
                                                  ),
                                                );
                                            context.router.push(
                                              CustomSurveyFormPreviewRoute(),
                                            );
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pop();
                                          },
                                          type: DigitButtonType.secondary,
                                          size: DigitButtonSize.large,
                                          prefixIcon: Icons.visibility,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ))
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
