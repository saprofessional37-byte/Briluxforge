// lib/core/utils/extensions.dart

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension StringExtension on String {
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

extension DoubleExtension on double {
  String toUsdString() {
    if (this >= 1000) return '\$${(this / 1000).toStringAsFixed(1)}k';
    if (this >= 100) return '\$${toStringAsFixed(0)}';
    if (this >= 10) return '\$${toStringAsFixed(2)}';
    return '\$${toStringAsFixed(4)}';
  }

  String toUsdDisplayString() {
    return '\$${toStringAsFixed(2)}';
  }
}
