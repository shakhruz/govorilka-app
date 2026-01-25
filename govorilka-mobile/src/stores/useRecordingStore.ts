import { create } from 'zustand';

interface RecordingState {
  isRecording: boolean;
  isConnecting: boolean;
  transcript: string;
  interimText: string;
  audioLevel: number;
  duration: number;
  error: string | null;

  setRecording: (isRecording: boolean) => void;
  setConnecting: (isConnecting: boolean) => void;
  appendFinalText: (text: string) => void;
  setInterimText: (text: string) => void;
  setAudioLevel: (level: number) => void;
  setDuration: (duration: number) => void;
  setError: (error: string | null) => void;
  reset: () => void;
}

export const useRecordingStore = create<RecordingState>((set) => ({
  isRecording: false,
  isConnecting: false,
  transcript: '',
  interimText: '',
  audioLevel: 0,
  duration: 0,
  error: null,

  setRecording: (isRecording) => set({ isRecording }),
  setConnecting: (isConnecting) => set({ isConnecting }),
  appendFinalText: (text) =>
    set((state) => ({
      transcript: state.transcript ? `${state.transcript} ${text}` : text,
      interimText: '',
    })),
  setInterimText: (interimText) => set({ interimText }),
  setAudioLevel: (audioLevel) => set({ audioLevel }),
  setDuration: (duration) => set({ duration }),
  setError: (error) => set({ error }),
  reset: () =>
    set({
      isRecording: false,
      isConnecting: false,
      transcript: '',
      interimText: '',
      audioLevel: 0,
      duration: 0,
      error: null,
    }),
}));
