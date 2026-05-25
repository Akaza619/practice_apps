String formatCurrency(double val) {
  if (val == 0) return '₹0.00';
  return '₹${val.toStringAsFixed(2)}';
}

String formatNum(double val) {
  if (val == val.truncate()) return val.toInt().toString();
  return val.toStringAsFixed(2);
}
