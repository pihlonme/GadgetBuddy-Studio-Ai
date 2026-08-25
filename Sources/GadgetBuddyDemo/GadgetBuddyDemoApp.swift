import GadgetBuddyUI
import SwiftUI

@main
struct GadgetBuddyDemoApp: App {
    @StateObject private var model = SongCommandScreenModel()

    var body: some Scene {
        WindowGroup("GadgetBuddy Studio AI") {
            SongCommandScreen(model: model)
                .frame(minWidth: 620, minHeight: 640)
        }
    }
}
