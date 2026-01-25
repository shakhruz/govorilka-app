export interface AppSettings {
  textCleaningEnabled: boolean;
  soundEnabled: boolean;
  hapticEnabled: boolean;
  proModeEnabled: boolean;
  googleDriveConnected: boolean;
  googleDriveEmail?: string;
}

export const DEFAULT_SETTINGS: AppSettings = {
  textCleaningEnabled: true,
  soundEnabled: true,
  hapticEnabled: true,
  proModeEnabled: false,
  googleDriveConnected: false,
};
