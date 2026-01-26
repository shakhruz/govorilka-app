/**
 * useGitHub hook
 * Manages GitHub connection state and operations
 */

import { useState, useEffect, useCallback } from 'react';
import { GitHubService, GitHubRepo, GitHubUser } from '../services/GitHubService';
import { useSettingsStore } from '../stores/useSettingsStore';

interface UseGitHubReturn {
  isConnected: boolean;
  isConnecting: boolean;
  username: string | undefined;
  selectedRepo: string | undefined;
  repos: GitHubRepo[];
  isLoadingRepos: boolean;
  error: string | null;

  connect: () => Promise<boolean>;
  disconnect: () => Promise<void>;
  selectRepo: (repoFullName: string) => void;
  refreshRepos: () => Promise<void>;
}

export function useGitHub(): UseGitHubReturn {
  const {
    githubConnected,
    githubUsername,
    githubSelectedRepo,
    setGitHubConnected,
    setGitHubSelectedRepo,
  } = useSettingsStore();

  const [isConnecting, setIsConnecting] = useState(false);
  const [repos, setRepos] = useState<GitHubRepo[]>([]);
  const [isLoadingRepos, setIsLoadingRepos] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Initialize on mount
  useEffect(() => {
    const init = async () => {
      const isAuthenticated = await GitHubService.initialize();
      if (isAuthenticated && !githubConnected) {
        // Token exists but store doesn't know about it - restore state
        const user = await GitHubService.getUser();
        if (user) {
          setGitHubConnected(true, user.login);
        }
      } else if (!isAuthenticated && githubConnected) {
        // Token doesn't exist but store thinks we're connected - clear state
        setGitHubConnected(false);
      }
    };

    init();
  }, []);

  // Load repos when connected
  useEffect(() => {
    if (githubConnected) {
      refreshRepos();
    } else {
      setRepos([]);
    }
  }, [githubConnected]);

  const connect = useCallback(async (): Promise<boolean> => {
    setIsConnecting(true);
    setError(null);

    try {
      const result = await GitHubService.authenticate();

      if (result.success) {
        setGitHubConnected(true, result.username);
        return true;
      } else {
        setError('Authentication failed');
        return false;
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connection failed');
      return false;
    } finally {
      setIsConnecting(false);
    }
  }, [setGitHubConnected]);

  const disconnect = useCallback(async (): Promise<void> => {
    await GitHubService.disconnect();
    setGitHubConnected(false);
    setRepos([]);
    setError(null);
  }, [setGitHubConnected]);

  const selectRepo = useCallback(
    (repoFullName: string) => {
      setGitHubSelectedRepo(repoFullName);
    },
    [setGitHubSelectedRepo]
  );

  const refreshRepos = useCallback(async (): Promise<void> => {
    if (!githubConnected) return;

    setIsLoadingRepos(true);
    setError(null);

    try {
      const fetchedRepos = await GitHubService.getRepositories();
      setRepos(fetchedRepos);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load repositories');
    } finally {
      setIsLoadingRepos(false);
    }
  }, [githubConnected]);

  return {
    isConnected: githubConnected,
    isConnecting,
    username: githubUsername,
    selectedRepo: githubSelectedRepo,
    repos,
    isLoadingRepos,
    error,
    connect,
    disconnect,
    selectRepo,
    refreshRepos,
  };
}
