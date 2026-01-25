import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { colors } from '../../theme/colors';

interface TranscriptPreviewProps {
  transcript: string;
  interimText: string;
  error: string | null;
}

export function TranscriptPreview({
  transcript,
  interimText,
  error,
}: TranscriptPreviewProps) {
  if (error) {
    return (
      <View style={styles.container}>
        <View style={[styles.card, styles.errorCard]}>
          <Text style={styles.errorText}>{error}</Text>
        </View>
      </View>
    );
  }

  if (!transcript && !interimText) {
    return (
      <View style={styles.container}>
        <Text style={styles.hint}>
          Нажмите кнопку для начала записи
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
        {transcript ? (
          <Text style={styles.finalText}>{transcript}</Text>
        ) : null}
        {interimText ? (
          <Text style={styles.interimText}>{interimText}</Text>
        ) : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    minHeight: 100,
    maxHeight: 200,
    marginHorizontal: 16,
    marginBottom: 16,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: 14,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  errorCard: {
    borderColor: colors.danger,
    borderWidth: 1,
  },
  scrollView: {
    backgroundColor: colors.white,
    borderRadius: 14,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  scrollContent: {
    flexGrow: 1,
  },
  finalText: {
    fontSize: 15,
    color: colors.textColor,
    lineHeight: 22,
  },
  interimText: {
    fontSize: 15,
    color: colors.gray,
    fontStyle: 'italic',
    lineHeight: 22,
  },
  errorText: {
    fontSize: 14,
    color: colors.danger,
  },
  hint: {
    fontSize: 14,
    color: colors.gray,
    textAlign: 'center',
    marginTop: 20,
  },
});
