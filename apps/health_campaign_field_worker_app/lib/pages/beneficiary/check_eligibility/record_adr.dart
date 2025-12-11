// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'package:digit_components/digit_components.dart';
import 'package:digit_components/utils/date_utils.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/services/location_bloc.dart' as location;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_radio_button/src/radio_button_builder.dart';
import 'package:group_radio_button/src/radio_group.dart';
import 'package:registration_delivery/blocs/household_overview/household_overview.dart';
import 'package:registration_delivery/blocs/search_households/search_households.dart';
import 'package:registration_delivery/blocs/side_effects/side_effects.dart';
import 'package:registration_delivery/models/entities/side_effect.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/utils/utils.dart';
import 'package:survey_form/survey_form.dart';

import '../../../models/entities/roles_type.dart';
import '../../../router/app_router.dart';
import '../../../utils/app_enums.dart';
import '../../../utils/i18_key_constants.dart' as i18_local;
import '../../../utils/utils.dart';
import '../../../widgets/custom_back_navigation.dart';
import '../../../widgets/localized.dart';

@RoutePage()
class RecordADRPage extends LocalizedStatefulWidget {
  final IndividualModel individual;
  final String? projectBeneficiaryClientReferenceId;
  final List<TaskModel> tasks;

  const RecordADRPage({
    super.key,
    super.appLocalizations,
    required this.individual,
    this.projectBeneficiaryClientReferenceId,
    required this.tasks,
  });

  @override
  State<RecordADRPage> createState() => _RecordADRPageState();
}

class _RecordADRPageState extends LocalizedState<RecordADRPage> {
  var submitTriggered = false;
  List<TextEditingController> controller = [];
  List<AttributesModel>? initialAttributes;
  ServiceDefinitionModel? selectedServiceDefinition;
  bool isControllersInitialized = false;
  List<int> visibleChecklistIndexes = [];
  GlobalKey<FormState> checklistFormKey = GlobalKey<FormState>();
  Map<String?, String> responses = {};

  @override
  void initState() {
    context
        .read<location.LocationBloc>()
        .add(const location.LocationEvent.load());
    context.read<ServiceBloc>().add(const ServiceSurveyFormEvent(
          value: '',
          submitTriggered: true,
        ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<location.LocationBloc, location.LocationState>(
        builder: (context, locationState) {
          return BlocBuilder<HouseholdOverviewBloc, HouseholdOverviewState>(
            builder: (context, householdOverviewState) {
              double? latitude = locationState.latitude;
              double? longitude = locationState.longitude;

              return BlocBuilder<ServiceDefinitionBloc, ServiceDefinitionState>(
                builder: (context, state) {
                  state.mapOrNull(
                    serviceDefinitionFetch: (value) {
                      final role = context.isCommunityDistributor
                          ? RolesType.communityDistributor.toValue()
                          : RolesType.healthFacilitySupervisor.toValue();

                      selectedServiceDefinition = value.serviceDefinitionList
                          .where(
                            (element) => element.code.toString().contains(
                                  '${context.selectedProject.name}.RECORD_ADR.$role',
                                ),
                          )
                          .toList()
                          .firstOrNull;
                      initialAttributes = selectedServiceDefinition?.attributes;

                      if (!isControllersInitialized) {
                        initialAttributes?.forEach((e) {
                          controller.add(TextEditingController());
                        });
                        isControllersInitialized = true;
                      }
                    },
                  );

                  return state.maybeMap(
                    orElse: () => Text(state.runtimeType.toString()),
                    serviceDefinitionFetch: (value) {
                      if (selectedServiceDefinition == null) {
                        return Center(
                          child: Text(
                            localizations.translate(
                              i18_local.checklist.noChecklistFound,
                            ),
                          ),
                        );
                      }

                      return ScrollableContent(
                        header: const Column(
                          children: [
                            CustomBackNavigationHelpHeaderWidget(
                              showHelp: false,
                            ),
                          ],
                        ),
                        enableFixedButton: true,
                        footer: DigitCard(
                          margin: const EdgeInsets.fromLTRB(0, kPadding, 0, 0),
                          padding: const EdgeInsets.fromLTRB(
                              kPadding, 0, kPadding, 0),
                          child: DigitElevatedButton(
                            onPressed: () async {
                              submitTriggered = true;
                              final isValid =
                                  checklistFormKey.currentState?.validate();
                              if (!isValid!) {
                                return;
                              }

                              final itemsAttributes = initialAttributes;

                              for (int i = 0; i < controller.length; i++) {
                                if (itemsAttributes?[i].required == true &&
                                    controller[i]
                                        .text
                                        .toString()
                                        .trim()
                                        .isEmpty) {
                                  return;
                                }
                              }

                              for (int i = 0; i < controller.length; i++) {
                                var attributeCode =
                                    '${initialAttributes?[i].code}';
                                var value = initialAttributes?[i].dataType !=
                                        'SingleValueList'
                                    ? controller[i]
                                            .text
                                            .toString()
                                            .trim()
                                            .isNotEmpty
                                        ? controller[i].text.toString()
                                        : (initialAttributes?[i].dataType !=
                                                'Number'
                                            ? ''
                                            : '0')
                                    : visibleChecklistIndexes.contains(i)
                                        ? controller[i].text.toString()
                                        : i18_local.checklist.notSelectedKey;
                                responses[attributeCode] = value;
                              }

                              final shouldSubmit = await DigitDialog.show(
                                context,
                                options: DigitDialogOptions(
                                  titleText: localizations.translate(
                                    i18_local
                                        .checklist.submitButtonDialogLabelText,
                                  ),
                                  content: Text(
                                    localizations.translate(
                                      i18_local
                                          .checklist.checklistDialogDescription,
                                    ),
                                  ),
                                  primaryAction: DigitDialogActions(
                                    label: localizations.translate(
                                      i18_local.checklist
                                          .checklistDialogPrimaryAction,
                                    ),
                                    action: (ctx) {
                                      final referenceId = IdGen.i.identifier;
                                      List<ServiceAttributesModel> attributes =
                                          [];

                                      for (int i = 0;
                                          i < controller.length;
                                          i++) {
                                        final attribute = initialAttributes;

                                        attributes.add(
                                          ServiceAttributesModel(
                                            auditDetails: AuditDetails(
                                              createdBy:
                                                  context.loggedInUserUuid,
                                              createdTime: context
                                                  .millisecondsSinceEpoch(),
                                            ),
                                            attributeCode:
                                                '${attribute?[i].code}',
                                            dataType: attribute?[i].dataType,
                                            clientReferenceId:
                                                IdGen.i.identifier,
                                            referenceId: referenceId,
                                            serviceClientReferenceId:
                                                referenceId,
                                            value: controller[i]
                                                    .text
                                                    .toString()
                                                    .trim()
                                                    .isNotEmpty
                                                ? controller[i].text.toString()
                                                : '',
                                            rowVersion: 1,
                                            tenantId: attribute?[i].tenantId,
                                            additionalFields:
                                                ServiceAttributesAdditionalFields(
                                              version: 1,
                                              fields: [
                                                AdditionalField(
                                                  'latitude',
                                                  latitude,
                                                ),
                                                AdditionalField(
                                                  'longitude',
                                                  longitude,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      context.read<ServiceBloc>().add(
                                            ServiceCreateEvent(
                                              serviceModel: ServiceModel(
                                                createdAt: DigitDateUtils
                                                    .getDateFromTimestamp(
                                                  DateTime.now()
                                                      .toLocal()
                                                      .millisecondsSinceEpoch,
                                                  dateFormat: Constants
                                                      .checklistViewDateFormat,
                                                ),
                                                tenantId:
                                                    selectedServiceDefinition!
                                                        .tenantId,
                                                clientId: referenceId,
                                                serviceDefId:
                                                    selectedServiceDefinition
                                                        ?.id,
                                                attributes: attributes,
                                                rowVersion: 1,
                                                accountId: context.projectId,
                                                auditDetails: AuditDetails(
                                                  createdBy:
                                                      context.loggedInUserUuid,
                                                  createdTime: DateTime.now()
                                                      .millisecondsSinceEpoch,
                                                ),
                                                clientAuditDetails:
                                                    ClientAuditDetails(
                                                  createdBy:
                                                      context.loggedInUserUuid,
                                                  createdTime: context
                                                      .millisecondsSinceEpoch(),
                                                  lastModifiedBy:
                                                      context.loggedInUserUuid,
                                                  lastModifiedTime: context
                                                      .millisecondsSinceEpoch(),
                                                ),
                                                additionalDetails: {
                                                  'boundaryCode':
                                                      context.boundary.code,
                                                },
                                                additionalFields:
                                                    ServiceAdditionalFields(
                                                  version: 1,
                                                  fields: [
                                                    AdditionalField(
                                                      'lng',
                                                      longitude,
                                                    ),
                                                    AdditionalField(
                                                      'lat',
                                                      latitude,
                                                    ),
                                                    AdditionalField(
                                                      'boundaryCode',
                                                      context.boundary.code,
                                                    ),
                                                    if (widget.individual
                                                            .clientReferenceId !=
                                                        null)
                                                      AdditionalField(
                                                        'relatedClientReferenceId',
                                                        widget.individual
                                                            .clientReferenceId,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );

                                      final q1Index =
                                          initialAttributes?.indexWhere((e) =>
                                                  e.code == 'CDD_ADR_Q1') ??
                                              -1;
                                      final List<String> symptoms = [];
                                      if (q1Index >= 0) {
                                        final q1Value = controller[q1Index]
                                            .text
                                            .toString()
                                            .trim();
                                        if (q1Value.isNotEmpty) {
                                          final parts = q1Value.split('.');
                                          for (final part in parts) {
                                            final symptom = part.trim();
                                            if (symptom.isNotEmpty) {
                                              symptoms.add(symptom);
                                            }
                                          }
                                        }
                                      }

                                      if (symptoms.isNotEmpty &&
                                          widget.tasks.isNotEmpty) {
                                        final lastTask = widget.tasks.last;
                                        final clientReferenceId =
                                            IdGen.i.identifier;

                                        final sideEffect = SideEffectModel(
                                          id: null,
                                          additionalFields:
                                              SideEffectAdditionalFields(
                                            version: 1,
                                            fields: [
                                              AdditionalField(
                                                'boundaryCode',
                                                RegistrationDeliverySingleton()
                                                    .boundary
                                                    ?.code,
                                              ),
                                            ],
                                          ),
                                          taskClientReferenceId:
                                              lastTask.clientReferenceId,
                                          projectBeneficiaryClientReferenceId:
                                              widget
                                                  .projectBeneficiaryClientReferenceId,
                                          projectId:
                                              RegistrationDeliverySingleton()
                                                  .projectId,
                                          symptoms: symptoms,
                                          clientReferenceId: clientReferenceId,
                                          tenantId:
                                              RegistrationDeliverySingleton()
                                                  .tenantId,
                                          rowVersion: 1,
                                          auditDetails: AuditDetails(
                                            createdBy:
                                                RegistrationDeliverySingleton()
                                                    .loggedInUserUuid!,
                                            createdTime: context
                                                .millisecondsSinceEpoch(),
                                            lastModifiedBy:
                                                RegistrationDeliverySingleton()
                                                    .loggedInUserUuid,
                                            lastModifiedTime: context
                                                .millisecondsSinceEpoch(),
                                          ),
                                          clientAuditDetails:
                                              ClientAuditDetails(
                                            createdBy:
                                                RegistrationDeliverySingleton()
                                                    .loggedInUserUuid!,
                                            createdTime: context
                                                .millisecondsSinceEpoch(),
                                            lastModifiedBy:
                                                RegistrationDeliverySingleton()
                                                    .loggedInUserUuid,
                                            lastModifiedTime: context
                                                .millisecondsSinceEpoch(),
                                          ),
                                        );

                                        context.read<SideEffectsBloc>().add(
                                              SideEffectsSubmitEvent(
                                                sideEffect,
                                                false,
                                              ),
                                            );
                                      }

                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop(true);
                                    },
                                  ),
                                  secondaryAction: DigitDialogActions(
                                    label: localizations.translate(
                                      i18_local.common.coreCommonCancel,
                                    ),
                                    action: (ctx) {
                                      Navigator.of(
                                        ctx,
                                        rootNavigator: true,
                                      ).pop(false);
                                    },
                                  ),
                                ),
                              );

                              if (shouldSubmit ?? false) {
                                final reloadState =
                                    context.read<HouseholdOverviewBloc>();
                                final searchBloc =
                                    context.read<SearchHouseholdsBloc>();
                                searchBloc.add(
                                  const SearchHouseholdsClearEvent(),
                                );

                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    reloadState.add(
                                      HouseholdOverviewReloadEvent(
                                        projectId: context.projectId,
                                        projectBeneficiaryType:
                                            context.beneficiaryType,
                                      ),
                                    );
                                  },
                                ).then(
                                  (value) => context.router.popAndPush(
                                    CustomHouseholdAcknowledgementRoute(
                                      enableViewHousehold: true,
                                      eligibilityAssessmentType:
                                          EligibilityAssessmentType.smc,
                                    ),
                                  ),
                                );

                                submitTriggered = true;
                                context.read<ServiceBloc>().add(
                                      const ServiceSurveyFormEvent(
                                        value: '',
                                        submitTriggered: true,
                                      ),
                                    );
                              }
                            },
                            child: Text(
                              localizations
                                  .translate(i18_local.common.coreCommonSubmit),
                            ),
                          ),
                        ),
                        children: [
                          Form(
                            key: checklistFormKey, //assigning key to form
                            child: DigitCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      localizations.translate(
                                        selectedServiceDefinition!.code
                                            .toString(),
                                      ),
                                      style: theme.textTheme.displayMedium,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  ...initialAttributes!.map((
                                    e,
                                  ) {
                                    int index =
                                        (initialAttributes ?? []).indexOf(e);

                                    return Column(children: [
                                      if (e.dataType == 'String' &&
                                          !(e.code ?? '').contains('.')) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 16.0, left: 8.0, right: 8.0),
                                          child: DigitTextField(
                                            autoValidation: AutovalidateMode
                                                .onUserInteraction,
                                            isRequired: true,
                                            controller: controller[index],
                                            validator: (value) {
                                              if (((value == null ||
                                                      value == '') &&
                                                  e.required == true)) {
                                                return localizations.translate(
                                                  i18_local.common
                                                      .corecommonRequired,
                                                );
                                              }
                                              if (e.regex != null) {
                                                return (RegExp(e.regex!)
                                                        .hasMatch(value!))
                                                    ? null
                                                    : localizations.translate(
                                                        "${e.code}_REGEX");
                                              }

                                              return null;
                                            },
                                            label: localizations.translate(
                                              '${selectedServiceDefinition?.code}.${e.code}',
                                            ),
                                          ),
                                        ),
                                      ] else if (e.dataType == 'Number' &&
                                          !(e.code ?? '').contains('.')) ...[
                                        DigitTextField(
                                          autoValidation: AutovalidateMode
                                              .onUserInteraction,
                                          textStyle:
                                              theme.textTheme.headlineMedium,
                                          textInputType: TextInputType.number,
                                          inputFormatter: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(
                                                "[0-9]",
                                              ),
                                            ),
                                          ],
                                          validator: (value) {
                                            if (((value == null ||
                                                    value == '') &&
                                                e.required == true)) {
                                              return localizations.translate(
                                                i18_local
                                                    .common.corecommonRequired,
                                              );
                                            }
                                            if (e.regex != null) {
                                              return (RegExp(e.regex!)
                                                      .hasMatch(value!))
                                                  ? null
                                                  : localizations.translate(
                                                      "${e.code}_REGEX");
                                            }

                                            return null;
                                          },
                                          controller: controller[index],
                                          label: '${localizations.translate(
                                                '${selectedServiceDefinition?.code}.${e.code}',
                                              ).trim()} ${e.required == true ? '*' : ''}',
                                        ),
                                      ] else if (e.dataType ==
                                              'MultiValueList' &&
                                          !(e.code ?? '').contains('.')) ...[
                                        DigitCard(
                                          child: Column(
                                            children: [
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        '${localizations.translate(
                                                          '${selectedServiceDefinition?.code}.${e.code}',
                                                        )} ${e.required == true ? '*' : ''}',
                                                        style: theme.textTheme
                                                            .headlineSmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              BlocBuilder<ServiceBloc,
                                                  ServiceState>(
                                                builder: (context, state) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 16.0,
                                                            top: 8.0),
                                                    child: Column(
                                                      children: e.values!
                                                          .map(
                                                            (e) =>
                                                                DigitCheckboxTile(
                                                              label:
                                                                  localizations
                                                                      .translate(
                                                                          e),
                                                              value: controller[
                                                                      index]
                                                                  .text
                                                                  .split('.')
                                                                  .contains(e),
                                                              onChanged:
                                                                  (value) {
                                                                setState(
                                                                  () {
                                                                    final String
                                                                        ele;
                                                                    var val = controller[
                                                                            index]
                                                                        .text
                                                                        .split(
                                                                            '.');
                                                                    if (val
                                                                        .contains(
                                                                            e)) {
                                                                      val.remove(
                                                                          e);
                                                                      ele = val
                                                                          .join(
                                                                              ".");
                                                                    } else {
                                                                      if (controller[
                                                                              index]
                                                                          .text
                                                                          .trim()
                                                                          .isEmpty) {
                                                                        ele =
                                                                            e; // first selection → "SYMPTOM1"
                                                                      } else {
                                                                        ele =
                                                                            "${controller[index].text}.$e"; // subsequent → "SYMPTOM1.SYMPTOM2"
                                                                      }
                                                                    }
                                                                    controller[index]
                                                                            .value =
                                                                        TextEditingController
                                                                            .fromValue(
                                                                      TextEditingValue(
                                                                        text:
                                                                            ele,
                                                                      ),
                                                                    ).value;
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else if (e.dataType ==
                                          'SingleValueList') ...[
                                        if (!(e.code ?? '').contains('.'))
                                          DigitCard(
                                            child: _buildChecklist(
                                              e,
                                              index,
                                              selectedServiceDefinition,
                                              context,
                                            ),
                                          ),
                                      ],
                                    ]);
                                  }),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChecklist(
    AttributesModel item,
    int index,
    ServiceDefinitionModel? selectedServiceDefinition,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    /* Check the data type of the attribute*/
    if (item.dataType == 'SingleValueList') {
      final childItems = getNextQuestions(
        item.code.toString(),
        initialAttributes ?? [],
      );
      List<int> excludedIndexes = [];

      // Ensure the current index is added to visible indexes and not excluded
      if (!visibleChecklistIndexes.contains(index) &&
          !excludedIndexes.contains(index)) {
        visibleChecklistIndexes.add(index);
      }

      // Determine excluded indexes
      for (int i = 0; i < (initialAttributes ?? []).length; i++) {
        if (!visibleChecklistIndexes.contains(i)) {
          excludedIndexes.add(i);
        }
      }

      return Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '${localizations.translate(
                  '${selectedServiceDefinition?.code}.${item.code}',
                )} ${item.required == true ? '*' : ''}',
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          Column(
            children: [
              BlocBuilder<ServiceBloc, ServiceState>(
                builder: (context, state) {
                  return RadioGroup<String>.builder(
                    groupValue: controller[index].text.trim(),
                    onChanged: (value) {
                      setState(() {
                        for (final matchingChildItem in childItems) {
                          final childIndex =
                              initialAttributes?.indexOf(matchingChildItem);
                          if (childIndex != null) {
                            visibleChecklistIndexes
                                .removeWhere((v) => v == childIndex);
                          }
                        }
                        controller[index].value =
                            TextEditingController.fromValue(
                          TextEditingValue(
                            text: value!,
                          ),
                        ).value;
                      });
                    },
                    items: item.values != null
                        ? item.values!
                            .where(
                                (e) => e != i18_local.checklist.notSelectedKey)
                            .toList()
                        : [],
                    itemBuilder: (item) => RadioButtonBuilder(
                      localizations.translate(
                        'CORE_COMMON_${item.trim().toUpperCase()}',
                      ),
                    ),
                  );
                },
              ),
              BlocBuilder<ServiceBloc, ServiceState>(
                builder: (context, state) {
                  final hasError = (item.required == true &&
                      controller[index].text.isEmpty &&
                      submitTriggered);

                  return Offstage(
                    offstage: !hasError,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        localizations.translate(
                          i18_local.common.corecommonRequired,
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (childItems.isNotEmpty &&
              controller[index].text.trim().isNotEmpty) ...[
            _buildNestedChecklists(
              item.code.toString(),
              index,
              controller[index].text.trim(),
              context,
            ),
          ],
        ],
      );
    } else if (item.dataType == 'String') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: DigitTextField(
          onChange: (value) {
            checklistFormKey.currentState?.validate();
          },
          isRequired: item.required ?? true,
          controller: controller[index],
          validator: (value) {
            if (((value == null || value == '') && item.required == true)) {
              return localizations.translate("${item.code}_REQUIRED");
            }
            if (item.regex != null) {
              return (RegExp(item.regex!).hasMatch(value!))
                  ? null
                  : localizations.translate("${item.code}_REGEX");
            }

            return null;
          },
          label: localizations.translate(
            '${selectedServiceDefinition?.code}.${item.code}',
          ),
        ),
      );
    } else if (item.dataType == 'Number') {
      return DigitTextField(
        autoValidation: AutovalidateMode.onUserInteraction,
        textStyle: theme.textTheme.headlineMedium,
        textInputType: TextInputType.number,
        inputFormatter: [
          FilteringTextInputFormatter.allow(RegExp(
            "[0-9]",
          )),
        ],
        validator: (value) {
          if (((value == null || value == '') && item.required == true)) {
            return localizations.translate(
              i18_local.common.corecommonRequired,
            );
          }
          if (item.regex != null) {
            return (RegExp(item.regex!).hasMatch(value!))
                ? null
                : localizations.translate("${item.code}_REGEX");
          }

          return null;
        },
        controller: controller[index],
        label: '${localizations.translate(
              '${selectedServiceDefinition?.code}.${item.code}',
            ).trim()} ${item.required == true ? '*' : ''}',
      );
    } else if (item.dataType == 'MultiValueList') {
      return Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    '${localizations.translate(
                      '${selectedServiceDefinition?.code}.${item.code}',
                    )} ${item.required == true ? '*' : ''}',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<ServiceBloc, ServiceState>(
            builder: (context, state) {
              return Column(
                children: item.values!
                    .map((e) => DigitCheckboxTile(
                          label: e,
                          value: controller[index].text.split('.').contains(e),
                          onChanged: (value) {
                            final String ele;
                            var val = controller[index].text.split('.');
                            if (val.contains(e)) {
                              val.remove(e);
                              ele = val.join(".");
                            } else {
                              ele = "${controller[index].text}.$e";
                            }
                            controller[index].value =
                                TextEditingController.fromValue(
                              TextEditingValue(
                                text: ele,
                              ),
                            ).value;
                          },
                        ))
                    .toList(),
              );
            },
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // Function to build nested checklists for child attributes
  Widget _buildNestedChecklists(
    String parentCode,
    int parentIndex,
    String parentControllerValue,
    BuildContext context,
  ) {
    // Retrieve child items for the given parent code
    final childItems = getNextQuestions(
      parentCode,
      initialAttributes ?? [],
    );

    return Column(
      children: [
        // Build cards for each matching child attribute
        for (final matchingChildItem in childItems.where((childItem) =>
            childItem.code!.startsWith('$parentCode.$parentControllerValue.')))
          Card(
            margin: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
            color: countDots(matchingChildItem.code ?? '') % 4 == 2
                ? const Color.fromRGBO(238, 238, 238, 1)
                : const DigitColors().white,
            child: _buildChecklist(
              matchingChildItem,
              initialAttributes?.indexOf(matchingChildItem) ??
                  parentIndex, // Pass parentIndex here as we're building at the same level
              selectedServiceDefinition,
              context,
            ),
          ),
      ],
    );
  }

  // Function to get the next questions (child attributes) based on a parent code
  List<AttributesModel> getNextQuestions(
    String parentCode,
    List<AttributesModel> checklistItems,
  ) {
    final childCodePrefix = '$parentCode.';
    final nextCheckLists = checklistItems.where((item) {
      return item.code!.startsWith(childCodePrefix) &&
          item.code?.split('.').length == parentCode.split('.').length + 2;
    }).toList();

    return nextCheckLists;
  }

  int countDots(String inputString) {
    int dotCount = 0;
    for (int i = 0; i < inputString.length; i++) {
      if (inputString[i] == '.') {
        dotCount++;
      }
    }

    return dotCount;
  }
}
