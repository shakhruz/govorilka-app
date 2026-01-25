import React, { useCallback, useMemo, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import BottomSheet, { BottomSheetView } from '@gorhom/bottom-sheet';
import { PhotoGallery } from './PhotoGallery';
import { useGoogleDrive } from '../../hooks/useGoogleDrive';
import { TranscriptEntry } from '../../types/transcript';
import { colors } from '../../theme/colors';

interface ProReviewSheetProps {
  entry: TranscriptEntry;
  visible: boolean;
  onDismiss: () => void;
}

export function ProReviewSheet({ entry, visible, onDismiss }: ProReviewSheetProps) {
  const bottomSheetRef = useRef<BottomSheet>(null);
  const snapPoints = useMemo(() => ['70%', '90%'], []);
  const { exportEntry, isUploading, isConnected } = useGoogleDrive();

  const handleExport = useCallback(async () => {
    const success = await exportEntry(entry);
    if (success) {
      Alert.alert('Готово', 'Запись загружена в Google Drive');
      onDismiss();
    }
  }, [entry, exportEntry, onDismiss]);

  if (!visible) return null;

  return (
    <BottomSheet
      ref={bottomSheetRef}
      snapPoints={snapPoints}
      onClose={onDismiss}
      enablePanDownToClose
      backgroundStyle={styles.background}
      handleIndicatorStyle={styles.indicator}
    >
      <BottomSheetView style={styles.content}>
        <Text style={styles.title}>Обзор записи</Text>

        {entry.photos && entry.photos.length > 0 && (
          <PhotoGallery photos={entry.photos} />
        )}

        <View style={styles.textSection}>
          <Text style={styles.sectionLabel}>Текст</Text>
          <Text style={styles.transcriptText}>{entry.text}</Text>
        </View>

        <View style={styles.actions}>
          {isConnected && (
            <TouchableOpacity
              style={[styles.exportBtn, isUploading && styles.exportBtnDisabled]}
              onPress={handleExport}
              disabled={isUploading}
            >
              <Text style={styles.exportBtnText}>
                {isUploading ? 'Загрузка...' : 'Экспорт в Google Drive'}
              </Text>
            </TouchableOpacity>
          )}
          <TouchableOpacity style={styles.dismissBtn} onPress={onDismiss}>
            <Text style={styles.dismissBtnText}>Закрыть</Text>
          </TouchableOpacity>
        </View>
      </BottomSheetView>
    </BottomSheet>
  );
}

const styles = StyleSheet.create({
  background: {
    backgroundColor: colors.white,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
  },
  indicator: {
    backgroundColor: colors.lightPink,
    width: 40,
  },
  content: {
    flex: 1,
    padding: 20,
  },
  title: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.textColor,
    textAlign: 'center',
    marginBottom: 16,
  },
  textSection: {
    flex: 1,
    marginTop: 12,
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.pink,
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  transcriptText: {
    fontSize: 15,
    color: colors.textColor,
    lineHeight: 22,
  },
  actions: {
    gap: 10,
    marginTop: 16,
  },
  exportBtn: {
    backgroundColor: colors.pink,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  exportBtnDisabled: {
    opacity: 0.6,
  },
  exportBtnText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.white,
  },
  dismissBtn: {
    paddingVertical: 12,
    alignItems: 'center',
  },
  dismissBtnText: {
    fontSize: 15,
    color: colors.gray,
  },
});
