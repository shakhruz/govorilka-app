import { DeepgramResponse, DeepgramConfig } from '../types/deepgram';

export type TranscriptCallback = (text: string, isFinal: boolean) => void;
export type ErrorCallback = (error: string) => void;
export type ConnectionCallback = () => void;

const DEFAULT_CONFIG: Omit<DeepgramConfig, 'apiKey'> = {
  language: 'ru',
  model: 'nova-2',
  encoding: 'linear16',
  sampleRate: 16000,
  channels: 1,
  interimResults: true,
  punctuate: true,
  smartFormat: true,
};

class DeepgramWebSocketServiceClass {
  private ws: WebSocket | null = null;
  private onTranscript: TranscriptCallback | null = null;
  private onError: ErrorCallback | null = null;
  private onConnected: ConnectionCallback | null = null;
  private onDisconnected: ConnectionCallback | null = null;
  private isConnected = false;
  private keepAliveInterval: ReturnType<typeof setInterval> | null = null;

  connect(
    apiKey: string,
    callbacks: {
      onTranscript: TranscriptCallback;
      onError: ErrorCallback;
      onConnected?: ConnectionCallback;
      onDisconnected?: ConnectionCallback;
    },
    config: Partial<Omit<DeepgramConfig, 'apiKey'>> = {}
  ): void {
    if (this.isConnected) {
      this.disconnect();
    }

    this.onTranscript = callbacks.onTranscript;
    this.onError = callbacks.onError;
    this.onConnected = callbacks.onConnected || null;
    this.onDisconnected = callbacks.onDisconnected || null;

    const finalConfig = { ...DEFAULT_CONFIG, ...config };

    const params = new URLSearchParams({
      token: apiKey,
      language: finalConfig.language,
      model: finalConfig.model,
      encoding: finalConfig.encoding,
      sample_rate: finalConfig.sampleRate.toString(),
      channels: finalConfig.channels.toString(),
      interim_results: finalConfig.interimResults.toString(),
      punctuate: finalConfig.punctuate.toString(),
      smart_format: finalConfig.smartFormat.toString(),
    });

    const url = `wss://api.deepgram.com/v1/listen?${params.toString()}`;

    try {
      this.ws = new WebSocket(url);

      this.ws.onopen = () => {
        this.isConnected = true;
        this.startKeepAlive();
        this.onConnected?.();
      };

      this.ws.onmessage = (event) => {
        this.handleMessage(event.data);
      };

      this.ws.onerror = (event: Event) => {
        const wsEvent = event as unknown as { message?: string };
        this.onError?.(wsEvent.message || 'WebSocket error');
      };

      this.ws.onclose = () => {
        this.isConnected = false;
        this.stopKeepAlive();
        this.onDisconnected?.();
      };
    } catch (error) {
      this.onError?.(`Connection failed: ${error}`);
    }
  }

  sendAudio(base64Data: string): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;

    const binaryString = atob(base64Data);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    this.ws.send(bytes.buffer);
  }

  finishStream(): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
    // Send close stream message
    this.ws.send(JSON.stringify({ type: 'CloseStream' }));
  }

  disconnect(): void {
    this.stopKeepAlive();
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.isConnected = false;
    this.onTranscript = null;
    this.onError = null;
    this.onConnected = null;
    this.onDisconnected = null;
  }

  getIsConnected(): boolean {
    return this.isConnected;
  }

  private handleMessage(data: string): void {
    try {
      const response = JSON.parse(data);

      if (response.type === 'Results') {
        const result = response as DeepgramResponse;
        const transcript = result.channel?.alternatives?.[0]?.transcript;
        if (transcript) {
          this.onTranscript?.(transcript, result.is_final);
        }
      }
    } catch {
      // Ignore non-JSON messages
    }
  }

  private startKeepAlive(): void {
    this.keepAliveInterval = setInterval(() => {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: 'KeepAlive' }));
      }
    }, 10000);
  }

  private stopKeepAlive(): void {
    if (this.keepAliveInterval) {
      clearInterval(this.keepAliveInterval);
      this.keepAliveInterval = null;
    }
  }
}

export const DeepgramWebSocketService = new DeepgramWebSocketServiceClass();
