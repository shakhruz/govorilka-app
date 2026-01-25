import { Audio } from 'expo-av';
import { Alert, Linking } from 'react-native';

export async function requestMicrophonePermission(): Promise<boolean> {
  const { status } = await Audio.requestPermissionsAsync();
  if (status !== 'granted') {
    Alert.alert(
      'Доступ к микрофону',
      'Для записи голоса необходим доступ к микрофону. Откройте Настройки для предоставления доступа.',
      [
        { text: 'Отмена', style: 'cancel' },
        { text: 'Настройки', onPress: () => Linking.openSettings() },
      ]
    );
    return false;
  }
  return true;
}
