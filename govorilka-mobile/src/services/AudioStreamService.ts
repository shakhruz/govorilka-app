import {
  ExpoAudioStreamModule,
  AudioEventPayload,
  RecordingConfig,
} from '@mykin-ai/expo-audio-stream';
import { EventSubscription } from 'expo-modules-core';

export interface AudioStreamConfig {
  sampleRate: number;
  channels: number;
  bitsPerSample: number;
  interval?: number;
}

const DEFAULT_CONFIG: AudioStreamConfig = {
  sampleRate: 16000,
  channels: 1,
  bitsPerSample: 16,
  interval: 100, // ms between audio chunks
};

export type AudioDataCallback = (base64Data: string) => void;
export type AudioLevelCallback = (level: number) => void;

class AudioStreamServiceClass {
  private isStreaming = false;
  private onAudioData: AudioDataCallback | null = null;
  private onAudioLevel: AudioLevelCallback | null = null;
  private subscription: EventSubscription | null = null;
  private config: AudioStreamConfig = DEFAULT_CONFIG;

  init(config: Partial<AudioStreamConfig> = {}): void {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  async start(onData: AudioDataCallback, onLevel?: AudioLevelCallback): Promise<void> {
    if (this.isStreaming) return;

    this.onAudioData = onData;
    this.onAudioLevel = onLevel || null;
    this.isStreaming = true;

    // Subscribe to audio events
    this.subscription = ExpoAudioStreamModule.subscribeToAudioEvents(
      (event: AudioEventPayload) => {
        if (this.onAudioData && event.data) {
          this.onAudioData(event.data);
        }
        if (this.onAudioLevel && typeof event.soundLevel === 'number') {
          // soundLevel is already 0-1 normalized
          this.onAudioLevel(event.soundLevel);
        }
      }
    );

    // Start recording with config
    const recordingConfig: RecordingConfig = {
      sampleRate: this.config.sampleRate,
      channels: this.config.channels as 1 | 2,
      encoding: 'pcm_16bit',
      interval: this.config.interval || 100,
    };

    await ExpoAudioStreamModule.startRecording(recordingConfig);
  }

  async stop(): Promise<void> {
    if (!this.isStreaming) return;
    this.isStreaming = false;

    try {
      await ExpoAudioStreamModule.stopRecording();
    } catch (e) {
      console.warn('Error stopping recording:', e);
    }

    if (this.subscription) {
      this.subscription.remove();
      this.subscription = null;
    }

    this.onAudioData = null;
    this.onAudioLevel = null;
  }

  getIsStreaming(): boolean {
    return this.isStreaming;
  }
}

export const AudioStreamService = new AudioStreamServiceClass();
