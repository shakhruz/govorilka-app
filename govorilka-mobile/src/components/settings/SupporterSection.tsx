import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Linking,
} from 'react-native';
import { PurchaseService, PurchaseState } from '../../services/PurchaseService';
import { colors } from '../../theme/colors';

export function SupporterSection() {
  const [state, setState] = useState<PurchaseState>(PurchaseService.getState());

  useEffect(() => {
    // Initialize service
    PurchaseService.initialize();

    // Subscribe to state changes
    const unsubscribe = PurchaseService.subscribe(setState);

    return () => {
      unsubscribe();
    };
  }, []);

  const handlePurchase = async () => {
    await PurchaseService.purchase();
  };

  const handleRestore = async () => {
    await PurchaseService.restore();
  };

  const openGitHub = () => {
    Linking.openURL('https://github.com/skylineyoga/govorilka');
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.icon}>{state.isSupporter ? '💖' : '🤍'}</Text>
        <View style={styles.info}>
          <Text style={styles.title}>
            {state.isSupporter ? 'Спасибо за поддержку!' : 'Поддержать разработку'}
          </Text>
          {state.isSupporter && (
            <View style={styles.badge}>
              <Text style={styles.badgeText}>Supporter ✓</Text>
            </View>
          )}
        </View>
      </View>

      {state.isSupporter ? (
        <Text style={styles.thankYou}>
          Вы помогаете развивать Говорилку. Спасибо!
        </Text>
      ) : (
        <>
          <Text style={styles.description}>
            Говорилка — open-source и бесплатна. Покупка поддерживает разработку
            и даёт автообновления из App Store.
          </Text>

          <View style={styles.buttons}>
            <TouchableOpacity
              style={styles.purchaseBtn}
              onPress={handlePurchase}
              disabled={state.isPurchasing || state.isRestoring}
            >
              {state.isPurchasing ? (
                <ActivityIndicator size="small" color={colors.white} />
              ) : (
                <>
                  <Text style={styles.purchaseBtnIcon}>💖</Text>
                  <Text style={styles.purchaseBtnText}>{state.price}</Text>
                </>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.restoreBtn}
              onPress={handleRestore}
              disabled={state.isPurchasing || state.isRestoring}
            >
              {state.isRestoring ? (
                <ActivityIndicator size="small" color={colors.pink} />
              ) : (
                <Text style={styles.restoreBtnText}>Восстановить</Text>
              )}
            </TouchableOpacity>
          </View>

          {state.error && <Text style={styles.error}>{state.error}</Text>}

          <TouchableOpacity style={styles.githubLink} onPress={openGitHub}>
            <Text style={styles.githubIcon}>{'</>'}</Text>
            <Text style={styles.githubText}>Собрать бесплатно из исходников</Text>
            <Text style={styles.arrow}>↗</Text>
          </TouchableOpacity>
        </>
      )}
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
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 8,
  },
  title: {
    fontSize: 15,
    fontWeight: '500',
    color: colors.textColor,
  },
  badge: {
    backgroundColor: colors.softPink,
    borderRadius: 12,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.pink,
  },
  thankYou: {
    fontSize: 13,
    color: colors.textColor,
    opacity: 0.7,
  },
  description: {
    fontSize: 13,
    color: colors.textColor,
    opacity: 0.7,
    lineHeight: 18,
    marginBottom: 12,
  },
  buttons: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 8,
  },
  purchaseBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.pink,
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 20,
    shadowColor: colors.pink,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 3,
  },
  purchaseBtnIcon: {
    fontSize: 14,
    marginRight: 6,
  },
  purchaseBtnText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.white,
  },
  restoreBtn: {
    paddingVertical: 12,
    paddingHorizontal: 8,
  },
  restoreBtnText: {
    fontSize: 13,
    color: colors.pink,
    fontWeight: '500',
  },
  error: {
    fontSize: 12,
    color: colors.danger,
    marginBottom: 8,
  },
  githubLink: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    paddingVertical: 4,
  },
  githubIcon: {
    fontSize: 12,
    color: colors.gray,
    marginRight: 6,
    fontFamily: 'monospace',
  },
  githubText: {
    fontSize: 12,
    color: colors.gray,
    flex: 1,
  },
  arrow: {
    fontSize: 12,
    color: colors.gray,
  },
});
