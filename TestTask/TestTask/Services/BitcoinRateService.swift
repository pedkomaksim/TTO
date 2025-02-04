//
//  BitcoinRateService.swift
//  TestTask
//
//  Created by Максим Педько on 03.02.2025.
//

import Foundation
import Combine

class BitcoinRateService {
    
    private var cancellables = Set<AnyCancellable>()
    private let apiURL = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private let bitcoinRateSubject = CurrentValueSubject<Double?, Never>(nil)
    
    var bitcoinRatePublisher: AnyPublisher<Double?, Never> { bitcoinRateSubject.eraseToAnyPublisher() }
    
    init() {
        fetchBitcoinRate()
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.fetchBitcoinRate()
        }
    }
    
    private func fetchBitcoinRate() {
        URLSession.shared.dataTaskPublisher(for: apiURL)
            .map { $0.data }
            .decode(type: BitcoinRateResponse.self, decoder: JSONDecoder())
            .map { $0.bpi.USD.rateFloat }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                print("Bitcoin rate updated: \(rate ?? 0)")
                self?.bitcoinRateSubject.send(rate)
            }
            .store(in: &cancellables)
    }
}

struct BitcoinRateResponse: Codable {
    
    struct BPI: Codable {
        struct USD: Codable {
            let rateFloat: Double
            
            enum CodingKeys: String, CodingKey {
                case rateFloat = "rate_float"
            }
        }
        let USD: USD
    }
    let bpi: BPI
}
