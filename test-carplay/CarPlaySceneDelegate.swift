//
//  CarPlaySceneDelegate.swift
//  test-carplay
//
//  Created by Alex Motoc on 26.11.2023.
//

import CarPlay

final class CollectedInfo {
    var issue: FalseData.IssueData?
    var car: FalseData.Car?
    var is4WD = false
    var towDestination: MKMapItem?
}

private class PrerequisitesData {}

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    enum Tab: Int, CaseIterable {
        case gasStations
        case roadsideAssistance
        case evCharging
    }
    
    private let service = FalseData()
    private var collectedInfo = CollectedInfo()
    private var isInternalRoadsideTabUpdate = false
    private let prerequisitesData = PrerequisitesData()
    private var cachedAdvisory: String?
    
    // MARK: - CPTemplateApplicationSceneDelegate
    
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
        fetchDataForRoadsideTab()
        presentWelcomeScreen()
        
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
        collectedInfo = .init()
        print("didDisconnect")
    }
    
    // MARK: - Utils
    
    private var selectedTabIndex = 0
    
    private lazy var mainTabTemplate: CPTabBarTemplate = {
        let template = CPTabBarTemplate(templates: [])
        template.delegate = self
        setupTabBar(template)
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
    
    private lazy var selectIssueTemplate: CPGridTemplate = {
        let template = CPGridTemplate(title: "Assistance", gridButtons: [])
        setupRoadsideTab(for: template)
        return template
    }()
    
    private lazy var selectCarTemplate: CPListTemplate = {
        .init(title: "Select car", sections: [])
    }()
    
    private lazy var selectTowDestinationTemplate: CPPointOfInterestTemplate = {
        .init(title: "Select tow destination", pointsOfInterest: [], selectedIndex: NSNotFound)
    }()
    
    private func makePrerequisitesNotSatisfiedScreen() -> CPInformationTemplate {
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
        template.userInfo = prerequisitesData
        setupRoadsideTab(for: template)
        return template
    }
    
    private func makeWelcomeScreen() -> CPAlertTemplate {
        .init(titleVariants: ["Do not use the app while driving"], actions: [
            .init(title: "Dismiss", style: .cancel, handler: { [weak self] _ in
                self?.interfaceController?.dismissTemplate(animated: true, completion: { _, _ in })
            })
        ])
    }
    
    private func makeLoadingScreen() -> CPInformationTemplate {
        let template = CPInformationTemplate(
            title: "Please wait",
            layout: .leading,
            items: [.init(title: "We are loading some data", detail: nil)],
            actions: []
        )
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
    
    private func setupTabBar(_ template: CPTabBarTemplate) {
        let isShowingRoadsideTab = isLocationEnabled && User.shared.isLoggedIn
        let roadsideTemplate = isShowingRoadsideTab ? selectIssueTemplate : makePrerequisitesNotSatisfiedScreen()
        template.updateTemplates([gasStationsTemplate, roadsideTemplate, evChargingStationsTemplate])
    }
    
    private func updateTabBar(_ template: CPTabBarTemplate, selectedIndex: Int) {
        setupTabBar(template)
        template.selectTemplate(at: selectedIndex)
    }
    
    private func updateRoadsideTab(with template: CPTemplate) {
        isInternalRoadsideTabUpdate = true
        setupRoadsideTab(for: template)
        mainTabTemplate.updateTemplates([gasStationsTemplate, template, evChargingStationsTemplate])
        mainTabTemplate.selectTemplate(at: selectedTabIndex)
    }
    
    private func fetchDataForRoadsideTab() {
        service.getAdvisory { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let advisory):
                guard isRoadsideTabSelected else {
                    cachedAdvisory = advisory
                    return
                }
                showAdvisory(message: advisory)
            case .failure(let failure):
                let alert = makeAlertTemplate(message: failure.localizedDescription)
                interfaceController?.presentTemplate(alert, animated: true, completion: nil)
            }
        }
        
        service.getIssues { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let issues):
                let buttons = issues.map { issue in
                    CPGridButton(
                        titleVariants: [issue.name],
                        image: UIImage(systemName: issue.systemIconName)!,
                        handler: { _ in
                            self.didSelectIssue(issue)
                        }
                    )
                }
                selectIssueTemplate.updateGridButtons(buttons)
            case .failure(let error):
                let alert = makeAlertTemplate(message: error.localizedDescription)
                interfaceController?.presentTemplate(alert, animated: true, completion: nil)
            }
        }
        
        service.getCars { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let cars):
                let items = cars.map { car in
                    let item = CPListItem(text: car.name, detailText: car.color)
                    item.handler = { _, completion in
                        self.didSelectCarItem(car, completion: completion)
                    }
                    return item
                }
                let section = CPListSection(items: items)
                selectCarTemplate.updateSections([section])
            case .failure(let error):
                let alert = makeAlertTemplate(message: error.localizedDescription)
                interfaceController?.presentTemplate(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func fetchTowDestinations(completion: @escaping () -> Void) {
        service.getTowDestinations { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let towDestinations):
                let pois = towDestinations.map { destination in
                    let poi = CPPointOfInterest(
                        location: destination,
                        title: destination.name ?? "",
                        subtitle: (destination.name ?? "") + " subtitle",
                        summary: (destination.name ?? "") + " summary",
                        detailTitle: destination.name ?? "",
                        detailSubtitle: (destination.name ?? "") + " detail subtitle",
                        detailSummary: (destination.name ?? "") + " detail summary",
                        pinImage: nil
                    )
                    poi.primaryButton = .init(title: "Select", textStyle: .confirm, handler: { _ in
                        self.didSelectTowLocation(destination)
                    })
                    return poi
                }
                selectTowDestinationTemplate.setPointsOfInterest(pois, selectedIndex: NSNotFound)
            case .failure(let error):
                let alert = makeAlertTemplate(message: error.localizedDescription)
                interfaceController?.presentTemplate(alert, animated: true, completion: nil)
            }
            
            completion()
        }
    }
    
    private func didSelectCarItem(_ car: FalseData.Car, completion: @escaping () -> Void) {
        collectedInfo.car = car
        fetchTowDestinations { [weak self] in
            defer { completion() }
            guard let self else { return }
            interfaceController?.presentTemplate(make4WDSelectionScreen(selection: { is4WD in
                self.collectedInfo.is4WD = is4WD
                self.interfaceController?.dismissTemplate(animated: true, completion: { _, _ in
                    self.updateRoadsideTab(with: self.selectTowDestinationTemplate)
                })
            }), animated: true, completion: nil)
        }
    }
    
    private func didSelectTowLocation(_ location: MKMapItem) {
        collectedInfo.towDestination = location
        let detail = makeTowDestinationDetail { [weak self] in
            guard let self else { return }
            self.interfaceController?.popTemplate(animated: true, completion: { _, _ in
                self.updateRoadsideTab(with: self.makeSummary())
            })
        }
        interfaceController?.pushTemplate(detail, animated: true, completion: nil)
    }
    
    private func didSelectIssue(_ issue: FalseData.IssueData) {
        collectedInfo.issue = issue
        updateRoadsideTab(with: selectCarTemplate)
    }
    
    private func showAdvisory(message: String) {
        let alert = makeAlertTemplate(message: message)
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
    
    private func makeAlertTemplate(message: String, hasDismiss: Bool = true, handler: (() -> Void)? = nil) -> CPAlertTemplate {
        let dismiss = CPAlertAction(
            title: "Dismiss",
            style: .cancel,
            handler: { [weak self] _ in
                self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
                handler?()
            }
        )
        return .init(
            titleVariants: [message],
            actions: hasDismiss ? [dismiss] : []
        )
    }
    
    private var isLocationEnabled: Bool {
        locationManager.authorizationStatus.isAuthorized &&
        locationManager.accuracyAuthorization == .fullAccuracy
    }
    
    private var isRoadsideTabSelected: Bool {
        mainTabTemplate.templates.count == Tab.allCases.count && Tab(rawValue: selectedTabIndex) == .roadsideAssistance
    }
    
    private func presentWelcomeScreen() {
        let welcomeScreen = makeWelcomeScreen()
        interfaceController?.presentTemplate(welcomeScreen, animated: true, completion: { _, _ in })
    }
    
    private func make4WDSelectionScreen(selection: @escaping (Bool) -> Void) -> CPAlertTemplate {
        .init(titleVariants: ["Is it a 4WD or AWD car?"], actions: [
            .init(title: "Yes", style: .default, handler: { _ in
                selection(true)
            }),
            .init(title: "No", style: .default, handler: { _ in
                selection(false)
            })
        ])
    }
    
    private func makeTowDestinationDetail(handler: @escaping () -> Void) -> CPInformationTemplate {
        .init(
            title: "Tow destintaion detail",
            layout: .leading,
            items: [
                .init(title: nil, detail: "AAA memebers receive a 10% labour discount on repairs performed at this facility. The maximum labour discount is $75."),
                .init(title: nil, detail: "Services excluded from this offer include: Not to be used with any other discount, special, sale or menu priced item or service"),
                .init(title: "Repair services", detail: "Air conditioning, Automatic transmission, Brakes, Clutch/Driveline, Cooling/Radiator, Electrical, Engine, Overhaul/Replace, Gas engine, Diagnostics, Hybrid powertrains, etc.")
            ],
            actions: [
                .init(title: "Confirm", textStyle: .confirm, handler: { _ in
                    handler()
                })
            ]
        )
    }
    
    private func makeSummary() -> CPInformationTemplate {
        .init(
            title: "Summary",
            layout: .twoColumn,
            items: [
                .init(title: "Location", detail: "Current user's location, formatted"),
                .init(title: "Issue", detail: collectedInfo.issue?.name ?? ""),
                .init(title: "Vehicle", detail: collectedInfo.car?.name ?? ""),
                .init(title: "4WD or AWD", detail: collectedInfo.is4WD ? "YES" : "NO"),
                .init(title: "Tow to", detail: collectedInfo.towDestination?.name ?? "")
            ],
            actions: [.init(title: "Send", textStyle: .confirm, handler: { button in
                let alert = self.makeAlertTemplate(message: "Please wait while we process your request", hasDismiss: false)
                self.interfaceController?.presentTemplate(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.interfaceController?.dismissTemplate(animated: true, completion: nil)
                    self.updateRoadsideTab(with: self.makeRequestSent())
                }
            })]
        )
    }
    
    private func makeRequestSent() -> CPInformationTemplate {
        .init(
            title: "Request sent",
            layout: .leading,
            items: [
                .init(title: nil, detail: "Your call has been successfully submitted"),
            ],
            actions: []
        )
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
        
        if let cachedAdvisory {
            showAdvisory(message: cachedAdvisory)
            self.cachedAdvisory = nil
        }
        
        // recreate the flow only if the roadside tab is selected and the user is somewhere other than root in the hierarchy
        if isInternalRoadsideTabUpdate {
            isInternalRoadsideTabUpdate.toggle()
            return
        }
        if selectedTemplate == selectIssueTemplate || (selectedTemplate.userInfo as? PrerequisitesData) === prerequisitesData { return }
        guard isRoadsideTabSelected else { return }
        updateTabBar(mainTabTemplate, selectedIndex: selectedTabIndex)
    }
}
