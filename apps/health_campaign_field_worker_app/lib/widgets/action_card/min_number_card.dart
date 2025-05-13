import 'package:digit_ui_components/theme/digit_extended_theme.dart';

import 'package:flutter/material.dart';

import 'package:inventory_management/utils/i18_key_constants.dart' as i18;
import 'package:qr_flutter/qr_flutter.dart';

class MinNumberCard extends StatelessWidget {
  final String minNumber;
  final String qrImagePath;
  final String cddCode;
  final String date;
  final List<Map<String, String>> items;
  final Map<String, dynamic> data;

  const MinNumberCard({
    super.key,
    required this.minNumber,
    required this.qrImagePath,
    required this.cddCode,
    required this.date,
    required this.items,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8.0), // Replace spacer2 with 8.0
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select the MIN number",
              style: textTheme.headingL,
            ),
            const SizedBox(height: 16.0), // Replace spacer4 with 16.0
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0), // Replace spacer2
              ),
              padding: const EdgeInsets.all(8.0), // Replace spacer2
              child: Text(
                minNumber,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8.0), // Replace spacer2
            Container(
              height: 155,
              width: 155,
              alignment: Alignment.center,
              child: QrImageView(
                data: data.toString(),
                version: QrVersions.auto,
                size: 150.0,
              ),
            ),
            const SizedBox(height: 8.0), // Replace spacer2
            Text(cddCode),
            const SizedBox(height: 8.0), // Replace spacer2
            Text(
              date,
              style: textTheme.bodyL,
            ),
            const SizedBox(height: 8.0), // Replace spacer2
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Replace spacer2
                child: Row(
                  children: [
                    Text(
                      item['name']!,
                      style: textTheme.bodyL,
                    ),
                    const SizedBox(width: 8.0), // Replace spacer2
                    Text(
                      "|",
                      style: textTheme.bodyL,
                    ),
                    const SizedBox(width: 8.0), // Replace spacer2
                    Text(
                      item['quantity']!,
                      style: textTheme.bodyL,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
