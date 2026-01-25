import React from 'react';
import { Text, StyleSheet } from 'react-native';
import { formatDuration } from '../../utils/formatDuration';
import { colors } from '../../theme/colors';

interface DurationDisplayProps {
  duration: number;
  isRecording: boolean;
}

export function DurationDisplay({ duration, isRecording }: DurationDisplayProps) {
  if (!isRecording && duration === 0) return null;

  return (
    <Text style={[styles.duration, isRecording && styles.recording]}>
      {formatDuration(duration)}
    </Text>
  );
}

const styles = StyleSheet.create({
  duration: {
    fontSize: 24,
    fontWeight: '300',
    fontVariant: ['tabular-nums'],
    color: colors.textColor,
    marginTop: 16,
  },
  recording: {
    color: colors.pink,
  },
});
