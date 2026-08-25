import Foundation

public enum SandboxProfile: String, Codable, CaseIterable, Sendable {
    case fast
    case challenge
    case fullLab

    public func includes(_ scenarioProfile: SandboxProfile) -> Bool {
        switch self {
        case .fast:
            return scenarioProfile == .fast
        case .challenge:
            return scenarioProfile == .fast || scenarioProfile == .challenge
        case .fullLab:
            return true
        }
    }
}
