import 'package:flutter/services.dart';

class BeneficiaryIdInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Build the raw ID (only [0-9A-Z], max 12 chars) and compute how many
    // raw characters are before the cursor, in a single pass over newValue.
    final rawBuffer = StringBuffer();
    int cursorRawIndex = 0;
    final selectionOffset = newValue.selection.baseOffset;

    for (var i = 0; i < newValue.text.length; i++) {
      var ch = newValue.text[i].toUpperCase();
      if (!RegExp(r'[0-9A-Z]').hasMatch(ch)) {
        continue; // Skip any non‑ID characters
      }

      // Enforce 12‑character limit by ignoring extra characters at the end.
      if (rawBuffer.length >= 12) {
        break;
      }

      rawBuffer.write(ch);

      // If this character is before the visual cursor, it contributes to the
      // raw index of the cursor.
      if (i < selectionOffset) {
        cursorRawIndex++;
      }
    }

    final raw = rawBuffer.toString();
    if (cursorRawIndex > raw.length) {
      cursorRawIndex = raw.length;
    }

    // Rebuild the formatted string with hyphens and compute the new cursor
    // position in the formatted text based on cursorRawIndex.
    final buffer = StringBuffer();
    var cursorPosition = 0;

    for (var i = 0; i < raw.length; i++) {
      if (i == 4 || i == 8) {
        buffer.write('-');
        if (i < cursorRawIndex) {
          cursorPosition++;
        }
      }
      buffer.write(raw[i]);
      if (i < cursorRawIndex) {
        cursorPosition++;
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
