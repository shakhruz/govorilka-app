/**
 * useGitHubSync hook
 * Handles automatic sync of feedback queue when network is available
 */

import { useEffect, useRef, useCallback } from 'react';
import { AppState, AppStateStatus } from 'react-native';
import NetInfo, { NetInfoState } from '@react-native-community/netinfo';
import { useFeedbackQueueStore } from '../stores/useFeedbackQueueStore';
import { useSettingsStore } from '../stores/useSettingsStore';

interface UseGitHubSyncOptions {
  enabled?: boolean;
}

interface UseGitHubSyncReturn {
  pendingCount: number;
  failedCount: number;
  isSyncing: boolean;
  syncNow: () => Promise<void>;
}

export function useGitHubSync(options: UseGitHubSyncOptions = {}): UseGitHubSyncReturn {
  const { enabled = true } = options;

  const { queue, isSyncing, syncAll } = useFeedbackQueueStore();
  const { githubConnected } = useSettingsStore();
  const lastSyncRef = useRef<number>(0);

  const pendingCount = queue.filter((f) => f.status === 'pending').length;
  const failedCount = queue.filter((f) => f.status === 'failed').length;

  // Sync when network becomes available
  useEffect(() => {
    if (!enabled || !githubConnected) return;

    const unsubscribe = NetInfo.addEventListener((state: NetInfoState) => {
      if (state.isConnected && state.isInternetReachable) {
        // Throttle syncs to once per 30 seconds
        const now = Date.now();
        if (now - lastSyncRef.current > 30000 && pendingCount > 0) {
          lastSyncRef.current = now;
          syncAll();
        }
      }
    });

    return () => {
      unsubscribe();
    };
  }, [enabled, githubConnected, pendingCount, syncAll]);

  // Sync when app comes to foreground
  useEffect(() => {
    if (!enabled || !githubConnected) return;

    const handleAppStateChange = (nextAppState: AppStateStatus) => {
      if (nextAppState === 'active' && pendingCount > 0) {
        const now = Date.now();
        if (now - lastSyncRef.current > 30000) {
          lastSyncRef.current = now;
          syncAll();
        }
      }
    };

    const subscription = AppState.addEventListener('change', handleAppStateChange);

    return () => {
      subscription.remove();
    };
  }, [enabled, githubConnected, pendingCount, syncAll]);

  // Initial sync on mount if there are pending items
  useEffect(() => {
    if (!enabled || !githubConnected) return;

    if (pendingCount > 0) {
      syncAll();
    }
  }, [enabled, githubConnected]);

  const syncNow = useCallback(async () => {
    if (!githubConnected) return;
    lastSyncRef.current = Date.now();
    await syncAll();
  }, [githubConnected, syncAll]);

  return {
    pendingCount,
    failedCount,
    isSyncing,
    syncNow,
  };
}
