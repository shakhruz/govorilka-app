export interface TranscriptEntry {
  id: string;
  text: string;
  timestamp: number;
  duration: number;
  isProMode: boolean;
  photos?: string[];
  googleDriveFileIds?: string[];
}
