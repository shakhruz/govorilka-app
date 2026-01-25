import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AppSettings, DEFAULT_SETTINGS } from '../types/settings';

interface SettingsState extends AppSettings {
  setTextCleaning: (enabled: boolean) => void;
  setSound: (enabled: boolean) => void;
  setHaptic: (enabled: boolean) => void;
  setProMode: (enabled: boolean) => void;
  setGoogleDriveConnected: (connected: boolean, email?: string) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      ...DEFAULT_SETTINGS,

      setTextCleaning: (textCleaningEnabled) => set({ textCleaningEnabled }),
      setSound: (soundEnabled) => set({ soundEnabled }),
      setHaptic: (hapticEnabled) => set({ hapticEnabled }),
      setProMode: (proModeEnabled) => set({ proModeEnabled }),
      setGoogleDriveConnected: (googleDriveConnected, googleDriveEmail) =>
        set({ googleDriveConnected, googleDriveEmail }),
    }),
    {
      name: 'govorilka-settings',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
