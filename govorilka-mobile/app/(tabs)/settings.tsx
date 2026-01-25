import React from 'react';
import { View, Text, StyleSheet, ScrollView, Switch } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ApiKeyInput } from '../../src/components/settings/ApiKeyInput';
import { GoogleDriveSection } from '../../src/components/settings/GoogleDriveSection';
import { useSettingsStore } from '../../src/stores/useSettingsStore';
import { colors } from '../../src/theme/colors';

export default function SettingsScreen() {
  const {
    textCleaningEnabled,
    soundEnabled,
    hapticEnabled,
    proModeEnabled,
    setTextCleaning,
    setSound,
    setHaptic,
    setProMode,
  } = useSettingsStore();

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[colors.backgroundTop, colors.backgroundBottom]}
        style={StyleSheet.absoluteFill}
      />
      <SafeAreaView style={styles.safeArea}>
        <ScrollView contentContainerStyle={styles.scroll}>
          <Text style={styles.title}>Настройки</Text>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>API</Text>
            <ApiKeyInput />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Транскрипция</Text>
            <SettingRow
              label="Очистка текста"
              subtitle="Удаление слов-паразитов"
              value={textCleaningEnabled}
              onValueChange={setTextCleaning}
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Обратная связь</Text>
            <SettingRow
              label="Звуки"
              subtitle="Звуковые сигналы при записи"
              value={soundEnabled}
              onValueChange={setSound}
            />
            <SettingRow
              label="Вибрация"
              subtitle="Тактильный отклик"
              value={hapticEnabled}
              onValueChange={setHaptic}
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Pro режим</Text>
            <SettingRow
              label="Pro режим"
              subtitle="Фото + расширенный экспорт"
              value={proModeEnabled}
              onValueChange={setProMode}
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Экспорт</Text>
            <GoogleDriveSection />
          </View>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

function SettingRow({
  label,
  subtitle,
  value,
  onValueChange,
}: {
  label: string;
  subtitle: string;
  value: boolean;
  onValueChange: (v: boolean) => void;
}) {
  return (
    <View style={styles.row}>
      <View style={styles.rowText}>
        <Text style={styles.rowLabel}>{label}</Text>
        <Text style={styles.rowSubtitle}>{subtitle}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={onValueChange}
        trackColor={{ false: '#ddd', true: colors.lightPink }}
        thumbColor={value ? colors.pink : '#f4f3f4'}
      />
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
  scroll: {
    padding: 16,
  },
  title: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.textColor,
    textAlign: 'center',
    marginBottom: 24,
    marginTop: 16,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.pink,
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: 14,
    borderRadius: 12,
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 1,
  },
  rowText: {
    flex: 1,
  },
  rowLabel: {
    fontSize: 15,
    fontWeight: '500',
    color: colors.textColor,
  },
  rowSubtitle: {
    fontSize: 12,
    color: colors.gray,
    marginTop: 2,
  },
});
