import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { TranscriptEntry } from '../types/transcript';

const MAX_ENTRIES = 50;

interface HistoryState {
  entries: TranscriptEntry[];
  addEntry: (entry: TranscriptEntry) => void;
  removeEntry: (id: string) => void;
  clearHistory: () => void;
}

export const useHistoryStore = create<HistoryState>()(
  persist(
    (set) => ({
      entries: [],

      addEntry: (entry) =>
        set((state) => ({
          entries: [entry, ...state.entries].slice(0, MAX_ENTRIES),
        })),

      removeEntry: (id) =>
        set((state) => ({
          entries: state.entries.filter((e) => e.id !== id),
        })),

      clearHistory: () => set({ entries: [] }),
    }),
    {
      name: 'govorilka-history',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
