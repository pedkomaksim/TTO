//
//  BitcoinRateResponse.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

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
