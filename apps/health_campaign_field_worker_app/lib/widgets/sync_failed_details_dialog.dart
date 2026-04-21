import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:flutter/material.dart';

import '../utils/sync_failure_reporter.dart';

/// Same intent as [DigitSyncDialog] for failures, plus a scrollable technical details area.
class SyncFailedDetailsDialog extends StatelessWidget {
  const SyncFailedDetailsDialog({
    super.key,
    required this.title,
    required this.detailText,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onRetry,
  });

  final String title;
  final String detailText;
  final String primaryLabel;
  final String secondaryLabel;
  final void Function(BuildContext context) onRetry;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String primaryLabel,
    required String secondaryLabel,
    required void Function(BuildContext context) onRetry,
  }) {
    final detailText = SyncFailureReporter.instance.detailText;
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: const DigitColors().overLayColor.withOpacity(.70),
      builder: (context) => SyncFailedDetailsDialog(
        title: title,
        detailText: detailText,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    final errorColor = theme.colorTheme.alert.error;
    final maxDetailHeight = MediaQuery.sizeOf(context).height * 0.42;

    return Dialog.fullscreen(
      backgroundColor: const DigitColors().transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(spacer4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: theme.colorTheme.paper.primary,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(.16),
                offset: const Offset(0, 1),
                spreadRadius: 0,
                blurRadius: 2,
              ),
            ],
          ),
          width: 320,
          constraints: const BoxConstraints(minHeight: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 32, color: errorColor),
              const SizedBox(height: spacer4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headingM.copyWith(color: errorColor),
              ),
              const SizedBox(height: spacer4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Technical details (for support)',
                  style: textTheme.bodyS.copyWith(
                    color: theme.colorTheme.text.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: spacer2),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxDetailHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorTheme.generic.divider),
                    borderRadius: BorderRadius.circular(4),
                    color: theme.colorTheme.generic.background,
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(spacer2),
                      child: SelectableText(
                        detailText,
                        style: textTheme.bodyS.copyWith(
                          color: theme.colorTheme.text.primary,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: spacer4),
              DigitButton(
                type: DigitButtonType.secondary,
                size: DigitButtonSize.medium,
                label: secondaryLabel,
                onPressed: () => Navigator.of(context).pop(),
                mainAxisSize: MainAxisSize.max,
              ),
              const SizedBox(height: spacer4),
              DigitButton(
                label: primaryLabel,
                onPressed: () => onRetry(context),
                size: DigitButtonSize.medium,
                type: DigitButtonType.primary,
                mainAxisSize: MainAxisSize.max,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
