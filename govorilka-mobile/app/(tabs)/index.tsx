import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { RecordButton } from '../../src/components/recording/RecordButton';
import { WaveformView } from '../../src/components/recording/WaveformView';
import { TranscriptPreview } from '../../src/components/recording/TranscriptPreview';
import { DurationDisplay } from '../../src/components/recording/DurationDisplay';
import { useAudioRecording } from '../../src/hooks/useAudioRecording';
import { colors } from '../../src/theme/colors';

export default function RecordingScreen() {
  const {
    isRecording,
    transcript,
    interimText,
    duration,
    audioLevel,
    toggleRecording,
    error,
  } = useAudioRecording();

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.backgroundTop, colors.backgroundBottom]}
        style={StyleSheet.absoluteFill}
      />
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.header}>
          <Text style={styles.title}>Говорилка</Text>
        </View>

        <View style={styles.content}>
          <WaveformView isRecording={isRecording} audioLevel={audioLevel} />
          <RecordButton isRecording={isRecording} onPress={toggleRecording} />
          <DurationDisplay duration={duration} isRecording={isRecording} />
        </View>

        <TranscriptPreview
          transcript={transcript}
          interimText={interimText}
          error={error}
        />
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  safeArea: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    paddingTop: 16,
    paddingBottom: 8,
  },
  title: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.textColor,
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
