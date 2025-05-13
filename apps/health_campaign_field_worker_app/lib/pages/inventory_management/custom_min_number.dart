import 'package:auto_route/auto_route.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_scanner/blocs/scanner.dart';
import 'package:digit_scanner/pages/qr_scanner.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/widgets/atoms/input_wrapper.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_campaign_field_worker_app/widgets/action_card/min_number_card.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/pages/facility_selection.dart';
import 'package:inventory_management/router/inventory_router.gm.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
import 'package:inventory_management/widgets/localized.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/utils/utils.dart';
import 'package:inventory_management/widgets/back_navigation_help_header.dart';
import 'package:inventory_management/widgets/inventory/no_facilities_assigned_dialog.dart';

import '../../router/app_router.dart';

@RoutePage()
class CustomMinNumberPage extends LocalizedStatefulWidget {
  const CustomMinNumberPage({
    super.key,
    super.appLocalizations,
  });

  @override
  State<CustomMinNumberPage> createState() => CustomMinNumberPageState();
}

class CustomMinNumberPageState extends LocalizedState<CustomMinNumberPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {
        "minNumber": "8976543210",
        "qrImagePath": "assets/images/qr_code_test.png",
        "cddCode": "CDD123",
        "date": "13 Feb 2024",
        "items": [
          {"name": "SPAQ1", "quantity": "50 blister"},
          {"name": "SPAQ2", "quantity": "50 blister"},
          {"name": "Bednet", "quantity": "50 blister"},
        ],
      },
      // Add more items here
    ];
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);

    return Scaffold(
      body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ScrollableContent(
            header: const Column(children: [
              BackNavigationHelpHeaderWidget(
                showHelp: true,
              ),
            ]),
            footer: SizedBox(
              child: DigitCard(
                  margin: const EdgeInsets.fromLTRB(0, spacer2, 0, 0),
                  children: [
                    DigitButton(
                        type: DigitButtonType.primary,
                        mainAxisSize: MainAxisSize.max,
                        size: DigitButtonSize.large,
                        label: localizations.translate(
                          i18.householdDetails.actionLabel,
                        ),
                        onPressed: () {}),
                  ]),
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(spacer2),
                ),
                margin: const EdgeInsets.all(spacer2),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MinNumberCard(
                          data: const {
                            'minNumber': 'MIN-123456',
                            'cddCode': 'CDD-9876',
                            'date': '2025-05-11',
                            'items': const [
                              {'name': 'Gloves', 'quantity': '10'},
                              {'name': 'Masks', 'quantity': '5'},
                            ],
                          },
                          minNumber: item['minNumber'],
                          qrImagePath: item['qrImagePath'],
                          cddCode: item['cddCode'],
                          date: item['date'],
                          items: List<Map<String, String>>.from(item['items']),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
