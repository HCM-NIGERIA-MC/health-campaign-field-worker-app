import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_campaign_field_worker_app/data/repositories/local/inventory_management/custom_stock.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/models/entities/transaction_reason.dart';
import 'package:inventory_management/models/entities/transaction_type.dart';
import 'package:inventory_management/utils/utils.dart';
import 'package:inventory_management/widgets/back_navigation_help_header.dart';
import '../../blocs/inventory_management/stock_bloc.dart';
import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/action_card/all_transactions_card.dart';
import '../../widgets/custom_back_navigation.dart';
import 'view_record_lga.dart';
import 'package:collection/collection.dart';

@RoutePage()
class ViewAllTransactionsScreen extends StatefulWidget {
  final String? warehouseId;
  const ViewAllTransactionsScreen({super.key, required this.warehouseId});

  @override
  State<ViewAllTransactionsScreen> createState() =>
      _ViewAllTransactionsScreenState();
}

class _ViewAllTransactionsScreenState extends State<ViewAllTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    loadLocalStockData();
    final stockState = context.read<RecordStockBloc>().state;
  }

  int? pressedIndex;
  List<StockModel> stockList = [];

  Future<void> loadLocalStockData() async {
    final repository =
        context.read<LocalRepository<StockModel, StockSearchModel>>()
            as CustomStockLocalRepository;
    String? warehouseId = widget.warehouseId;

    List<StockModel> result;
    List<StockModel> receivedResult;
    // check for valid user
    if (isLGAUser() ||
        isHFUser(context) ||
        InventorySingleton().isDistributor) {
      result = await repository.search(StockSearchModel(
          transactionType: [TransactionType.dispatched.toValue()],
          transactionReason: [],
          receiverId: warehouseId == null ? [] : [warehouseId]));
      receivedResult = await repository.search(StockSearchModel(
          transactionType: [TransactionType.received.toValue()],
          transactionReason: [TransactionReason.received.toValue()],
          receiverId: [warehouseId ?? '']));
      result = result.where((stock) {
        String minStock = stock.additionalFields?.fields
                .firstWhere(
                  (field) => field.key == 'materialNoteNumber',
                  orElse: () => const AdditionalField('materialNoteNumber', ''),
                )
                .value
                ?.toString() ??
            'N/A';
        return receivedResult.firstWhereOrNull((item) {
              return item.productVariantId == stock.productVariantId &&
                  item.receiverId == stock.receiverId &&
                  item.senderId == stock.senderId &&
                  minStock ==
                      item.additionalFields?.fields
                          .firstWhere(
                            (field) => field.key == 'materialNoteNumber',
                            orElse: () =>
                                const AdditionalField('materialNoteNumber', ''),
                          )
                          .value
                          ?.toString();
            }) ==
            null;
      }).toList();
    } else {
      result = await repository.search(StockSearchModel(
          transactionType: [TransactionType.received.toValue()],
          transactionReason: [TransactionReason.received.toValue()],
          senderId: warehouseId));
    }

    setState(() {
      stockList = result;
    });
  }

  List<StockModel> groupStockByMrn(List<StockModel> stocks) {
    final List<StockModel> filtered = [];
    for (final stock in stocks) {
      final mrn = stock.additionalFields?.fields
              .firstWhere(
                (f) => f.key == 'materialNoteNumber',
                orElse: () => const AdditionalField('materialNoteNumber', ''),
              )
              .value
              ?.toString() ??
          'UNKNOWN';
      if (mrn != "") {
        filtered.add(stock);
      }
    }
    return filtered.reversed.toList();
  }

  void _navigateToDetails(StockModel stock) {
    final mrnNumber = stock.additionalFields?.fields
            .firstWhere(
              (field) => field.key == 'materialNoteNumber',
              orElse: () => const AdditionalField('materialNoteNumber', ''),
            )
            .value
            ?.toString() ??
        'N/A';

    // Filter stocks with the same MRN number
    final List<StockModel> sameMrnStocks = stockList.where((s) {
      final currentMrn = s.additionalFields?.fields
              .firstWhere(
                (field) => field.key == 'materialNoteNumber',
                orElse: () => const AdditionalField('materialNoteNumber', ''),
              )
              .value
              ?.toString() ??
          'N/A';
      return currentMrn == mrnNumber;
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewStockRecordsLGAPage(
          mrnNumber: mrnNumber,
          stockRecords: [stock],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    List<StockModel> filteredStock = groupStockByMrn(stockList);

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ScrollableContent(
          header: const Column(
            children: [
              CustomBackNavigationHelpHeaderWidget(showHelp: false),
            ],
          ),
          children: [
            if (filteredStock.isEmpty)
              const Center(child: Text('No transactions available.'))
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(spacer2),
                ),
                margin: const EdgeInsets.all(spacer2),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16.0),
                      Text("Select the MIN number", style: textTheme.headingL),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: BlocBuilder<StockBloc, StockState>(
                          builder: (context, state) {
                            return ListView.builder(
                              // reverse: true,
                              itemCount: filteredStock.length,
                              itemBuilder: (context, index) {
                                final stock = filteredStock[index];
                                return Material(
                                  color: pressedIndex == index
                                      ? Colors.orange[300]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () => _navigateToDetails(stock),
                                    onTapDown: (_) =>
                                        setState(() => pressedIndex = index),
                                    onTapUp: (_) =>
                                        setState(() => pressedIndex = null),
                                    onTapCancel: () =>
                                        setState(() => pressedIndex = null),
                                    borderRadius: BorderRadius.circular(8),
                                    customBorder: const RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: TransactionsCard(
                                        backgroundColor: pressedIndex == index
                                            ? Colors.orange[300]
                                            : Colors.grey[200],
                                        minNumber:
                                            stock.additionalFields?.fields
                                                    .firstWhere(
                                                      (field) =>
                                                          field.key ==
                                                          'materialNoteNumber',
                                                      orElse: () =>
                                                          const AdditionalField(
                                                              'materialNoteNumber',
                                                              ''),
                                                    )
                                                    .value
                                                    ?.toString() ??
                                                'N/A',
                                        cddCode: InventorySingleton()
                                                .loggedInUser
                                                ?.name ??
                                            (stock.senderId ?? ''),
                                        date: (stock.dateOfEntry != null)
                                            ? DateFormat('d MMMM yyyy').format(
                                                (stock.dateOfEntryTime ??
                                                        DateTime.now())
                                                    .toLocal())
                                            : formatDateFromMillis(stock
                                                    .auditDetails
                                                    ?.createdTime ??
                                                0),
                                        items: [
                                          {
                                            'name':
                                                stock.additionalFields?.fields
                                                        .firstWhere(
                                                          (field) =>
                                                              field.key ==
                                                              'productName',
                                                          orElse: () =>
                                                              const AdditionalField(
                                                                  'productName',
                                                                  'N/A'),
                                                        )
                                                        .value
                                                        ?.toString() ??
                                                    'N/A',
                                            'quantity':
                                                (stock.quantity ?? 0).toString()
                                          }
                                        ],
                                        data: {},
                                        waybillNumber:
                                            ' ${stock.wayBillNumber ?? 'N/A'}',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
