import '../../domain/entities/entitlements_entity.dart';
import '../../domain/repositories/entitlements_repository.dart';
import '../services/entitlements_service.dart';

class EntitlementsRepositoryImpl implements EntitlementsRepository {
  final EntitlementsService _service;

  EntitlementsRepositoryImpl(this._service);

  @override
  Future<EntitlementsEntity> getEntitlements() async {
    final json = await _service.fetchEntitlements();
    return EntitlementsEntity.fromJson(json);
  }
}
