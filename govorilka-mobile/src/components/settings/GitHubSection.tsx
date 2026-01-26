import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Modal,
  FlatList,
  Pressable,
} from 'react-native';
import { useGitHub } from '../../hooks/useGitHub';
import { useGitHubSync } from '../../hooks/useGitHubSync';
import { colors } from '../../theme/colors';

export function GitHubSection() {
  const {
    isConnected,
    isConnecting,
    username,
    selectedRepo,
    repos,
    isLoadingRepos,
    error,
    connect,
    disconnect,
    selectRepo,
    refreshRepos,
  } = useGitHub();

  const { pendingCount, failedCount, isSyncing, syncNow } = useGitHubSync();

  const [showRepoPicker, setShowRepoPicker] = useState(false);

  const handleConnect = async () => {
    await connect();
  };

  const handleSelectRepo = (repoFullName: string) => {
    selectRepo(repoFullName);
    setShowRepoPicker(false);
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.icon}>🐙</Text>
        <View style={styles.info}>
          <Text style={styles.title}>GitHub</Text>
          {isConnected && username && (
            <Text style={styles.username}>@{username}</Text>
          )}
        </View>
      </View>

      {isConnected ? (
        <>
          <View style={styles.connectedRow}>
            <View style={styles.statusDot} />
            <Text style={styles.statusText}>Подключено</Text>
            <TouchableOpacity style={styles.disconnectBtn} onPress={disconnect}>
              <Text style={styles.disconnectText}>Отключить</Text>
            </TouchableOpacity>
          </View>

          {/* Repository selector */}
          <TouchableOpacity
            style={styles.repoSelector}
            onPress={() => setShowRepoPicker(true)}
          >
            <Text style={styles.repoLabel}>Репозиторий:</Text>
            <Text style={styles.repoValue}>
              {selectedRepo || 'Выберите...'}
            </Text>
            <Text style={styles.chevron}>›</Text>
          </TouchableOpacity>

          {/* Sync status */}
          {(pendingCount > 0 || failedCount > 0) && (
            <View style={styles.syncRow}>
              {pendingCount > 0 && (
                <View style={styles.syncBadge}>
                  <Text style={styles.syncBadgeText}>
                    {pendingCount} в очереди
                  </Text>
                </View>
              )}
              {failedCount > 0 && (
                <View style={[styles.syncBadge, styles.syncBadgeFailed]}>
                  <Text style={styles.syncBadgeText}>
                    {failedCount} ошибок
                  </Text>
                </View>
              )}
              <TouchableOpacity
                style={styles.syncBtn}
                onPress={syncNow}
                disabled={isSyncing}
              >
                {isSyncing ? (
                  <ActivityIndicator size="small" color={colors.pink} />
                ) : (
                  <Text style={styles.syncBtnText}>Синхронизировать</Text>
                )}
              </TouchableOpacity>
            </View>
          )}
        </>
      ) : (
        <TouchableOpacity
          style={styles.connectBtn}
          onPress={handleConnect}
          disabled={isConnecting}
        >
          {isConnecting ? (
            <ActivityIndicator size="small" color={colors.white} />
          ) : (
            <Text style={styles.connectBtnText}>Подключить GitHub</Text>
          )}
        </TouchableOpacity>
      )}

      {error && <Text style={styles.error}>{error}</Text>}

      <Text style={styles.hint}>
        Фидбэк будет коммититься в папку .govorilka/feedback/
      </Text>

      {/* Repository picker modal */}
      <Modal
        visible={showRepoPicker}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setShowRepoPicker(false)}
      >
        <View style={styles.modal}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Выберите репозиторий</Text>
            <TouchableOpacity
              style={styles.modalClose}
              onPress={() => setShowRepoPicker(false)}
            >
              <Text style={styles.modalCloseText}>Готово</Text>
            </TouchableOpacity>
          </View>

          {isLoadingRepos ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={colors.pink} />
            </View>
          ) : (
            <FlatList
              data={repos}
              keyExtractor={(item) => item.id.toString()}
              renderItem={({ item }) => (
                <Pressable
                  style={[
                    styles.repoItem,
                    selectedRepo === item.full_name && styles.repoItemSelected,
                  ]}
                  onPress={() => handleSelectRepo(item.full_name)}
                >
                  <View style={styles.repoItemContent}>
                    <Text style={styles.repoName}>{item.name}</Text>
                    {item.description && (
                      <Text style={styles.repoDescription} numberOfLines={1}>
                        {item.description}
                      </Text>
                    )}
                  </View>
                  {selectedRepo === item.full_name && (
                    <Text style={styles.checkmark}>✓</Text>
                  )}
                </Pressable>
              )}
              ListEmptyComponent={
                <Text style={styles.emptyText}>
                  Нет доступных репозиториев
                </Text>
              }
              refreshing={isLoadingRepos}
              onRefresh={refreshRepos}
            />
          )}
        </View>
      </Modal>
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
  icon: {
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
  username: {
    fontSize: 12,
    color: colors.gray,
    marginTop: 2,
  },
  connectedRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
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
  repoSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.softPink,
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
  },
  repoLabel: {
    fontSize: 13,
    color: colors.textColor,
    marginRight: 8,
  },
  repoValue: {
    flex: 1,
    fontSize: 13,
    fontWeight: '500',
    color: colors.pink,
  },
  chevron: {
    fontSize: 18,
    color: colors.gray,
  },
  syncRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    flexWrap: 'wrap',
    gap: 8,
  },
  syncBadge: {
    backgroundColor: colors.lightPink,
    borderRadius: 12,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  syncBadgeFailed: {
    backgroundColor: '#FFE0E0',
  },
  syncBadgeText: {
    fontSize: 11,
    color: colors.textColor,
  },
  syncBtn: {
    paddingVertical: 4,
    paddingHorizontal: 10,
  },
  syncBtnText: {
    fontSize: 13,
    color: colors.pink,
    fontWeight: '500',
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
  error: {
    fontSize: 12,
    color: colors.danger,
    marginBottom: 8,
  },
  hint: {
    fontSize: 11,
    color: colors.gray,
    marginTop: 4,
  },
  // Modal styles
  modal: {
    flex: 1,
    backgroundColor: colors.backgroundTop,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.lightPink,
    backgroundColor: colors.white,
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: colors.textColor,
  },
  modalClose: {
    padding: 4,
  },
  modalCloseText: {
    fontSize: 15,
    color: colors.pink,
    fontWeight: '600',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  repoItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: 14,
    borderBottomWidth: 1,
    borderBottomColor: colors.lightGray,
  },
  repoItemSelected: {
    backgroundColor: colors.softPink,
  },
  repoItemContent: {
    flex: 1,
  },
  repoName: {
    fontSize: 15,
    fontWeight: '500',
    color: colors.textColor,
  },
  repoDescription: {
    fontSize: 12,
    color: colors.gray,
    marginTop: 2,
  },
  checkmark: {
    fontSize: 18,
    color: colors.pink,
    fontWeight: '600',
  },
  emptyText: {
    fontSize: 14,
    color: colors.gray,
    textAlign: 'center',
    padding: 40,
  },
});
