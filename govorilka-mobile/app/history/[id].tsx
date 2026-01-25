import React, { useMemo, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import * as Clipboard from 'expo-clipboard';
import { useHistoryStore } from '../../src/stores/useHistoryStore';
import { PhotoGallery } from '../../src/components/pro/PhotoGallery';
import { useGoogleDrive } from '../../src/hooks/useGoogleDrive';
import { formatTimestamp } from '../../src/utils/formatTimestamp';
import { formatDuration } from '../../src/utils/formatDuration';
import { colors } from '../../src/theme/colors';

export default function HistoryDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const entries = useHistoryStore((s) => s.entries);
  const entry = useMemo(() => entries.find((e) => e.id === id), [entries, id]);
  const { exportEntry, isUploading, isConnected } = useGoogleDrive();

  if (!entry) {
    return (
      <View style={styles.container}>
        <Text style={styles.notFound}>Запись не найдена</Text>
      </View>
    );
  }

  const handleCopy = async () => {
    await Clipboard.setStringAsync(entry.text);
    Alert.alert('', 'Текст скопирован');
  };

  const handleExport = async () => {
    const success = await exportEntry(entry);
    if (success) {
      Alert.alert('Готово', 'Запись загружена в Google Drive');
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.meta}>
        <Text style={styles.time}>{formatTimestamp(entry.timestamp)}</Text>
        <Text style={styles.duration}>{formatDuration(entry.duration)}</Text>
        {entry.isProMode && (
          <View style={styles.proBadge}>
            <Text style={styles.proBadgeText}>Pro</Text>
          </View>
        )}
      </View>

      {entry.photos && entry.photos.length > 0 && (
        <PhotoGallery photos={entry.photos} />
      )}

      <View style={styles.textCard}>
        <Text style={styles.text}>{entry.text}</Text>
      </View>

      <View style={styles.actions}>
        <TouchableOpacity style={styles.copyBtn} onPress={handleCopy}>
          <Text style={styles.copyBtnText}>Копировать текст</Text>
        </TouchableOpacity>

        {isConnected && entry.isProMode && (
          <TouchableOpacity
            style={[styles.exportBtn, isUploading && styles.disabled]}
            onPress={handleExport}
            disabled={isUploading}
          >
            <Text style={styles.exportBtnText}>
              {isUploading ? 'Загрузка...' : 'Экспорт в Drive'}
            </Text>
          </TouchableOpacity>
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.backgroundTop,
  },
  content: {
    padding: 16,
  },
  notFound: {
    fontSize: 16,
    color: colors.gray,
    textAlign: 'center',
    marginTop: 40,
  },
  meta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  time: {
    fontSize: 14,
    color: colors.gray,
  },
  duration: {
    fontSize: 14,
    color: colors.textColor,
    fontVariant: ['tabular-nums'],
  },
  proBadge: {
    backgroundColor: colors.pink,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  proBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.white,
  },
  textCard: {
    backgroundColor: colors.white,
    borderRadius: 14,
    padding: 16,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  text: {
    fontSize: 15,
    color: colors.textColor,
    lineHeight: 24,
  },
  actions: {
    gap: 12,
  },
  copyBtn: {
    backgroundColor: colors.pink,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  copyBtnText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.white,
  },
  exportBtn: {
    borderWidth: 1.5,
    borderColor: colors.pink,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  exportBtnText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.pink,
  },
  disabled: {
    opacity: 0.5,
  },
});
