import React, { useCallback } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { FlashList } from '@shopify/flash-list';
import { useHistoryStore } from '../../stores/useHistoryStore';
import { HistoryRow } from './HistoryRow';
import { EmptyState } from './EmptyState';
import { TranscriptEntry } from '../../types/transcript';
import * as Clipboard from 'expo-clipboard';

export function HistoryList() {
  const { entries, removeEntry } = useHistoryStore();

  const handleCopy = useCallback(async (entry: TranscriptEntry) => {
    await Clipboard.setStringAsync(entry.text);
    Alert.alert('', 'Текст скопирован', [{ text: 'OK' }]);
  }, []);

  const handleDelete = useCallback(
    (entry: TranscriptEntry) => {
      Alert.alert('Удалить запись?', 'Это действие нельзя отменить', [
        { text: 'Отмена', style: 'cancel' },
        {
          text: 'Удалить',
          style: 'destructive',
          onPress: () => removeEntry(entry.id),
        },
      ]);
    },
    [removeEntry]
  );

  if (entries.length === 0) {
    return <EmptyState />;
  }

  return (
    <View style={styles.container}>
      <FlashList
        data={entries}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <HistoryRow
            entry={item}
            onPress={() => handleCopy(item)}
            onLongPress={() => handleDelete(item)}
          />
        )}
        contentContainerStyle={styles.listContent}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 20,
  },
});
