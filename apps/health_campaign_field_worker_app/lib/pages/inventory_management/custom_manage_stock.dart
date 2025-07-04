import 'package:auto_route/auto_route.dart';
import 'package:digit_scanner/pages/qr_scanner.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/widgets/atoms/menu_card.dart';
import 'package:digit_ui_components/widgets/scrollable_content.dart';
import 'package:flutter/material.dart';
import 'package:health_campaign_field_worker_app/router/app_router.dart';
import 'package:health_campaign_field_worker_app/widgets/custom_back_navigation.dart';
import 'package:inventory_management/router/inventory_router.gm.dart';
import 'package:digit_components/widgets/digit_dialog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
import '../../utils/i18_key_constants.dart' as i18_local;
import 'package:inventory_management/utils/utils.dart';
import 'package:inventory_management/widgets/localized.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/widgets/back_navigation_help_header.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import 'qrscanner.dart';

@RoutePage()
class CustomManageStocksPage extends LocalizedStatefulWidget {
  const CustomManageStocksPage({
    super.key,
    super.appLocalizations,
  });

  @override
  State<CustomManageStocksPage> createState() => CustomManageStocksPageState();
}

class CustomManageStocksPageState
    extends LocalizedState<CustomManageStocksPage> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);

    return Scaffold(
      body: ScrollableContent(
        header: const CustomBackNavigationHelpHeaderWidget(
          showHelp: false,
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: spacer2,
                    right: spacer2,
                    bottom: spacer4,
                    top: spacer4),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    localizations
                        .translate(i18_local.stockDetails.manageStockLabel),
                    style: textTheme.headingXl,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Column(children: [
                Padding(
                  padding: const EdgeInsets.only(left: spacer2, right: spacer2),
                  child: Stack(children: [
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 0.94 * MediaQuery.of(context).size.width,
                        child: MenuCard(
                          heading: localizations.translate(
                              i18.manageStock.recordStockReceiptLabel),
                          description: insertNewlines(localizations.translate(
                              i18.manageStock.recordStockReceiptDescription)),
                          icon: Icons.file_download_outlined,
                          onTap: () {
                            showStockReceiptDialog(context);
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 16,
                      child: Center(
                          child: GestureDetector(
                        onTap: () {
                          showStockReceiptDialog(context);
                        },
                        child: Icon(
                          Icons.arrow_circle_right,
                          color: Colors.orange[800],
                          size: Base.height,
                        ),
                      )),
                    ),
                  ]),
                ),
                const SizedBox(
                  height: spacer4,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: spacer2, right: spacer2),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 0.94 * MediaQuery.of(context).size.width,
                          child: MenuCard(
                              heading: localizations.translate(context.isCDD
                                  ? i18.manageStock.recordStockReturnedLabel
                                  : i18.manageStock.recordStockIssuedLabel),
                              description: insertNewlines(
                                  localizations.translate(context.isCDD
                                      ? i18_local.stockDetails
                                          .recordStockReturnedDescription
                                      : i18.manageStock
                                          .recordStockIssuedDescription)),
                              icon: context.isCDD
                                  ? Icons.settings_backup_restore
                                  : Icons.file_upload_outlined,
                              onTap: () {
                                showStockIssueDialog(context);
                              }),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 16,
                        child: Center(
                            child: GestureDetector(
                          onTap: () {
                            showStockIssueDialog(context);
                          },
                          child: Icon(
                            Icons.arrow_circle_right,
                            color: Colors.orange[800],
                            size: Base.height,
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
                if (!context.isCDD)
                  const SizedBox(
                    height: spacer4,
                  ),
                if (!context.isCDD)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: spacer2, right: spacer2),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 0.94 * MediaQuery.of(context).size.width,
                            child: MenuCard(
                                heading: localizations.translate(
                                    i18.manageStock.recordStockReturnedLabel),
                                description: insertNewlines(
                                    localizations.translate(i18_local
                                        .stockDetails
                                        .recordStockReturnedDescription)),
                                icon: Icons.settings_backup_restore,
                                onTap: () {
                                  showStockReturnDialog(context);
                                }),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 16,
                          child: Center(
                              child: GestureDetector(
                            onTap: () {
                              showStockReturnDialog(context);
                            },
                            child: Icon(
                              Icons.arrow_circle_right,
                              color: Colors.orange[800],
                              size: Base.height,
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
              ]),
              const SizedBox(height: spacer4),
            ],
          ),
        ],
      ),
    );
  }

  void showStockReceiptDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    context.router.push(
                      RecordStockWrapperRoute(
                        type: StockRecordEntryType.receipt,
                      ),
                    );

                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange[800]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_outlined,
                            size: 24,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.translate(i18_local
                                .stockDetails.createNewTransactionLabel),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Add spacing between buttons
                GestureDetector(
                  onTap: () {
                    context.router.push(
                      CustomMinNumberRoute(
                        type: StockRecordEntryType.receipt,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange[800]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye,
                            size: 24,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.translate(i18_local
                                .stockDetails.viewCreatedTransactionLabel),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  void showStockIssueDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    context.router.push(
                      RecordStockWrapperRoute(
                        type: StockRecordEntryType.dispatch,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange[800]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_outlined,
                            size: 24,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.translate(i18_local
                                .stockDetails.createNewTransactionLabel),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Add spacing between buttons
                GestureDetector(
                  onTap: () {
                    context.router.push(
                      CustomMinNumberRoute(
                        type: StockRecordEntryType.dispatch,
                      ),
                    );

                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange[800]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye,
                            size: 24,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.translate(i18_local
                                .stockDetails.viewCreatedTransactionLabel),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  void showStockReturnDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    context.router.push(
                      RecordStockWrapperRoute(
                        type: StockRecordEntryType.returned,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange[800]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_outlined,
                            size: 24,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.translate(i18_local
                                .stockDetails.createNewTransactionLabel),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    context.router.push(
                      CustomMinNumberRoute(
                        type: StockRecordEntryType.returned,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange[800]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye,
                            size: 24,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.translate(i18_local
                                .stockDetails.viewCreatedTransactionLabel),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  String insertNewlines(String text) {
    int charLimit = 0.94 * MediaQuery.of(context).size.width ~/ 8;
    // 8 is the average character width

    final words = text.split(' ');
    final buffer = StringBuffer();

    int currentLineLength = 0;

    for (var word in words) {
      // +1 for the space that follows the word
      if (currentLineLength + word.length + 1 > charLimit) {
        buffer.write('\n');
        currentLineLength = 0;
      } else if (buffer.isNotEmpty) {
        buffer.write(' ');
        currentLineLength += 1;
      }

      buffer.write(word);
      currentLineLength += word.length;
    }

    return buffer.toString();
  }
}
