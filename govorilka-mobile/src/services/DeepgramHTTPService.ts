import { File } from 'expo-file-system';

interface HTTPTranscriptionResult {
  text: string;
  confidence: number;
}

class DeepgramHTTPServiceClass {
  async transcribe(
    audioFileUri: string,
    apiKey: string,
    language: string = 'ru'
  ): Promise<HTTPTranscriptionResult> {
    const url = `https://api.deepgram.com/v1/listen?language=${language}&model=nova-2&punctuate=true&smart_format=true`;

    const file = new File(audioFileUri);
    if (!file.exists) {
      throw new Error('Audio file not found');
    }

    const base64Audio = await file.text();
    const binaryString = atob(base64Audio);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Token ${apiKey}`,
        'Content-Type': 'audio/wav',
      },
      body: bytes.buffer,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Deepgram HTTP error ${response.status}: ${errorText}`);
    }

    const result = await response.json();
    const transcript = result.results?.channels?.[0]?.alternatives?.[0]?.transcript || '';
    const confidence = result.results?.channels?.[0]?.alternatives?.[0]?.confidence || 0;

    return { text: transcript, confidence };
  }
}

export const DeepgramHTTPService = new DeepgramHTTPServiceClass();
