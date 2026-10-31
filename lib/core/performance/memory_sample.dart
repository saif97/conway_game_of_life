class MemorySample {
  const MemorySample(this.bytes, this.label, this.description);
  final int? bytes;
  final String label;
  final String description;
}

const unavailableMemory = MemorySample(
  null,
  'Memory',
  'This browser does not expose memory measurements. Use browser task manager for total RAM.',
);
