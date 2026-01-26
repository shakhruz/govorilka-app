import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import * as FileSystem from 'expo-file-system';
import { useRecordingStore } from '../src/stores/useRecordingStore';
import { useHistoryStore } from '../src/stores/useHistoryStore';
import { useSettingsStore } from '../src/stores/useSettingsStore';
import { useFeedbackQueueStore } from '../src/stores/useFeedbackQueueStore';
import { colors } from '../src/theme/colors';

export default function ProReviewScreen() {
  const transcript = useRecordingStore((s) => s.transcript);
  const addEntry = useHistoryStore((s) => s.addEntry);
  const { githubConnected, githubSelectedRepo } = useSettingsStore();
  const addToQueue = useFeedbackQueueStore((s) => s.addToQueue);
  const [photos, setPhotos] = useState<string[]>([]);
  const [isPushingToGitHub, setIsPushingToGitHub] = useState(false);

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

  const handlePushToGitHub = useCallback(async () => {
    if (!githubSelectedRepo) {
      Alert.alert('Ошибка', 'Выберите репозиторий в настройках');
      return;
    }

    setIsPushingToGitHub(true);

    try {
      // Convert photo URIs to base64
      const photoBase64s: string[] = [];
      for (const uri of photos) {
        try {
          const base64 = await FileSystem.readAsStringAsync(uri, {
            encoding: 'base64',
          });
          photoBase64s.push(base64);
        } catch (err) {
          console.error('Failed to read photo:', err);
        }
      }

      // Add to queue (will sync automatically or retry later)
      addToQueue(githubSelectedRepo, {
        text: transcript,
        timestamp: new Date(),
        photos: photoBase64s.length > 0 ? photoBase64s : undefined,
      });

      Alert.alert('Отправлено', 'Фидбэк добавлен в очередь синхронизации');

      // Also save locally
      handleSave();
    } catch (error) {
      console.error('GitHub push error:', error);
      Alert.alert('Ошибка', 'Не удалось отправить в GitHub');
    } finally {
      setIsPushingToGitHub(false);
    }
  }, [githubSelectedRepo, photos, transcript, addToQueue, handleSave]);

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

        {/* GitHub Push Button */}
        {githubConnected && (
          <View style={styles.githubSection}>
            <TouchableOpacity
              style={[
                styles.githubBtn,
                !githubSelectedRepo && styles.githubBtnDisabled,
              ]}
              onPress={handlePushToGitHub}
              disabled={isPushingToGitHub || !githubSelectedRepo}
            >
              {isPushingToGitHub ? (
                <ActivityIndicator size="small" color={colors.white} />
              ) : (
                <>
                  <Text style={styles.githubBtnIcon}>🐙</Text>
                  <Text style={styles.githubBtnText}>Push to GitHub</Text>
                </>
              )}
            </TouchableOpacity>
            {githubSelectedRepo && (
              <Text style={styles.repoHint}>→ {githubSelectedRepo}</Text>
            )}
          </View>
        )}
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
  githubSection: {
    marginTop: 24,
    marginBottom: 40,
  },
  githubBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#24292e',
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 20,
  },
  githubBtnDisabled: {
    opacity: 0.5,
  },
  githubBtnIcon: {
    fontSize: 18,
    marginRight: 8,
  },
  githubBtnText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.white,
  },
  repoHint: {
    fontSize: 12,
    color: colors.gray,
    textAlign: 'center',
    marginTop: 8,
  },
});
