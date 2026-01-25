import * as SecureStore from 'expo-secure-store';

const API_KEY_KEY = 'deepgram_api_key';

export const SecureStorageService = {
  async getApiKey(): Promise<string | null> {
    return SecureStore.getItemAsync(API_KEY_KEY);
  },

  async setApiKey(key: string): Promise<void> {
    await SecureStore.setItemAsync(API_KEY_KEY, key);
  },

  async deleteApiKey(): Promise<void> {
    await SecureStore.deleteItemAsync(API_KEY_KEY);
  },
};
