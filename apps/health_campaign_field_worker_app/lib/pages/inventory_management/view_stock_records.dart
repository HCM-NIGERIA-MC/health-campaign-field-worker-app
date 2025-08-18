import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/widgets/atoms/input_wrapper.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/models/entities/transaction_reason.dart';
import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
import 'package:inventory_management/utils/utils.dart';
import 'package:registration_delivery/widgets/localized.dart';

import '../../utils/i18_key_constants.dart' as i18_local;
import '../../utils/utils.dart';

@RoutePage()
class ViewStockRecordsPage extends LocalizedStatefulWidget {
  final String mrnNumber;
  final List<StockModel> stockRecords;

  const ViewStockRecordsPage({
    super.key,
    super.appLocalizations,
    required this.mrnNumber,
    required this.stockRecords,
  });

  @override
  State<ViewStockRecordsPage> createState() => _ViewStockRecordsPageState();
}

class _ViewStockRecordsPageState extends LocalizedState<ViewStockRecordsPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.stockRecords.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          labelColor: Colors.white,
          indicator: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.orange),
              right: BorderSide(color: Colors.orange),
              bottom: BorderSide(color: Colors.orange),
              top: BorderSide(color: Colors.orange),
            ),
          ),
          indicatorPadding: const EdgeInsets.fromLTRB(0.1, 0, 0.1, 0.1),
          controller: _tabController,
          isScrollable: true,
          tabs: widget.stockRecords
              .map((stock) => Tab(
                    text: stock.additionalFields?.fields
                            .firstWhere(
                              (field) => field.key == 'productName',
                              orElse: () =>
                                  const AdditionalField('productName', ''),
                            )
                            .value
                            ?.toString() ??
                        '',
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.stockRecords.map(_buildStockRecordTab).toList(),
      ),
    );
  }

  Widget _buildStockRecordTab(StockModel stock) {
    final senderIdToShowOnTab = stock.senderId;

    String? partialQuantity = stock.additionalFields?.fields
        .firstWhereOrNull((e) => e.key == "partialBlistersReturned")
        ?.value
        .toString();

    String? wastedQuantity = stock.additionalFields?.fields
        .firstWhereOrNull((e) => e.key == "wastedBlistersReturned")
        ?.value
        .toString();

    String? expireDate = stock.additionalFields?.fields
        .firstWhereOrNull((e) => e.key == "expireDate")
        ?.value
        .toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // MRN Card
          DigitCard(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations
                        .translate(i18_local.stockDetails.stockReceiptDetails),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: Text(localizations
                              .translate(i18_local.stockDetails.mrnNumber))),
                      Expanded(child: Text(widget.mrnNumber)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: Text(localizations
                              .translate(i18_local.stockDetails.resource))),
                      Expanded(
                        child: Text(
                          stock.additionalFields?.fields
                                  .firstWhere(
                                    (field) => field.key == 'productName',
                                    orElse: () => const AdditionalField(
                                        'productName', ''),
                                  )
                                  .value
                                  ?.toString() ??
                              '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(localizations.translate(getEntryTypeLabel(
                            widget.stockRecords.firstOrNull))),
                      ),
                      Expanded(
                          child: Text(localizations.translate(
                              getSecondaryPartyValue(
                                  widget.stockRecords.firstOrNull)))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stock Details Card

          DigitCard(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations
                        .translate(i18_local.stockDetails.stockDetails),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (InventorySingleton().isDistributor != true) ...[
                    // Waybill Number
                    ViewStockField(
                      label: localizations
                          .translate(i18_local.stockDetails.waybillNumber),
                      value: stock.wayBillNumber ?? '',
                    ),
                    // Batch Number
                    if (stock.transactionReason !=
                        TransactionReason.returned.toValue())
                      ViewStockField(
                        label: localizations
                            .translate(i18_local.stockDetails.batchNumberLabel),
                        value: stock.additionalFields?.fields
                                .firstWhere(
                                  (field) => field.key == 'batchNumber',
                                  orElse: () =>
                                      const AdditionalField('batchNumber', ''),
                                )
                                .value
                                ?.toString() ??
                            '',
                      )
                  ],

                  // Quantity
                  ViewStockField(
                    label: localizations
                        .translate(i18_local.stockDetails.quantity),
                    value: stock.quantity ?? '',
                  ),

                  // Partial Quantity
                  if (stock.transactionReason ==
                      TransactionReason.returned.toValue())
                    ViewStockField(
                      label: localizations
                          .translate(i18_local.stockDetails.partialQuantity),
                      value: partialQuantity ?? "",
                    ),

                  // Expire Date
                  if (stock.transactionReason !=
                      TransactionReason.returned.toValue())
                    ViewStockField(
                      label: localizations
                          .translate(i18_local.stockDetails.expireDate),
                      value: expireDate != null
                          ? DateFormat("dd MMM yyyy")
                              .format(DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(expireDate)))
                              .toString()
                          : localizations
                              .translate(i18_local.stockDetails.expireDate),
                    ),

                  // Wasted Quantity
                  if (wastedQuantity != null)
                    ViewStockField(
                      label: localizations
                          .translate(i18_local.stockDetails.wastedQuantity),
                      value: wastedQuantity,
                    ),
                  if (wastedQuantity != null) const SizedBox(height: 12),
                  // Comments
                  ViewStockField(
                    type: InputType.textArea,
                    label: localizations
                        .translate(i18_local.stockDetails.comments),
                    value: stock.additionalFields?.fields
                            .firstWhere(
                              (field) => field.key == 'comments',
                              orElse: () =>
                                  const AdditionalField('comments', ''),
                            )
                            .value
                            ?.toString() ??
                        '',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          DigitButton(
            label: localizations.translate(i18.common.corecommonclose),
            onPressed: () => context.router.pop(),
            type: DigitButtonType.secondary,
            size: DigitButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(value),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class ViewStockField extends StatelessWidget {
  final String label;
  final String value;
  final InputType type;
  const ViewStockField(
      {super.key,
      required this.value,
      required this.label,
      this.type = InputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputField(
          type: type,
          label: label,
          initialValue: value,
          isDisabled: true,
          readOnly: true,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
