import '../domain/reporting_repository.dart';
import '../domain/summary.dart';

class ReportingService {
  const ReportingService(this.repository);
  final ReportingRepositoryPort repository;

  Future<SafeFlowSummary> summary() => repository.summary();
}
