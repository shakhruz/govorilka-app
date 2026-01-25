import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { TranscriptEntry } from '../../types/transcript';
import { formatTimestamp } from '../../utils/formatTimestamp';
import { formatDuration } from '../../utils/formatDuration';
import { colors } from '../../theme/colors';

interface HistoryRowProps {
  entry: TranscriptEntry;
  onPress: () => void;
  onLongPress: () => void;
}

export function HistoryRow({ entry, onPress, onLongPress }: HistoryRowProps) {
  const preview = entry.text.length > 80
    ? entry.text.substring(0, 80) + '...'
    : entry.text;

  return (
    <TouchableOpacity
      style={styles.container}
      onPress={onPress}
      onLongPress={onLongPress}
      activeOpacity={0.7}
    >
      <View style={styles.header}>
        <Text style={styles.time}>{formatTimestamp(entry.timestamp)}</Text>
        <View style={styles.badges}>
          {entry.isProMode && (
            <View style={styles.proBadge}>
              <Text style={styles.proBadgeText}>Pro</Text>
            </View>
          )}
          <Text style={styles.duration}>{formatDuration(entry.duration)}</Text>
        </View>
      </View>
      <Text style={styles.text} numberOfLines={2}>
        {preview}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 14,
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  time: {
    fontSize: 12,
    color: colors.gray,
  },
  badges: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  proBadge: {
    backgroundColor: colors.pink,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  proBadgeText: {
    fontSize: 10,
    fontWeight: '600',
    color: colors.white,
  },
  duration: {
    fontSize: 12,
    color: colors.gray,
    fontVariant: ['tabular-nums'],
  },
  text: {
    fontSize: 14,
    color: colors.textColor,
    lineHeight: 20,
  },
});
