//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//

/// Rate Service should fetch data from https://api.coindesk.com/v1/bpi/currentprice.json
/// Fetching should be scheduled with dynamic update interval
/// Rate should be cached for the offline mode
/// Every successful fetch should be logged with analytics service
/// The service should be covered by unit tests
///
import Foundation
import Combine


// MARK: - BitcoinRateService

protocol BitcoinRateService: AnyObject {
    
    var bitcoinRatePublisher: AnyPublisher<Double, Never> { get }
    var cachedRate: Double? { get }
    
    func updateFetchInterval(_ interval: TimeInterval)
    
}

// MARK: - BitcoinRateService

final class BitcoinRateServiceImpl: BitcoinRateService {
    
    // MARK: - Public Properties
    
    private let bitcoinRateSubject = PassthroughSubject<Double, Never>()
    var bitcoinRatePublisher: AnyPublisher<Double, Never> {
        bitcoinRateSubject.eraseToAnyPublisher()
    }
    
    var cachedRate: Double?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    private let apiURL = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!
    private var updateInterval: TimeInterval
    private let analyticsService: AnalyticsService
    private let userDefaults: UserDefaults
    
    // MARK: - Init
    
    init(updateInterval: TimeInterval = 300,
         analyticsService: AnalyticsService,
         userDefaults: UserDefaults = .standard) {
        self.updateInterval = updateInterval
        self.analyticsService = analyticsService
        self.userDefaults = userDefaults
        
        let savedRate = userDefaults.double(forKey: "CachedBitcoinRate")
        self.cachedRate = (savedRate != 0 ? savedRate : nil)
        
        startTimer()
        fetchBitcoinRate()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func updateFetchInterval(_ interval: TimeInterval) {
        updateInterval = interval
        startTimer()
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.fetchBitcoinRate()
        }
    }
    
    private func fetchBitcoinRate() {
        URLSession.shared.dataTaskPublisher(for: apiURL)
            .map { $0.data }
            .decode(type: BitcoinRateResponse.self, decoder: JSONDecoder())
            .map { $0.bpi.USD.rateFloat }
            .catch { [weak self] error -> Just<Double> in
                guard let self = self else { return Just(0) }
                
                if let cached = self.cachedRate {
                    self.analyticsService.trackEvent(
                        name: "bitcoin_rate_update_error",
                        parameters: [
                            "error": error.localizedDescription,
                            "fallback": "cached",
                            "rate": String(format: "%.2f", cached)
                        ]
                    )
                    return Just(cached)
                } else {
                    self.analyticsService.trackEvent(
                        name: "bitcoin_rate_update_error",
                        parameters: [
                            "error": error.localizedDescription,
                            "fallback": "none"
                        ]
                    )
                    return Just(0)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                guard let self = self, rate != 0 else { return }
                
                self.cachedRate = rate
                self.userDefaults.set(rate, forKey: "CachedBitcoinRate")
                
                self.bitcoinRateSubject.send(rate)
                
                self.analyticsService.trackEvent(
                    name: "bitcoin_rate_update",
                    parameters: ["rate": String(format: "%.2f", rate)]
                )
            }
            .store(in: &cancellables)
    }
 
}
