import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { useGoogleDrive } from '../../hooks/useGoogleDrive';
import { useSettingsStore } from '../../stores/useSettingsStore';
import { colors } from '../../theme/colors';

export function GoogleDriveSection() {
  const { isConnected, connect, disconnect } = useGoogleDrive();
  const googleDriveEmail = useSettingsStore((s) => s.googleDriveEmail);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.driveIcon}>📁</Text>
        <View style={styles.info}>
          <Text style={styles.title}>Google Drive</Text>
          {isConnected && googleDriveEmail && (
            <Text style={styles.email}>{googleDriveEmail}</Text>
          )}
        </View>
      </View>

      {isConnected ? (
        <View style={styles.connectedRow}>
          <View style={styles.statusDot} />
          <Text style={styles.statusText}>Подключено</Text>
          <TouchableOpacity style={styles.disconnectBtn} onPress={disconnect}>
            <Text style={styles.disconnectText}>Отключить</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <TouchableOpacity style={styles.connectBtn} onPress={connect}>
          <Text style={styles.connectBtnText}>Подключить Google Drive</Text>
        </TouchableOpacity>
      )}

      <Text style={styles.hint}>
        Pro-записи будут сохраняться в папку "Govorilka" на Google Drive
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.white,
    borderRadius: 12,
    padding: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  driveIcon: {
    fontSize: 24,
    marginRight: 10,
  },
  info: {
    flex: 1,
  },
  title: {
    fontSize: 15,
    fontWeight: '500',
    color: colors.textColor,
  },
  email: {
    fontSize: 12,
    color: colors.gray,
    marginTop: 2,
  },
  connectedRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.success,
    marginRight: 6,
  },
  statusText: {
    fontSize: 13,
    color: colors.success,
    flex: 1,
  },
  disconnectBtn: {
    paddingVertical: 4,
    paddingHorizontal: 10,
  },
  disconnectText: {
    fontSize: 13,
    color: colors.danger,
  },
  connectBtn: {
    backgroundColor: colors.pink,
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
    marginBottom: 8,
  },
  connectBtnText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.white,
  },
  hint: {
    fontSize: 11,
    color: colors.gray,
    marginTop: 4,
  },
});
