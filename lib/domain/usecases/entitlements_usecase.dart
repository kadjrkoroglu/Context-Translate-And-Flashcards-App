import '../entities/entitlements_entity.dart';
import '../repositories/entitlements_repository.dart';

class EntitlementsUsecase {
  final EntitlementsRepository _repository;

  EntitlementsUsecase(this._repository);

  Future<EntitlementsEntity> execute() {
    return _repository.getEntitlements();
  }
}
