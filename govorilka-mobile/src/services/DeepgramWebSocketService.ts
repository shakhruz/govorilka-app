import { DeepgramResponse, DeepgramConfig } from '../types/deepgram';

// Тип для события закрытия WebSocket
interface WebSocketCloseEvent {
  code: number;
  reason: string;
  wasClean: boolean;
}

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
        const message = wsEvent.message || 'Ошибка подключения к Deepgram';
        this.onError?.(message);
      };

      this.ws.onclose = (event: WebSocketCloseEvent) => {
        this.stopKeepAlive();
        const wasConnected = this.isConnected;
        this.isConnected = false;

        // Обработка кодов ошибок Deepgram
        if (event.code === 1008) {
          // Policy Violation - обычно неверный API ключ
          this.onError?.('Неверный API ключ. Проверьте ключ в настройках.');
        } else if (event.code === 1006) {
          // Abnormal Closure - проблемы с сетью
          this.onError?.('Нет подключения к серверу. Проверьте интернет.');
        } else if (event.code === 1011) {
          // Internal Error
          this.onError?.('Ошибка сервера Deepgram. Попробуйте позже.');
        } else if (event.code === 1003) {
          // Unsupported Data
          this.onError?.('Неподдерживаемый формат данных.');
        } else if (event.code !== 1000 && wasConnected) {
          // Любой другой код ошибки (кроме нормального закрытия 1000)
          this.onError?.(`Соединение закрыто (код ${event.code})`);
        }

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
