//
//  CarPlaySceneDelegate.swift
//  test-carplay
//
//  Created by Alex Motoc on 26.11.2023.
//

import CarPlay

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    private var interfaceController: CPInterfaceController?
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        
        interfaceController.setRootTemplate(mainTabTemplate, animated: false, completion: nil)
        
        User.shared.didChangeLoginStatus = { _ in
            self.updateTabBar(self.mainTabTemplate, selectedIndex: self.selectedTabIndex)
        }
        
        print("didConnect")
    }
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        selectedTabIndex = 0
        print("didDisconnect")
    }
    
    // MARK: - Utils
    
    private var selectedTabIndex = 0
    
    private lazy var mainTabTemplate: CPTabBarTemplate = {
        let template = CPTabBarTemplate(templates: [])
        template.delegate = self
        updateTabBar(template, selectedIndex: selectedTabIndex)
        return template
    }()
    
    private lazy var gasStationsTemplate: CPPointOfInterestTemplate = {
        let template = CPPointOfInterestTemplate(
            title: "Gas stations",
            pointsOfInterest: makeFalsePointOfInterests(),
            selectedIndex: 0
        )
        template.tabTitle = "Gas stations"
        template.tabImage = UIImage(systemName: "fuelpump")
        return template
    }()
    
    private lazy var evChargingStationsTemplate: CPPointOfInterestTemplate = {
        let template = CPPointOfInterestTemplate(
            title: "EV charging stations",
            pointsOfInterest: makeFalsePointOfInterests(),
            selectedIndex: 0
        )
        template.tabTitle = "EV Charging"
        template.tabImage = UIImage(systemName: "ev.charger")
        return template
    }()
    
    private func makeWelcomeScreen() -> CPInformationTemplate {
        var items: [CPInformationItem] = []
        if !User.shared.isLoggedIn {
            items.append(.init(title: "Login required", detail: "You need to be logged in before proceeding further"))
        }
        
        if !isLocationEnabled {
            let message = "Open the AAA app and enable precise location or enable it from the Settings app."
            items.append(.init(title: "Precise location required", detail: message))
        }
        
        let template = CPInformationTemplate(
            title: "Welcome",
            layout: .leading,
            items: items,
            actions: []
        )
        setupRoadsideTab(for: template)
        return template
    }
    
    private func makeLoadingScreen() -> CPAlertTemplate {
        let template = CPAlertTemplate(titleVariants: ["Loading..."], actions: [])
        setupRoadsideTab(for: template)
        return template
    }
    
    private func makeFalsePointOfInterests() -> [CPPointOfInterest] {
        FalseData.falseMapItems().map {
            CPPointOfInterest(
                location: $0,
                title: $0.name ?? "Mock",
                subtitle: nil,
                summary: nil,
                detailTitle: $0.name ?? "Mock",
                detailSubtitle: nil,
                detailSummary: nil,
                pinImage: nil
            )
        }
    }
    
    private func setupRoadsideTab(for template: CPTemplate) {
        template.tabTitle = "Assistance"
        template.tabImage = UIImage(systemName: "wrench.and.screwdriver")
    }
    
    private func updateTabBar(_ template: CPTabBarTemplate, selectedIndex: Int) {
        let roadsideTemplate = isLocationEnabled && User.shared.isLoggedIn ? makeLoadingScreen() : makeWelcomeScreen()
        template.updateTemplates([gasStationsTemplate, roadsideTemplate, evChargingStationsTemplate])
        template.selectTemplate(at: selectedIndex)
    }
    
    private var isLocationEnabled: Bool {
        locationManager.authorizationStatus.isAuthorized &&
        locationManager.accuracyAuthorization == .fullAccuracy
    }
}

extension CarPlaySceneDelegate: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateTabBar(mainTabTemplate, selectedIndex: selectedTabIndex)
    }
}

extension CLAuthorizationStatus {
    var isAuthorized: Bool {
       self == .authorizedWhenInUse || self == .authorizedAlways
    }
}

extension CarPlaySceneDelegate: CPTabBarTemplateDelegate {
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
        selectedTabIndex = tabBarTemplate.templates.firstIndex(of: selectedTemplate) ?? 0
    }
}
