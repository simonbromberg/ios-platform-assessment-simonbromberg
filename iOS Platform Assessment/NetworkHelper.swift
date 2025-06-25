//
//  NetworkHelper.swift
//  iOS Platform Assessment
//
//  Created by Simon Bromberg on 2025-06-22.
//

import Foundation

protocol DataProvider {
  func getVehicles() async throws -> [Vehicle]
}

struct NetworkHelper: DataProvider {
  enum Endpoint {
    case vehicles
    case locationEntry(equipmentId: Int, locationEntryId: Int)
    
    func url(base: String) -> URL? {
      let path: String = {
        switch self {
        case .vehicles:
          "vehicles"
        case .locationEntry(let vehicleId, let locationEntryId):
          "vehicles/\(vehicleId)/location_entries/\(locationEntryId)"
        }
      }()
        
      return URL(string: base + path)
    }
  }
  
  init(baseURL: String = .defaultAPIURL) {
    self.baseURL = baseURL
  }
  
  let baseURL: String
  
  func getVehicles() async throws -> [Vehicle] {
    guard let vehiclesURL = Endpoint.vehicles.url(base: baseURL) else {
      throw NetworkError.invalidURL
    }
    
    guard let apiKey = CredentialStore.apiKey, let accountToken = CredentialStore.accountToken else {
      throw NetworkError.unauthorized
    }
    
    var request = URLRequest(url: vehiclesURL)
    request.addValue(accountToken, forHTTPHeaderField: "Account-Token")
    request.addValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
    
    
    let (data, _) = try await URLSession.shared.data(for: request)
    
//    let responseBody = String(data: data, encoding: .utf8) ?? "No readable data"
//    print(responseBody)
    
    let decoder = DataDecoder()
    
    return try decoder.decodeVehicles(data: data)
  }
  
  enum NetworkError: Error {
    case invalidURL
    case unauthorized
  }
}

struct DataDecoder {
  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
  
  func decodeVehicles(data: Data) throws -> [Vehicle] {
    try decoder.decode(VehiclesResponse.self, from: data).records.vehicleModels
  }
}

struct SampleDataProvider: DataProvider {
  let mockNetworkDelaySeconds: Int = 2
  func getVehicles() async throws -> [Vehicle] {
    try? await Task.sleep(nanoseconds: UInt64(mockNetworkDelaySeconds) * 1_000_000_000)
    return SampleData.vehicleList
  }
}

private extension String {
  static let defaultAPIURL = "https://secure.fleetio.com/api/v1/"
}
