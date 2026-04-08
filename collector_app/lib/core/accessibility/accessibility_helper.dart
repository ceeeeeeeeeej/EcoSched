import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityHelper {
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
  
  static Widget buildSemanticButton({
    required Widget child,
    required VoidCallback onPressed,
    required String label,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      onTap: enabled ? onPressed : null,
      child: child,
    );
  }
  
  static Widget buildSemanticCard({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }
  
  static Widget buildSemanticTextField({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool isPassword = false,
    bool isRequired = false,
  }) {
    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      value: value,
      child: child,
    );
  }
  
  static Widget buildSemanticIcon({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }
  
  static Widget buildSemanticImage({
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(
      image: true,
      label: label,
      hint: hint,
      child: child,
    );
  }
  
  static Widget buildSemanticProgressIndicator({
    required Widget child,
    required String label,
    double? value,
  }) {
    return Semantics(
      label: label,
      value: value != null ? '${(value * 100).round()}%' : null,
      child: child,
    );
  }
  
  static Widget buildSemanticSwitch({
    required Widget child,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      button: true,
      label: label,
      toggled: value,
      onTap: () => onChanged(!value),
      child: child,
    );
  }
  
  static Widget buildSemanticSlider({
    required Widget child,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Semantics(
      slider: true,
      label: label,
      value: value.toString(),
      increasedValue: (value + (max - min) * 0.1).clamp(min, max).toStringAsFixed(1),
      decreasedValue: (value - (max - min) * 0.1).clamp(min, max).toStringAsFixed(1),
      onIncrease: () => onChanged((value + (max - min) * 0.1).clamp(min, max)),
      onDecrease: () => onChanged((value - (max - min) * 0.1).clamp(min, max)),
      child: child,
    );
  }
}
