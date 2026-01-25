import { useState, useCallback } from 'react';
import { Alert } from 'react-native';
import { GoogleDriveService } from '../services/GoogleDriveService';
import { useSettingsStore } from '../stores/useSettingsStore';
import { TranscriptEntry } from '../types/transcript';

export function useGoogleDrive() {
  const [isUploading, setIsUploading] = useState(false);
  const { googleDriveConnected, setGoogleDriveConnected } = useSettingsStore();

  const connect = useCallback(async () => {
    const result = await GoogleDriveService.signIn();
    if (result) {
      setGoogleDriveConnected(true, result.email);
    } else {
      Alert.alert('Ошибка', 'Не удалось подключить Google Drive');
    }
  }, [setGoogleDriveConnected]);

  const disconnect = useCallback(async () => {
    await GoogleDriveService.signOut();
    setGoogleDriveConnected(false);
  }, [setGoogleDriveConnected]);

  const exportEntry = useCallback(
    async (entry: TranscriptEntry): Promise<boolean> => {
      if (!googleDriveConnected) {
        Alert.alert('Google Drive', 'Сначала подключите Google Drive в настройках');
        return false;
      }

      setIsUploading(true);
      try {
        const timestamp = new Date(entry.timestamp).toISOString().split('T')[0];
        const fileIds: string[] = [];

        // Upload photos if Pro mode
        if (entry.photos && entry.photos.length > 0) {
          for (let i = 0; i < entry.photos.length; i++) {
            const photoId = await GoogleDriveService.uploadFile(
              entry.photos[i],
              `${timestamp}_photo_${i + 1}.jpg`,
              'image/jpeg'
            );
            fileIds.push(photoId);
          }
        }

        // Upload text as markdown
        const mdContent = [
          `# Запись ${timestamp}`,
          '',
          `**Дата:** ${new Date(entry.timestamp).toLocaleString('ru-RU')}`,
          `**Длительность:** ${entry.duration} сек`,
          entry.isProMode ? `**Режим:** Pro` : '',
          '',
          '## Текст',
          '',
          entry.text,
        ]
          .filter(Boolean)
          .join('\n');

        const textId = await GoogleDriveService.uploadText(
          mdContent,
          `${timestamp}_transcript.md`
        );
        fileIds.push(textId);

        setIsUploading(false);
        return true;
      } catch (error) {
        setIsUploading(false);
        Alert.alert('Ошибка', `Не удалось загрузить в Google Drive: ${error}`);
        return false;
      }
    },
    [googleDriveConnected]
  );

  return {
    isConnected: googleDriveConnected,
    isUploading,
    connect,
    disconnect,
    exportEntry,
  };
}
