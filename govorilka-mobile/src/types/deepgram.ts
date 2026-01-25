export interface DeepgramWord {
  word: string;
  start: number;
  end: number;
  confidence: number;
  punctuated_word?: string;
}

export interface DeepgramAlternative {
  transcript: string;
  confidence: number;
  words: DeepgramWord[];
}

export interface DeepgramChannel {
  alternatives: DeepgramAlternative[];
}

export interface DeepgramResponse {
  type: 'Results';
  channel_index: number[];
  duration: number;
  start: number;
  is_final: boolean;
  speech_final: boolean;
  channel: DeepgramChannel;
}

export interface DeepgramMetadata {
  type: 'Metadata';
  transaction_key: string;
  request_id: string;
  sha256: string;
  created: string;
}

export type DeepgramMessage = DeepgramResponse | DeepgramMetadata;

export interface DeepgramConfig {
  apiKey: string;
  language: string;
  model: string;
  encoding: string;
  sampleRate: number;
  channels: number;
  interimResults: boolean;
  punctuate: boolean;
  smartFormat: boolean;
}
