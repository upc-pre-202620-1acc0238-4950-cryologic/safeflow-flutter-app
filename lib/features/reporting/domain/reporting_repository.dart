import 'summary.dart';

abstract interface class ReportingRepositoryPort {
  Future<SafeFlowSummary> summary();
}
