import SwiftUI

@main
struct ChineseRussianDictionaryApp: App {
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
