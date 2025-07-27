// Importing necessary packages and modules
import 'dart:convert';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_data_model/models/entities/household_type.dart';
import 'package:digit_data_model/models/templates/template_config.dart';
import 'package:digit_formula_parser/digit_formula_parser.dart';
import 'package:digit_ui_components/utils/date_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:registration_delivery/blocs/registration_wrapper/registration_wrapper_bloc.dart';
import 'package:registration_delivery/models/entities/household.dart';
import 'package:registration_delivery/router/registration_delivery_router.gm.dart';

import 'package:registration_delivery/models/entities/additional_fields_type.dart';
import 'package:registration_delivery/models/entities/referral.dart';
import 'package:registration_delivery/models/entities/side_effect.dart';
import 'package:registration_delivery/models/entities/status.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/utils/utils.dart';

Map<String, dynamic> customFetchProductVariant(
    ProjectCycleDelivery? currentDelivery,
    IndividualModel? individualModel,
    HouseholdModel? householdModel,
    {BuildContext? context}) {
  List<String> errorMessages = [];
  DeliveryDoseCriteria? deliveryDoseCriteria;

  if (currentDelivery != null) {
    var individualAgeInMonths = 0;
    var gender;
    var roomCount;
    var memberCount;
    String? structureType;
    var weight = 0.0;
    var height = 0.0;

    if (individualModel != null) {
      final individualAge = DigitDateUtils.calculateAge(
        DigitDateUtils.getFormattedDateToDateTime(
              individualModel.dateOfBirth!,
            ) ??
            DateTime.now(),
      );
      individualAgeInMonths = individualAge.years * 12 + individualAge.months;

      gender = individualModel.gender?.toValue();

      weight = double.tryParse(individualModel.additionalFields?.fields
                  .firstWhere(
                    (element) =>
                        element.key == AdditionalFieldsType.weight.toValue(),
                    orElse: () => AdditionalField(
                        AdditionalFieldsType.weight.toValue(), '0.0'),
                  )
                  .value ??
              '0.0') ??
          0.0;

      height = double.tryParse(individualModel.additionalFields?.fields
                  .firstWhere(
                    (element) =>
                        element.key == AdditionalFieldsType.height.toValue(),
                    orElse: () => AdditionalField(
                        AdditionalFieldsType.height.toValue(), '0.0'),
                  )
                  .value ??
              '0.0') ??
          0.0;
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

    dynamic quantityFromCondition = 0;

    final filteredCriteria = currentDelivery.doseCriteria?.where((criteria) {
      final condition = criteria.condition;
      if (condition != null) {
        if (condition.contains('and')) {
          final conditions = condition.split('and');

          List<bool> expressionParser = [];
          for (var element in conditions) {
            final expression = CustomFormulaParser.parseCondition(element, {
              'age': individualAgeInMonths,
              if (gender != null) 'gender': gender,
              if (memberCount != null) 'memberCount': memberCount,
              if (roomCount != null) 'roomCount': roomCount,
              if (structureType != null) 'type_of_structure': structureType,
              'weight': weight,
              'height': height,
            }, stringKeys: [
              'type_of_structure',
              'gender'
            ]);
            final error = expression;
            if (error["value"] == null || !error["value"]) {
              errorMessages.add(condition);
            }
            if (error["value"] == null) {
              expressionParser.add(false);
            } else {
              expressionParser.add(error["value"]);
            }
          }

          return expressionParser.where((element) => element == true).length ==
              conditions.length;
        } else if (condition.contains('or')) {
          final conditions = condition.split('or');

          List<bool> expressionParser = [];
          for (var element in conditions) {
            final expression = CustomFormulaParser.parseCondition(element, {
              if (individualModel != null && individualAgeInMonths != 0)
                'age': individualAgeInMonths,
              if (gender != null) 'gender': gender,
              if (memberCount != null) 'memberCount': memberCount,
              if (roomCount != null) 'roomCount': roomCount,
              if (structureType != null) 'type_of_structure': structureType,
              'weight': weight,
              'height': height,
            }, stringKeys: [
              'type_of_structure',
              'gender'
            ]);
            final error = expression;
            if (error["value"] == null || !error["value"]) {
              errorMessages.add(condition);
            }
            if (error["value"] == null) {
              expressionParser.add(false);
            } else {
              expressionParser.add(error["value"]);
            }
          }

          return expressionParser
              .where((element) => element == true)
              .isNotEmpty;
        } else {
          final conditions = condition.split(
              'and'); // Assuming there's only one condition since we have contain for and check above and split with and will return the first condition so this is valid

          List<bool> expressionParser = [];
          for (var element in conditions) {
            final expression = CustomFormulaParser.parseCondition(element, {
              if (individualModel != null && individualAgeInMonths != 0)
                'age': individualAgeInMonths,
              if (gender != null) 'gender': gender,
              if (memberCount != null) 'memberCount': memberCount,
              if (roomCount != null) 'roomCount': roomCount,
              if (structureType != null) 'type_of_structure': structureType,
              'weight': weight,
              'height': height,
            }, stringKeys: [
              'type_of_structure',
              'gender'
            ]);
            final error = expression;
            if (error["value"] == null || (error is bool && !error["value"])) {
              errorMessages.add(condition);
            }
            if (error["value"] == null) {
              expressionParser.add(false);
            } else if (error["value"] is bool && error["value"] == true) {
              expressionParser.add(error["value"]);
            } else {
              /// if some value is coming from condition
              expressionParser.add(true);
              // quantityFromCondition = error["value"];
            }
          }

          return expressionParser.where((element) => element == true).length ==
              conditions.length;
        }
      }

      return false;
    }).toList();

    if ((filteredCriteria ?? []).isNotEmpty) {
      final firstCriteria = filteredCriteria!.first;
      final int? roundedQuantity = quantityFromCondition != 0
          ? quantityFromCondition.ceil() // Convert double to int by rounding up
          : null;

      final updatedVariant = roundedQuantity != null
          ? firstCriteria.productVariants?.first
              .copyWith(quantity: roundedQuantity)
          : firstCriteria.productVariants?.first;

      deliveryDoseCriteria = firstCriteria.copyWith(
        productVariants: updatedVariant != null ? [updatedVariant] : null,
      );
    } else {
      deliveryDoseCriteria = null;
    }
  }

  // Remove duplicate error messages
  errorMessages = errorMessages.toSet().toList();

  return {
    'criteria': deliveryDoseCriteria,
    'errors': errorMessages,
  };
}
