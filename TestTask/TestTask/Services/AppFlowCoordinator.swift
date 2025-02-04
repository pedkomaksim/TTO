//
//  AppFlowCoordinator..swift
//  TestTask
//
//  Created by Максим Педько on 04.02.2025.
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
        coreDataService.initializeBalanceIfNeeded()
        coreDataService.seedTransactions()
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

extension AppFlowCoordinator: BitcoinDashboardModelNavigationHandler { }
