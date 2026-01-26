import Foundation
import StoreKit

/// Product identifiers for In-App Purchases
enum ProductID: String {
    case supporter = "com.govorilka.supporter"
}

/// Service for handling In-App Purchases using StoreKit 2
@MainActor
final class PurchaseService: ObservableObject {
    static let shared = PurchaseService()

    // MARK: - Published Properties

    @Published private(set) var isSupporter: Bool = false
    @Published private(set) var supporterProduct: Product?
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isSupporter = "is_supporter"
    }

    // MARK: - Initialization

    private init() {
        // Load cached status
        isSupporter = defaults.bool(forKey: Keys.isSupporter)

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products and verify purchases
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available products from App Store
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [ProductID.supporter.rawValue])
            supporterProduct = products.first
            print("[PurchaseService] Loaded products: \(products.map { $0.id })")
        } catch {
            print("[PurchaseService] Failed to load products: \(error)")
            errorMessage = "Не удалось загрузить продукты: \(error.localizedDescription)"
        }
    }

    /// Purchase the supporter product
    func purchaseSupporter() async -> Bool {
        guard let product = supporterProduct else {
            errorMessage = "Продукт недоступен"
            return false
        }

        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update supporter status
                await updateSupporterStatus(true)

                // Finish the transaction
                await transaction.finish()

                isPurchasing = false
                print("[PurchaseService] Purchase successful")
                return true

            case .userCancelled:
                isPurchasing = false
                print("[PurchaseService] User cancelled purchase")
                return false

            case .pending:
                isPurchasing = false
                errorMessage = "Покупка ожидает подтверждения"
                print("[PurchaseService] Purchase pending")
                return false

            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            isPurchasing = false
            errorMessage = "Ошибка покупки: \(error.localizedDescription)"
            print("[PurchaseService] Purchase failed: \(error)")
            return false
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Update purchased products
            await updatePurchasedProducts()

            isPurchasing = false

            if !isSupporter {
                errorMessage = "Покупки не найдены"
            }

            print("[PurchaseService] Restore completed, isSupporter: \(isSupporter)")
        } catch {
            isPurchasing = false
            errorMessage = "Ошибка восстановления: \(error.localizedDescription)"
            print("[PurchaseService] Restore failed: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)

                    if let transaction = transaction,
                       transaction.productID == ProductID.supporter.rawValue {
                        await self?.updateSupporterStatus(true)
                    }

                    await transaction?.finish()
                } catch {
                    print("[PurchaseService] Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Check verified transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let signedType):
            return signedType
        }
    }

    /// Update purchased products status
    private func updatePurchasedProducts() async {
        // Check for supporter entitlement
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == ProductID.supporter.rawValue {
                    await updateSupporterStatus(true)
                    return
                }
            } catch {
                print("[PurchaseService] Entitlement verification failed: \(error)")
            }
        }

        // No valid entitlements found
        await updateSupporterStatus(false)
    }

    /// Update supporter status
    private func updateSupporterStatus(_ isSupporter: Bool) async {
        await MainActor.run {
            self.isSupporter = isSupporter
            self.defaults.set(isSupporter, forKey: Keys.isSupporter)
            print("[PurchaseService] Supporter status updated: \(isSupporter)")
        }
    }

    /// Get formatted price string
    var formattedPrice: String {
        supporterProduct?.displayPrice ?? "$4.99"
    }
}
