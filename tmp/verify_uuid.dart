void main() {
  final seed = 'TP1A.220905.001';
  final hash = seed.hashCode.abs().toString().padRight(32, '0');
  final p1 = hash.substring(0, 8);
  final p2 = hash.substring(8, 12);
  final p3 = hash.substring(12, 16);
  final p4 = hash.substring(16, 20);
  final p5 = hash.substring(20, 32);

  print('Seed: $seed');
  print('Generated UUID: $p1-$p2-$p3-$p4-$p5');
}
