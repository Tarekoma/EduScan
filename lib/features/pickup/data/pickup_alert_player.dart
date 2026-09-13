import 'package:audioplayers/audioplayers.dart';

/// Plays the "new pickup request" alert. Kept behind an interface so the
/// detection logic in [PickupAlertCubit] stays unit-testable.
abstract interface class PickupAlertPlayer {
  Future<void> playAlert();
  Future<void> dispose();
}

class AudioPickupAlertPlayer implements PickupAlertPlayer {
  AudioPickupAlertPlayer() : _player = AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;

  @override
  Future<void> playAlert() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/pickup_alert.wav'));
    } catch (_) {
      // Audio must never break the pickup queue.
    }
  }

  @override
  Future<void> dispose() => _player.dispose();
}
