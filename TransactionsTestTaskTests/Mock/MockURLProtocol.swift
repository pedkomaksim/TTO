//
//  MockURLProtocol.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import Foundation

class MockURLProtocol: URLProtocol {
    
    static var stubData: Data?
    static var stubError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.stubError {
            client?.urlProtocol(self, didFailWithError: error)
        } else if let data = MockURLProtocol.stubData {
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
    }
    
}
