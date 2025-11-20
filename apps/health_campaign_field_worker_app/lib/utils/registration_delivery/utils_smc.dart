import 'package:collection/collection.dart';
import 'package:digit_data_model/models/entities/individual.dart';
import 'package:digit_data_model/models/entities/project_type.dart';
import 'package:digit_data_model/models/project_type/project_type_model.dart';
import 'package:digit_ui_components/utils/date_utils.dart';
import 'package:health_campaign_field_worker_app/utils/constants.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:registration_delivery/models/entities/additional_fields_type.dart';
import 'package:registration_delivery/models/entities/household.dart';
import 'package:registration_delivery/models/entities/side_effect.dart';
import 'package:registration_delivery/models/entities/status.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/utils/utils.dart';

import '../../models/entities/additional_fields_type.dart'
    as additional_fields_local;
import '../app_enums.dart';
import '../../../models/entities/assessment_checklist/status.dart'
    as status_local;
import 'package:formula_parser/src/formula_parser_base.dart';

bool checkStatusSMC(List<TaskModel>? tasks, ProjectCycle? currentCycle) {
  if (currentCycle == null) {
    return false;
  }

  if (tasks == null || tasks.isEmpty) {
    return true;
  }

  if (tasks.firstWhereOrNull((e) =>
          e.additionalFields?.fields.firstWhereOrNull(
            (element) =>
                element.key ==
                    additional_fields_local.AdditionalFieldsType.deliveryType
                        .toValue() &&
                element.value == EligibilityAssessmentStatus.smcDone.name,
          ) !=
          null) ==
      null) {
    return true;
  }

  final lastTask = tasks.last;
  final lastTaskCreatedTime = lastTask.clientAuditDetails?.createdTime;

  if (lastTaskCreatedTime == null) {
    return false;
  }

  final date = DateTime.fromMillisecondsSinceEpoch(lastTaskCreatedTime);
  final diff = DateTime.now().difference(date);
  final isLastCycleRunning = lastTaskCreatedTime >= currentCycle.startDate &&
      lastTaskCreatedTime <= currentCycle.endDate;

  if (isLastCycleRunning) {
    if (lastTask.status == Status.delivered.name.toUpperCase() ||
        lastTask.status == Status.administeredSuccess.name.toUpperCase() ||
        lastTask.status == Status.visited.name.toUpperCase()) {
      return false;
    }
    return false; // [TODO: Move gap between doses to config]
  }

  return true;
}

bool checkStatusVAS(List<TaskModel>? tasks, ProjectCycle? currentCycle) {
  if (currentCycle == null) {
    return false;
  }

  if (tasks == null || tasks.isEmpty) {
    return true;
  }

  if (tasks.firstWhereOrNull((e) =>
          e.additionalFields?.fields.firstWhereOrNull(
            (element) =>
                element.key ==
                    additional_fields_local.AdditionalFieldsType.deliveryType
                        .toValue() &&
                element.value == EligibilityAssessmentStatus.vasDone.name,
          ) !=
          null) ==
      null) {
    return true;
  }

  final lastTask = tasks.last;
  final lastTaskCreatedTime = lastTask.clientAuditDetails?.createdTime;

  if (lastTaskCreatedTime == null) {
    return false;
  }

  final date = DateTime.fromMillisecondsSinceEpoch(lastTaskCreatedTime);
  final diff = DateTime.now().difference(date);
  final isLastCycleRunning = lastTaskCreatedTime >= currentCycle.startDate &&
      lastTaskCreatedTime <= currentCycle.endDate;

  if (isLastCycleRunning) {
    if (lastTask.status == Status.delivered.name) {
      return true;
    }
    return diff.inHours >= 24; // [TODO: Move gap between doses to config]
  }

  return true;
}

bool redosePending(List<TaskModel>? tasks, ProjectCycle? selectedCycle) {
  var redosePending = true;
  if ((tasks ?? []).isEmpty) {
    return true;
  }

  if (selectedCycle == null) {
    return false;
  }

  // get the fist task which was marked as visited as this is the one which was created in redose flow
  TaskModel? redoseTask = tasks!
      .where(
        (element) => element.status == Status.visited.toValue(),
      )
      .lastOrNull;

  final redoseTaskCreatedTime = redoseTask?.clientAuditDetails?.createdTime;

  final isRedoseDoneInCurrentCycle = redoseTaskCreatedTime != null &&
      redoseTaskCreatedTime >= selectedCycle.startDate &&
      redoseTaskCreatedTime <= selectedCycle.endDate;

  TaskModel? successfullTask = tasks
      .where(
        (element) => element.status == Status.administeredSuccess.toValue(),
      )
      .lastOrNull;

  int diff = DateTime.now().millisecondsSinceEpoch -
      (successfullTask?.clientAuditDetails?.createdTime ??
          DateTime.now().millisecondsSinceEpoch);

  redosePending = (redoseTask == null || !isRedoseDoneInCurrentCycle)
      ? true
      : (redoseTask.additionalFields?.fields
                  .where(
                    (element) => element.key == Constants.reAdministeredKey,
                  )
                  .toList() ??
              [])
          .isEmpty;

  return redosePending && (diff <= 30 * 60 * 1000);
}

bool checkBeneficiaryReferredSMC(
    List<TaskModel>? tasks, ProjectCycle? currentCycle) {
  if (currentCycle == null) {
    return false;
  }
  if ((tasks ?? []).isEmpty) {
    return false;
  }
  var successfulTask = tasks!
      .where(
        (element) =>
            element.status == Status.beneficiaryReferred.toValue() &&
            element.additionalFields?.fields.firstWhereOrNull(
                  (e) =>
                      e.key ==
                          additional_fields_local
                              .AdditionalFieldsType.deliveryType
                              .toValue() &&
                      e.value == EligibilityAssessmentStatus.smcDone.name,
                ) !=
                null,
      )
      .lastOrNull;

  final successfulTaskCreatedTime =
      successfulTask?.clientAuditDetails?.createdTime;

  if (successfulTaskCreatedTime == null) {
    return false;
  }
  final isLastCycleRunning =
      successfulTaskCreatedTime >= currentCycle.startDate &&
          successfulTaskCreatedTime <= currentCycle.endDate;

  return isLastCycleRunning;
}

bool checkBeneficiaryInEligibleSMC(
    List<TaskModel>? tasks, ProjectCycle? currentCycle) {
  if (currentCycle == null) {
    return false;
  }
  if ((tasks ?? []).isEmpty) {
    return false;
  }
  var successfulTask = tasks!
      .where(
        (element) =>
            element.status ==
                status_local.Status.beneficiaryInEligible.toValue() &&
            element.additionalFields?.fields.firstWhereOrNull(
                  (e) =>
                      e.key ==
                          additional_fields_local
                              .AdditionalFieldsType.deliveryType
                              .toValue() &&
                      e.value == EligibilityAssessmentStatus.smcDone.name,
                ) !=
                null,
      )
      .lastOrNull;

  final successfulTaskCreatedTime =
      successfulTask?.clientAuditDetails?.createdTime;

  if (successfulTaskCreatedTime == null) {
    return false;
  }

  final date = DateTime.fromMillisecondsSinceEpoch(successfulTaskCreatedTime);

  final isLastCycleRunning =
      successfulTaskCreatedTime >= currentCycle.startDate &&
          successfulTaskCreatedTime <= currentCycle.endDate;

  return isLastCycleRunning;
}

bool checkBeneficiaryInEligibleVAS(List<TaskModel>? tasks) {
  if ((tasks ?? []).isEmpty) {
    return false;
  }
  var successfulTask = tasks!
      .where(
        (element) =>
            element.status ==
                status_local.Status.beneficiaryInEligible.toValue() &&
            element.additionalFields?.fields.firstWhereOrNull(
                  (e) =>
                      e.key ==
                          additional_fields_local
                              .AdditionalFieldsType.deliveryType
                              .toValue() &&
                      e.value == EligibilityAssessmentStatus.vasDone.name,
                ) !=
                null,
      )
      .lastOrNull;

  return successfulTask != null;
}

bool checkEligibilityForAgeAndSideEffectAll(
  DigitDOBAgeConvertor age,
  ProjectTypeModel? projectType,
  TaskModel? tasks,
  List<SideEffectModel>? sideEffects,
  IndividualModel? individual,
  HouseholdModel? household,
) {
  int totalAgeMonths = age.years * 12 + age.months;
  bool skipAge = false;
  final currentCycle = projectType?.cycles?.firstWhereOrNull(
    (e) =>
        (e.startDate!) < DateTime.now().millisecondsSinceEpoch &&
        (e.endDate!) > DateTime.now().millisecondsSinceEpoch,
    // Return null when no matching cycle is found
  );
  if (currentCycle != null &&
      currentCycle.startDate != null &&
      currentCycle.endDate != null) {
    bool recordedSideEffect = false;
    if ((tasks != null) && sideEffects != null && sideEffects.isNotEmpty) {
      final lastTaskTime =
          tasks.clientReferenceId == sideEffects.last.taskClientReferenceId
              ? tasks.clientAuditDetails?.createdTime
              : null;
      recordedSideEffect = lastTaskTime != null &&
          (lastTaskTime >= currentCycle.startDate! &&
              lastTaskTime <= currentCycle.endDate!);

      return projectType?.validMinAge != null &&
              projectType?.validMaxAge != null
          ? skipAge ||
                  (totalAgeMonths >= projectType!.validMinAge! &&
                      totalAgeMonths <= projectType.validMaxAge!)
              ? recordedSideEffect && !checkStatus([tasks], currentCycle)
                  ? false
                  : true
              : false
          : false;
    } else {
      if (individual != null) {
        return (fetchProductVariant(
                  currentCycle.deliveries!.firstOrNull,
                  individual,
                  household!,
                ) !=
                null)
            ? true
            : false;
      }

      return skipAge ||
              (totalAgeMonths >= projectType!.validMinAge! &&
                  totalAgeMonths <= projectType.validMaxAge!)
          ? true
          : false;
    }
  }

  return false;
}

bool checkBeneficiaryReferredVAS(List<TaskModel>? tasks) {
  if ((tasks ?? []).isEmpty) {
    return false;
  }
  var successfulTask = tasks!
      .where(
        (element) =>
            element.status == Status.beneficiaryReferred.toValue() &&
            element.additionalFields?.fields.firstWhereOrNull(
                  (e) =>
                      e.key ==
                          additional_fields_local
                              .AdditionalFieldsType.deliveryType
                              .toValue() &&
                      e.value == EligibilityAssessmentStatus.vasDone.name,
                ) !=
                null,
      )
      .lastOrNull;

  return successfulTask != null;
}

bool assessmentSMCPending(List<TaskModel>? tasks, ProjectCycle? currentCycle) {
  // this task confirms eligibility and dose administrations is done

  if (currentCycle == null) {
    return true;
  }
  if ((tasks ?? []).isEmpty) {
    return true;
  }
  var successfulTask = tasks!
      .where(
        (element) =>
            element.status == Status.administeredSuccess.toValue() &&
            element.additionalFields?.fields.firstWhereOrNull(
                  (e) =>
                      e.key ==
                          additional_fields_local
                              .AdditionalFieldsType.deliveryType
                              .toValue() &&
                      e.value == EligibilityAssessmentStatus.smcDone.name,
                ) !=
                null,
      )
      .lastOrNull;

  final successfulTaskCreatedTime =
      successfulTask?.clientAuditDetails?.createdTime;

  if (successfulTaskCreatedTime == null) {
    return true;
  }

  final date = DateTime.fromMillisecondsSinceEpoch(successfulTaskCreatedTime);

  final isLastCycleRunning =
      successfulTaskCreatedTime >= currentCycle.startDate &&
          successfulTaskCreatedTime <= currentCycle.endDate;

  return !isLastCycleRunning;
}

bool assessmentVASPending(List<TaskModel>? tasks) {
  // this task confirms eligibility and dose administrations is done
  if ((tasks ?? []).isEmpty) {
    return true;
  }
  var successfulTask = tasks!
      .where(
        (element) => (element.status == Status.administeredSuccess.toValue() &&
            element.additionalFields?.fields.firstWhereOrNull(
                  (e) =>
                      e.key ==
                          additional_fields_local
                              .AdditionalFieldsType.deliveryType
                              .toValue() &&
                      e.value == EligibilityAssessmentStatus.vasDone.name,
                ) !=
                null),
      )
      .lastOrNull;

  return successfulTask == null;
}

bool recordedSideEffect(
  Cycle? selectedCycle,
  TaskModel? task,
  List<SideEffectModel>? sideEffects,
) {
  if (selectedCycle != null &&
      selectedCycle.startDate != null &&
      selectedCycle.endDate != null) {
    if ((task != null) && (sideEffects ?? []).isNotEmpty) {
      final lastTaskCreatedTime =
          task.clientReferenceId == sideEffects?.last.taskClientReferenceId
              ? task.clientAuditDetails?.createdTime
              : null;

      return lastTaskCreatedTime != null &&
          lastTaskCreatedTime >= selectedCycle.startDate! &&
          lastTaskCreatedTime <= selectedCycle.endDate!;
    }
  }

  return false;
}

bool allDosesDelivered(
  List<TaskModel>? tasks,
  Cycle? selectedCycle,
  List<SideEffectModel>? sideEffects,
  IndividualModel? individualModel,
) {
  if (selectedCycle == null ||
      selectedCycle.id == 0 ||
      (selectedCycle.deliveries ?? []).isEmpty) {
    return true;
  } else {
    if ((tasks ?? []).isNotEmpty) {
      final lastCycle = int.tryParse(tasks?.last.additionalFields?.fields
              .where(
                (e) => e.key == AdditionalFieldsType.cycleIndex.toValue(),
              )
              .firstOrNull
              ?.value ??
          '');
      final lastDose = int.tryParse(tasks?.last.additionalFields?.fields
              .where(
                (e) => e.key == AdditionalFieldsType.doseIndex.toValue(),
              )
              .firstOrNull
              ?.value ??
          '');
      if (lastDose != null &&
          lastDose == selectedCycle.deliveries?.length &&
          lastCycle != null &&
          lastCycle == selectedCycle.id &&
          tasks?.last.status != Status.delivered.toValue()) {
        return true;
      } else if (selectedCycle.id == lastCycle &&
          tasks?.last.status == Status.delivered.toValue()) {
        return false;
      } else if ((sideEffects ?? []).isNotEmpty) {
        return recordedSideEffect(selectedCycle, tasks?.last, sideEffects);
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
}

Map<String, dynamic>? minimumAgeValidator(AbstractControl control) {
  final date = control.value;
  if (date is! DateTime) return null;

  final today = DateTime.now();
  final age = today.year -
      date.year -
      ((today.month < date.month ||
              (today.month == date.month && today.day < date.day))
          ? 1
          : 0);

  if (age < 18) {
    return {'minAge': true};
  }

  return null;
}

DeliveryDoseCriteria? fetchProductVariant(ProjectCycleDelivery? currentDelivery,
    IndividualModel? individualModel, HouseholdModel? householdModel) {
  if (currentDelivery != null) {
    int? individualAgeInMonths = 0;
    int? gender;
    int? roomCount;
    int? memberCount;
    String? structureType;
    int? height;

    if (individualModel != null) {
      final individualAge = DigitDateUtils.calculateAge(
        DigitDateUtils.getFormattedDateToDateTime(
              individualModel.dateOfBirth!,
            ) ??
            DateTime.now(),
      );
      individualAgeInMonths = individualAge.years * 12 + individualAge.months;

      gender = individualModel.gender?.index;

      if (individualModel.additionalFields != null) {
        if (individualModel.additionalFields!.fields.isNotEmpty &&
            individualModel.additionalFields!.fields
                .where((element) => element.key == Constants.height)
                .isNotEmpty) {
          height = int.parse(individualModel.additionalFields!.fields
                  .where((element) => element.key == Constants.height)
                  .first
                  .value ??
              '0');
        }
      }
    }
    if (householdModel != null && householdModel.additionalFields != null) {
      memberCount = householdModel.memberCount;
      roomCount = int.tryParse(householdModel.additionalFields?.fields
              .where((h) => h.key == AdditionalFieldsType.noOfRooms.toValue())
              .firstOrNull
              ?.value
              .toString() ??
          '1')!;
      structureType = householdModel.additionalFields?.fields
          .where((h) =>
              h.key == AdditionalFieldsType.houseStructureTypes.toValue())
          .firstOrNull
          ?.value
          .toString();
    }

    final filteredCriteria = currentDelivery.doseCriteria?.where((criteria) {
      final condition = criteria.condition;
      // Build variables map with age and height (if available for 12-59 months)
      final variables = {
        'age': individualAgeInMonths,
        if (height != null) 'height': height,
      };
      if (condition != null) {
        final normalized = condition.replaceAll(' ', '');

        // Split by logical operators
        if (normalized.contains('and')) {
          final conditions = normalized
              .split('and')
              .where((c) => !c.contains('weight'))
              .toList();

          List expressionParser = [];
          for (var element in conditions) {
            final expression = FormulaParser(
              element,
              {
                ...variables,
                if (gender != null) 'gender': gender,
                if (memberCount != null) 'memberCount': memberCount,
                if (roomCount != null) 'roomCount': roomCount
              },
            );
            final error = expression.parse;
            expressionParser.add(error["value"]);
          }

          // If all valid conditions pass, it's true
          return expressionParser.where((e) => e == true).length ==
              conditions.length;
        } else if (condition.contains('or')) {
          final conditions = condition.split('or');

          List expressionParser = [];
          for (var element in conditions) {
            final expression = CustomFormulaParser.parseCondition(element, {
              ...variables,
              if (gender != null) 'gender': gender,
              if (memberCount != null) 'memberCount': memberCount,
              if (roomCount != null) 'roomCount': roomCount,
              if (structureType != null) 'type_of_structure': structureType
            }, stringKeys: [
              'type_of_structure'
            ]);
            final error = expression;
            expressionParser.add(error["value"]);
          }

          return expressionParser.where((element) => element == true).isNotEmpty
              ? true
              : false;
        } else {
          final conditions = condition.split(
              'and'); // Assuming there's only one condition since we have contain for and check above and split with and will return the first condition so this is valid

          List expressionParser = [];
          for (var element in conditions) {
            final expression = CustomFormulaParser.parseCondition(element, {
              ...variables,
              if (gender != null) 'gender': gender,
              if (memberCount != null) 'memberCount': memberCount,
              if (roomCount != null) 'roomCount': roomCount,
              if (structureType != null) 'type_of_structure': structureType
            }, stringKeys: [
              'type_of_structure'
            ]);
            final error = expression;
            expressionParser.add(error["value"]);
          }

          return expressionParser.where((element) => element == true).length ==
              conditions.length;
        }
      }

      return false;
    }).toList();

    return (filteredCriteria ?? []).isNotEmpty ? filteredCriteria?.first : null;
  }

  return null;
}
