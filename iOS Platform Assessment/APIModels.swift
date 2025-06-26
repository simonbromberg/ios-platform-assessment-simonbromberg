//
//  APIModels.swift
//  iOS Platform Assessment
//
//  Created by Simon Bromberg on 2025-06-23.
//

import Foundation

/// Vehicles

struct VehiclesResponse: Decodable {
  // MARK - Pagination
  let startCursor: String
  let nextCursor: String?
  let perPage: Int
  let estimatedRemainingCount: Int
  
  // MARK: - Vehicles
  let records: [Vehicle]
  
  /// Workaround for `year` being a number when a string is expected, remove when fixed
  struct Vehicle: Decodable {
    let id: Int
    let name: String
    let model: String
    let year: String
    let make: String
    
    let vehicleStatusId: Int
    let vehicleStatusName: String
    let vehicleStatusColor: String
    
    let currentLocationEntryId: Int?
    let customFields: CustomFields
    
    enum CodingKeys: CodingKey {
      case id
      case name
      case model
      case year
      case make
      case vehicleStatusId
      case vehicleStatusName
      case vehicleStatusColor
      case currentLocationEntryId
      case customFields
    }
    
    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try container.decode(Int.self, forKey: .id)
      self.name = try container.decode(String.self, forKey: .name)
      self.model = try container.decode(String.self, forKey: .model)
      self.year = String(try container.decode(Int.self, forKey: .year)) // workaround
      self.make = try container.decode(String.self, forKey: .make)
      
      self.vehicleStatusId = try container.decode(Int.self, forKey: .vehicleStatusId)
      self.vehicleStatusName = try container.decode(String.self, forKey: .vehicleStatusName)
      self.vehicleStatusColor = try container.decode(String.self, forKey: .vehicleStatusColor)
      
      self.currentLocationEntryId = try? container.decode(Int.self, forKey: .currentLocationEntryId)
      
      self.customFields = try container.decode(CustomFields.self, forKey: .customFields) // TODO
    }
  }
  
  struct CustomFields: Decodable {
    let name: String?
  }
}

extension Array where Element == VehiclesResponse.Vehicle {
  var vehicleModels: [Vehicle] {
    map {
      .init(
        id: $0.id,
        name: $0.name,
        model: $0.model,
        year: $0.year,
        make: $0.make,
        status: $0.vehicleStatusName,
        location: "", // FIXME: get location name
        customName: $0.customFields.name ?? ""
      )
    }
  }
}
