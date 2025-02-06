//
//  AppFlowCoordinator.swift
//  TransactionsTestTask
//
//  Created by Максим Педько on 06.02.2025.
//

import Foundation
import UIKit

final class AppFlowCoordinator: NSObject, FlowCoordinator {
    
    var containerViewController: UIViewController?
    
    private weak var navigationController: UINavigationController?
    private weak var rootViewController: UIViewController?
    private let coreDataService: CoreDataService = ServicesAssembler.coreDataService
    private let bitcoinRateService: BitcoinRateService = ServicesAssembler.bitcoinRateService
    
    override init() {
        super.init()
    }
    
    func createFlow() -> UIViewController {
        let model = BitcoinDashboardModel(
            bitcoinRateService: bitcoinRateService,
            navigationHandler: self as BitcoinDashboardModelNavigationHandler,
            coreDataService: coreDataService
        )
        let controller = BitcoinDashboardViewController(model: model)
        let navigationController = UINavigationController(rootViewController: controller)
        
        self.navigationController = navigationController
        rootViewController = navigationController
        
        return navigationController
    }
    
}

extension AppFlowCoordinator: BitcoinDashboardModelNavigationHandler {
    
    func showAddTransaction() {
        let model = AddTransactionModel(
            navigationHandler: self,
            coreDataService: coreDataService
        )
        
        let controller = AddTransactionViewController(model: model)
        navigationController?.pushViewController(controller, animated: true)
    }
    
}

extension AppFlowCoordinator: AddTransactionModelNavigationHandler { }
