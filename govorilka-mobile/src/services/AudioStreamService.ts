import LiveAudioStream from 'react-native-live-audio-stream';

export interface AudioStreamConfig {
  sampleRate: number;
  channels: number;
  bitsPerSample: number;
  audioSource?: number;
  bufferSize?: number;
  wavFile: string;
}

const DEFAULT_CONFIG: AudioStreamConfig = {
  sampleRate: 16000,
  channels: 1,
  bitsPerSample: 16,
  audioSource: 6,
  bufferSize: 2048,
  wavFile: '', // Not used, streaming only
};

export type AudioDataCallback = (base64Data: string) => void;
export type AudioLevelCallback = (level: number) => void;

class AudioStreamServiceClass {
  private isStreaming = false;
  private onAudioData: AudioDataCallback | null = null;
  private onAudioLevel: AudioLevelCallback | null = null;

  init(config: Partial<AudioStreamConfig> = {}): void {
    const finalConfig = { ...DEFAULT_CONFIG, ...config };
    LiveAudioStream.init(finalConfig);
  }

  start(onData: AudioDataCallback, onLevel?: AudioLevelCallback): void {
    if (this.isStreaming) return;

    this.onAudioData = onData;
    this.onAudioLevel = onLevel || null;
    this.isStreaming = true;

    LiveAudioStream.start();

    LiveAudioStream.on('data', (data: string) => {
      if (this.onAudioData) {
        this.onAudioData(data);
      }
      if (this.onAudioLevel) {
        const level = this.calculateLevel(data);
        this.onAudioLevel(level);
      }
    });
  }

  stop(): void {
    if (!this.isStreaming) return;
    this.isStreaming = false;
    LiveAudioStream.stop();
    this.onAudioData = null;
    this.onAudioLevel = null;
  }

  getIsStreaming(): boolean {
    return this.isStreaming;
  }

  private calculateLevel(base64Data: string): number {
    try {
      const binaryString = atob(base64Data);
      const length = binaryString.length;
      let sum = 0;
      const sampleCount = Math.floor(length / 2);

      for (let i = 0; i < length - 1; i += 2) {
        const low = binaryString.charCodeAt(i);
        const high = binaryString.charCodeAt(i + 1);
        let sample = (high << 8) | low;
        if (sample > 32767) sample -= 65536;
        sum += Math.abs(sample);
      }

      const average = sum / sampleCount;
      // Normalize to 0-1 range (16-bit max is 32768)
      return Math.min(average / 8000, 1.0);
    } catch {
      return 0;
    }
  }
}

export const AudioStreamService = new AudioStreamServiceClass();
