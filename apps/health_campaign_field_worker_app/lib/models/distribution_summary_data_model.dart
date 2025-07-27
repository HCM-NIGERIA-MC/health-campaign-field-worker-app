import 'package:digit_data_model/data_model.dart';
import 'package:flutter/material.dart';

import 'data_model.dart';

class DistributionSummaryData extends EntityModel {
  int householdRegisteredCount;
  int childrenTreatedCount1;
  int childrenTreatedCount2;
  double childrenTreatedPercentageCount;

  dynamic drugsUsed;
  dynamic drugsReceived;
  dynamic drugsBalance;

  DistributionSummaryData({
    required this.householdRegisteredCount,
    required this.childrenTreatedCount1,
    required this.childrenTreatedCount2,
    required this.childrenTreatedPercentageCount,
    required this.drugsUsed,
    required this.drugsReceived,
    required this.drugsBalance,
  }) : super();

  @override
  // TODO: implement copyWith
  EntityModelCopyWith<EntityModel, EntityModel, EntityModel> get copyWith =>
      throw UnimplementedError();

  @override
  String toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap() {
    // TODO: implement toMap
    throw UnimplementedError();
  }
}
