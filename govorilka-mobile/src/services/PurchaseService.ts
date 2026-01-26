/**
 * PurchaseService for iOS In-App Purchases
 * Handles supporter purchase using expo-in-app-purchases
 */

import * as InAppPurchases from 'expo-in-app-purchases';
import AsyncStorage from '@react-native-async-storage/async-storage';

const PRODUCT_ID = 'com.govorilka.supporter';
const IS_SUPPORTER_KEY = 'is_supporter';

export interface PurchaseState {
  isSupporter: boolean;
  isPurchasing: boolean;
  isRestoring: boolean;
  price: string;
  error: string | null;
}

class PurchaseServiceClass {
  private isConnected = false;
  private listeners: ((state: PurchaseState) => void)[] = [];
  private state: PurchaseState = {
    isSupporter: false,
    isPurchasing: false,
    isRestoring: false,
    price: '$4.99',
    error: null,
  };

  /**
   * Initialize the purchase service
   * Call this on app startup
   */
  async initialize(): Promise<void> {
    try {
      // Load cached supporter status
      const cached = await AsyncStorage.getItem(IS_SUPPORTER_KEY);
      if (cached === 'true') {
        this.updateState({ isSupporter: true });
      }

      // Connect to the store
      await InAppPurchases.connectAsync();
      this.isConnected = true;

      // Set up purchase listener
      InAppPurchases.setPurchaseListener(this.handlePurchaseUpdate.bind(this));

      // Load products
      await this.loadProducts();

      // Verify current purchases
      await this.verifyPurchases();

      console.log('[PurchaseService] Initialized');
    } catch (error) {
      console.error('[PurchaseService] Init error:', error);
    }
  }

  /**
   * Clean up the purchase service
   */
  async cleanup(): Promise<void> {
    if (this.isConnected) {
      await InAppPurchases.disconnectAsync();
      this.isConnected = false;
    }
  }

  /**
   * Load product information
   */
  private async loadProducts(): Promise<void> {
    try {
      const { responseCode, results } = await InAppPurchases.getProductsAsync([PRODUCT_ID]);

      if (responseCode === InAppPurchases.IAPResponseCode.OK && results?.length) {
        const product = results[0];
        this.updateState({ price: product.price || '$4.99' });
        console.log('[PurchaseService] Product loaded:', product.price);
      }
    } catch (error) {
      console.error('[PurchaseService] Load products error:', error);
    }
  }

  /**
   * Verify existing purchases
   */
  private async verifyPurchases(): Promise<void> {
    try {
      const { responseCode, results } = await InAppPurchases.getPurchaseHistoryAsync();

      if (responseCode === InAppPurchases.IAPResponseCode.OK && results) {
        const hasSupporterPurchase = results.some(
          (purchase: InAppPurchases.InAppPurchase) => purchase.productId === PRODUCT_ID
        );

        if (hasSupporterPurchase) {
          await this.setSupporterStatus(true);
        }
      }
    } catch (error) {
      console.error('[PurchaseService] Verify purchases error:', error);
    }
  }

  /**
   * Handle purchase updates from the store
   */
  private async handlePurchaseUpdate(result: InAppPurchases.IAPQueryResponse<InAppPurchases.InAppPurchase>): Promise<void> {
    const { responseCode, results } = result;

    if (responseCode === InAppPurchases.IAPResponseCode.OK && results) {
      for (const purchase of results) {
        if (purchase.productId === PRODUCT_ID) {
          // Finish the transaction
          if (!purchase.acknowledged) {
            await InAppPurchases.finishTransactionAsync(purchase, true);
          }

          // Update supporter status
          await this.setSupporterStatus(true);
          this.updateState({ isPurchasing: false, isRestoring: false, error: null });

          console.log('[PurchaseService] Purchase successful');
        }
      }
    } else if (responseCode === InAppPurchases.IAPResponseCode.USER_CANCELED) {
      this.updateState({ isPurchasing: false, isRestoring: false, error: null });
      console.log('[PurchaseService] User cancelled');
    } else {
      this.updateState({
        isPurchasing: false,
        isRestoring: false,
        error: 'Purchase failed',
      });
      console.error('[PurchaseService] Purchase failed:', responseCode);
    }
  }

  /**
   * Purchase the supporter product
   */
  async purchase(): Promise<boolean> {
    if (!this.isConnected) {
      this.updateState({ error: 'Store not connected' });
      return false;
    }

    this.updateState({ isPurchasing: true, error: null });

    try {
      await InAppPurchases.purchaseItemAsync(PRODUCT_ID);
      // The result will come through the purchase listener
      return true;
    } catch (error) {
      console.error('[PurchaseService] Purchase error:', error);
      this.updateState({
        isPurchasing: false,
        error: error instanceof Error ? error.message : 'Purchase failed',
      });
      return false;
    }
  }

  /**
   * Restore previous purchases
   */
  async restore(): Promise<boolean> {
    if (!this.isConnected) {
      this.updateState({ error: 'Store not connected' });
      return false;
    }

    this.updateState({ isRestoring: true, error: null });

    try {
      const { responseCode, results } = await InAppPurchases.getPurchaseHistoryAsync();

      if (responseCode === InAppPurchases.IAPResponseCode.OK) {
        if (results?.some((p: InAppPurchases.InAppPurchase) => p.productId === PRODUCT_ID)) {
          await this.setSupporterStatus(true);
          this.updateState({ isRestoring: false, error: null });
          console.log('[PurchaseService] Restore successful');
          return true;
        } else {
          this.updateState({ isRestoring: false, error: 'No purchases found' });
          return false;
        }
      } else {
        this.updateState({ isRestoring: false, error: 'Restore failed' });
        return false;
      }
    } catch (error) {
      console.error('[PurchaseService] Restore error:', error);
      this.updateState({
        isRestoring: false,
        error: error instanceof Error ? error.message : 'Restore failed',
      });
      return false;
    }
  }

  /**
   * Set and persist supporter status
   */
  private async setSupporterStatus(isSupporter: boolean): Promise<void> {
    await AsyncStorage.setItem(IS_SUPPORTER_KEY, isSupporter ? 'true' : 'false');
    this.updateState({ isSupporter });
  }

  /**
   * Get current state
   */
  getState(): PurchaseState {
    return { ...this.state };
  }

  /**
   * Subscribe to state changes
   */
  subscribe(listener: (state: PurchaseState) => void): () => void {
    this.listeners.push(listener);
    listener(this.state); // Call immediately with current state

    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  /**
   * Update state and notify listeners
   */
  private updateState(partial: Partial<PurchaseState>): void {
    this.state = { ...this.state, ...partial };
    this.listeners.forEach((listener) => listener(this.state));
  }
}

export const PurchaseService = new PurchaseServiceClass();
