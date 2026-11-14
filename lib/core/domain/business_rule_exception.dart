class BusinessRuleException implements Exception {
  const BusinessRuleException(this.message);
  final String message;
  @override
  String toString() => message;
}
