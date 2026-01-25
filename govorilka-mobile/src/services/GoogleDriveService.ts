import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { File } from 'expo-file-system';

const FOLDER_NAME = 'Govorilka';
const DRIVE_API = 'https://www.googleapis.com/drive/v3';
const UPLOAD_API = 'https://www.googleapis.com/upload/drive/v3';

class GoogleDriveServiceClass {
  private folderId: string | null = null;

  configure(webClientId: string): void {
    GoogleSignin.configure({
      scopes: ['https://www.googleapis.com/auth/drive.file'],
      webClientId,
      offlineAccess: true,
    });
  }

  async signIn(): Promise<{ email: string } | null> {
    try {
      await GoogleSignin.hasPlayServices();
      const userInfo = await GoogleSignin.signIn();
      return { email: userInfo.data?.user?.email || '' };
    } catch (error) {
      console.error('Google Sign-In error:', error);
      return null;
    }
  }

  async signOut(): Promise<void> {
    try {
      await GoogleSignin.signOut();
      this.folderId = null;
    } catch {
      // Ignore
    }
  }

  async isSignedIn(): Promise<boolean> {
    return GoogleSignin.hasPreviousSignIn();
  }

  async getAccessToken(): Promise<string | null> {
    try {
      const tokens = await GoogleSignin.getTokens();
      return tokens.accessToken;
    } catch {
      return null;
    }
  }

  async ensureFolder(): Promise<string> {
    if (this.folderId) return this.folderId;

    const token = await this.getAccessToken();
    if (!token) throw new Error('Not authenticated');

    const searchUrl = `${DRIVE_API}/files?q=name='${FOLDER_NAME}' and mimeType='application/vnd.google-apps.folder' and trashed=false&fields=files(id,name)`;
    const searchResponse = await fetch(searchUrl, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const searchResult = await searchResponse.json();

    if (searchResult.files && searchResult.files.length > 0) {
      this.folderId = searchResult.files[0].id;
      return this.folderId!;
    }

    const createResponse = await fetch(`${DRIVE_API}/files`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: FOLDER_NAME,
        mimeType: 'application/vnd.google-apps.folder',
      }),
    });
    const folder = await createResponse.json();
    this.folderId = folder.id;
    return this.folderId!;
  }

  async uploadFile(
    localUri: string,
    fileName: string,
    mimeType: string
  ): Promise<string> {
    const token = await this.getAccessToken();
    if (!token) throw new Error('Not authenticated');

    const folderId = await this.ensureFolder();

    const file = new File(localUri);
    const fileContent = file.text(); // base64 content for images

    const boundary = 'govorilka_boundary_' + Date.now();
    const metadata = JSON.stringify({
      name: fileName,
      parents: [folderId],
    });

    const body =
      `--${boundary}\r\n` +
      `Content-Type: application/json; charset=UTF-8\r\n\r\n` +
      `${metadata}\r\n` +
      `--${boundary}\r\n` +
      `Content-Type: ${mimeType}\r\n` +
      `Content-Transfer-Encoding: base64\r\n\r\n` +
      `${fileContent}\r\n` +
      `--${boundary}--`;

    const response = await fetch(
      `${UPLOAD_API}/files?uploadType=multipart&fields=id`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': `multipart/related; boundary=${boundary}`,
        },
        body,
      }
    );

    if (!response.ok) {
      throw new Error(`Upload failed: ${response.status}`);
    }

    const result = await response.json();
    return result.id;
  }

  async uploadText(text: string, fileName: string): Promise<string> {
    const token = await this.getAccessToken();
    if (!token) throw new Error('Not authenticated');

    const folderId = await this.ensureFolder();

    const boundary = 'govorilka_boundary_' + Date.now();
    const metadata = JSON.stringify({
      name: fileName,
      parents: [folderId],
    });

    const body =
      `--${boundary}\r\n` +
      `Content-Type: application/json; charset=UTF-8\r\n\r\n` +
      `${metadata}\r\n` +
      `--${boundary}\r\n` +
      `Content-Type: text/markdown; charset=UTF-8\r\n\r\n` +
      `${text}\r\n` +
      `--${boundary}--`;

    const response = await fetch(
      `${UPLOAD_API}/files?uploadType=multipart&fields=id`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': `multipart/related; boundary=${boundary}`,
        },
        body,
      }
    );

    if (!response.ok) {
      throw new Error(`Upload failed: ${response.status}`);
    }

    const result = await response.json();
    return result.id;
  }
}

export const GoogleDriveService = new GoogleDriveServiceClass();
