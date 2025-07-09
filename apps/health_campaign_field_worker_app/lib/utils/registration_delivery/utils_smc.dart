import 'package:collection/collection.dart';
import 'package:digit_data_model/models/entities/individual.dart';
import 'package:digit_data_model/models/entities/project_type.dart';
import 'package:digit_data_model/models/project_type/project_type_model.dart';
import 'package:digit_ui_components/utils/date_utils.dart';
import 'package:health_campaign_field_worker_app/utils/constants.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:registration_delivery/models/entities/additional_fields_type.dart';
import 'package:registration_delivery/models/entities/side_effect.dart';
import 'package:registration_delivery/models/entities/status.dart';
import 'package:registration_delivery/models/entities/task.dart';

import '../../models/entities/additional_fields_type.dart'
    as additional_fields_local;
import '../app_enums.dart';
import '../../../models/entities/assessment_checklist/status.dart'
    as status_local;

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

bool checkBeneficiaryReferredMV(
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
                      e.value == EligibilityAssessmentStatus.mvDone.name,
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

bool checkBeneficiaryInEligibleMV(
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
                      e.value == EligibilityAssessmentStatus.mvDone.name,
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
) {
  int totalAgeMonths = age.years * 12 + age.months;
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
          ? totalAgeMonths >= projectType!.validMinAge! &&
                  totalAgeMonths <= projectType.validMaxAge!
              ? recordedSideEffect && !checkStatusSMC([tasks], currentCycle)
                  ? false
                  : true
              : false
          : false;
    } else {
      if (projectType?.validMaxAge != null &&
          projectType?.validMinAge != null) {
        return totalAgeMonths >= projectType!.validMinAge! &&
                totalAgeMonths <= projectType.validMaxAge!
            ? true
            : false;
      }
      return false;
    }
  }

  return false;
}

bool checkEligibilityForAgeMV(IndividualModel individual) {
  if (individual.dateOfBirth == null) {
    return false;
  }
  DigitDOBAgeConvertor age = DigitDateUtils.calculateAge(
    DigitDateUtils.getFormattedDateToDateTime(
          individual.dateOfBirth!,
        ) ??
        DateTime.now(),
  );
  int totalAgeMonths = age.years * 12 + age.months;

  return totalAgeMonths <= 11 && totalAgeMonths >= 5;
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

  //return successfulTask == null;
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

bool assessmentMVPending(List<TaskModel>? tasks, ProjectCycle? currentCycle) {
  if (currentCycle == null) {
    return true;
  }
  if ((tasks ?? []).isEmpty) {
    return true;
  }
  var successfulTask = tasks!
      .where(
        (element) => (element.additionalFields?.fields.firstWhereOrNull(
              (e) =>
                  e.key ==
                      additional_fields_local.AdditionalFieldsType.deliveryType
                          .toValue() &&
                  e.value == EligibilityAssessmentStatus.mvDone.name,
            ) !=
            null),
      )
      .lastOrNull;

  final successfulTaskCreatedTime =
      successfulTask?.clientAuditDetails?.createdTime;

  if (successfulTaskCreatedTime == null) {
    return true;
  }

  final isLastCycleRunning =
      successfulTaskCreatedTime >= currentCycle.startDate &&
          successfulTaskCreatedTime <= currentCycle.endDate;

  return !isLastCycleRunning;
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
