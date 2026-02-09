import { useCallback, useRef } from 'react';
import { Alert } from 'react-native';
import { useRecordingStore } from '../stores/useRecordingStore';
import { useHistoryStore } from '../stores/useHistoryStore';
import { useSettingsStore } from '../stores/useSettingsStore';
import { AudioStreamService } from '../services/AudioStreamService';
import { DeepgramWebSocketService } from '../services/DeepgramWebSocketService';
import { LocalRecorderService } from '../services/LocalRecorderService';
import { TextCleanerService } from '../services/TextCleanerService';
import { SoundService } from '../services/SoundService';
import { SecureStorageService } from '../services/SecureStorageService';
import { requestMicrophonePermission } from '../utils/permissions';
import { useTimer } from './useTimer';

export function useAudioRecording() {
  const {
    isRecording,
    isConnecting,
    transcript,
    interimText,
    duration,
    audioLevel,
    error,
    setRecording,
    setConnecting,
    appendFinalText,
    setInterimText,
    setAudioLevel,
    setError,
    reset,
  } = useRecordingStore();

  const addEntry = useHistoryStore((s) => s.addEntry);
  const settings = useSettingsStore();
  const startTimeRef = useRef<number>(0);
  const connectionTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useTimer();

  const startRecording = useCallback(async () => {
    const apiKey = await SecureStorageService.getApiKey();
    if (!apiKey) {
      Alert.alert('API ключ', 'Добавьте API ключ Deepgram в настройках');
      return;
    }

    const hasPermission = await requestMicrophonePermission();
    if (!hasPermission) return;

    reset();
    setConnecting(true);

    SoundService.setSoundEnabled(settings.soundEnabled);
    SoundService.setHapticEnabled(settings.hapticEnabled);

    // Initialize audio stream
    AudioStreamService.init({
      sampleRate: 16000,
      channels: 1,
      bitsPerSample: 16,
      interval: 100, // ms between audio chunks
    });

    // Таймаут подключения (10 секунд)
    connectionTimeoutRef.current = setTimeout(() => {
      if (useRecordingStore.getState().isConnecting) {
        DeepgramWebSocketService.disconnect();
        setError('Таймаут подключения. Проверьте интернет-соединение.');
        setConnecting(false);
        SoundService.playError();
      }
    }, 10000);

    // Connect to Deepgram
    DeepgramWebSocketService.connect(apiKey, {
      onTranscript: (text, isFinal) => {
        if (isFinal) {
          const cleaned = settings.textCleaningEnabled
            ? TextCleanerService.clean(text)
            : text;
          if (cleaned.trim()) {
            appendFinalText(cleaned);
          }
        } else {
          setInterimText(text);
        }
      },
      onError: (err) => {
        // Очищаем таймаут при ошибке
        if (connectionTimeoutRef.current) {
          clearTimeout(connectionTimeoutRef.current);
          connectionTimeoutRef.current = null;
        }
        setError(err);
        stopRecording();
        SoundService.playError();
      },
      onConnected: async () => {
        // Очищаем таймаут при успешном подключении
        if (connectionTimeoutRef.current) {
          clearTimeout(connectionTimeoutRef.current);
          connectionTimeoutRef.current = null;
        }
        setConnecting(false);
        setRecording(true);
        startTimeRef.current = Date.now();
        SoundService.playStart();

        // Start local backup recording
        LocalRecorderService.startRecording();

        // Start audio streaming
        await AudioStreamService.start(
          (base64Data) => {
            DeepgramWebSocketService.sendAudio(base64Data);
            LocalRecorderService.addChunk(base64Data);
          },
          (level) => {
            setAudioLevel(level);
          }
        );
      },
      onDisconnected: () => {
        // Очищаем таймаут при отключении
        if (connectionTimeoutRef.current) {
          clearTimeout(connectionTimeoutRef.current);
          connectionTimeoutRef.current = null;
        }
        if (useRecordingStore.getState().isRecording) {
          stopRecording();
        }
      },
    });
  }, [settings.soundEnabled, settings.hapticEnabled, settings.textCleaningEnabled]);

  const stopRecording = useCallback(async () => {
    await AudioStreamService.stop();
    DeepgramWebSocketService.finishStream();

    // Small delay for final transcript to arrive
    setTimeout(() => {
      DeepgramWebSocketService.disconnect();
    }, 500);

    setRecording(false);
    SoundService.playStop();

    // Save local backup
    await LocalRecorderService.stopAndSave();

    // Save to history
    const state = useRecordingStore.getState();
    const finalText = state.transcript.trim();
    if (finalText) {
      const entry = {
        id: Date.now().toString(),
        text: finalText,
        timestamp: startTimeRef.current,
        duration: Math.floor((Date.now() - startTimeRef.current) / 1000),
        isProMode: settings.proModeEnabled,
      };
      addEntry(entry);
      SoundService.playSuccess();
    }
  }, [settings.proModeEnabled, addEntry]);

  const toggleRecording = useCallback(async () => {
    if (isRecording || isConnecting) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }, [isRecording, isConnecting, startRecording, stopRecording]);

  return {
    isRecording,
    isConnecting,
    transcript,
    interimText,
    duration,
    audioLevel,
    error,
    toggleRecording,
  };
}
