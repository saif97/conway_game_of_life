abstract interface class SimulationTransport {
  Future<Map<String, Object?>> request(Map<String, Object?> message);
  void dispose();
}

class WorkerStopped implements Exception {
  const WorkerStopped();
}
