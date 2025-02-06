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
    private let coreDataService = CoreDataService.shared
    
    override init() {
        super.init()
    }
    
    func createFlow() -> UIViewController {
        let model = BitcoinDashboardModel(
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
        guard let navigationController = navigationController,
              let dashboardVC = navigationController.viewControllers.first as? BitcoinDashboardViewController else {
            return
        }

        let model = AddTransactionModel(
            navigationHandler: self,
            coreDataService: coreDataService
        )
        
        let controller = AddTransactionViewController(model: model)
        controller.delegate = dashboardVC.model as? TransactionUpdaterDelegate
        
        navigationController.pushViewController(controller, animated: true)
    }

}

extension AppFlowCoordinator: AddTransactionModelNavigationHandler { }
