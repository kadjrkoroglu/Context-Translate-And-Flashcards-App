import '../entities/entitlements_entity.dart';

abstract class EntitlementsRepository {
  Future<EntitlementsEntity> getEntitlements();
}
