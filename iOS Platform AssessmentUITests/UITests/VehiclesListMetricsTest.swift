//
//  VehiclesListMetricsTest.swift
//  iOS Platform AssessmentUITests
//
//  Created by Simon Bromberg on 2025-06-27.
//

import XCTest

final class VehiclesListMetricsTest: UITest {
  func test_AppLaunchLoadVehiclesMetrics() throws {
    LoginScreenActions()
      .iLogin(accountToken: Utils.defaultAccountToken, apiKey: Utils.defaultApiKey)
    HomeScreenActions()
      .iTapBrowseTab()
    BrowseScreenActions()
      .iTapVehiclesButton()

    let label = app.staticTexts["Sierra 1500"] // placeholder, ensure API call finishes before test ends

    // Wait up to 10 seconds for the text to appear
    let exists = label.waitForExistence(timeout: 10)

    XCTAssertTrue(exists, "Expected text did not appear")

    // Simplified implementation, real reporting system would be more elaborate / note this will only work for tests run on a simulator

    guard let metrics = MetricsLogger.loadFromFile() else {
      XCTFail("Missing metrics file")
      return
    }
    print(metrics)

    let metricsString = metrics.toString()
    let attachment = XCTAttachment(string: metricsString)
    attachment.name = "Performance Metrics"
    attachment.lifetime = .keepAlways
    add(attachment)

    appendResultsToFile(metricsString)
  }

  func appendResultsToFile(_ metrics: String) {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsURL.appendingPathComponent("metrics.txt")
    if FileManager.default.fileExists(atPath: fileURL.path) {
      do {
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        try fileHandle.seekToEnd()
        if let data = ("\n" + metrics).data(using: .utf8) {
          fileHandle.write(data)
        }
        try fileHandle.close()
      } catch {
        XCTFail("Append metrics failure: \(error)")
      }
    } else {
      do {
        try metrics.write(to: fileURL, atomically: true, encoding: .utf8)
      } catch {
        XCTFail("Write new file for metrics error: \(error)")
      }
    }
    print("Documents URL: \(documentsURL)") // search for "Documents URL" in test log in reports navigator to find output location for analysis
    // file would need to be deleted manually for now once the 10 runs are complete
  }
}
