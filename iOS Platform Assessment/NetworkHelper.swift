//
//  NetworkHelper.swift
//  iOS Platform Assessment
//
//  Created by Simon Bromberg on 2025-06-22.
//

import Foundation

protocol DataProvider {
  func getVehicles(startCursor: String?) async throws -> (results: [Vehicle], paging: Paging)
}

struct Paging {
  let nextCursor: String?
  let estimatedRemainingCount: Int
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

      return URL(string: path, relativeTo: URL(string: base))
    }
  }

  init(baseURL: String = .defaultAPIURL) {
    self.baseURL = baseURL
  }

  let baseURL: String

  func getVehicles(startCursor: String?) async throws -> (results: [Vehicle], paging: Paging) {
    let startDate: Date = .now

    guard let vehiclesURL = Endpoint.vehicles.url(base: baseURL),
          var components = URLComponents(url: vehiclesURL, resolvingAgainstBaseURL: true) else {
      throw NetworkError.invalidURL
    }

    if let startCursor {
      components.queryItems = [
        .init(name: "start_cursor", value: startCursor),
      ]
    }

    guard let url = components.url else {
      throw NetworkError.invalidURL
    }

    guard let apiKey = CredentialStore.apiKey, let accountToken = CredentialStore.accountToken else {
      throw NetworkError.unauthorized
    }

    var request = URLRequest(url: url)
    request.addValue(accountToken, forHTTPHeaderField: "Account-Token")
    request.addValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")


    let (data, _) = try await URLSession.shared.data(for: request)

    //    let responseBody = String(data: data, encoding: .utf8) ?? "No readable data"
    //    print(responseBody)

    let decoder = DataDecoder()

    let vehicles = try decoder.decodeVehicles(data: data)

    MetricsLogger.shared.logAPICall(endpoint: "vehicles", start: startDate)
    MetricsLogger.shared.save()

    return vehicles
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

  func decodeVehicles(data: Data) throws -> (results: [Vehicle], paging: Paging) {
    let response = try decoder.decode(VehiclesResponse.self, from: data)
    return (
      response.records.vehicleModels,
      .init(
        nextCursor: response.nextCursor,
        estimatedRemainingCount: response.estimatedRemainingCount
      )
    )
  }
}

struct SampleDataProvider: DataProvider {
  let mockNetworkDelaySeconds: Int = 2
  func getVehicles(startCursor: String?) async throws -> (results: [Vehicle], paging: Paging) {
    try? await Task.sleep(nanoseconds: UInt64(mockNetworkDelaySeconds) * 1_000_000_000)
    // TODO: could implement paging with sample data as well
    return (
      SampleData.vehicleList,
      .init(
        nextCursor: nil,
        estimatedRemainingCount: 0
      )
    )
  }
}

private extension String {
  static let defaultAPIURL = "https://secure.fleetio.com/api/v1/"
}
