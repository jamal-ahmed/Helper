import CoreLocation
import Combine

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public final class LocationManager: NSObject {
    private let manager: CLLocationManager = CLLocationManager()
    private let location: PassthroughSubject<CLLocation, LocationError>
    private let heading: PassthroughSubject<CLHeading, LocationError>
    var locationPublisher: AnyPublisher<CLLocation, LocationError>
    var headerPublisher: AnyPublisher<CLHeading, LocationError>
    
    public override init() {
        location = PassthroughSubject<CLLocation, LocationError>()
        locationPublisher = location.eraseToAnyPublisher()
        heading = PassthroughSubject<CLHeading, LocationError>()
        headerPublisher = heading.eraseToAnyPublisher()
        super.init()
        manager.delegate = self
    }
}

// MARK: - Location Service
@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension LocationManager: LocationService {
    public func enableService() {
        manager.startUpdatingLocation()
    }
    public func disableService() {
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocation Delegate
@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension LocationManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        self.heading.send(heading)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.sorted(by: { $0.timestamp > $1.timestamp}).first else { return }
        self.location.send(location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.location.send(completion: .failure(.other(error: error)))
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            location.send(completion: .failure(.notAuthorized))
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            break
        @unknown default:
            location.send(completion: .failure(.unknown))
        }
    }
}
