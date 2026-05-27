import CoreLocation
import Foundation

/// GPS konumu; izin yoksa Gelibolu varsayılanı.
@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<GeoLocation, Never>?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async -> GeoLocation {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        guard CLLocationManager.locationServicesEnabled() else {
            return .gelibolu
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return await withCheckedContinuation { cont in
                self.continuation = cont
                manager.requestLocation()
            }
        default:
            return .gelibolu
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let loc = locations.first else { return }
        Task { @MainActor in
            let geo = GeoLocation(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                label: "GPS konumu",
                isFallback: false
            )
            GeoLocation.saveLastKnown(geo)
            continuation?.resume(returning: geo)
            continuation = nil
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            continuation?.resume(returning: .gelibolu)
            continuation = nil
        }
    }
}
