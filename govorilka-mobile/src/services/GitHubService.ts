/**
 * GitHubService for iOS
 * Handles GitHub OAuth, repository operations, and feedback commits
 */

import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

// Configuration
const GITHUB_CLIENT_ID = 'YOUR_GITHUB_CLIENT_ID'; // TODO: Replace with actual client ID
const OAUTH_REDIRECT_URI = Linking.createURL('oauth/github');
const API_BASE_URL = 'https://govorilka.milagpt.com/api';
const GITHUB_API = 'https://api.github.com';

// Storage keys
const GITHUB_TOKEN_KEY = 'github_access_token';

export interface GitHubUser {
  login: string;
  name: string | null;
  avatar_url: string;
  email: string | null;
}

export interface GitHubRepo {
  id: number;
  name: string;
  full_name: string;
  private: boolean;
  description: string | null;
  default_branch: string;
}

export interface FeedbackData {
  text: string;
  timestamp: Date;
  photos?: string[]; // Base64 encoded images
  duration?: number;
}

class GitHubServiceClass {
  private accessToken: string | null = null;

  /**
   * Initialize service and load stored token
   */
  async initialize(): Promise<boolean> {
    try {
      this.accessToken = await SecureStore.getItemAsync(GITHUB_TOKEN_KEY);
      return !!this.accessToken;
    } catch (error) {
      console.error('[GitHubService] Init error:', error);
      return false;
    }
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return !!this.accessToken;
  }

  /**
   * Start OAuth flow
   */
  async authenticate(): Promise<{ success: boolean; username?: string }> {
    try {
      // Build OAuth URL
      const authUrl = `https://github.com/login/oauth/authorize?` +
        `client_id=${GITHUB_CLIENT_ID}&` +
        `redirect_uri=${encodeURIComponent(OAUTH_REDIRECT_URI)}&` +
        `scope=repo,user:email&` +
        `state=${Date.now()}`;

      // Open browser for OAuth
      const result = await WebBrowser.openAuthSessionAsync(authUrl, OAUTH_REDIRECT_URI);

      if (result.type !== 'success' || !result.url) {
        return { success: false };
      }

      // Parse the OAuth code from the URL
      const url = new URL(result.url);
      const code = url.searchParams.get('code');

      if (!code) {
        console.error('[GitHubService] No code in OAuth response');
        return { success: false };
      }

      // Exchange code for token via our backend
      const tokenResponse = await fetch(`${API_BASE_URL}/github-oauth`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ code }),
      });

      if (!tokenResponse.ok) {
        const error = await tokenResponse.json();
        console.error('[GitHubService] Token exchange failed:', error);
        return { success: false };
      }

      const tokenData = await tokenResponse.json();
      this.accessToken = tokenData.access_token;

      // Save token securely
      if (this.accessToken) {
        await SecureStore.setItemAsync(GITHUB_TOKEN_KEY, this.accessToken);
      }

      // Get user info
      const user = await this.getUser();
      if (user) {
        console.log('[GitHubService] Authenticated as:', user.login);
        return { success: true, username: user.login };
      }

      return { success: true };
    } catch (error) {
      console.error('[GitHubService] Auth error:', error);
      return { success: false };
    }
  }

  /**
   * Disconnect from GitHub
   */
  async disconnect(): Promise<void> {
    this.accessToken = null;
    await SecureStore.deleteItemAsync(GITHUB_TOKEN_KEY);
  }

  /**
   * Get authenticated user info
   */
  async getUser(): Promise<GitHubUser | null> {
    if (!this.accessToken) return null;

    try {
      const response = await fetch(`${GITHUB_API}/user`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
          Accept: 'application/vnd.github+json',
        },
      });

      if (!response.ok) {
        if (response.status === 401) {
          await this.disconnect();
        }
        return null;
      }

      return await response.json();
    } catch (error) {
      console.error('[GitHubService] Get user error:', error);
      return null;
    }
  }

  /**
   * Get user's repositories
   */
  async getRepositories(): Promise<GitHubRepo[]> {
    if (!this.accessToken) return [];

    try {
      const repos: GitHubRepo[] = [];
      let page = 1;
      const perPage = 100;

      while (true) {
        const response = await fetch(
          `${GITHUB_API}/user/repos?sort=updated&per_page=${perPage}&page=${page}`,
          {
            headers: {
              Authorization: `Bearer ${this.accessToken}`,
              Accept: 'application/vnd.github+json',
            },
          }
        );

        if (!response.ok) {
          break;
        }

        const pageRepos: GitHubRepo[] = await response.json();
        repos.push(...pageRepos);

        // If we got less than perPage, we've reached the end
        if (pageRepos.length < perPage) {
          break;
        }

        page++;
      }

      return repos;
    } catch (error) {
      console.error('[GitHubService] Get repos error:', error);
      return [];
    }
  }

  /**
   * Commit feedback to a repository
   */
  async commitFeedback(
    repoFullName: string,
    feedback: FeedbackData
  ): Promise<{ success: boolean; commitUrl?: string }> {
    if (!this.accessToken) {
      return { success: false };
    }

    try {
      const timestamp = feedback.timestamp.toISOString().replace(/[:.]/g, '-').slice(0, 19);
      const basePath = `.govorilka/feedback/${timestamp}`;

      // Get default branch
      const repoResponse = await fetch(`${GITHUB_API}/repos/${repoFullName}`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
          Accept: 'application/vnd.github+json',
        },
      });

      if (!repoResponse.ok) {
        console.error('[GitHubService] Repo fetch failed');
        return { success: false };
      }

      const repo = await repoResponse.json();
      const defaultBranch = repo.default_branch;

      // Get current commit SHA
      const refResponse = await fetch(
        `${GITHUB_API}/repos/${repoFullName}/git/ref/heads/${defaultBranch}`,
        {
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            Accept: 'application/vnd.github+json',
          },
        }
      );

      if (!refResponse.ok) {
        console.error('[GitHubService] Ref fetch failed');
        return { success: false };
      }

      const refData = await refResponse.json();
      const baseCommitSha = refData.object.sha;

      // Get the base tree
      const commitResponse = await fetch(
        `${GITHUB_API}/repos/${repoFullName}/git/commits/${baseCommitSha}`,
        {
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            Accept: 'application/vnd.github+json',
          },
        }
      );

      if (!commitResponse.ok) {
        console.error('[GitHubService] Commit fetch failed');
        return { success: false };
      }

      const commitData = await commitResponse.json();
      const baseTreeSha = commitData.tree.sha;

      // Create tree entries
      const treeEntries: Array<{
        path: string;
        mode: '100644';
        type: 'blob';
        content?: string;
      }> = [];

      // Add markdown file
      const mdContent = this.generateMarkdown(feedback);
      treeEntries.push({
        path: `${basePath}_feedback.md`,
        mode: '100644',
        type: 'blob',
        content: mdContent,
      });

      // Add photos if any
      if (feedback.photos) {
        for (let i = 0; i < feedback.photos.length; i++) {
          const photoContent = feedback.photos[i];
          // For binary files, we need to create a blob first
          const blobResponse = await fetch(`${GITHUB_API}/repos/${repoFullName}/git/blobs`, {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${this.accessToken}`,
              Accept: 'application/vnd.github+json',
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              content: photoContent,
              encoding: 'base64',
            }),
          });

          if (blobResponse.ok) {
            const blobData = await blobResponse.json();
            treeEntries.push({
              path: `${basePath}_photo_${i + 1}.jpg`,
              mode: '100644',
              type: 'blob',
              sha: blobData.sha,
            } as any);
          }
        }
      }

      // Create new tree
      const treeResponse = await fetch(`${GITHUB_API}/repos/${repoFullName}/git/trees`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
          Accept: 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          base_tree: baseTreeSha,
          tree: treeEntries,
        }),
      });

      if (!treeResponse.ok) {
        console.error('[GitHubService] Tree creation failed');
        return { success: false };
      }

      const treeData = await treeResponse.json();

      // Create commit
      const newCommitResponse = await fetch(
        `${GITHUB_API}/repos/${repoFullName}/git/commits`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            Accept: 'application/vnd.github+json',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: `feedback: ${feedback.text.slice(0, 50)}${feedback.text.length > 50 ? '...' : ''}`,
            tree: treeData.sha,
            parents: [baseCommitSha],
          }),
        }
      );

      if (!newCommitResponse.ok) {
        console.error('[GitHubService] Commit creation failed');
        return { success: false };
      }

      const newCommitData = await newCommitResponse.json();

      // Update ref to point to new commit
      const updateRefResponse = await fetch(
        `${GITHUB_API}/repos/${repoFullName}/git/refs/heads/${defaultBranch}`,
        {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            Accept: 'application/vnd.github+json',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            sha: newCommitData.sha,
          }),
        }
      );

      if (!updateRefResponse.ok) {
        console.error('[GitHubService] Ref update failed');
        return { success: false };
      }

      console.log('[GitHubService] Feedback committed:', newCommitData.sha);

      return {
        success: true,
        commitUrl: newCommitData.html_url,
      };
    } catch (error) {
      console.error('[GitHubService] Commit feedback error:', error);
      return { success: false };
    }
  }

  /**
   * Generate markdown content for feedback
   */
  private generateMarkdown(feedback: FeedbackData): string {
    const timestamp = feedback.timestamp.toLocaleString('ru-RU');
    const duration = feedback.duration
      ? `${Math.floor(feedback.duration / 60)}:${String(Math.floor(feedback.duration % 60)).padStart(2, '0')}`
      : null;

    let md = `# Feedback\n\n`;
    md += `**Date:** ${timestamp}\n`;
    if (duration) {
      md += `**Duration:** ${duration}\n`;
    }
    md += `\n---\n\n`;
    md += feedback.text;
    md += `\n\n---\n`;
    md += `*Generated by [Govorilka](https://govorilka.milagpt.com)*\n`;

    return md;
  }
}

export const GitHubService = new GitHubServiceClass();
