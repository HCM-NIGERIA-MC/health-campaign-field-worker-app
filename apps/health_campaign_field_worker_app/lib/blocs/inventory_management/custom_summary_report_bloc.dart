import 'dart:async';
import 'package:digit_data_model/data_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:inventory_management/inventory_management.dart';
import 'package:inventory_management/utils/typedefs.dart' as stock_typedefs;
import 'package:path/path.dart';
import 'package:registration_delivery/models/entities/household.dart';
import 'package:registration_delivery/models/entities/household_member.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/models/entities/task_resource.dart';
import 'package:registration_delivery/registration_delivery.dart';
import 'package:registration_delivery/utils/typedefs.dart';

import '../../data/repositories/custom_task.dart';
import '../../data/repositories/local/inventory_management/custom_stock.dart';
import '../../models/entities/assessment_checklist/status.dart';
import '../../utils/app_enums.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../utils/utils.dart';
part 'custom_summary_report_bloc.freezed.dart';

typedef SummaryReportEmitter = Emitter<SummaryReportState>;

class SummaryReportBloc extends Bloc<SummaryReportEvent, SummaryReportState> {
  final HouseholdDataRepository householdRepository;
  final HouseholdMemberDataRepository householdMemberRepository;
  final TaskDataRepository taskDataRepository;
  final ProductVariantDataRepository productVariantDataRepository;
  final stock_typedefs.StockDataRepository customStockLocalRepository;

  SummaryReportBloc({
    required this.householdRepository,
    required this.householdMemberRepository,
    required this.productVariantDataRepository,
    required this.taskDataRepository,
    required this.customStockLocalRepository,
  }) : super(const SummaryReportEmptyState()) {
    on<SummaryReportLoadDataEvent>(_handleLoadDataEvent);
    on<SummaryReportLoadingEvent>(_handleLoadingEvent);
  }

  Future<void> _handleLoadDataEvent(
    SummaryReportLoadDataEvent event,
    SummaryReportEmitter emit,
  ) async {
    emit(const SummaryReportLoadingState());

    try {
      final selectedCycle = RegistrationDeliverySingleton()
          .selectedProject
          ?.additionalDetails
          ?.projectType
          ?.cycles
          ?.where(
            (e) =>
                (e.startDate) < DateTime.now().millisecondsSinceEpoch &&
                (e.endDate) > DateTime.now().millisecondsSinceEpoch,
          )
          .firstOrNull;
      // date to start from
      final cycleStartDate = selectedCycle?.startDate ?? 0;
      List<HouseholdModel> householdList = [];
      List<HouseholdMemberModel> householdMemberList = [];
      List<TaskModel> taskList = [];
      List<TaskModel> administeredChildrenList = [];
      List<ProductVariantModel> productVariantList = [];
      List<TaskResourceModel> AzmList = [];
      List<StockModel> AzmStockList = [];
      householdList =
          await (householdRepository).search(HouseholdSearchModel());
      householdMemberList = await (householdMemberRepository)
          .search(HouseholdMemberSearchModel(isHeadOfHousehold: false));
      taskList = await (taskDataRepository as CustomTaskLocalRepository)
          .conditionalSearch(TaskSearchModel(),
              RegistrationDeliverySingleton().loggedInUserUuid, cycleStartDate);
      productVariantList = await (productVariantDataRepository)
          .search(ProductVariantSearchModel());
      for (var element in taskList) {
        if (element.status == null) {
          continue;
        }
        final status = StatusMapper.fromValue(element.status);

        if (status == Status.administeredSuccess) {
          administeredChildrenList.add(element);
        }
      }

      for (var task in administeredChildrenList) {
        if (task.resources != null) {
          for (var resource in task.resources!) {
            for (var productVariant in productVariantList) {
              if (productVariant.id == resource.productVariantId &&
                  productVariant.sku == Constants.azm) {
                AzmList.add(resource);
              }
            }
          }
        }
      }

      AzmStockList = await (customStockLocalRepository).search(StockSearchModel(
        receiverId: [InventorySingleton().loggedInUserUuid],
        transactionType: [TransactionType.received.toValue()],
      ));

      Map<String, List<HouseholdModel>> dateVsHouseholdList = {};
      Map<String, List<HouseholdMemberModel>> dateVsHouseholdMembersList = {};
      Map<String, List<TaskModel>> dateVsAdministeredChilderenList = {};
      Map<String, List<TaskResourceModel>> dateVsAzmList = {};
      Map<String, List<StockModel>> dateVsAzmStockList = {};
      Set<String> uniqueDates = {};
      Map<String, int> dateVsHouseholdCount = {};
      Map<String, int> dateVsHouseholdMembersCount = {};
      Map<String, int> dateVsAdministeredChilderenCount = {};
      Map<String, int> dateVsAzmCount = {};
      Map<String, int> dateVsAzmStockCount = {};
      Map<String, Map<String, int>> dateVsEntityVsCountMap = {};
      for (var element in householdMemberList) {
        if (element.clientAuditDetails!.createdTime >= cycleStartDate) {
          var dateKey = DigitDateUtils.getDateFromTimestamp(
              element.clientAuditDetails!.createdTime);
          dateVsHouseholdMembersList
              .putIfAbsent(dateKey, () => [])
              .add(element);
        }
      }
      for (var element in administeredChildrenList) {
        if (element.clientAuditDetails!.createdTime >= cycleStartDate) {
          var dateKey = DigitDateUtils.getDateFromTimestamp(
              element.clientAuditDetails!.createdTime);
          dateVsAdministeredChilderenList
              .putIfAbsent(dateKey, () => [])
              .add(element);
        }
      }
      for (var element in AzmList) {
        if (element.auditDetails!.createdTime >= cycleStartDate) {
          var dateKey = DigitDateUtils.getDateFromTimestamp(
              element.auditDetails!.createdTime);
          dateVsAzmList.putIfAbsent(dateKey, () => []).add(element);
        }
      }

      for (var element in AzmStockList) {
        if (element.auditDetails!.createdTime >= cycleStartDate) {
          var dateKey = DigitDateUtils.getDateFromTimestamp(
              element.auditDetails!.createdTime);
          dateVsAzmStockList.putIfAbsent(dateKey, () => []).add(element);
        }
      }

      for (var element in householdList) {
        if (element.auditDetails!.createdTime >= cycleStartDate) {
          var dateKey = DigitDateUtils.getDateFromTimestamp(
              element.auditDetails!.createdTime);
          dateVsHouseholdList.putIfAbsent(dateKey, () => []).add(element);
        }
      }

      // get a set of unique dates
      getUniqueSetOfDates(
        dateVsHouseholdList,
        dateVsAzmStockList,
        dateVsHouseholdMembersList,
        dateVsAdministeredChilderenList,
        dateVsAzmList,
        uniqueDates,
      );

      // If a cycle start date is provided, filter uniqueDates to include only
      // dates greater than or equal to the cycle start date.
      // uniqueDates are formatted as 'dd/MM/yyyy' or 'dd/MM/yy' .
      if (cycleStartDate != null) {
        uniqueDates = uniqueDates
            .where((dateStr) =>
                DigitDateUtils.dateToTimeStamp(dateStr) >= cycleStartDate)
            .toSet();
      }

      // populate the day vs count for that day map
      populateDateVsCountMap(
          dateVsHouseholdMembersList, dateVsHouseholdMembersCount);
      populateDateVsCountMap(
          dateVsAdministeredChilderenList, dateVsAdministeredChilderenCount);
      populateDateVsResourceCountMap(dateVsAzmList, dateVsAzmCount);
      populateDateVsStockCountMap(dateVsAzmStockList, dateVsAzmStockCount);
      populateDateVsCountMap(dateVsHouseholdList, dateVsHouseholdCount);

      popoulateDateVsEntityCountMap(
        dateVsHouseholdCount,
        dateVsAzmStockCount,
        dateVsEntityVsCountMap,
        dateVsHouseholdMembersCount,
        dateVsAdministeredChilderenCount,
        dateVsAzmCount,
        uniqueDates,
      );
      dateVsEntityVsCountMap =
          sortMapByDateKeyAndRenameDate(dateVsEntityVsCountMap);
      dateVsEntityVsCountMap = addTotalEntryToMap(dateVsEntityVsCountMap);

      emit(SummaryReportDataState(data: dateVsEntityVsCountMap));
    } catch (e) {
      // Log the error and emit empty state to prevent infinite loading
      emit(const SummaryReportEmptyState());
    }
  }

  void getUniqueSetOfDates(
    Map<String, List<HouseholdModel>> dateVsHouseholdList,
    Map<String, List<StockModel>> dateVsAzmStockList,
    Map<String, List<HouseholdMemberModel>> dateVsHouseholdMembersList,
    Map<String, List<TaskModel>> dateVsAdministeredChilderenList,
    Map<String, List<TaskResourceModel>> dateVsAzmList,
    Set<String> uniqueDates,
  ) {
    uniqueDates.addAll(dateVsHouseholdList.keys.toSet());
    uniqueDates.addAll(dateVsAzmStockList.keys.toSet());
    uniqueDates.addAll(dateVsHouseholdMembersList.keys.toSet());
    uniqueDates.addAll(dateVsAdministeredChilderenList.keys.toSet());
    uniqueDates.addAll(dateVsAzmList.keys.toSet());
  }

  void populateDateVsCountMap(
      Map<String, List> map, Map<String, int> dateVsCount) {
    map.forEach((key, value) {
      dateVsCount[key] = value.length;
    });
  }

  void populateDateVsStockCountMap(
      Map<String, List<StockModel>> map, Map<String, int> dateVsCount) {
    map.forEach((key, value) {
      int total = 0;
      for (final e in value) {
        // Handle decimal strings like "14.0" by parsing as double first
        total += (double.tryParse(e.quantity ?? '0') ?? 0).toInt();
      }
      dateVsCount[key] = total;
    });
  }

  void populateDateVsResourceCountMap(
      Map<String, List<TaskResourceModel>> map, Map<String, int> dateVsCount) {
    map.forEach((key, value) {
      int total = 0;
      for (final e in value) {
        // Handle decimal strings like "14.0" by parsing as double first
        total += (double.tryParse(e.quantity ?? '0') ?? 0).toInt();
      }
      dateVsCount[key] = total;
    });
  }

  void popoulateDateVsEntityCountMap(
    Map<String, int> dateVsHouseholdCount,
    Map<String, int> dateVsAzmStockCount,
    Map<String, Map<String, int>> dateVsEntityVsCountMap,
    Map<String, int> dateVsHouseholdMembersCount,
    Map<String, int> dateVsAdministeredChilderenCount,
    Map<String, int> dateVsAzmCount,
    Set<String> uniqueDates,
  ) {
    for (var date in uniqueDates) {
      Map<String, int> elementVsCount = {};
      if (dateVsHouseholdMembersCount.containsKey(date) &&
          dateVsHouseholdMembersCount[date] != null) {
        var count = dateVsHouseholdMembersCount[date];
        elementVsCount[Constants.registered] = count ?? 0;
      }
      if (dateVsAdministeredChilderenCount.containsKey(date) &&
          dateVsAdministeredChilderenCount[date] != null) {
        var count = dateVsAdministeredChilderenCount[date];
        elementVsCount[Constants.administered] = count ?? 0;
      }
      if (dateVsAzmCount.containsKey(date) && dateVsAzmCount[date] != null) {
        var count = dateVsAzmCount[date];
        elementVsCount[Constants.azm] = count ?? 0;
      }
      if (dateVsHouseholdCount.containsKey(date) &&
          dateVsHouseholdCount[date] != null) {
        var count = dateVsHouseholdCount[date];
        elementVsCount[Constants.household] = count ?? 0;
      }
      if (dateVsAzmStockCount.containsKey(date) &&
          dateVsAzmStockCount[date] != null) {
        var count = dateVsAzmStockCount[date];
        elementVsCount[Constants.azmStock] = count ?? 0;
      }

      dateVsEntityVsCountMap[date] = elementVsCount;
    }
  }

  Map<String, Map<String, int>> sortMapByDateKeyAndRenameDate(
    Map<String, Map<String, int>> dateVsEntityVsCountMap,
  ) {
    final sortedEntries = dateVsEntityVsCountMap.entries.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(_toIsoFormat(a.key));
        final dateB = DateTime.parse(_toIsoFormat(b.key));
        return dateA.compareTo(dateB);
      });

    final Map<String, Map<String, int>> renamedMap = {};

    for (int i = 0; i < sortedEntries.length; i++) {
      final originalDate = sortedEntries[i].key;
      final newKey = '$originalDate Day${i + 1}';
      renamedMap[newKey] = sortedEntries[i].value;
    }

    return renamedMap;
  }

  Map<String, Map<String, int>> addTotalEntryToMap(
      Map<String, Map<String, int>> originalMap) {
    final Map<String, int> totalMap = {};

    for (final dayEntry in originalMap.entries) {
      final dayData = dayEntry.value;
      for (final entry in dayData.entries) {
        totalMap.update(entry.key, (value) => value + entry.value,
            ifAbsent: () => entry.value);
      }
    }

    // Create new map with 'Total' at the beginning
    final Map<String, Map<String, int>> newMap = {
      'Total': totalMap,
      ...originalMap,
    };

    return newMap;
  }

  /// Converts 'dd/MM/yyyy' to 'yyyy-MM-dd' for proper DateTime parsing
  String _toIsoFormat(String dateStr) {
    final parts = dateStr.split('/');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Future<void> _handleLoadingEvent(
    SummaryReportLoadingEvent event,
    SummaryReportEmitter emit,
  ) async {
    emit(const SummaryReportLoadingState());
  }
}

@freezed
class SummaryReportEvent with _$SummaryReportEvent {
  const factory SummaryReportEvent.loadSummaryData({
    required String userId,
  }) = SummaryReportLoadDataEvent;

  const factory SummaryReportEvent.loading() = SummaryReportLoadingEvent;
}

@freezed
class SummaryReportState with _$SummaryReportState {
  const factory SummaryReportState.loading() = SummaryReportLoadingState;
  const factory SummaryReportState.empty() = SummaryReportEmptyState;

  const factory SummaryReportState.data({
    @Default({}) Map<String, Map<String, int>> data,
  }) = SummaryReportDataState;
}
