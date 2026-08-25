import Foundation
@testable import GadgetBuddyCore

enum FixtureLoaderError: Error, Equatable {
    case missingResource(String)
}

enum FixtureLoader {
    static func load(_ name: String) throws -> [SandboxScenario] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw FixtureLoaderError.missingResource(name)
        }
        return try JSONDecoder().decode([SandboxScenario].self, from: Data(contentsOf: url))
    }
}
