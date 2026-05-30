import 'package:flutter/services.dart';

class PakistanPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final localDigits = digits.startsWith('92') ? digits.substring(2) : digits;
    final limitedDigits =
        localDigits.length > 10 ? localDigits.substring(0, 10) : localDigits;

    final buffer = StringBuffer('+92 ');
    if (limitedDigits.length <= 3) {
      buffer.write(limitedDigits);
    } else {
      buffer
        ..write(limitedDigits.substring(0, 3))
        ..write('-')
        ..write(limitedDigits.substring(3));
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String? validatePakistanPhoneNumber(String? value) {
  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  final localDigits = digits.startsWith('92') ? digits.substring(2) : digits;

  if (localDigits.isEmpty) {
    return 'Please enter your phone number';
  }
  if (localDigits.length != 10) {
    return 'Enter 10 digits after +92';
  }
  return null;
}
