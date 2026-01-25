import { File, Directory, Paths } from 'expo-file-system';

class LocalRecorderServiceClass {
  private recordingDir: Directory;
  private currentChunks: string[] = [];
  private isRecording = false;

  constructor() {
    this.recordingDir = new Directory(Paths.document, 'recordings');
  }

  ensureDirectory(): void {
    if (!this.recordingDir.exists) {
      this.recordingDir.create();
    }
  }

  startRecording(): void {
    this.currentChunks = [];
    this.isRecording = true;
  }

  addChunk(base64Data: string): void {
    if (!this.isRecording) return;
    this.currentChunks.push(base64Data);
  }

  async stopAndSave(): Promise<string | null> {
    if (!this.isRecording || this.currentChunks.length === 0) {
      this.isRecording = false;
      return null;
    }

    this.isRecording = false;
    this.ensureDirectory();

    const filename = `recording_${Date.now()}.wav`;
    const file = new File(this.recordingDir, filename);

    // Create WAV file from PCM chunks
    const wavBase64 = this.createWavBase64(this.currentChunks);
    file.write(wavBase64, { encoding: 'base64' });

    this.currentChunks = [];
    return file.uri;
  }

  deleteRecording(filePath: string): void {
    const file = new File(filePath);
    if (file.exists) {
      file.delete();
    }
  }

  listRecordings(): string[] {
    this.ensureDirectory();
    return this.recordingDir.list().map((item) => item.uri);
  }

  private createWavBase64(chunks: string[]): string {
    let totalLength = 0;
    const decodedChunks: Uint8Array[] = [];

    for (const chunk of chunks) {
      const binary = atob(chunk);
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
      }
      decodedChunks.push(bytes);
      totalLength += bytes.length;
    }

    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
    const blockAlign = numChannels * (bitsPerSample / 8);
    const dataSize = totalLength;
    const fileSize = 36 + dataSize;

    const header = new ArrayBuffer(44);
    const view = new DataView(header);

    this.writeString(view, 0, 'RIFF');
    view.setUint32(4, fileSize, true);
    this.writeString(view, 8, 'WAVE');
    this.writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, numChannels, true);
    view.setUint32(24, sampleRate, true);
    view.setUint32(28, byteRate, true);
    view.setUint16(32, blockAlign, true);
    view.setUint16(34, bitsPerSample, true);
    this.writeString(view, 36, 'data');
    view.setUint32(40, dataSize, true);

    const wavBuffer = new Uint8Array(44 + totalLength);
    wavBuffer.set(new Uint8Array(header), 0);

    let offset = 44;
    for (const chunk of decodedChunks) {
      wavBuffer.set(chunk, offset);
      offset += chunk.length;
    }

    let binary = '';
    for (let i = 0; i < wavBuffer.length; i++) {
      binary += String.fromCharCode(wavBuffer[i]);
    }
    return btoa(binary);
  }

  private writeString(view: DataView, offset: number, str: string): void {
    for (let i = 0; i < str.length; i++) {
      view.setUint8(offset + i, str.charCodeAt(i));
    }
  }
}

export const LocalRecorderService = new LocalRecorderServiceClass();
