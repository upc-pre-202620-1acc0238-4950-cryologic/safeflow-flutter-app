import '../../../core/domain/business_rule_exception.dart';
import '../domain/alerts_repository.dart';

class AlertService {
  const AlertService(this.repository);
  final AlertsRepositoryPort repository;

  Future<void> resolveIncident(int id, String action) async {
    if (action.trim().isEmpty) {
      throw const BusinessRuleException(
        'Describe la acci?n correctiva antes de resolver.',
      );
    }
    await repository.resolveIncident(id, action.trim());
  }
}
