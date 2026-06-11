import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.decimalPattern('vi_VN');

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = _digitsOnly(newValue.text);
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final formatted = _currencyFormatter.format(int.parse(digitsOnly));
    final digitsBeforeCursor = _digitsOnly(newValue.text.substring(0, newValue.selection.end)).length;

    int selectionIndex = 0;
    int digitCount = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        selectionIndex = i + 1;
        break;
      }
    }
    if (digitCount < digitsBeforeCursor) {
      selectionIndex = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

String formatCurrency(int value) {
  return _currencyFormatter.format(value);
}

int parseCurrencyInt(String text) {
  final digitsOnly = _digitsOnly(text);
  return digitsOnly.isEmpty ? 0 : int.parse(digitsOnly);
}

String _digitsOnly(String value) {
  return value.replaceAll(RegExp(r'[^0-9]'), '');
}
