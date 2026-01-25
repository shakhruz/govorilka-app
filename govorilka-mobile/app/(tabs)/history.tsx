import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { HistoryList } from '../../src/components/history/HistoryList';
import { colors } from '../../src/theme/colors';

export default function HistoryScreen() {
  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.backgroundTop, colors.backgroundBottom]}
        style={StyleSheet.absoluteFill}
      />
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.header}>
          <Text style={styles.title}>История</Text>
        </View>
        <HistoryList />
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
    paddingBottom: 12,
  },
  title: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.textColor,
  },
});
