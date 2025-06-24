//
//  APIDecodingTests.swift
//  iOS Platform AssessmentTests
//
//  Created by Simon Bromberg on 2025-06-24.
//

import Foundation
import Testing
@testable import iOS_Platform_Assessment

class TestClass {
  var bundle: Bundle {
    Bundle(for: type(of: self))
  }
}

struct APIDecodingTests {
  func loadJSONFromFile(named fileName: String) throws -> Data {
    let bundle = TestClass().bundle
    guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
      throw NSError(domain: "FileNotFound", code: 1, userInfo: nil)
    }
    return try Data(contentsOf: url)
  }
  
  @Test func vehicles() async throws {
    let decoder = DataDecoder()
    let data = try loadJSONFromFile(named: "Vehicles")
    let vehicles = try decoder.decodeVehicles(data: data)

    #expect(vehicles.count == 50)
    #expect(vehicles.first?.name == "2024 GMC Sierra 1500 SLT")
    #expect(vehicles.first?.status == "Active")
    #expect(vehicles.last?.year == "2024")
  }
  
}
