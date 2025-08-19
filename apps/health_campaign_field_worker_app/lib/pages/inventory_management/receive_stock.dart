import 'package:auto_route/auto_route.dart';
import 'package:digit_components/widgets/atoms/digit_date_form_picker.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/widgets/atoms/input_wrapper.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/models/entities/transaction_reason.dart';
import 'package:inventory_management/models/entities/transaction_type.dart';
import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
import 'package:inventory_management/utils/utils.dart';
import 'package:registration_delivery/widgets/localized.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../blocs/auth/auth.dart';
import '../../router/app_router.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions/extensions.dart';
import 'package:collection/collection.dart';

import '../../widgets/custom_back_navigation.dart';
import '../../utils/i18_key_constants.dart' as i18_local;

@RoutePage()
class ReceiveStockPage extends LocalizedStatefulWidget {
  final String mrnNumber;
  final List<StockModel> stockRecords;

  const ReceiveStockPage({
    super.key,
    super.appLocalizations,
    required this.mrnNumber,
    required this.stockRecords,
  });

  @override
  State<ReceiveStockPage> createState() => _ViewStockRecordsLGAPageState();
}

class _ViewStockRecordsLGAPageState extends LocalizedState<ReceiveStockPage> {
  static const _expireDateKey = 'expireDate';
  static const _quantityReceivedKey = 'quantityReceived';
  static const _commentsKey = 'comments';

  DateTime before150Years = DateTime(
      DateTime.now().year - 150, DateTime.now().month, DateTime.now().day);
  DateTime after150Years = DateTime(
      DateTime.now().year + 150, DateTime.now().month, DateTime.now().day);

  late final FormGroup _form;
  late final Map<String, int> _issuedQuantities;
  bool _commentsRequired = false;
  bool isSubmitClicked = false;

  @override
  void initState() {
    super.initState();
    _issuedQuantities = {
      for (final stock in widget.stockRecords)
        stock.additionalFields?.fields
                .firstWhereOrNull((f) => f.key == 'productName')
                ?.value
                .toString() ??
            '': int.tryParse(stock.quantity ?? '0') ?? 0
    };
    _form = FormGroup({
      _quantityReceivedKey: FormControl<int>(
        validators: [
          Validators.required,
          Validators.min(1),
          Validators.delegate((control) {
            final productName = widget
                    .stockRecords.first.additionalFields?.fields
                    .firstWhereOrNull((f) => f.key == 'productName')
                    ?.value
                    .toString() ??
                '';
            final issued = _issuedQuantities[productName] ?? 0;
            final received = control.value ?? 0;
            if (received > issued) {
              return {'maxIssued': true};
            }
            return null;
          })
        ],
      ),
      _expireDateKey: FormControl<DateTime>(
        validators: [
          Validators.required,
        ],
      ),
      _commentsKey: FormControl<String>(),
    });
    _form.control(_quantityReceivedKey).valueChanges.listen((value) {
      final received = value ?? 0;
      final productName = widget.stockRecords.first.additionalFields?.fields
              .firstWhereOrNull((f) => f.key == 'productName')
              ?.value
              .toString() ??
          '';
      final issued = _issuedQuantities[productName] ?? 0;
      final required = received < issued;
      if (_commentsRequired != required) {
        setState(() {
          _commentsRequired = required;
        });
      }
    });
    _form.control(_commentsKey).setValidators([
      Validators.delegate((control) {
        final received = _form.control(_quantityReceivedKey).value ?? 0;
        final productName = widget.stockRecords.first.additionalFields?.fields
                .firstWhereOrNull((f) => f.key == 'productName')
                ?.value
                .toString() ??
            '';
        final issued = _issuedQuantities[productName] ?? 0;
        if (received < issued &&
            (control.value == null || control.value.isEmpty)) {
          control.markAllAsTouched();
          return {'requiredIfShort': true};
        }
        return null;
      })
    ]);
    _form.control(_quantityReceivedKey).valueChanges.listen((value) {
      _form.control(_commentsKey).updateValueAndValidity();
    });
    final recordStockBloc = BlocProvider.of<RecordStockBloc>(context);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _handleSubmission() async {
    if (_form.valid && !isSubmitClicked) {
      isSubmitClicked = true;
      DateTime? expireDate = _form.control(_expireDateKey).value;
      Set<String> additionalKeys = {
        'quantitySent',
        _quantityReceivedKey,
        _expireDateKey,
        _commentsKey,
      };
      final updatedStocks = widget.stockRecords.map((stock) {
        final additionalFields = stock.additionalFields?.fields ?? [];
        final filteredAdditionalFields = additionalFields
            .whereNot((field) => additionalKeys.contains(field.key))
            .toList();

        filteredAdditionalFields.addAll([
          if (stock.quantity != null)
            AdditionalField(
              'quantitySent',
              stock.quantity,
            ),
          if (_form.control(_quantityReceivedKey).value != null)
            AdditionalField(_quantityReceivedKey,
                _form.control(_quantityReceivedKey).value.toString()),
          if (expireDate != null)
            AdditionalField(_expireDateKey, expireDate.millisecondsSinceEpoch),
          if (_form.control(_commentsKey).value != null)
            AdditionalField(_commentsKey, _form.control(_commentsKey).value),
        ]);

        // final newFields = [
        //   ...additionalFields.where((field) =>
        //       field.key != _quantityReceivedKey && field.key != _commentsKey),
        //   AdditionalField(_quantityReceivedKey,
        //       _form.control(_quantityReceivedKey).value.toString()),
        //   AdditionalField(
        //     'quantitySent',
        //     stock.quantity ?? '',
        //   ),
        //   if (_form.control(_expireDateKey).value != null)
        //     AdditionalField(
        //         _expireDateKey, _form.control(_expireDateKey).value),
        //   if (_form.control(_commentsKey).value != null)
        //     AdditionalField(_commentsKey, _form.control(_commentsKey).value),
        // ];

        return stock.copyWith(
          id: null,
          rowVersion: 1,
          clientReferenceId: IdGen.i.identifier,
          referenceId: context.selectedProject.id,
          transactionType: TransactionType.received.toValue(),
          transactionReason: TransactionReason.received.toValue(),
          quantity: _form.control(_quantityReceivedKey).value.toString(),
          additionalFields: stock.additionalFields?.copyWith(
            fields: filteredAdditionalFields,
          ),
          auditDetails: AuditDetails(
            createdBy: InventorySingleton().loggedInUserUuid,
            createdTime: context.millisecondsSinceEpoch(),
            lastModifiedBy: InventorySingleton().loggedInUserUuid,
            lastModifiedTime: context.millisecondsSinceEpoch(),
          ),
          clientAuditDetails: ClientAuditDetails(
            createdBy: InventorySingleton().loggedInUserUuid,
            createdTime: context.millisecondsSinceEpoch(),
            lastModifiedBy: InventorySingleton().loggedInUserUuid,
            lastModifiedTime: context.millisecondsSinceEpoch(),
          ),
        );
      }).toList();

      final stockState = context.read<RecordStockBloc>().state;
      for (final stock in updatedStocks) {
        final bloc = RecordStockBloc(
          stockRepository: context.repository<StockModel, StockSearchModel>(),
          RecordStockCreateState(
            entryType: stockState.entryType,
            projectId: InventorySingleton().projectId,
            dateOfRecord: DateTime.now(),
            facilityModel: stockState.facilityModel ??
                FacilityModel(
                  id: stockState.primaryId ?? context.loggedInUserUuid,
                ),
            primaryId: stockState.primaryId,
            primaryType: stockState.primaryType,
          ),
        );

        bloc.add(
          RecordStockSaveStockDetailsEvent(
            stockModel: stock,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500), () {});
        bloc.add(
          const RecordStockCreateStockEntryEvent(),
        );

        bloc.close();

        //TODO: old
        // context.read<RecordStockBloc>().add(
        //       RecordStockSaveStockDetailsEvent(
        //         stockModel: stock,
        //       ),
        //     );
        // context.read<RecordStockBloc>().add(
        //       const RecordStockCreateStockEntryEvent(),
        //     );

        // end of it
        // if (InventorySingleton().isDistributor) {
        final totalQty =
            int.parse(_form.control(_quantityReceivedKey).value.toString());

        int bednetCount = context.bednet;

        int spaq1Count = context.spaq1;
        int spaq2Count = context.spaq2;

        int blueVasCount = context.blueVas;
        int redVasCount = context.redVas;
        String productName = stock.additionalFields?.fields
            .firstWhereOrNull((element) => element.key == "productName")
            ?.value;
        // Custom logic based on productName
        if (productName == Constants.bednet) {
          bednetCount = totalQty;
          spaq1Count = 0;
          spaq2Count = 0;
          redVasCount = 0;
          blueVasCount = 0;
        } else if (productName == Constants.spaq1) {
          bednetCount = 0;
          spaq1Count = totalQty;
          spaq2Count = 0;
          redVasCount = 0;
          blueVasCount = 0;
        } else if (productName == Constants.spaq2) {
          bednetCount = 0;
          spaq2Count = totalQty;
          spaq1Count = 0;
          redVasCount = 0;
          blueVasCount = 0;
        } else if (productName == Constants.blueVAS) {
          bednetCount = 0;
          blueVasCount = totalQty;
          spaq1Count = 0;
          spaq2Count = 0;
          redVasCount = 0;
        } else {
          bednetCount = 0;
          blueVasCount = 0;
          spaq1Count = 0;
          spaq2Count = 0;
          redVasCount = totalQty;
        }
        context.read<AuthBloc>().add(
              AuthAddProductCountsEvent(
                bednetCount: bednetCount,
                spaq1Count: spaq1Count,
                spaq2Count: spaq2Count,
                blueVasCount: blueVasCount,
                redVasCount: redVasCount,
              ),
            );
        await Future.delayed(const Duration(milliseconds: 500));
        // _tabController.animateTo(_tabController.index + 1);
        // await Future.delayed(const Duration(milliseconds: 500));
        // context.read<RecordStockBloc>().add(
        //       const RecordStockCreateStockEntryEvent(),
        //     );
        // }
      }

      context.router.push(
        CustomAcknowledgementRoute(
            mrnNumber: widget.mrnNumber,
            stockRecords: updatedStocks,
            entryType: StockRecordEntryType.receipt),
      );
    } else {
      _form.markAllAsTouched();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assumption sender receiver Id not changed ,
    //using the same as downloaded stock data
    // and this flow is for stock receipt for LGA
    final senderIdToShowOnTab = widget.stockRecords.first.senderId;
    bool commentRequired = false;

    return Scaffold(
      body: ScrollableContent(
        header: const Column(
          children: [
            CustomBackNavigationHelpHeaderWidget(),
          ],
        ),
        children: [
          ReactiveForm(
            formGroup: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DigitCard(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate(
                                i18_local.stockDetails.stockReceiptDetails),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                localizations.translate(
                                    i18_local.stockDetails.mrnNumber),
                              )),
                              Expanded(child: Text(widget.mrnNumber)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: Text('Received from')),
                              // TODO : verify this , showing senderId here
                              Expanded(
                                child: Text(localizations
                                    .translate('FAC_$senderIdToShowOnTab')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...widget.stockRecords.map((stock) {
                    final productName = stock.additionalFields?.fields
                            .firstWhere(
                              (field) => field.key == 'productName',
                              orElse: () => AdditionalField('productName', ''),
                            )
                            .value
                            ?.toString() ??
                        '';

                    return Column(
                      children: [
                        DigitCard(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: productName == 'SPAQ 1' ||
                                            productName == 'SPAQ 2'
                                        ? Colors.orange
                                        : productName == 'Red VAS'
                                            ? Colors.red
                                            : productName == 'Blue VAS'
                                                ? Colors.blue
                                                : Theme.of(context)
                                                    .primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InputField(
                                  type: InputType.text,
                                  label: localizations.translate(
                                      i18_local.stockDetails.waybillNumber),
                                  initialValue: stock.wayBillNumber ?? '',
                                  isDisabled: true,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 12),
                                InputField(
                                  type: InputType.text,
                                  label: localizations.translate(
                                      i18_local.stockDetails.batchNumberLabel),
                                  initialValue: stock.additionalFields?.fields
                                          .firstWhere(
                                            (field) =>
                                                field.key == 'batchNumber',
                                            orElse: () => AdditionalField(
                                                'batchNumber', ''),
                                          )
                                          .value
                                          ?.toString() ??
                                      '',
                                  isDisabled: true,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 12),
                                InputField(
                                  type: InputType.text,
                                  label: localizations.translate(i18_local
                                      .stockDetails.quantitySentByWarehouse),
                                  initialValue: stock.quantity ?? '',
                                  isDisabled: true,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 12),
                                ReactiveWrapperField(
                                  formControlName: _quantityReceivedKey,
                                  builder: (field) => InputField(
                                    type: InputType.text,
                                    label: localizations.translate(i18_local
                                        .stockDetails.actualQuantityReceived),
                                    isRequired: true,
                                    errorMessage: field.errorText,
                                    keyboardType: TextInputType.number,
                                    onChange: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        field.control.value =
                                            int.tryParse(value);
                                      } else {
                                        field.control.value = null;
                                      }
                                    },
                                  ),
                                  validationMessages: {
                                    'required': (_) => localizations.translate(
                                        i18_local
                                            .stockDetails.quantityRequired),
                                    'min': (_) => localizations.translate(
                                        i18_local
                                            .stockDetails.quantityMinError),
                                    'number': (_) => localizations.translate(
                                        i18_local
                                            .stockDetails.quantityInvalidError),
                                    'maxIssued': (_) => localizations.translate(
                                        i18_local
                                            .stockDetails.quantityMaxError),
                                  },
                                ),
                                DigitDateFormPicker(
                                  label: localizations.translate(
                                      i18_local.stockDetails.expireDate),
                                  isRequired: true,
                                  start: before150Years,
                                  formControlName: _expireDateKey,
                                  validationMessages: {
                                    'required': (_) => localizations.translate(
                                        i18_local
                                            .stockDetails.expireDateRequired),
                                  },
                                  cancelText: localizations
                                      .translate(i18.common.coreCommonCancel),
                                  confirmText: localizations
                                      .translate(i18.common.coreCommonOk),
                                  onChangeOfFormControl: (formControl) {
                                    // Handle changes to the control's value here
                                    DateTime? value = formControl.value;
                                    if (value == null) return;
                                    DigitDOBAge age =
                                        DigitDateUtils.calculateAge(value);
                                    if ((age.years == 0 && age.months == 0) ||
                                        age.months > 11 ||
                                        (age.years >= 150 && age.months >= 0)) {
                                      formControl.setErrors({'': true});
                                    } else {
                                      formControl.removeError('');
                                    }
                                  },
                                  end: after150Years,
                                ),
                                const SizedBox(height: 12),
                                ReactiveWrapperField(
                                  formControlName: _commentsKey,
                                  validationMessages: {
                                    'requiredIfShort': (_) =>
                                        localizations.translate(i18_local
                                            .stockDetails
                                            .commentsRequiredIfShort),
                                  },
                                  builder: (field) => InputField(
                                    isRequired: _commentsRequired,
                                    type: InputType.textArea,
                                    label: localizations.translate(
                                        i18_local.stockDetails.comments),
                                    errorMessage: field.errorText,
                                    onChange: (value) =>
                                        field.control.value = value,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  DigitButton(
                    label: localizations.translate(i18.common.coreCommonSubmit),
                    onPressed: _handleSubmission,
                    type: DigitButtonType.primary,
                    size: DigitButtonSize.large,
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
