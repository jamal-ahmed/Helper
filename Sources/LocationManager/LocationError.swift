public enum LocationError: Error {
    case notAuthorized
    case serviceUnavailable
    case unableToFindLocation
    case unableToDetermineHeading
    case unknown
    case other(error: Error)
}
