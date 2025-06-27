import SwiftUI

@main
struct iOS_Platform_AssessmentApp: App {
  private let appStartDate: Date = .now

  var body: some Scene {
    WindowGroup {
      RootView()
        .onAppear {
          MetricsLogger.shared.logAppStart(appStartDate)
          MetricsLogger.shared.save()
        }
    }
  }
}
