import { useEffect, useRef } from 'react';
import { useRecordingStore } from '../stores/useRecordingStore';

export function useTimer() {
  const isRecording = useRecordingStore((s) => s.isRecording);
  const setDuration = useRecordingStore((s) => s.setDuration);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const startTimeRef = useRef<number>(0);

  useEffect(() => {
    if (isRecording) {
      startTimeRef.current = Date.now();
      setDuration(0);
      intervalRef.current = setInterval(() => {
        const elapsed = (Date.now() - startTimeRef.current) / 1000;
        setDuration(elapsed);
      }, 100);
    } else {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [isRecording, setDuration]);
}
