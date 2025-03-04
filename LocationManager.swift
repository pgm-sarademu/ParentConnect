import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        // Update region to center on user's location
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    // Calculate distance in miles from user's location to a coordinate
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLocation = location else { return nil }
        
        let destination = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distanceInMeters = userLocation.distance(from: destination)
        
        // Convert to miles (1 meter = 0.000621371 miles)
        return distanceInMeters * 0.000621371
    }
    
    // Find nearby events within a certain radius (in miles)
    func findNearbyLocations(coordinates: [CLLocationCoordinate2D], radiusInMiles: Double) -> [Int] {
        guard let userLocation = location else { return [] }
        
        var nearbyIndices: [Int] = []
        let radiusInMeters = radiusInMiles / 0.000621371 // Convert miles to meters
        
        for (index, coordinate) in coordinates.enumerated() {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = userLocation.distance(from: location)
            
            if distance <= radiusInMeters {
                nearbyIndices.append(index)
            }
        }
        
        return nearbyIndices
    }
    
    // Get addresses from coordinates
    func getAddressFromCoordinate(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil else {
                print("Reverse geocoding error: \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            
            var addressString = ""
            
            if let name = placemark.name {
                addressString += name + ", "
            }
            
            if let street = placemark.thoroughfare {
                addressString += street + ", "
            }
            
            if let city = placemark.locality {
                addressString += city + ", "
            }
            
            if let state = placemark.administrativeArea {
                addressString += state + " "
            }
            
            if let zip = placemark.postalCode {
                addressString += zip
            }
            
            completion(addressString)
        }
    }
}
