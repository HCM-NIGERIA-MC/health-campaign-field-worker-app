// import 'package:auto_route/auto_route.dart';
// import 'package:digit_data_model/data_model.dart';
// import 'package:digit_ui_components/digit_components.dart';
// import 'package:digit_ui_components/widgets/atoms/input_wrapper.dart';
// import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:inventory_management/blocs/record_stock.dart';
// import 'package:inventory_management/models/entities/stock.dart';
// import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
// import 'package:inventory_management/utils/utils.dart';
// import 'package:registration_delivery/widgets/localized.dart';

// @RoutePage()
// class ViewStockRecordsPage extends LocalizedStatefulWidget {
//   final String mrnNumber;
//   final List<StockModel> stockRecords;
//   StockRecordEntryType entryType;

//   ViewStockRecordsPage({
//     super.key,
//     super.appLocalizations,
//     required this.mrnNumber,
//     required this.stockRecords,
//     this.entryType = StockRecordEntryType.dispatch,
//   });

//   @override
//   State<ViewStockRecordsPage> createState() => _ViewStockRecordsPageState();
// }

// class _ViewStockRecordsPageState extends LocalizedState<ViewStockRecordsPage>
//     with TickerProviderStateMixin {
//   late final TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(
//       length: widget.stockRecords.length,
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         bottom: TabBar(
//           labelColor: Colors.white,
//           indicator: BoxDecoration(
//             border: Border(
//               left: BorderSide(color: Colors.orange),
//               right: BorderSide(color: Colors.orange),
//               bottom: BorderSide(color: Colors.orange),
//               top: BorderSide(color: Colors.orange),
//             ),
//           ),
//           indicatorPadding: EdgeInsets.fromLTRB(0.1, 0, 0.1, 0.1),
//           controller: _tabController,
//           isScrollable: true,
//           tabs: widget.stockRecords
//               .map((stock) => Tab(
//                     text: stock.additionalFields?.fields
//                             .firstWhere(
//                               (field) => field.key == 'productName',
//                               orElse: () => AdditionalField('productName', ''),
//                             )
//                             .value
//                             ?.toString() ??
//                         '',
//                   ))
//               .toList(),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: widget.stockRecords.map(_buildStockRecordTab).toList(),
//       ),
//     );
//   }

//   Widget _buildStockRecordTab(StockModel stock) {
//     final senderIdToShowOnTab = stock.senderId;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // MRN Card
//           DigitCard(
//             padding: const EdgeInsets.all(16),
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Stock Receipt Details',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       const Expanded(child: Text('MRN Number')),
//                       Expanded(child: Text(widget.mrnNumber)),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       const Expanded(child: Text('Resource')),
//                       Expanded(
//                         child: Text(
//                           stock.additionalFields?.fields
//                                   .firstWhere(
//                                     (field) => field.key == 'productName',
//                                     orElse: () =>
//                                         AdditionalField('productName', ''),
//                                   )
//                                   .value
//                                   ?.toString() ??
//                               '',
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       const Expanded(child: Text('Received From')),
//                       Expanded(
//                           child: Text(localizations
//                               .translate('FAC_$senderIdToShowOnTab'))),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           // Stock Details Card

//           DigitCard(
//             padding: const EdgeInsets.all(16),
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Stock Details',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 12),
//                   if (InventorySingleton().isDistributor != true) ...[
//                     // Waybill Number
//                     InputField(
//                       type: InputType.text,
//                       label: 'Waybill Number *',
//                       initialValue: stock.wayBillNumber ?? '',
//                       isDisabled: true,
//                       readOnly: true,
//                     ),
//                     const SizedBox(height: 12),
//                     // Batch Number
//                     InputField(
//                       type: InputType.text,
//                       label: 'Batch Number',
//                       initialValue: stock.additionalFields?.fields
//                               .firstWhere(
//                                 (field) => field.key == 'batchNumber',
//                                 orElse: () =>
//                                     const AdditionalField('batchNumber', ''),
//                               )
//                               .value
//                               ?.toString() ??
//                           '',
//                       isDisabled: true,
//                       readOnly: true,
//                     ),
//                     const SizedBox(height: 12),
//                   ],

//                   // Quantity
//                   Offstage(
//                     offstage: (stock.additionalFields?.fields ?? [])
//                         .any((e) => e.key == "unusedBlistersReturned"),
//                     child:

//                   InputField(
//                     type: InputType.text,
//                     label: (stock.additionalFields?.fields ?? [])
//                             .any((e) => e.key == "quantityReceived")
//                         ? 'Issued Quantity *'
//                         : 'Quantity *',
//                     initialValue: (stock.additionalFields?.fields ?? [])
//                             .any((e) => e.key == "quantityReceived")
//                         ? (stock.additionalFields?.fields ?? [])
//                             .firstWhere(
//                               (e) => e.key == "quantitySent",
//                               orElse: () =>
//                                   const AdditionalField('quantitySent', ''),
//                             )
//                             .value
//                             ?.toString()
//                         : stock.quantity ?? '',
//                     isDisabled: true,
//                     readOnly: true,
//                   )),
//                   Offstage(
//                     offstage: !(stock.additionalFields?.fields ?? [])
//                         .any((e) => e.key == "unusedBlistersReturned"),
//                     child:

//                   Column(
//                     children: [
//                       InputField(
//                         type: InputType.text,
//                         label: 'Unused Quantity *',
//                         initialValue: (stock.additionalFields?.fields ?? [])
//                               .firstWhere(
//                                 (e) => e.key == "unusedBlistersReturned",
//                                 orElse: () => const AdditionalField(
//                                     'unusedBlistersReturned', ''),
//                               )
//                               .value
//                               ?.toString() ??
//                           '',
//                         isDisabled: true,
//                         readOnly: true,
//                       ),
//                        const SizedBox(height: 12),
//                        InputField(
//                         type: InputType.text,
//                         label: 'Partially Used Quantity *',
//                         initialValue: (stock.additionalFields?.fields ?? [])
//                               .firstWhere(
//                                 (e) => e.key == "partiallyUsedBlistersReturned",
//                                 orElse: () => const AdditionalField(
//                                     'partiallyUsedBlistersReturned', ''),
//                               )
//                               .value
//                               ?.toString() ??
//                           '',
//                         isDisabled: true,
//                         readOnly: true,
//                       ),
//                        const SizedBox(height: 12),
//                        InputField(
//                         type: InputType.text,
//                         label: 'Wasted Quantity *',
//                         initialValue: (stock.additionalFields?.fields ?? [])
//                               .firstWhere(
//                                 (e) => e.key == "wastedBlistersReturned",
//                                 orElse: () => const AdditionalField(
//                                     'wastedBlistersReturned', ''),
//                               )
//                               .value
//                               ?.toString() ??
//                           '',
//                         isDisabled: true,
//                         readOnly: true,
//                       ),
                       
//                     ],
//                   )),
//                   const SizedBox(height: 12),
//                   Offstage(
//                     offstage: !(stock.additionalFields?.fields ?? [])
//                         .any((e) => e.key == "quantityReceived"),
//                     child: InputField(
//                       type: InputType.text,
//                       label: 'Actual Quantity Received *',
//                       initialValue: (stock.additionalFields?.fields ?? [])
//                               .firstWhere(
//                                 (e) => e.key == "quantityReceived",
//                                 orElse: () => const AdditionalField(
//                                     'quantityReceived', ''),
//                               )
//                               .value
//                               ?.toString() ??
//                           '',
//                       isDisabled: true,
//                       readOnly: true,
//                     ),
//                   ),
//                   // Comments
//                   InputField(
//                     type: InputType.textArea,
//                     label: 'Comments',
//                     initialValue: stock.additionalFields?.fields
//                             .firstWhere(
//                               (field) => field.key == 'comments',
//                               orElse: () => AdditionalField('comments', ''),
//                             )
//                             .value
//                             ?.toString() ??
//                         '',
//                     isDisabled: true,
//                     readOnly: true,
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           const SizedBox(height: 24),
//           DigitButton(
//             label: localizations.translate(i18.common.corecommonclose),
//             onPressed: () => context.router.pop(),
//             type: DigitButtonType.secondary,
//             size: DigitButtonSize.large,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReadOnlyField({required String label, required String value}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 4),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(value),
//           ),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
// }



import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/widgets/atoms/input_wrapper.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
import 'package:inventory_management/utils/utils.dart';
import 'package:registration_delivery/widgets/localized.dart';

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
          indicator: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.orange),
              right: BorderSide(color: Colors.orange),
              bottom: BorderSide(color: Colors.orange),
              top: BorderSide(color: Colors.orange),
            ),
          ),
          indicatorPadding: EdgeInsets.fromLTRB(0.1, 0, 0.1, 0.1),
          controller: _tabController,
          isScrollable: true,
          tabs: widget.stockRecords
              .map((stock) => Tab(
                    text: stock.additionalFields?.fields
                            .firstWhere(
                              (field) => field.key == 'productName',
                              orElse: () => AdditionalField('productName', ''),
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
        .firstWhereOrNull((e) => e.key == "partialQuantity")
        ?.value
        .toString();

    String? wastedQuantity = stock.additionalFields?.fields
        .firstWhereOrNull((e) => e.key == "wastedQuantity")
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
                  const Text(
                    'Stock Receipt Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Text('MRN Number')),
                      Expanded(child: Text(widget.mrnNumber)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('Resource')),
                      Expanded(
                        child: Text(
                          stock.additionalFields?.fields
                                  .firstWhere(
                                    (field) => field.key == 'productName',
                                    orElse: () =>
                                        AdditionalField('productName', ''),
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
                      const Expanded(child: Text('Received From')),
                      Expanded(
                          child: Text(localizations
                              .translate('FAC_$senderIdToShowOnTab'))),
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
                  const Text(
                    'Stock Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (InventorySingleton().isDistributor != true) ...[
                    // Waybill Number
                    InputField(
                      type: InputType.text,
                      label: 'Waybill Number *',
                      initialValue: stock.wayBillNumber ?? '',
                      isDisabled: true,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    // Batch Number
                    InputField(
                      type: InputType.text,
                      label: 'Batch Number',
                      initialValue: stock.additionalFields?.fields
                              .firstWhere(
                                (field) => field.key == 'batchNumber',
                                orElse: () =>
                                    const AdditionalField('batchNumber', ''),
                              )
                              .value
                              ?.toString() ??
                          '',
                      isDisabled: true,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Quantity
                  InputField(
                    type: InputType.text,
                    label: 'Quantity *',
                    initialValue: stock.quantity ?? '',
                    isDisabled: true,
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // Partial Quantity
                  if (partialQuantity != null)
                    InputField(
                      type: InputType.text,
                      label: 'Partial Quantity *',
                      initialValue: partialQuantity,
                      isDisabled: true,
                      readOnly: true,
                    ),
                  if (partialQuantity != null) const SizedBox(height: 12),
                  // Wasted Quantity
                  if (wastedQuantity != null)
                    InputField(
                      type: InputType.text,
                      label: 'Wasted Quantity *',
                      initialValue: wastedQuantity,
                      isDisabled: true,
                      readOnly: true,
                    ),
                  if (wastedQuantity != null) const SizedBox(height: 12),
                  // Comments
                  InputField(
                    type: InputType.textArea,
                    label: 'Comments',
                    initialValue: stock.additionalFields?.fields
                            .firstWhere(
                              (field) => field.key == 'comments',
                              orElse: () => AdditionalField('comments', ''),
                            )
                            .value
                            ?.toString() ??
                        '',
                    isDisabled: true,
                    readOnly: true,
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