/**
 * Feedback Queue Store
 * Manages offline queue of feedbacks to sync to GitHub
 */

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { GitHubService, FeedbackData } from '../services/GitHubService';

export interface QueuedFeedback {
  id: string;
  repoFullName: string;
  feedback: FeedbackData;
  createdAt: string;
  retryCount: number;
  lastError?: string;
  status: 'pending' | 'syncing' | 'failed';
}

interface FeedbackQueueState {
  queue: QueuedFeedback[];
  isSyncing: boolean;

  // Actions
  addToQueue: (repoFullName: string, feedback: FeedbackData) => void;
  removeFromQueue: (id: string) => void;
  updateFeedbackStatus: (id: string, status: QueuedFeedback['status'], error?: string) => void;
  incrementRetry: (id: string) => void;
  clearQueue: () => void;
  syncAll: () => Promise<void>;
  syncOne: (id: string) => Promise<boolean>;
}

const MAX_RETRIES = 3;

export const useFeedbackQueueStore = create<FeedbackQueueState>()(
  persist(
    (set, get) => ({
      queue: [],
      isSyncing: false,

      addToQueue: (repoFullName, feedback) => {
        const newFeedback: QueuedFeedback = {
          id: `${Date.now()}_${Math.random().toString(36).slice(2)}`,
          repoFullName,
          feedback: {
            ...feedback,
            timestamp: feedback.timestamp,
          },
          createdAt: new Date().toISOString(),
          retryCount: 0,
          status: 'pending',
        };

        set((state) => ({
          queue: [...state.queue, newFeedback],
        }));

        // Try to sync immediately if online
        get().syncOne(newFeedback.id);
      },

      removeFromQueue: (id) => {
        set((state) => ({
          queue: state.queue.filter((f) => f.id !== id),
        }));
      },

      updateFeedbackStatus: (id, status, error) => {
        set((state) => ({
          queue: state.queue.map((f) =>
            f.id === id ? { ...f, status, lastError: error } : f
          ),
        }));
      },

      incrementRetry: (id) => {
        set((state) => ({
          queue: state.queue.map((f) =>
            f.id === id ? { ...f, retryCount: f.retryCount + 1 } : f
          ),
        }));
      },

      clearQueue: () => {
        set({ queue: [] });
      },

      syncAll: async () => {
        const { queue, isSyncing, syncOne } = get();

        if (isSyncing) return;

        set({ isSyncing: true });

        const pendingFeedbacks = queue.filter(
          (f) => f.status === 'pending' || (f.status === 'failed' && f.retryCount < MAX_RETRIES)
        );

        for (const feedback of pendingFeedbacks) {
          await syncOne(feedback.id);
        }

        set({ isSyncing: false });
      },

      syncOne: async (id) => {
        const { queue, updateFeedbackStatus, incrementRetry, removeFromQueue } = get();
        const feedback = queue.find((f) => f.id === id);

        if (!feedback) return false;

        // Check if max retries exceeded
        if (feedback.retryCount >= MAX_RETRIES) {
          updateFeedbackStatus(id, 'failed', 'Max retries exceeded');
          return false;
        }

        // Check if GitHub is authenticated
        if (!GitHubService.isAuthenticated()) {
          updateFeedbackStatus(id, 'failed', 'GitHub not connected');
          return false;
        }

        updateFeedbackStatus(id, 'syncing');

        try {
          const result = await GitHubService.commitFeedback(feedback.repoFullName, {
            ...feedback.feedback,
            timestamp: new Date(feedback.feedback.timestamp),
          });

          if (result.success) {
            removeFromQueue(id);
            console.log('[FeedbackQueue] Synced:', id);
            return true;
          } else {
            incrementRetry(id);
            updateFeedbackStatus(id, 'failed', 'Commit failed');
            return false;
          }
        } catch (error) {
          incrementRetry(id);
          updateFeedbackStatus(
            id,
            'failed',
            error instanceof Error ? error.message : 'Unknown error'
          );
          return false;
        }
      },
    }),
    {
      name: 'govorilka-feedback-queue',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
