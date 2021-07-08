import CoreLocation
import Combine

public final class LocationManager: NSObject {
    private let manager: CLLocationManager
    private let location: PassthroughSubject<CLLocation, LocationError>
    private let heading: PassthroughSubject<CLHeading, LocationError>
    var locationPublisher: AnyPublisher<CLLocation, LocationError>
    var headerPublisher: AnyPublisher<CLHeading, LocationError>
    
    init() {
        location = PassthroughSubject<CLLocation, LocationError>()
        locationPublisher = location.eraseToAnyPublisher()
        header = PassthroughSubject<CLHeading, LocationError>()
        headerPublisher = heading.eraseToAnyPublisher()
        super.init()
        manager.delegate = self
    }
}

// MARK: - Location Service
public extension LocationManager: LocationService {
    func enableService() {
        manager.startUpdatingLocation()
    }
    func disableService() {
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocation Delegate
private extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        self.heading.send(heading)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.sorted(by: { $0.timestamp > $1.timestamp}).first else { return }
        self.location.send(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.location.send(completion: .failure(.other(error: error)))
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
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
