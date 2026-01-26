export interface AppSettings {
  textCleaningEnabled: boolean;
  soundEnabled: boolean;
  hapticEnabled: boolean;
  proModeEnabled: boolean;
  // Google Drive integration
  googleDriveConnected: boolean;
  googleDriveEmail?: string;
  // GitHub integration
  githubConnected: boolean;
  githubUsername?: string;
  githubSelectedRepo?: string;
  // Supporter status
  isSupporter: boolean;
}

export const DEFAULT_SETTINGS: AppSettings = {
  textCleaningEnabled: true,
  soundEnabled: true,
  hapticEnabled: true,
  proModeEnabled: false,
  googleDriveConnected: false,
  githubConnected: false,
  isSupporter: false,
};
