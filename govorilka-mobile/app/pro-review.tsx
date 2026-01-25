import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image, ScrollView, Alert } from 'react-native';
import { router } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { useRecordingStore } from '../src/stores/useRecordingStore';
import { useHistoryStore } from '../src/stores/useHistoryStore';
import { colors } from '../src/theme/colors';

export default function ProReviewScreen() {
  const transcript = useRecordingStore((s) => s.transcript);
  const addEntry = useHistoryStore((s) => s.addEntry);
  const [photos, setPhotos] = useState<string[]>([]);

  const takePhoto = useCallback(async () => {
    const result = await ImagePicker.launchCameraAsync({
      mediaTypes: ['images'],
      quality: 0.7,
      allowsEditing: true,
    });

    if (!result.canceled && result.assets[0]) {
      setPhotos((prev) => [...prev, result.assets[0].uri]);
    }
  }, []);

  const removePhoto = useCallback((index: number) => {
    setPhotos((prev) => prev.filter((_, i) => i !== index));
  }, []);

  const handleSave = useCallback(() => {
    const entry = {
      id: Date.now().toString(),
      text: transcript,
      timestamp: Date.now(),
      duration: 0,
      isProMode: true,
      photos,
    };
    addEntry(entry);
    router.back();
  }, [transcript, photos, addEntry]);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.cancelText}>Отмена</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Pro Обзор</Text>
        <TouchableOpacity onPress={handleSave}>
          <Text style={styles.saveText}>Сохранить</Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content}>
        <View style={styles.photosSection}>
          <Text style={styles.sectionLabel}>Фотографии</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View style={styles.photosRow}>
              {photos.map((uri, index) => (
                <TouchableOpacity
                  key={index}
                  onLongPress={() => removePhoto(index)}
                >
                  <Image source={{ uri }} style={styles.photoThumb} />
                </TouchableOpacity>
              ))}
              <TouchableOpacity style={styles.addPhotoBtn} onPress={takePhoto}>
                <Text style={styles.addPhotoIcon}>📷</Text>
                <Text style={styles.addPhotoText}>Фото</Text>
              </TouchableOpacity>
            </View>
          </ScrollView>
        </View>

        <View style={styles.textSection}>
          <Text style={styles.sectionLabel}>Текст</Text>
          <View style={styles.textCard}>
            <Text style={styles.transcriptText}>
              {transcript || 'Нет текста'}
            </Text>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.backgroundTop,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 60,
    paddingBottom: 16,
  },
  cancelText: {
    fontSize: 16,
    color: colors.gray,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.textColor,
  },
  saveText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.pink,
  },
  content: {
    flex: 1,
    padding: 16,
  },
  photosSection: {
    marginBottom: 24,
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.pink,
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  photosRow: {
    flexDirection: 'row',
    gap: 12,
  },
  photoThumb: {
    width: 100,
    height: 100,
    borderRadius: 12,
    backgroundColor: colors.softPink,
  },
  addPhotoBtn: {
    width: 100,
    height: 100,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: colors.lightPink,
    borderStyle: 'dashed',
    alignItems: 'center',
    justifyContent: 'center',
  },
  addPhotoIcon: {
    fontSize: 24,
    marginBottom: 4,
  },
  addPhotoText: {
    fontSize: 12,
    color: colors.gray,
  },
  textSection: {
    flex: 1,
  },
  textCard: {
    backgroundColor: colors.white,
    borderRadius: 14,
    padding: 16,
    minHeight: 150,
  },
  transcriptText: {
    fontSize: 15,
    color: colors.textColor,
    lineHeight: 22,
  },
});
