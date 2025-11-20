import 'package:digit_components/widgets/atoms/digit_toaster.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/models/RadioButtonModel.dart';
import 'package:digit_ui_components/services/location_bloc.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/widgets/atoms/pop_up_card.dart';
import 'package:digit_ui_components/widgets/atoms/text_block.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/custom_back_navigation.dart';

import 'package:registration_delivery/models/entities/household.dart';
import 'package:registration_delivery/router/registration_delivery_router.gm.dart';
import 'package:registration_delivery/utils/i18_key_constants.dart' as i18;
import 'package:registration_delivery/utils/utils.dart';
import 'package:registration_delivery/widgets/localized.dart';

import '../../blocs/registration_delivery/custom_beneficairy_registration.dart';
import '../../router/app_router.dart';
import '../../utils/extensions/extensions.dart';
import '../../utils/i18_key_constants.dart' as i18_local;
import 'custom_beneficiary_acknowledgement.dart';

enum CaregiverConsentEnum {
  yes,
  no,
}

@RoutePage()
class CaregiverConsentPage extends LocalizedStatefulWidget {
  const CaregiverConsentPage({
    super.key,
    super.appLocalizations,
  });

  @override
  State<CaregiverConsentPage> createState() => CaregiverConsentPageState();
}

class CaregiverConsentPageState extends LocalizedState<CaregiverConsentPage> {
  CaregiverConsentEnum? selectedConsent = null;
  final clickedStatus = ValueNotifier<bool>(false);
  TextEditingController consentComment = TextEditingController();
  String? commentErrorText;

  onSubmit(HouseholdModel? householdModel, AddressModel? addressModel) async {
    final bloc = context.read<CustomBeneficiaryRegistrationBloc>();
    final router = context.router;
    var household = householdModel;

    household ??= HouseholdModel(
      tenantId: RegistrationDeliverySingleton().tenantId,
      clientReferenceId:
          householdModel?.clientReferenceId ?? IdGen.i.identifier,
      rowVersion: 1,
      clientAuditDetails: ClientAuditDetails(
        createdBy: RegistrationDeliverySingleton().loggedInUserUuid!,
        createdTime: context.millisecondsSinceEpoch(),
        lastModifiedBy: RegistrationDeliverySingleton().loggedInUserUuid,
        lastModifiedTime: context.millisecondsSinceEpoch(),
      ),
      auditDetails: AuditDetails(
        createdBy: RegistrationDeliverySingleton().loggedInUserUuid!,
        createdTime: context.millisecondsSinceEpoch(),
        lastModifiedBy: RegistrationDeliverySingleton().loggedInUserUuid,
        lastModifiedTime: context.millisecondsSinceEpoch(),
      ),
    );

    household = household.copyWith(
        rowVersion: 1,
        tenantId: RegistrationDeliverySingleton().tenantId,
        clientReferenceId:
            householdModel?.clientReferenceId ?? IdGen.i.identifier,
        memberCount: 1,
        clientAuditDetails: ClientAuditDetails(
          createdBy:
              RegistrationDeliverySingleton().loggedInUserUuid.toString(),
          createdTime: context.millisecondsSinceEpoch(),
          lastModifiedBy:
              RegistrationDeliverySingleton().loggedInUserUuid.toString(),
          lastModifiedTime: context.millisecondsSinceEpoch(),
        ),
        auditDetails: AuditDetails(
          createdBy:
              RegistrationDeliverySingleton().loggedInUserUuid.toString(),
          createdTime: context.millisecondsSinceEpoch(),
          lastModifiedBy:
              RegistrationDeliverySingleton().loggedInUserUuid.toString(),
          lastModifiedTime: context.millisecondsSinceEpoch(),
        ),
        address: addressModel,
        additionalFields: HouseholdAdditionalFields(version: 1, fields: [
          const AdditionalField(
            "caregiver_consent_registration",
            false,
          ),
          AdditionalField(
            "caregiver_consent_comment",
            consentComment.text,
          ),
        ]));

    bloc.add(
      BeneficiaryRegistrationCreateHouseholdEvent(
        household: household,
        registrationDate: DateTime.now(),
        boundary: RegistrationDeliverySingleton().boundary!,
      ),
    );
    router.popUntil(
        (route) => route.settings.name == SearchBeneficiaryRoute.name);
    context.router.push(CustomBeneficiaryAcknowledgementRoute(
        enableViewHousehold: true,
        acknowledgementType: AcknowledgementType.addHousehold));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    final router = context.router;

    return Scaffold(
      body: BlocBuilder<CustomBeneficiaryRegistrationBloc,
          BeneficiaryRegistrationState>(builder: (context, registrationState) {
        return ScrollableContent(
          enableFixedDigitButton: true,
          header: const Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: spacer2),
                child: CustomBackNavigationHelpHeaderWidget(
                  showHelp: false,
                ),
              ),
            ],
          ),
          footer:
              DigitCard(margin: const EdgeInsets.only(top: spacer2), children: [
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, locationState) {
                return DigitButton(
                  label: localizations.translate(i18.common.coreCommonSubmit),
                  type: DigitButtonType.primary,
                  size: DigitButtonSize.large,
                  mainAxisSize: MainAxisSize.max,
                  onPressed: () {
                    if (selectedConsent == null) {
                      DigitToast.show(context,
                          options: DigitToastOptions(
                            localizations.translate(
                                i18_local.caregiverConsent.caregiveroption),
                            true,
                            theme,
                          ));
                      return;
                    }
                    if (selectedConsent == CaregiverConsentEnum.yes) {
                      router.push(CustomHouseHoldDetailsRoute());
                    } else if (consentComment.text.length >= 2) {
                      registrationState.maybeWhen(orElse: () {
                        return;
                      }, create: (
                        addressModel,
                        householdModel,
                        individualModel,
                        projectBeneficiaryModel,
                        registrationDate,
                        searchQuery,
                        loading,
                        isHeadOfHousehold,
                      ) async {
                        final submit = await showDialog(
                          context: context,
                          builder: (ctx) => Popup(
                            title: localizations.translate(
                              i18.deliverIntervention.dialogTitle,
                            ),
                            description: localizations.translate(
                              i18.deliverIntervention.dialogContent,
                            ),
                            actions: [
                              DigitButton(
                                  label: localizations.translate(
                                    i18.common.coreCommonSubmit,
                                  ),
                                  onPressed: () {
                                    clickedStatus.value = true;
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop(true);
                                  },
                                  type: DigitButtonType.primary,
                                  size: DigitButtonSize.large),
                              DigitButton(
                                  label: localizations.translate(
                                    i18.common.coreCommonCancel,
                                  ),
                                  onPressed: () => Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop(false),
                                  type: DigitButtonType.secondary,
                                  size: DigitButtonSize.large),
                            ],
                          ),
                        );
                        if (submit == true) {
                          onSubmit(householdModel, addressModel);
                        }
                      });
                    } else {
                      DigitToast.show(
                        context,
                        options: DigitToastOptions(
                          localizations.translate(
                              i18_local.common.coreCommonConsentReasonRequired),
                          true,
                          theme,
                        ),
                      );
                      return;
                    }
                  },
                );
              },
            ),
          ]),
          slivers: [
            SliverToBoxAdapter(
              child:
                  DigitCard(margin: const EdgeInsets.all(spacer2), children: [
                DigitTextBlock(
                  padding: EdgeInsets.zero,
                  heading: localizations.translate(
                      i18_local.caregiverConsent.caregiverConsentLabelText),
                  headingStyle: textTheme.headingXl
                      .copyWith(color: theme.colorTheme.text.primary),
                  description: "${localizations.translate(
                    i18_local
                        .caregiverConsent.caregiverConsentDescriptionTextAZM,
                  )} *",
                  descriptionStyle: textTheme.bodyL.copyWith(
                    color: theme.colorTheme.text.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    builder: (context) {
                      return RadioList(
                        radioDigitButtons: [
                          RadioButtonModel(
                            code: CaregiverConsentEnum.yes.name,
                            name: localizations.translate(
                              i18_local.common.coreCommonYes,
                            ),
                          ),
                          RadioButtonModel(
                            code: CaregiverConsentEnum.no.name,
                            name: localizations.translate(
                              i18_local.common.coreCommonNo,
                            ),
                          ),
                        ],
                        groupValue: selectedConsent == null
                            ? ''
                            : selectedConsent!.name,
                        onChanged: (value) {
                          setState(() {
                            if (value.code == CaregiverConsentEnum.yes.name) {
                              consentComment.clear();
                              selectedConsent = CaregiverConsentEnum.yes;
                            } else {
                              selectedConsent = CaregiverConsentEnum.no;
                            }
                          });
                        },
                      );
                    }),
                if (selectedConsent == CaregiverConsentEnum.no)
                  LabeledField(
                    isRequired: true,
                    label: localizations.translate(
                        i18_local.caregiverConsent.caregiverConsentReason),
                    child: DigitTextFormInput(controller: consentComment),
                  )
              ]),
            ),
          ],
        );
      }),
    );
  }
}
