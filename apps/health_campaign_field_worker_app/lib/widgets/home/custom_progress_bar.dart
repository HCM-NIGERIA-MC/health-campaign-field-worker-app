import 'dart:math';

import 'package:collection/collection.dart';
import 'package:digit_components/widgets/digit_card.dart';
import 'package:digit_data_model/data/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration_delivery/models/entities/status.dart';
import 'package:registration_delivery/registration_delivery.dart';
import '../../../data/repositories/custom_task.dart';
import '../../../utils/extensions/extensions.dart';
import '../../data/repositories/custom_project_beneficiary.dart';
import '../progress_indicator/progress_indicator.dart';

class CustomBeneficiaryProgressBar extends StatefulWidget {
  final String label;
  final String prefixLabel;

  const CustomBeneficiaryProgressBar({
    super.key,
    required this.label,
    required this.prefixLabel,
  });

  @override
  State<CustomBeneficiaryProgressBar> createState() =>
      _CustomBeneficiaryProgressBarState();
}

class _CustomBeneficiaryProgressBarState
    extends State<CustomBeneficiaryProgressBar> {
  int current = 0;
  @override
  void didChangeDependencies() {
    final taskRepository =
        context.read<LocalRepository<TaskModel, TaskSearchModel>>()
            as CustomTaskLocalRepository;

    final projectBeneficiaryRepository = context.read<
            LocalRepository<ProjectBeneficiaryModel,
                ProjectBeneficiarySearchModel>>()
        as ProjectBeneficiaryLocalRepository;

    final projectId = RegistrationDeliverySingleton().projectId;
    final loggedInUserUuid = RegistrationDeliverySingleton().loggedInUserUuid;

    final now = DateTime.now();
    final gte = DateTime(
      now.year,
      now.month,
      now.day,
    );
    final lte = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    );

    if (context.isDistributor) {
      taskRepository.listenToChanges(
        query: TaskSearchModel(
          status: Status.administeredSuccess.toValue(),
          projectId: projectId,
          createdBy: loggedInUserUuid,
          plannedEndDate: lte.millisecondsSinceEpoch,
          plannedStartDate: gte.millisecondsSinceEpoch,
        ),
        listener: (taskData) async {
          if (mounted) {
            final now = DateTime.now();
            final gte = DateTime(
              now.year,
              now.month,
              now.day,
            );
            final lte = DateTime(
              now.year,
              now.month,
              now.day,
              23,
              59,
              59,
              999,
            );
            TaskSearchModel taskSearchQuery = TaskSearchModel(
              status: Status.administeredSuccess.toValue(),
              createdBy: loggedInUserUuid,
              plannedEndDate: lte.millisecondsSinceEpoch,
              plannedStartDate: gte.millisecondsSinceEpoch,
              projectId: projectId,
            );
            List<TaskModel> results =
                await taskRepository.progressBarSearch(taskSearchQuery);
            final groupedEntries = results.groupListsBy(
              (element) => element.projectBeneficiaryClientReferenceId,
            );
            if (mounted) {
              setState(() {
                if (mounted) {
                  current = groupedEntries.entries.length;
                }
              });
            }
          }
        },
      );
    } else {
      projectBeneficiaryRepository.listenToChanges(
        query: ProjectBeneficiarySearchModel(
          projectId: [projectId ?? ''],
          beneficiaryRegistrationDateLte: lte,
          beneficiaryRegistrationDateGte: gte,
        ),
        listener: (data) async {
          if (mounted) {
            final now = DateTime.now();
            final gte = DateTime(
              now.year,
              now.month,
              now.day,
            );
            final lte = DateTime(
              now.year,
              now.month,
              now.day,
              23,
              59,
              59,
              999,
            );
            ProjectBeneficiarySearchModel projectBeneficiarySearchModel =
                ProjectBeneficiarySearchModel(
              beneficiaryRegistrationDateLte: lte,
              beneficiaryRegistrationDateGte: gte,
              projectId: [projectId ?? ''],
            );
            List<ProjectBeneficiaryModel> results =
                await projectBeneficiaryRepository.search(
                    projectBeneficiarySearchModel, loggedInUserUuid);

            if (mounted) {
              setState(() {
                if (mounted) {
                  current = results.length;
                }
              });
            }
          }
        },
      );
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    int target = 60;

    return DigitCard(
      child: ProgressIndicatorContainer(
        label: '${max(target - current, 0).round()} ${widget.label}',
        prefixLabel: '$current ${widget.prefixLabel}',
        suffixLabel: target.toStringAsFixed(0),
        value: target == 0 ? 0 : min(current / target, 1),
      ),
    );
  }
}
