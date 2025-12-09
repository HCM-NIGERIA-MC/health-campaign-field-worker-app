import 'package:collection/collection.dart';
import 'package:digit_components/widgets/digit_checkbox_tile.dart';
import 'package:digit_data_model/models/entities/individual.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/material.dart';

import '../../../utils/i18_key_constants.dart' as i18_local;
import '../../../models/entities/identifier_types.dart';
import '../../../router/app_router.dart';
import '../../../utils/app_enums.dart';
import '../../../widgets/localized.dart';

@RoutePage()
class HealthTalkPage extends LocalizedStatefulWidget {
  final EligibilityAssessmentType eligibilityAssessmentType;
  final IndividualModel? individual;

  const HealthTalkPage({
    super.key,
    super.appLocalizations,
    required this.eligibilityAssessmentType,
    required this.individual,
  });

  @override
  State<HealthTalkPage> createState() => _HealthTalkPageState();
}

class _HealthTalkPageState extends LocalizedState<HealthTalkPage> {
  late List<bool> _subChecks;

  @override
  void initState() {
    super.initState();
    // subpoints under item 3
    _subChecks = List<bool>.filled(5, false);
  }

  bool get _allChecked => _subChecks.every((v) => v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? beneficiaryName = widget.individual?.name?.givenName ?? "";
    String? beneficiaryId = widget.individual?.identifiers
        ?.firstWhereOrNull(
          (id) =>
              id.identifierType ==
              IdentifierTypes.uniqueBeneficiaryID.toValue(),
        )
        ?.identifierId;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(spacer2),
            child: DigitCard(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: spacer2),
                  child: Text(
                    localizations.translate(
                        i18_local.deliverIntervention.healthTalkTitle),
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.left,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: spacer2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyLarge,
                            children: [
                              TextSpan(
                                text: localizations.translate(
                                  i18_local
                                      .deliverIntervention.healthTalkItem1Part1,
                                ),
                              ),
                              TextSpan(
                                text: beneficiaryId,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: localizations.translate(
                                  i18_local
                                      .deliverIntervention.healthTalkItem1Part2,
                                ),
                              ),
                              TextSpan(
                                text: beneficiaryName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: localizations.translate(
                                  i18_local
                                      .deliverIntervention.healthTalkItem1Part3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNumberedItem(
                  index: 2,
                  text: localizations.translate(
                    i18_local.deliverIntervention.healthTalkItem2,
                  ),
                ),
                _buildItemWithSubpoints(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(spacer2),
          child: DigitCard(
            children: [
              DigitButton(
                label: 'Next',
                type: DigitButtonType.primary,
                size: DigitButtonSize.large,
                mainAxisSize: MainAxisSize.max,
                isDisabled: !_allChecked,
                onPressed: _allChecked
                    ? () {
                        context.router.popAndPush(
                          CustomHouseholdAcknowledgementRoute(
                            enableViewHousehold: true,
                            eligibilityAssessmentType:
                                widget.eligibilityAssessmentType,
                          ),
                        );
                      }
                    : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedItem({
    required int index,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: spacer2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$index. $text',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  /// Item 3 with mandatory subpoints, each having a checkbox.
  Widget _buildItemWithSubpoints() {
    final theme = Theme.of(context);

    final subpoints = [
      i18_local.deliverIntervention.healthTalkItem3Checkpoint1,
      i18_local.deliverIntervention.healthTalkItem3Checkpoint2,
      i18_local.deliverIntervention.healthTalkItem3Checkpoint3,
      i18_local.deliverIntervention.healthTalkItem3Checkpoint4,
      i18_local.deliverIntervention.healthTalkItem3Checkpoint5,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: spacer2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3. ${localizations.translate(
              i18_local.deliverIntervention.healthTalkItem3,
            )}',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: spacer3),
          ...List.generate(subpoints.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: spacer2 / 2),
              child: DigitCheckboxTile(
                label: localizations.translate(subpoints[i]),
                value: _subChecks[i],
                onChanged: (val) {
                  setState(() {
                    _subChecks[i] = val;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
