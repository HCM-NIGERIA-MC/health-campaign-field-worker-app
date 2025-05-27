import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:digit_components/digit_components.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration_delivery/blocs/app_localization.dart';
import 'package:registration_delivery/blocs/household_overview/household_overview.dart';
import 'package:registration_delivery/models/entities/project_beneficiary.dart';
import 'package:registration_delivery/models/entities/side_effect.dart';
import 'package:registration_delivery/models/entities/status.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/router/registration_delivery_router.gm.dart';
import 'package:registration_delivery/utils/i18_key_constants.dart' as i18;
import '../../blocs/localization/app_localization.dart';
import '../../models/entities/identifier_types.dart';
// import '../../utils/registration_delivery/utils_smc.dart';
//import 'package:registration_delivery/utils/utils.dart';
import '../../router/app_router.dart';
import '../../utils/app_enums.dart';
import '../../utils/registration_delivery/utils_smc.dart';
import '../../utils/utils.dart';
import '../action_card/action_card.dart';

import '../../utils/i18_key_constants.dart' as i18_local;

import '../../models/entities/additional_fields_type.dart'
    as additional_fields_local;
import '../../utils/extensions/extensions.dart';

class CustomMemberCard extends StatelessWidget {
  final List<ProductVariantModel> variant;
  final String name;
  final String? gender;
  final int? years;
  final int? months;
  final bool isHead;
  final IndividualModel individual;
  final List<ProjectBeneficiaryModel>? projectBeneficiaries;
  final bool isSMCDelivered;

  final VoidCallback setAsHeadAction;
  final VoidCallback editMemberAction;
  final VoidCallback deleteMemberAction;
  final RegistrationDeliveryLocalization localizations;
  final List<TaskModel>? tasks;
  final List<SideEffectModel>? sideEffects;
  final bool isNotEligibleSMC;

  final bool isBeneficiaryRefused;
  final bool isBeneficiaryIneligible;
  final bool isBeneficiaryReferred;
  final String? projectBeneficiaryClientReferenceId;

  const CustomMemberCard({
    super.key,
    required this.individual,
    required this.projectBeneficiaries,
    required this.name,
    this.gender,
    required this.years,
    this.isHead = false,
    this.months = 0,
    required this.localizations,
    required this.isSMCDelivered,
    required this.setAsHeadAction,
    required this.editMemberAction,
    required this.deleteMemberAction,
    this.tasks,
    this.isNotEligibleSMC = false,
    this.projectBeneficiaryClientReferenceId,
    this.isBeneficiaryRefused = false,
    this.isBeneficiaryIneligible = false,
    this.isBeneficiaryReferred = false,
    this.sideEffects,
    required this.variant,
  });

  List<TaskModel>? _getSMCStatusData() {
    return tasks
        ?.where((e) =>
            e.additionalFields?.fields.firstWhereOrNull(
              (element) =>
                  element.key ==
                      additional_fields_local.AdditionalFieldsType.deliveryType
                          .toValue() &&
                  element.value == EligibilityAssessmentStatus.smcDone.name,
            ) !=
            null)
        .toList();
  }

  Widget statusWidget(BuildContext context) {
    List<TaskModel>? smcTasks = _getSMCStatusData();

    bool isBeneficiaryReferredSMC =
        checkBeneficiaryReferredSMC(smcTasks, context.selectedCycle);

    bool isBeneficiaryInEligibleSMC =
        checkBeneficiaryInEligibleSMC(smcTasks, context.selectedCycle);

    final theme = Theme.of(context);
    if (isHead) {
      return Align(
        alignment: Alignment.centerLeft,
        child: DigitIconButton(
          icon: Icons.info_rounded,
          iconSize: 20,
          iconText: localizations.translate(i18_local
              .householdOverView.householdOverViewHouseholderHeadLabel),
          iconTextColor: theme.colorScheme.surfaceTint,
          iconColor: theme.colorScheme.surfaceTint,
        ),
      );
    }
    if ((isSMCDelivered ||
        //isVASDelivered ||
        isBeneficiaryReferredSMC ||
        // isBeneficiaryReferredVAS ||
        // isBeneficiaryInEligibleVAS ||
        isBeneficiaryInEligibleSMC)) {
      return Column(
        children: [
          if (isSMCDelivered ||
              isBeneficiaryReferredSMC ||
              isBeneficiaryInEligibleSMC)
            Align(
              alignment: Alignment.centerLeft,
              child: DigitIconButton(
                icon: Icons.check_circle,
                iconText: localizations.translate(
                  isBeneficiaryInEligibleSMC
                      ? i18.householdOverView
                          .householdOverViewNotEligibleIconLabel
                      : isBeneficiaryReferredSMC
                          ? i18_local.householdOverView
                              .householdOverViewBeneficiaryReferredSMCLabel
                          : i18_local.householdOverView
                              .householdOverViewSMCDeliveredIconLabel,
                ),
                iconSize: 20,
                iconTextColor:
                    (isBeneficiaryReferredSMC || isBeneficiaryInEligibleSMC)
                        ? DigitTheme.instance.colorScheme.error
                        : DigitTheme.instance.colorScheme.onSurfaceVariant,
                iconColor:
                    (isBeneficiaryReferredSMC || isBeneficiaryInEligibleSMC)
                        ? DigitTheme.instance.colorScheme.error
                        : DigitTheme.instance.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    } else if (isNotEligibleSMC || isBeneficiaryIneligible) {
      return Column(
        children: [
          if (isHead || isNotEligibleSMC || isBeneficiaryIneligible)
            Align(
              alignment: Alignment.centerLeft,
              child: DigitIconButton(
                icon: Icons.info_rounded,
                iconSize: 20,
                iconText: localizations.translate(
                    (isNotEligibleSMC || isBeneficiaryIneligible)
                        ? i18.householdOverView
                            .householdOverViewNotEligibleIconLabel
                        : ""),
                iconTextColor: theme.colorScheme.error,
                iconColor: theme.colorScheme.error,
              ),
            ),
          // if (isBeneficiaryReferredSMC || isBeneficiaryReferredVAS)
          //   Align(
          //     alignment: Alignment.centerLeft,
          //     child: DigitIconButton(
          //       icon: Icons.info_rounded,
          //       iconSize: 20,
          //       iconText: localizations.translate(
          //         isBeneficiaryReferredSMC || isBeneficiaryReferredVAS
          //             ? isBeneficiaryReferredSMC
          //                 ? (i18_local.householdOverView
          //                     .householdOverViewBeneficiaryReferredSMCLabel)
          //                 : (i18_local.householdOverView
          //                     .householdOverViewBeneficiaryReferredVACLabel)
          //             : isBeneficiaryRefused
          //                 ? Status.beneficiaryRefused.toValue()
          //                 : Status.notVisited.toValue(),
          //       ),
          //       iconTextColor: theme.colorScheme.error,
          //       iconColor: theme.colorScheme.error,
          //     ),
          //   ),
        ],
      );
    } else if (isBeneficiaryRefused) {
      return Align(
          alignment: Alignment.centerLeft,
          child: DigitIconButton(
            icon: Icons.info_rounded,
            iconSize: 20,
            iconText:
                localizations.translate(Status.beneficiaryRefused.toValue()),
            iconTextColor: theme.colorScheme.error,
            iconColor: theme.colorScheme.error,
          ));
    } else {
      return Container();
    }
  }

  Widget actionButton(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    List<TaskModel>? smcTasks = _getSMCStatusData();

    final doseStatus =  checkStatusSMC(smcTasks, context.selectedCycle);
    bool smcAssessmentPendingStatus =
        assessmentSMCPending(smcTasks, context.selectedCycle);

    bool isBeneficiaryReferredSMC =
        checkBeneficiaryReferredSMC(smcTasks, context.selectedCycle);

    bool isBeneficiaryInEligibleSMC =
        checkBeneficiaryInEligibleSMC(smcTasks, context.selectedCycle);

    final redosePendingStatus = smcAssessmentPendingStatus
        ? true
        : redosePending(smcTasks, context.selectedCycle);
    if ((isNotEligibleSMC || isBeneficiaryIneligible) && !doseStatus) {
      return const Offstage();
    }
    if (isNotEligibleSMC || (!redosePendingStatus)) {
      return const Offstage();
    }
    return Column(
      children: [
        if (smcAssessmentPendingStatus &&
            !isBeneficiaryReferredSMC &&
            !isBeneficiaryInEligibleSMC)
          DigitElevatedButton(
            child: Center(
              child: Text(
                localizations.translate(
                  i18_local.householdOverView
                      .householdOverViewSMCAssessmentActionText,
                ),
                style: textTheme.headingM.copyWith(color: Colors.white),
              ),
            ),
            onPressed: () async {
              final bloc = context.read<HouseholdOverviewBloc>();
              bloc.add(
                HouseholdOverviewEvent.selectedIndividual(
                  individualModel: individual,
                ),
              );

              context.router.push(
                EligibilityChecklistViewRoute(
                  projectBeneficiaryClientReferenceId:
                      projectBeneficiaryClientReferenceId,
                  individual: individual,
                  eligibilityAssessmentType: EligibilityAssessmentType.smc,
                ),
              );
            },
          ),
        if ((!smcAssessmentPendingStatus) && redosePendingStatus)
          DigitElevatedButton(
            child: Center(
              child: Text(
                localizations.translate(
                  i18_local.householdOverView.householdOverViewRedoseActionText,
                ),
                style: textTheme.headingM.copyWith(color: Colors.white),
              ),
            ),
            onPressed: () async {
              final bloc = context.read<HouseholdOverviewBloc>();
              bloc.add(
                HouseholdOverviewEvent.selectedIndividual(
                  individualModel: individual,
                ),
              );

              if ((smcTasks ?? []).isNotEmpty) {
                TaskModel? successfulTask = smcTasks
                    ?.where(
                      (element) =>
                          element.status ==
                          Status.administeredSuccess.toValue(),
                    )
                    .lastOrNull;
                if (redosePendingStatus) {
                  final spaq1 = context.spaq1;
                  final spaq2 = context.spaq2;

                  int doseCount = double.parse(
                    successfulTask?.resources?.first.quantity ?? "0",
                  ).round();

                  final value = variant
                      .firstWhere(
                        (element) =>
                            element.id ==
                            successfulTask!.resources!.first.productVariantId,
                      )
                      .sku;

                  if (successfulTask != null &&
                      value != null &&
                      ((value.contains(
                                Constants.spaq1,
                              ) &&
                              spaq1 > 0) ||
                          (value.contains(
                                Constants.spaq2,
                              ) &&
                              spaq2 > 0))) {
                    context.router.push(
                      RecordRedoseRoute(
                        tasks: [successfulTask],
                      ),
                    );
                  } else {
                    DigitDialog.show(
                      context,
                      options: DigitDialogOptions(
                        titleText: localizations.translate(
                          i18_local.beneficiaryDetails.insufficientStockHeading,
                        ),
                        titleIcon: Icon(
                          Icons.warning,
                          color: DigitTheme.instance.colorScheme.error,
                        ),
                        contentText: (value == Constants.spaq1)
                            ? "${localizations.translate(
                                i18_local.beneficiaryDetails
                                    .insufficientAZTStockMessageDelivery,
                              )} \n ${localizations.translate(
                                i18_local.beneficiaryDetails.spaq1DoseUnit,
                              )}"
                            : "${localizations.translate(
                                i18_local.beneficiaryDetails
                                    .insufficientAZTStockMessageDelivery,
                              )} \n ${localizations.translate(
                                i18_local.beneficiaryDetails.spaq2DoseUnit,
                              )}",
                        primaryAction: DigitDialogActions(
                          label: localizations.translate(i18_local
                              .beneficiaryDetails.backToHouseholdDetails),
                          action: (ctx) {
                            Navigator.of(
                              ctx,
                              rootNavigator: true,
                            ).pop();
                          },
                        ),
                      ),
                    );
                  }
                }
              }
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final beneficiaryType = context.beneficiaryType;

    return Container(
      decoration: BoxDecoration(
        color: DigitTheme.instance.colorScheme.background,
        border: Border.all(
          color: DigitTheme.instance.colorScheme.outline,
          width: 1,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(4.0),
        ),
      ),
      margin: DigitTheme.instance.containerMargin,
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  individual.identifiers != null
                      ? Padding(
                          padding: const EdgeInsets.all(kPadding),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: DigitTheme.instance.colorScheme.primary,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(kPadding),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                kPadding,
                              ),
                              child: Text(
                                individual.identifiers!
                                        .lastWhere(
                                          (e) =>
                                              e.identifierType ==
                                              IdentifierTypes
                                                  .uniqueBeneficiaryID
                                                  .toValue(),
                                        )
                                        .identifierId ??
                                    localizations
                                        .translate(i18.common.noResultsFound),
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                          ),
                        )
                      : const Offstage(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 1.8,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: kPadding,
                            top: kPadding,
                          ),
                          child: Text(
                            name,
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ((tasks ?? [])
                              .where(
                                (element) =>
                                    element.status ==
                                    Status.administeredSuccess.toValue(),
                              )
                              .lastOrNull ==
                          null &&
                      !isSMCDelivered &&
                      !isBeneficiaryIneligible &&
                      !isBeneficiaryReferred)
                  ? Positioned(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: DigitIconButton(
                          onPressed: () => DigitActionDialog.show(
                            context,
                            widget: ActionCard(
                              items: [
                                ActionCardModel(
                                  icon: Icons.edit,
                                  label: localizations.translate(
                                    i18.memberCard.editIndividualDetails,
                                  ),
                                  action: editMemberAction,
                                ),
                              ],
                            ),
                          ),
                          iconText: localizations.translate(
                            i18.memberCard.editDetails,
                          ),
                          icon: Icons.edit,
                        ),
                      ),
                    )
                  : const Offstage(),
            ],
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: DigitTheme.instance.containerMargin,
                  child: Text(
                    gender != null
                        ? localizations
                            .translate('CORE_COMMON_${gender?.toUpperCase()}')
                        : ' - ',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    " | $years ${localizations.translate(i18.memberCard.deliverDetailsYearText)} $months ${localizations.translate(i18.memberCard.deliverDetailsMonthsText)}",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: kPadding / 2,
            ),
            child: Offstage(
              offstage: beneficiaryType != BeneficiaryType.individual,
              child: statusWidget(context),
            ),
          ),
          Offstage(
            offstage: beneficiaryType != BeneficiaryType.individual,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: isHead
                  ? const Column(
                      children: [],
                    )
                  : Column(
                      children: [
                        actionButton(context),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
