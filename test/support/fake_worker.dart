import 'package:conway_game_of_life/core/worker/transport.dart';
import 'package:conway_game_of_life/core/worker/worker_service.dart';

/// Test-only transport. Production always uses a real worker/isolate.
class FakeWorker implements SimulationTransport {
  final service = WorkerService();
  final requests = <Map<String, Object?>>[];
  bool disposed = false;
  @override
  Future<Map<String, Object?>> request(Map<String, Object?> message) async {
    requests.add(message);
    return service.handle(message);
  }

  @override
  void dispose() => disposed = true;
}
