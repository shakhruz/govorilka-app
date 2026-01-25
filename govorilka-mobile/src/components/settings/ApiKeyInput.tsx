import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet } from 'react-native';
import { SecureStorageService } from '../../services/SecureStorageService';
import { colors } from '../../theme/colors';

export function ApiKeyInput() {
  const [apiKey, setApiKey] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [isSaved, setIsSaved] = useState(false);

  useEffect(() => {
    loadKey();
  }, []);

  async function loadKey() {
    const key = await SecureStorageService.getApiKey();
    if (key) {
      setApiKey(key);
      setIsSaved(true);
    }
  }

  async function saveKey() {
    if (apiKey.trim()) {
      await SecureStorageService.setApiKey(apiKey.trim());
      setIsSaved(true);
      setIsEditing(false);
    }
  }

  async function deleteKey() {
    await SecureStorageService.deleteApiKey();
    setApiKey('');
    setIsSaved(false);
    setIsEditing(false);
  }

  const maskedKey = isSaved && !isEditing
    ? `${apiKey.substring(0, 6)}${'•'.repeat(20)}${apiKey.substring(apiKey.length - 4)}`
    : apiKey;

  return (
    <View style={styles.container}>
      <View style={styles.inputRow}>
        <TextInput
          style={styles.input}
          value={isEditing ? apiKey : maskedKey}
          onChangeText={setApiKey}
          placeholder="Вставьте API ключ Deepgram"
          placeholderTextColor={colors.gray}
          secureTextEntry={!isEditing}
          editable={isEditing || !isSaved}
          autoCapitalize="none"
          autoCorrect={false}
        />
      </View>
      <View style={styles.actions}>
        {isSaved && !isEditing ? (
          <>
            <TouchableOpacity style={styles.actionBtn} onPress={() => setIsEditing(true)}>
              <Text style={styles.actionText}>Изменить</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionBtn} onPress={deleteKey}>
              <Text style={[styles.actionText, styles.deleteText]}>Удалить</Text>
            </TouchableOpacity>
          </>
        ) : (
          <>
            <TouchableOpacity
              style={[styles.actionBtn, styles.saveBtn]}
              onPress={saveKey}
              disabled={!apiKey.trim()}
            >
              <Text style={styles.saveBtnText}>Сохранить</Text>
            </TouchableOpacity>
            {isEditing && (
              <TouchableOpacity
                style={styles.actionBtn}
                onPress={() => {
                  setIsEditing(false);
                  loadKey();
                }}
              >
                <Text style={styles.actionText}>Отмена</Text>
              </TouchableOpacity>
            )}
          </>
        )}
      </View>
      <Text style={styles.hint}>
        Получите ключ на console.deepgram.com
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
  inputRow: {
    marginBottom: 10,
  },
  input: {
    backgroundColor: colors.softPink,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: colors.textColor,
    fontFamily: 'Courier',
  },
  actions: {
    flexDirection: 'row',
    gap: 12,
  },
  actionBtn: {
    paddingVertical: 6,
    paddingHorizontal: 12,
  },
  actionText: {
    fontSize: 14,
    color: colors.pink,
    fontWeight: '500',
  },
  deleteText: {
    color: colors.danger,
  },
  saveBtn: {
    backgroundColor: colors.pink,
    borderRadius: 8,
  },
  saveBtnText: {
    fontSize: 14,
    color: colors.white,
    fontWeight: '600',
  },
  hint: {
    fontSize: 11,
    color: colors.gray,
    marginTop: 8,
  },
});
