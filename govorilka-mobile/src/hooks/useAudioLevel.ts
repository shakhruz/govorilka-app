import { useEffect, useRef } from 'react';
import { useRecordingStore } from '../stores/useRecordingStore';

export function useAudioLevel() {
  const audioLevel = useRecordingStore((s) => s.audioLevel);
  const isRecording = useRecordingStore((s) => s.isRecording);
  const smoothedRef = useRef(0);

  useEffect(() => {
    if (!isRecording) {
      smoothedRef.current = 0;
    }
  }, [isRecording]);

  // Smooth the audio level for animation
  const smoothFactor = 0.3;
  smoothedRef.current = smoothedRef.current * (1 - smoothFactor) + audioLevel * smoothFactor;

  return {
    rawLevel: audioLevel,
    smoothedLevel: smoothedRef.current,
  };
}
