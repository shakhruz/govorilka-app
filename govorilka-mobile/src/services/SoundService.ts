import { Audio } from 'expo-av';
import * as Haptics from 'expo-haptics';

type SoundName = 'start' | 'stop' | 'success' | 'error';

const SOUND_FILES: Record<SoundName, number | null> = {
  start: null,
  stop: null,
  success: null,
  error: null,
};

class SoundServiceClass {
  private sounds: Record<string, Audio.Sound | null> = {};
  private soundEnabled = true;
  private hapticEnabled = true;

  setSoundEnabled(enabled: boolean): void {
    this.soundEnabled = enabled;
  }

  setHapticEnabled(enabled: boolean): void {
    this.hapticEnabled = enabled;
  }

  async playStart(): Promise<void> {
    await this.haptic(Haptics.ImpactFeedbackStyle.Medium);
    await this.playSystemSound();
  }

  async playStop(): Promise<void> {
    await this.haptic(Haptics.ImpactFeedbackStyle.Light);
    await this.playSystemSound();
  }

  async playSuccess(): Promise<void> {
    await this.haptic(Haptics.NotificationFeedbackType.Success);
  }

  async playError(): Promise<void> {
    await this.haptic(Haptics.NotificationFeedbackType.Error);
  }

  private async haptic(
    style: Haptics.ImpactFeedbackStyle | Haptics.NotificationFeedbackType
  ): Promise<void> {
    if (!this.hapticEnabled) return;
    try {
      if (Object.values(Haptics.ImpactFeedbackStyle).includes(style as Haptics.ImpactFeedbackStyle)) {
        await Haptics.impactAsync(style as Haptics.ImpactFeedbackStyle);
      } else {
        await Haptics.notificationAsync(style as Haptics.NotificationFeedbackType);
      }
    } catch {
      // Haptics not available (simulator)
    }
  }

  private async playSystemSound(): Promise<void> {
    if (!this.soundEnabled) return;
    // Using system sounds since we don't bundle custom audio files
    // In production, load from assets/sounds/
  }

  async cleanup(): Promise<void> {
    for (const sound of Object.values(this.sounds)) {
      if (sound) {
        await sound.unloadAsync();
      }
    }
    this.sounds = {};
  }
}

export const SoundService = new SoundServiceClass();
