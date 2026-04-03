import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      
      content = content.replaceAll('BorderRadius.circular(24)', 'BorderRadius.circular(32)');
      content = content.replaceAll('BorderRadius.circular(22)', 'BorderRadius.circular(32)');
      content = content.replaceAll('BorderRadius.circular(20)', 'BorderRadius.circular(28)');
      content = content.replaceAll('BorderRadius.circular(18)', 'BorderRadius.circular(24)');
      content = content.replaceAll('Radius.circular(28)', 'Radius.circular(40)');
      
      content = content.replaceAll('white.withValues(alpha: 0.05)', 'white.withValues(alpha: 0.03)');
      content = content.replaceAll('white.withValues(alpha: 0.04)', 'white.withValues(alpha: 0.02)');
      
      // Update clip radii to match the new container radii mathematically
      // For PuzzleBoard: 32 container radius -> 30.5 inner radius
      content = content.replaceAll('Radius.circular(20.5)', 'Radius.circular(30.5)');
      
      file.writeAsStringSync(content);
    }
  }
  print('Updated UI radii and opacities globally!');
}
