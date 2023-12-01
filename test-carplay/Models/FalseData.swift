/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`FalseData` manages the false data in the response.
*/

import CarPlay
import MapKit
import Contacts

final class FalseData {
    
    var advisoryError: Error?
    var issuesError: Error?
    var carsError: Error?
    var towDestinationsError: Error?
    
    // MARK: - API requests
    
    func getAdvisory(completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if let advisoryError = self.advisoryError {
                completion(.failure(advisoryError))
            } else {
                completion(.success("Due to the recent storms, a service truck could take up to 3 hours to reach your location"))
            }
        }
    }
    
    func getIssues(completion: @escaping (Result<[IssueData], Error>) -> Void) {
        let issues: [IssueData] = [
            .init(name: "Flat tire", systemIconName: "car.rear.and.tire.marks"),
            .init(name: "Stuck", systemIconName: "car.side.lock"),
            .init(name: "Accident", systemIconName: "car.side.rear.and.collision.and.car.side.front"),
            .init(name: "Need a tow", systemIconName: "car.side.hill.up"),
            .init(name: "Need gas", systemIconName: "fuelpump"),
            .init(name: "Need charge", systemIconName: "ev.charger")
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if let advisoryError = self.issuesError {
                completion(.failure(advisoryError))
            } else {
                completion(.success(issues))
            }
        }
    }
    
    func getCars(completion: @escaping (Result<[Car], Error>) -> Void) {
        let cars: [Car] = [
            .init(name: "2019 Chevrolet Camaro", color: "Black"),
            .init(name: "2019 Hyundai Elantra GT", color: "Blue"),
            .init(name: "2019 Dodge Durango", color: "White"),
            .init(name: "2023 Mercedes E320", color: "Pearl grey"),
            .init(name: "2023 BMW 7 series", color: "Cameleon orange"),
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if let carsError = self.carsError {
                completion(.failure(carsError))
            } else {
                completion(.success(cars))
            }
        }
    }
    
    func getTowDestinations(completion: @escaping (Result<[MKMapItem], Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if let towDestinationsError = self.towDestinationsError {
                completion(.failure(towDestinationsError))
            } else {
                completion(.success(Self.falseMapItems()))
            }
        }
    }
    
    // MARK: - Map Itemse
    
    static func falseMapItems() -> [MKMapItem] {
        let bridgeItem = MKMapItem(
            placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.807_977, longitude: -122.475_306),
                                   postalAddress: TheBridge()))
        bridgeItem.name = "Place 1"
        let cityHallItem = MKMapItem(
            placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.778_858, longitude: -122.419_326),
                                   postalAddress: CityHall()))
        cityHallItem.name = "Place 2"
        return [bridgeItem, cityHallItem]
    }
    
    static let falseRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.790, longitude: -122.450),
                              latitudinalMeters: 500_000, longitudinalMeters: 500_000)
    
    // MARK: - Address Data

    fileprivate class BaseAddress: CNPostalAddress {
        
        override var country: String {
            return "US"
        }
        
        override var city: String {
            return "San Francisco"
        }
        
        override var state: String {
            return "CA"
        }
        
        override var postalCode: String {
            return "94102"
        }
        
    }

    fileprivate class CityHall: BaseAddress {
        
        override var street: String {
            return "1 Dr. Carlton B Goodlett Pl"
        }
    }

    fileprivate class TheBridge: BaseAddress {
        
        override var street: String {
            return "Golden Gate Bridge Plaza"
        }
        
        override var postalCode: String {
            return "94129"
        }
    }
    
    // MARK: - IssueData
    
    struct IssueData {
        let name: String
        let systemIconName: String
    }
    
    struct Car {
        let name: String
        let color: String
    }
}
