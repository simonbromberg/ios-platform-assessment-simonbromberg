//
//  AnalyticsLogger.swift
//  iOS Platform Assessment
//
//  Created by Simon Bromberg on 2025-06-26.
//

import Foundation

struct Metrics: Codable {
  var appStartTime: TimeInterval?
  var pageLoadTimes: [String: TimeInterval] = [:]
  var apiCallDurations: [String: TimeInterval] = [:]

  func toString() -> String {
    "appStartTime: \(appStartTime ?? -1)\npageLoadTimes:\(pageLoadTimes)\napiCallDurations:\(apiCallDurations)"
  }
}

final class MetricsLogger {
  static let shared = MetricsLogger()
  var metrics = Metrics()

  func logAppStart(_ appStart: Date) {
    metrics.appStartTime = Date.now.timeIntervalSince(appStart)
  }

  func logPageLoad(page: String, start: Date) {
    metrics.pageLoadTimes[page] = Date.now.timeIntervalSince(start)
  }

  func logAPICall(endpoint: String, start: Date) {
    metrics.apiCallDurations[endpoint] = Date().timeIntervalSince(start)
  }

  func save() {
    guard let url = try? MetricsLogger.metricsURL() else {
      return
    }

    do {
      let data = try JSONEncoder().encode(metrics)
      try data.write(to: url)
    } catch {
      print("Error saving metrics: \(error)")
    }
  }

  static func loadFromFile() -> Metrics? {
    guard let url = try? metricsURL() else {
      return nil
    }

    do {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(Metrics.self, from: data)
    } catch {
      print("Error loading metrics from file: \(error)")
    }

    return nil
  }

  static func metricsURL() throws -> URL? {
    guard let simulatorSharedDirectory = ProcessInfo().environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] else {
      return nil
    }
    let simulatorHomeURL = URL(fileURLWithPath: simulatorSharedDirectory)
    let sharedFolderURL = simulatorHomeURL.appendingPathComponent("FleetioMetrics")
    try FileManager.default.createDirectory(
      at: sharedFolderURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    return sharedFolderURL.appendingPathComponent("metrics.json")
  }
}
