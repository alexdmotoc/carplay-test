/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`FalseData` manages the false data in the response.
*/

import CarPlay
import MapKit
import Contacts

enum FalseData {
    
    // MARK: Map Items
    
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
    
    // MARK: Address Data

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
    
}
