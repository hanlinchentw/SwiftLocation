import Foundation
import CoreLocation

extension Tasks {
    
    public final class LocatePermission: AnyTask {
        public typealias Continuation = CheckedContinuation<CLAuthorizationStatus, Error>
        
        public let uuid = UUID()
        public var cancellable: CancellableTask?
        var continuation: Continuation?
        
        private weak var instance: Location?
        
        init(instance: Location) {
            self.instance = instance
        }
        
        public func receivedLocationManagerEvent(_ event: LocationManagerBridgeEvent) {
            switch event {
            case .didChangeAuthorization(let authorization):
                guard let continuation = continuation else {
                    cancellable?.cancel(task: self)
                    return
                }
                
                continuation.resume(returning: authorization)
                self.continuation = nil
                cancellable?.cancel(task: self)
            default:
                break
            }
        }
        
        func requestWhenInUsePermission() async throws -> CLAuthorizationStatus {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                let isAuthorized = instance.authorizationStatus != .notDetermined
                guard !isAuthorized else {
                    continuation.resume(returning: instance.authorizationStatus)
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestWhenInUseAuthorization()
            }
        }
        
        func requestAlwaysPermission() async throws -> CLAuthorizationStatus {
            try await withCheckedThrowingContinuation { continuation in
                guard let instance = self.instance else { return }
                
                let isAuthorized = instance.authorizationStatus != .notDetermined && instance.authorizationStatus != .authorizedWhenInUse
                guard !isAuthorized else {
                    continuation.resume(with: .success(instance.authorizationStatus))
                    return
                }
                
                self.continuation = continuation
                instance.asyncBridge.add(task: self)
                instance.locationManager.requestAlwaysAuthorization()
            }
        }
        
    }
    
}
