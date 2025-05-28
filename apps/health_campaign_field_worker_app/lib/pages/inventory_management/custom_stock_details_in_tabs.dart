import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:digit_components/widgets/atoms/digit_toaster.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_data_model/models/entities/product_variant.dart';
import 'package:digit_scanner/blocs/scanner.dart';
import 'package:digit_ui_components/services/location_bloc.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/widgets/atoms/input_wrapper.dart';
import 'package:digit_ui_components/widgets/atoms/pop_up_card.dart';
import 'package:digit_ui_components/widgets/molecules/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_campaign_field_worker_app/pages/inventory_management/custom_acknowledgement.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/models/entities/inventory_transport_type.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/models/entities/transaction_reason.dart';
import 'package:inventory_management/models/entities/transaction_type.dart';
import 'package:inventory_management/utils/utils.dart';
import 'package:inventory_management/widgets/localized.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
import '../../blocs/auth/auth.dart';
import '../../blocs/inventory_management/stock_bloc.dart';
import '../../data/repositories/local/inventory_management/custom_stock.dart';
import '../../router/app_router.dart';
import '../../utils/i18_key_constants.dart' as i18_local;
import '../../utils/constants.dart';
import '../../utils/extensions/extensions.dart';
import '../../utils/registration_delivery/registration_delivery_utils.dart';

class DynamicTabsPage extends LocalizedStatefulWidget {
  @override
  LocalizedState<DynamicTabsPage> createState() => _DynamicTabsPageState();
}

class _DynamicTabsPageState extends LocalizedState<DynamicTabsPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final Map<String, FormGroup> _forms = {};
  late List<ProductVariantModel> products;
  late String receivedFrom;
  late String secondaryPartyType;
  late List<dynamic> _formkeys;
  final Map<String, StockModel> _tabStocks = {};
  String _sharedMRN = '';
  bool _isInitializing = true;
  String? senderIdToShowOnTab = '';

// fields to capture stock metadata
  String? senderId;
  String? senderType;
  String? receiverId;
  String? receiverType;
  String? transactionType;
  String? transactionReason;

  static const _productVariantKey = 'productVariant';
  static const _secondaryPartyKey = 'secondaryParty';
  static const _transactionReasonKey = 'transactionReason';
  static const _transactionQuantityKey = 'quantity';
  static const _waybillNumberKey = 'waybillNumber';
  // static const _waybillQuantityKey = 'waybillQuantity';
  static const _batchNumberKey = 'batchNumberKey';
  static const _vehicleNumberKey = 'vehicleNumber';
  static const _typeOfTransportKey = 'typeOfTransport';
  static const _commentsKey = 'comments';
  static const _deliveryTeamKey = 'deliveryTeam';
  List<InventoryTransportTypes> transportTypes = [];

  static const _transactionQuantityPartialKey = 'quantityPartial';

  static const _transactionQuantityWastedKey = 'quantityWasted';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Generate unique MRN first
      final mrnNumbers = await UniqueIdGeneration()
          .generateUniqueMaterialNoteNumber(
            loggedInUserId: context.loggedInUserUuid,
            returnCombinedIds: true,
          )
          .timeout(const Duration(seconds: 5));

      if (mrnNumbers.isEmpty) {
        throw Exception('Failed to generate MRN number');
      }

      _sharedMRN = mrnNumbers.first;

      transportTypes = InventorySingleton().transportType;
      context.read<LocationBloc>().add(const LoadLocationEvent());

      final state = context.read<StockBloc>().state;
      if (state is StockSelectedState) {
        products = state.selectedProducts;
        receivedFrom = state.receivedFrom;
        secondaryPartyType = state.secondaryPartyType;
        _tabController = TabController(length: products.length, vsync: this);
        _formkeys =
            List.generate(products.length, (_) => GlobalKey<FormState>());

        _initializeForms();
        await _initializeStocks();
      }
    } on TimeoutException {
      _sharedMRN = 'MRN-${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('MRN generation timed out, using fallback');
    } catch (e) {
      _sharedMRN = 'MRN-${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Error generating MRN: $e');
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  void _initializeForms() {
    final selectedProducts =
        products.map((variant) => variant.sku).whereType<String>().toList();

    _forms.addAll({
      for (final product in selectedProducts)
        product: FormGroup({
          'materialNoteNumber': FormControl<String>(value: _sharedMRN),
          _transactionReasonKey: FormControl<String>(),
          _waybillNumberKey: FormControl<String>(
            validators: InventorySingleton().isWareHouseMgr
                ? [
                    Validators.minLength(2),
                    Validators.maxLength(200),
                    Validators.required
                  ]
                : [],
          ),
          _transactionQuantityKey: FormControl<int>(
              validators: InventorySingleton().isWareHouseMgr
                  ? [
                      Validators.number(),
                      Validators.required,
                      Validators.min(1),
                      Validators.max(1000000),
                    ]
                  : [
                      Validators.number(),
                      Validators.required,
                      Validators.min(1),
                      Validators.max(1000000),
                    ]),
          // _waybillQuantityKey:
          //     FormControl<String>(validators: [Validators.required]),
          _transactionQuantityPartialKey: FormControl<int>(validators: []),

          _transactionQuantityWastedKey: FormControl<int>(validators: []),
          _batchNumberKey: FormControl<String>(),
          _commentsKey: FormControl<String>(),
        }),
    });
  }

  Future<void> _initializeStocks() async {
    for (final product in products) {
      _tabStocks[product.sku ?? ''] = await _createEmptyStock(product);
    }
  }

  Future<StockModel> _createEmptyStock(ProductVariantModel product) async {
    final productSku = product.sku ?? '';
    final state = context.read<RecordStockBloc>().state;
    StockRecordEntryType entryType = state.entryType;

    // info setting the transaction related info here for the stock the model

    // setTransactionTypeAndReason(
    //   entryType,
    //   transactionType,
    //   transactionReason,
    // );

    switch (entryType) {
      case StockRecordEntryType.receipt:
        transactionType = TransactionType.received.toValue();
        transactionReason = TransactionReason.received.toValue();

        break;
      case StockRecordEntryType.dispatch:
        transactionType = TransactionType.dispatched.toValue();

        break;
      case StockRecordEntryType.returned:
        transactionType = TransactionType.received.toValue();
        transactionReason = TransactionReason.returned.toValue();

        break;
      case StockRecordEntryType.loss:
        transactionType = TransactionType.dispatched.toValue();

        break;
      case StockRecordEntryType.damaged:
        transactionType = TransactionType.dispatched.toValue();
        break;
    }

    // setSenderReceiverIdAndType(
    //     entryType, senderId, senderType, receiverId, receiverType);
    final secondartParty = receivedFrom.contains(("FAC_"))
        ? receivedFrom.replaceFirst("FAC_", "")
        : receivedFrom;

    final primaryType = BlocProvider.of<RecordStockBloc>(
      context,
    ).state.primaryType;

    final primaryId = BlocProvider.of<RecordStockBloc>(
      context,
    ).state.primaryId;

    switch (entryType) {
      case StockRecordEntryType.receipt:
      case StockRecordEntryType.loss:
      case StockRecordEntryType.damaged:
      case StockRecordEntryType.returned:
        senderId = secondaryPartyType == 'STAFF'
            ? secondartParty.split(Constants.pipeSeparator).last
            : secondartParty;
        senderType = secondaryPartyType;
        receiverId = primaryId;
        receiverType = primaryType;
        senderIdToShowOnTab = senderId;

        break;
      case StockRecordEntryType.dispatch:
        receiverId = secondaryPartyType == 'STAFF'
            ? secondartParty.split(Constants.pipeSeparator).last
            : secondartParty;
        receiverType = secondaryPartyType;
        senderId = primaryId;
        senderType = primaryType;
        senderIdToShowOnTab = senderId;
        break;
    }

    String? distributorName = secondaryPartyType == 'STAFF'
        ? secondartParty.split(Constants.pipeSeparator).first
        : null;

    return StockModel(
      id: null,
      facilityId: receivedFrom,
      productVariantId: product.id,
      quantity: _forms[productSku]
              ?.control(_transactionQuantityKey)
              ?.value
              ?.toString() ??
          '0',
      wayBillNumber:
          _forms[productSku]?.control(_waybillNumberKey)?.value?.toString(),
      transactionReason: transactionReason ??
          _forms[productSku]?.control(_transactionReasonKey)?.value?.toString(),
      clientReferenceId: IdGen.i.identifier,
      additionalFields: StockAdditionalFields(
        version: 1,
        fields: [
          AdditionalField('productName', product.sku),
          AdditionalField('variation', product.variation),
          AdditionalField('materialNoteNumber', _sharedMRN),
          if (distributorName != null)
            AdditionalField('distributorName', distributorName),
        ],
      ),
      referenceId: context.projectId,
      referenceIdType: 'PROJECT',
      transactingPartyId: null,
      transactingPartyType: null,
      receiverId: receiverId,
      receiverType: receiverType,
      senderId: senderId,
      senderType: senderType,
      nonRecoverableError: false,
      rowVersion: null,
      transactionType: transactionType,
      auditDetails: AuditDetails(
        createdBy: InventorySingleton().loggedInUserUuid,
        createdTime: context.millisecondsSinceEpoch(),
      ),
      clientAuditDetails: ClientAuditDetails(
        createdBy: InventorySingleton().loggedInUserUuid,
        createdTime: context.millisecondsSinceEpoch(),
        lastModifiedBy: InventorySingleton().loggedInUserUuid,
        lastModifiedTime: context.millisecondsSinceEpoch(),
      ),
    );
  }

  void setTransactionTypeAndReason(StockRecordEntryType entryType,
      String? transactionType, String? transactionReason) {
    // todo set the reasons , for othe entryType (can capture from field once added)

    switch (entryType) {
      case StockRecordEntryType.receipt:
        transactionType = TransactionType.received.toValue();
        transactionReason = TransactionReason.received.toValue();

        break;
      case StockRecordEntryType.dispatch:
        transactionType = TransactionType.dispatched.toValue();

        break;
      case StockRecordEntryType.returned:
        transactionType = TransactionType.received.toValue();
        transactionReason = TransactionReason.returned.toValue();

        break;
      case StockRecordEntryType.loss:
        transactionType = TransactionType.dispatched.toValue();

        break;
      case StockRecordEntryType.damaged:
        transactionType = TransactionType.dispatched.toValue();
        break;
    }
  }

  void setSenderReceiverIdAndType(
    StockRecordEntryType entryType,
    String? senderId,
    String? senderType,
    String? receiverId,
    String? receiverType,
  ) {
    // info captured on the transaction details , secondaryParty
    // additionalCheck to correct this ,(TODO :correct this at stock detail page )

    final secondartParty = receivedFrom.contains(("FAC_"))
        ? receivedFrom.replaceFirst("FAC_", "")
        : receivedFrom;

    final primaryType = BlocProvider.of<RecordStockBloc>(
      context,
    ).state.primaryType;

    final primaryId = BlocProvider.of<RecordStockBloc>(
      context,
    ).state.primaryId;

    switch (entryType) {
      case StockRecordEntryType.receipt:
      case StockRecordEntryType.loss:
      case StockRecordEntryType.damaged:
      case StockRecordEntryType.returned:
        senderId = secondartParty;
        senderType = "WAREHOUSE";
        receiverId = primaryId;
        receiverType = primaryType;

        break;
      case StockRecordEntryType.dispatch:
        receiverId = secondartParty;
        receiverType = "WAREHOUSE";
        senderId = primaryId;
        senderType = primaryType;
        break;
    }
  }

  Widget _buildTabContent(BuildContext context, String productName,
      String receivedFrom, List<String> selectedProducts) {
    // final theme = Theme.of(context);
    // final textTheme = theme.digitTextTheme(context);
    // final isDistributor = context.isDistributor;

    final stockState = context.read<RecordStockBloc>().state;
    bool isWareHouseMgr = InventorySingleton().isWareHouseMgr;
    final form = _forms[productName]!;
    StockRecordEntryType entryType = stockState.entryType;
    bool isLastTab = _tabController.index == _tabController.length - 1;
    String quantityCountLabel;
    String pageTitle;

    String quantityPartialCountLabel = "";

    String quantityWastedCountLabel = "";

    switch (entryType) {
      case StockRecordEntryType.receipt:
        pageTitle = i18.stockDetails.receivedPageTitle;
        if (productName == Constants.spaq1 || productName == Constants.spaq2) {
          quantityCountLabel = i18.stockDetails.quantityReceivedLabel;
        } else {
          quantityCountLabel = i18.stockDetails.quantityReceivedLabel;
        }
        break;
      case StockRecordEntryType.dispatch:
        pageTitle = InventorySingleton().isWareHouseMgr
            ? i18.stockDetails.issuedPageTitle
            : i18.stockDetails.returnedPageTitle;
        if (productName == Constants.spaq1 || productName == Constants.spaq2) {
          quantityCountLabel = InventorySingleton().isWareHouseMgr
              ? i18.stockDetails.quantitySentLabel
              : i18.stockDetails.quantityReturnedLabel;

          quantityPartialCountLabel =
              i18_local.stockDetails.quantityPartialReturnedLabel;

          quantityWastedCountLabel =
              i18_local.stockDetails.quantityWastedReturnedLabel;
        } else {
          quantityCountLabel = InventorySingleton().isWareHouseMgr
              ? i18.stockDetails.quantitySentLabel
              : i18.stockDetails.quantityReturnedLabel;
        }
        break;
      case StockRecordEntryType.returned:
        pageTitle = i18.stockDetails.returnedPageTitle;
        if (productName == Constants.spaq1 || productName == Constants.spaq2) {
          quantityCountLabel =
              i18_local.stockDetails.quantityUnusedReturnedLabel;
          quantityPartialCountLabel =
              i18_local.stockDetails.quantityPartialReturnedLabel;
        } else {
          quantityCountLabel = i18.stockDetails.quantityReturnedLabel;
        }
        break;
      case StockRecordEntryType.loss:
        pageTitle = i18.stockDetails.lostPageTitle;
        quantityCountLabel = i18.stockDetails.quantityLostLabel;

        break;
      case StockRecordEntryType.damaged:
        pageTitle = i18.stockDetails.damagedPageTitle;
        quantityCountLabel = i18.stockDetails.quantityDamagedLabel;
        break;
    }

    if ((entryType == StockRecordEntryType.dispatch &&
            context.isCommunityDistributor) ||
        entryType == StockRecordEntryType.returned) {
      form.control(_transactionQuantityPartialKey).setValidators([
        Validators.number(),
        Validators.required,
        Validators.min(0),
        Validators.max(1000000),
      ], autoValidate: true);
    }

    if (entryType == StockRecordEntryType.dispatch &&
        context.isCommunityDistributor) {
      form.control(_transactionQuantityWastedKey).setValidators([
        Validators.number(),
        Validators.required,
        Validators.min(0),
        Validators.max(1000000),
      ], autoValidate: true);
    }

    return _KeepAliveTabContent(
      child: ReactiveForm(
        formGroup: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DigitCard(
              padding: const EdgeInsets.all(16),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate(pageTitle),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(child: Text('Resource')),
                        Expanded(child: Text(productName)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text((context.isCDD &&
                                  entryType == StockRecordEntryType.dispatch)
                              ? localizations
                                  .translate(i18_local.stockDetails.returnedTo)
                              : localizations.translate(
                                  '${pageTitle}_${i18.stockReconciliationDetails.stockLabel}')),
                        ),
                        Expanded(
                            child: Text(
                          secondaryPartyType == 'STAFF'
                              ? receivedFrom.split(Constants.pipeSeparator)[0]
                              : localizations.translate('FAC_$receivedFrom'),
                        )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            DigitCard(
              padding: const EdgeInsets.all(16),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (isWareHouseMgr)
                      ReactiveWrapperField(
                          formControlName: _waybillNumberKey,
                          builder: (field) {
                            return InputField(
                              type: InputType.text,
                              label: localizations.translate(
                                i18.stockDetails.waybillNumberLabel,
                              ),
                              errorMessage: field.errorText,
                              onChange: (val) {
                                field.control.value = val;
                              },
                              isRequired: true,
                            );
                          }),
                    if (isWareHouseMgr &&
                        entryType != StockRecordEntryType.returned)
                      ReactiveWrapperField(
                          formControlName: _batchNumberKey,
                          builder: (field) {
                            return InputField(
                              type: InputType.text,
                              label: localizations.translate(
                                i18_local.stockDetails.batchNumberLabel,
                              ),
                              errorMessage: field.errorText,
                              onChange: (val) {
                                if (val == '') {
                                  field.control.value = '0';
                                } else {
                                  field.control.value = val;
                                }
                              },
                            );
                          }),
                    const SizedBox(height: 16),
                    ReactiveWrapperField(
                        formControlName: _transactionQuantityKey,
                        validationMessages: {
                          "number": (object) => localizations.translate(
                                '${quantityCountLabel}_ERROR',
                              ),
                          "max": (object) => localizations.translate(
                                '${quantityCountLabel}_MAX_ERROR',
                              ),
                          "min": (object) => localizations.translate(
                                '${quantityCountLabel}_MIN_ERROR',
                              ),
                        },
                        showErrors: (control) =>
                            control.invalid && control.touched,
                        builder: (field) {
                          return LabeledField(
                            label: localizations.translate(
                              quantityCountLabel,
                            ),
                            isRequired: true,
                            child: BaseDigitFormInput(
                              errorMessage: field.errorText,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]'),
                                ),
                                LengthLimitingTextInputFormatter(9),
                              ],
                              onChange: (val) {
                                field.control.markAsTouched();
                                if (val == "") {
                                  field.control.value = null;
                                  return;
                                }
                                if (int.parse(val) > 10000000000) {
                                  field.control.value = 10000;
                                } else {
                                  if (val != '') {
                                    field.control.value = int.parse(val);
                                  } else {
                                    field.control.value = null;
                                  }
                                }
                              },
                            ),
                          );
                        }),
                    // TODO:
                    if ((entryType == StockRecordEntryType.dispatch &&
                            context.isCommunityDistributor) ||
                        entryType == StockRecordEntryType.returned)
                      ReactiveWrapperField(
                          formControlName: _transactionQuantityPartialKey,
                          validationMessages: {
                            "number": (object) => localizations.translate(
                                  '${quantityCountLabel}_ERROR',
                                ),
                            "max": (object) => localizations.translate(
                                  '${quantityCountLabel}_MAX_ERROR',
                                ),
                            "min": (object) => localizations.translate(
                                  '${quantityCountLabel}_MIN_ERROR',
                                ),
                          },
                          showErrors: (control) =>
                              control.invalid && control.touched,
                          builder: (field) {
                            return LabeledField(
                              label: localizations.translate(
                                quantityPartialCountLabel,
                              ),
                              isRequired: true,
                              child: BaseDigitFormInput(
                                errorMessage: field.errorText,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]'),
                                  ),
                                  LengthLimitingTextInputFormatter(9),
                                ],
                                onChange: (val) {
                                  field.control.markAsTouched();

                                  if (val == "") {
                                    field.control.value = null;

                                    return;
                                  }

                                  if (int.parse(val) > 10000000000) {
                                    field.control.value = 10000;
                                  } else {
                                    if (val != '') {
                                      field.control.value = int.parse(val);
                                    } else {
                                      field.control.value = null;
                                    }
                                  }
                                },
                              ),
                            );
                          }),

                    if (entryType == StockRecordEntryType.dispatch &&
                        context.isCommunityDistributor)
                      ReactiveWrapperField(
                          formControlName: _transactionQuantityWastedKey,
                          validationMessages: {
                            "number": (object) => localizations.translate(
                                  '${quantityCountLabel}_ERROR',
                                ),
                            "max": (object) => localizations.translate(
                                  '${quantityCountLabel}_MAX_ERROR',
                                ),
                            "min": (object) => localizations.translate(
                                  '${quantityCountLabel}_MIN_ERROR',
                                ),
                          },
                          showErrors: (control) =>
                              control.invalid && control.touched,
                          builder: (field) {
                            return LabeledField(
                              label: localizations.translate(
                                quantityWastedCountLabel,
                              ),
                              isRequired: true,
                              child: BaseDigitFormInput(
                                errorMessage: field.errorText,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]'),
                                  ),
                                  LengthLimitingTextInputFormatter(9),
                                ],
                                onChange: (val) {
                                  field.control.markAsTouched();

                                  if (val == "") {
                                    field.control.value = null;

                                    return;
                                  }

                                  if (int.parse(val) > 10000000000) {
                                    field.control.value = 10000;
                                  } else {
                                    if (val != '') {
                                      field.control.value = int.parse(val);
                                    } else {
                                      field.control.value = null;
                                    }
                                  }
                                },
                              ),
                            );
                          }),
                    // ReactiveWrapperField(
                    //   formControlName: _waybillQuantityKey,
                    //   builder: (field) {
                    //     return InputField(
                    //       type: InputType.text,
                    //       label: 'Quantity of Blisters' + ,
                    //       errorMessage: field.errorText,
                    //       onChange: (val) {
                    //         if (val == '') {
                    //           field.control.value = '0';
                    //         } else {
                    //           field.control.value = val;
                    //         }
                    //       },
                    //       isRequired: true,
                    //     );
                    //   },
                    // ),
                    const SizedBox(height: 16),
                    ReactiveWrapperField(
                      formControlName: _commentsKey,
                      builder: (field) {
                        return InputField(
                          type: InputType.textArea,
                          label: localizations.translate(
                            i18.stockDetails.commentsLabel,
                          ),
                          errorMessage: field.errorText,
                          onChange: (val) => field.control.value = val,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DigitButton(
                  size: DigitButtonSize.large,
                  type: DigitButtonType.primary,
                  onPressed: () async {
                    if (form.valid) {
                      //TODO:
                      // bool isValid =
                      //     await _saveCurrentTabData(productName, entryType);
                      // if (!isValid) {
                      //   return;
                      // }

                      if (_tabController.index < products.length - 1) {
                        if (form.valid) {
                          _tabController.animateTo(_tabController.index + 1);
                        }
                      } else {
                        int index = 0;
                        for (final form in _forms.values) {
                          form.markAllAsTouched();
                          if (form.invalid) {
                            _tabController.animateTo(index);
                            return;
                          }
                          index++;
                        }
                        await _handleFinalSubmission(
                            context, entryType, selectedProducts);
                      }
                    } else {
                      form.markAllAsTouched();
                    }
                  },
                  label: isLastTab
                      ? localizations.translate(i18.common.coreCommonSubmit)
                      : localizations.translate(i18.common.coreCommonNext),
                ),
                const SizedBox(height: 12),
                // DigitButton(
                //   type: DigitButtonType.secondary,
                //   size: DigitButtonSize.large,
                //   onPressed: () {
                //     // Secondary action if needed
                //   },
                //   label: localizations.translate(
                //     i18.common.coreCommonCancel,
                //   ),
                // ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<bool> _saveCurrentTabData(
      String productName, StockRecordEntryType entryType) async {
    final form = _forms[productName]!;
    final currentStock = _tabStocks[productName]!;

    final theme = Theme.of(context);

    _tabStocks[productName] = currentStock.copyWith(
      //TODO:
      // quantity: form.control(_transactionQuantityKey).value?.toString() != "0"
      //     ? form.control(_transactionQuantityKey).value?.toString()
      //     : (_forms[productName]?.value)?["quantity"] as String?,
      // wayBillNumber: form.control(_waybillNumberKey).value?.toString() ??
      //     (_forms[productName]?.value)?["waybillNumber"] as String?,

      quantity: form.control(_transactionQuantityKey).value?.toString(),

      wayBillNumber: form.control(_waybillNumberKey).value?.toString(),
      transactionReason:
          form.control(_transactionReasonKey).value?.toString() ??
              transactionReason,
      additionalFields: currentStock.additionalFields?.copyWith(
        fields: [
          // ...(currentStock.additionalFields?.fields ?? []),
          // if (form.control(_batchNumberKey).value != null) ...[
          //   AdditionalField('batchNumber', form.control(_batchNumberKey).value),
          // ] else if ((_forms[productName]?.value)?["batchNumberKey"] !=
          //     null) ...[
          //   AdditionalField(
          //       'batchNumber', (_forms[productName]?.value)?["batchNumberKey"]),
          // ],
          // if (form.control(_commentsKey).value != null) ...[
          //   AdditionalField('comments', form.control(_commentsKey).value),
          // ] else if ((_forms[productName]?.value)?["comments"] != null) ...[
          //   AdditionalField(
          //       'comments', (_forms[productName]?.value)?["comments"]),
          // ]

          ...(currentStock.additionalFields?.fields ?? []),

          if (form.control(_batchNumberKey).value != null)
            AdditionalField('batchNumber', form.control(_batchNumberKey).value),

          if (form.control(_commentsKey).value != null)
            AdditionalField('comments', form.control(_commentsKey).value),

          if (form.control(_transactionQuantityPartialKey).value != null)
            AdditionalField('partialBlistersReturned',
                form.control(_transactionQuantityPartialKey).value),

          if (form.control(_transactionQuantityWastedKey).value != null)
            AdditionalField('wastedBlistersReturned',
                form.control(_transactionQuantityWastedKey).value),
        ],
      ),
    );

//     bool isSubtracted = (entryType == StockRecordEntryType.dispatch ||
//         entryType == StockRecordEntryType.returned);
//     final ss = int.parse(
//         form.control(_transactionQuantityKey).value?.toString() ?? "0");

//     final spaq1Count = context.spaq1;
//     final spaq2Count = context.spaq2;

//     final blueVasCount = context.blueVas;
//     final redVasCount = context.redVas;

//     // Custom logic based on productName
//     if (productName == Constants.spaq1 && isSubtracted && ss > spaq1Count) {
//       await DigitToast.show(
//         context,
//         options: DigitToastOptions(
//             localizations.translate((entryType == StockRecordEntryType.dispatch)
//                 ? i18_local.beneficiaryDetails.validationForExcessStockDispatch
//                 : i18_local.beneficiaryDetails.validationForExcessStockReturn),
//             true,
//             theme),
//       );
//       return false;
//     } else if (productName == Constants.spaq2 &&
//         isSubtracted &&
//         ss > spaq2Count) {
//       await DigitToast.show(
//         context,
//         options: DigitToastOptions(
//             localizations.translate((entryType == StockRecordEntryType.dispatch)
//                 ? i18_local.beneficiaryDetails.validationForExcessStockDispatch
//                 : i18_local.beneficiaryDetails.validationForExcessStockReturn),
//             true,
//             theme),
//       );
//       return false;
//     } else if (productName == Constants.blueVAS &&
//         isSubtracted &&
//         ss > blueVasCount) {
//       await DigitToast.show(
//         context,
//         options: DigitToastOptions(
//             localizations.translate((entryType == StockRecordEntryType.dispatch)
//                 ? i18_local.beneficiaryDetails.validationForExcessStockDispatch
//                 : i18_local.beneficiaryDetails.validationForExcessStockReturn),
//             true,
//             theme),
//       );
//       return false;
//     } else if (productName == Constants.redVAS &&
//         isSubtracted &&
//         ss > redVasCount) {
//       await DigitToast.show(
//         context,
//         options: DigitToastOptions(
//             localizations.translate((entryType == StockRecordEntryType.dispatch)
//                 ? i18_local.beneficiaryDetails.validationForExcessStockDispatch
//                 : i18_local.beneficiaryDetails.validationForExcessStockReturn),
//             true,
//             theme),
//       );
//       return false;
//     }

//     final recordStock = context.read<RecordStockBloc>().state;
//     context.read<RecordStockBloc>().add(
//           RecordStockSaveStockDetailsEvent(
//             stockModel: currentStock,
//           ),
//         );

//     final isDistributor = context.isDistributor;

// //     if ((ss > context.spaq1 ||
// //             ss > context.spaq2 ||
// //             ss > context.blueVas ||
// //             ss > context.redVas) &&
// //         context.isDistributor &&
// //         recordStock.entryType == StockRecordEntryType.dispatch) {
// // //       showCustomPopup(
// // //         context: context,
// // //         builder: (popupContext) => Popup(
// // //           title:
// // //               localizations.translate(i18_local.beneficiaryDetails.errorHeader),
// // //           onOutsideTap: () {
// // //             Navigator.of(popupContext).pop(false);
// // //           },
// // //           description: localizations.translate(
// // //             i18_local.beneficiaryDetails.validationForExcessStock,
// // //           ),
// // //           type: PopUpType.simple,
// // //           actions: [
// // //             DigitButton(
// // //               label: localizations.translate(
// // //                 i18_local.common.coreCommonCancel,
// // //               ),
// // //               onPressed: () {
// // //                 Navigator.of(
// // //                   popupContext,
// // //                   rootNavigator: true,
// // //                 ).pop();
// // // //
// // //               },
// // //               type: DigitButtonType.primary,
// // //               size: DigitButtonSize.large,
// // //             ),
// // //           ],
// // //         ),
// // //       );

// //       return;
// //     }
//     // bool submit = false;
//     // if (_tabController.index == _tabController.length - 1) {
//     //   submit = await showCustomPopup(
//     //     context: context,
//     //     builder: (popupContext) => Popup(
//     //       title: localizations.translate(i18.stockDetails.dialogTitle),
//     //       onOutsideTap: () {
//     //         Navigator.of(popupContext).pop(false);
//     //       },
//     //       description: localizations.translate(
//     //         i18.stockDetails.dialogContent,
//     //       ),
//     //       type: PopUpType.simple,
//     //       actions: [
//     //         DigitButton(
//     //           label: localizations.translate(
//     //             i18.common.coreCommonSubmit,
//     //           ),
//     //           onPressed: () {
//     //             Navigator.of(
//     //               popupContext,
//     //               rootNavigator: true,
//     //             ).pop(true);
//     //             Navigator.of(context, rootNavigator: true).pop(true);
//     //             Navigator.of(context).push(
//     //               MaterialPageRoute(
//     //                 builder: (context) => CustomAcknowledgementPage(
//     //                   mrnNumber: _sharedMRN,
//     //                   stockRecords: _tabStocks.values.toList(),
//     //                 ),
//     //               ),
//     //             );
//     //             // todo : correct the routing here to show , page where we can see transactions
//     //           },
//     //           type: DigitButtonType.primary,
//     //           size: DigitButtonSize.large,
//     //         ),
//     //         DigitButton(
//     //           label: localizations.translate(
//     //             i18.common.coreCommonCancel,
//     //           ),
//     //           onPressed: () {
//     //             Navigator.of(
//     //               popupContext,
//     //               rootNavigator: true,
//     //             ).pop(false);
//     //           },
//     //           type: DigitButtonType.secondary,
//     //           size: DigitButtonSize.large,
//     //         ),
//     //       ],
//     //     ),
//     //   ) as bool;
//     // }

    return true;
  }

  Future<void> _handleFinalSubmission(BuildContext context,
      StockRecordEntryType entryType, List<String> selectedProducts) async {
    final lastProduct = products.last.sku ?? '';

    final theme = Theme.of(context);

    final submit = await showCustomPopup(
      context: context,
      builder: (popupContext) => Popup(
        title: localizations.translate(i18.stockDetails.dialogTitle),
        onOutsideTap: () {
          Navigator.of(popupContext).pop(false);
        },
        description: localizations.translate(
          i18.stockDetails.dialogContent,
        ),
        type: PopUpType.simple,
        actions: [
          DigitButton(
            label: localizations.translate(
              i18.common.coreCommonSubmit,
            ),
            onPressed: () {
              Navigator.of(
                popupContext,
              ).pop(true);
            },
            type: DigitButtonType.primary,
            size: DigitButtonSize.large,
          ),
          DigitButton(
            label: localizations.translate(
              i18.common.coreCommonCancel,
            ),
            onPressed: () {
              Navigator.of(
                popupContext,
              ).pop(false);
            },
            type: DigitButtonType.secondary,
            size: DigitButtonSize.large,
          ),
        ],
      ),
    ) as bool;

    if (submit && context.mounted) {
      int currentSpaq1Count = context.spaq1;

      int currentSpaq2Count = context.spaq2;

      int spaq1Count = 0;

      int spaq2Count = 0;

      for (var productName in selectedProducts) {
        await _saveCurrentTabData(productName, entryType);
      }

      final stockState = context.read<RecordStockBloc>().state;
      // Loop through all stocks and dispatch individual events
      for (final stockModel in _tabStocks.values) {
        int quantity = int.parse(stockModel.quantity.toString());

        int quantityWasted = int.parse(stockModel.additionalFields?.fields
                .firstWhereOrNull(
                    (element) => element.key == 'wastedBlistersReturned')
                ?.value
                ?.toString() ??
            '0');

        final totalQty = ((entryType == StockRecordEntryType.dispatch)
                ? quantity * -1
                : quantity) -
            quantityWasted;

        String? productName = stockModel.additionalFields?.fields
            .firstWhereOrNull((element) => element.key == 'productName')
            ?.value;

        // Custom logic based on productName

        if (entryType == StockRecordEntryType.dispatch) {
          if (productName == Constants.spaq1 &&
              (currentSpaq1Count + totalQty < 0)) {
            await DigitToast.show(
              context,
              options: DigitToastOptions(
                  localizations.translate(context.isCDD
                      ? i18_local
                          .beneficiaryDetails.validationForExcessStockReturn
                      : i18_local
                          .beneficiaryDetails.validationForExcessStockDispatch),
                  true,
                  theme),
            );
            return;
          } else if (productName == Constants.spaq2 &&
              (currentSpaq2Count + totalQty < 0)) {
            await DigitToast.show(
              context,
              options: DigitToastOptions(
                  localizations.translate(context.isCDD
                      ? i18_local
                          .beneficiaryDetails.validationForExcessStockReturn
                      : i18_local
                          .beneficiaryDetails.validationForExcessStockDispatch),
                  true,
                  theme),
            );
            return;
          }
        }

        if (productName == Constants.spaq1) {
          spaq1Count = totalQty;
        } else if (productName == Constants.spaq2) {
          spaq2Count = totalQty;
        }

        final bloc = RecordStockBloc(
          stockRepository: context.repository<StockModel, StockSearchModel>(),
          RecordStockCreateState(
            entryType: stockState.entryType,
            projectId: InventorySingleton().projectId,
            dateOfRecord: DateTime.now(),
            facilityModel: FacilityModel(
              id: context.loggedInUserUuid,
            ),
            primaryId: context.loggedInUserUuid,
            primaryType: "STAFF",
          ),
        );

        bloc.add(
          RecordStockSaveStockDetailsEvent(
            stockModel: stockModel,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500), () {});
        bloc.add(
          const RecordStockCreateStockEntryEvent(),
        );

        bloc.close();

//TODO: commented [pitabash], previous code
        // context.read<RecordStockBloc>().add(
        //       RecordStockSaveStockDetailsEvent(
        //         stockModel: stockModel,
        //       ),
        //     );
        // context.read<RecordStockBloc>().add(
        //       const RecordStockCreateStockEntryEvent(),
        //     );
      }

      context.read<AuthBloc>().add(
            AuthAddSpaqCountsEvent(
              spaq1Count: spaq1Count,
              spaq2Count: spaq2Count,
              blueVasCount: 0,
              redVasCount: 0,
            ),
          );
          

      (context.router.parent() as StackRouter).maybePop();

      context.router.push(CustomAcknowledgementRoute(
          mrnNumber: _sharedMRN,
          stockRecords: _tabStocks.values.toList(),
          entryType: entryType));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedProducts =
        products.map((variant) => variant.sku).whereType<String>().toList();

    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: selectedProducts
              .map((product) => Tab(text: product.toUpperCase()))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: selectedProducts
            .map((product) => _buildTabContent(
                context, product, receivedFrom, selectedProducts))
            .toList(),
      ),
    );
  }

  void _nextTab() {
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

//TODO:
  // String? wastageQuantity(FormGroup form, BuildContext context) {
  //   final quantity = form.control(_transactionQuantityKey).value;
  //   final partialBlisters = form.control(_transactionQuantityKey).value;

  //   if (quantity == null || partialBlisters == null) {
  //     return null;
  //   }

  //   int totalQuantity = 0;
  //   int totalRemainingQuantityInMl = context.spaq1;

  //   int totalExpectedUnusedBottles =
  //       totalRemainingQuantityInMl ~/ Constants.mlPerBottle;

  //   int totalExpectedPartialQuantityInMl =
  //       totalRemainingQuantityInMl % Constants.mlPerBottle;

  //   int totalExpectedPartialBottles =
  //       totalRemainingQuantityInMl % Constants.mlPerBottle != 0 ? 1 : 0;

  //   totalQuantity = quantity != null ? int.parse(quantity.toString()) : 0;

  //   return (((totalExpectedUnusedBottles - totalQuantity) *
  //               Constants.mlPerBottle) +
  //           ((totalExpectedPartialBottles >
  //                   (partialBlisters != null
  //                       ? int.parse(partialBlisters.toString())
  //                       : 0))
  //               ? totalExpectedPartialQuantityInMl
  //               : 0))
  //       .toString();
  // }

  num _getQuantityCount(Iterable<StockModel> stocks) {
    return stocks.fold<num>(
      0.0,
      (old, e) => (num.tryParse(e.quantity ?? '') ?? 0.0) + old,
    );
  }

  void clearQRCodes() {
    context.read<DigitScannerBloc>().add(const DigitScannerEvent.handleScanner(
          barCode: [],
          qrCode: [],
        ));
  }

  bool _isCurrentTabValid() {
    return _formkeys[_tabController.index].currentState?.validate() ?? false;
  }
}

class _KeepAliveTabContent extends StatefulWidget {
  final Widget child;

  const _KeepAliveTabContent({required this.child});

  @override
  State<_KeepAliveTabContent> createState() => _KeepAliveTabContentState();
}

class _KeepAliveTabContentState extends State<_KeepAliveTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
