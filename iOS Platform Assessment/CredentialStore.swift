//
//  CredentialStore.swift
//  iOS Platform Assessment
//
//  Created by Simon Bromberg on 2025-06-24.
//

import Foundation
import Security

// Parts of this file were adapted from https://stackoverflow.com/questions/37539997/save-and-load-from-keychain-swift

struct KeychainHelper {
  // MARK: - String helpers
  
  @discardableResult
  static func save(value: String?, key: String) -> OSStatus? {
    guard let data = value?.data(using: .utf8) else {
      print("Error saving value for \(key)")
      return nil
    }
    return save(key: key, data: data)
  }
  
  static func loadString(key: String) -> String? {
    guard let data = load(key: key) else {
      return nil
    }
    return .init(data: data, encoding: .utf8)
  }
  
  // MARK: - Generalized functions
  
  @discardableResult
  static func save(key: String, data: Data?) -> OSStatus {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword as String,
      kSecAttrAccount as String: key
    ]
    let deletionStatus = SecItemDelete(query as CFDictionary)
    
    guard let data else {
      return deletionStatus
    }
    
    query[kSecValueData as String] = data
    
    return SecItemAdd(query as CFDictionary, nil)
  }
  
  static func load(key: String) -> Data? {
    let query = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne ] as [String: Any]
    
    var dataTypeRef: AnyObject? = nil
    
    let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    if status == noErr {
      return dataTypeRef as! Data?
    } else {
      return nil
    }
  }
}

struct CredentialStore {
  static var apiKey: String? {
    get {
      KeychainHelper.loadString(key: #function)
    }
    set {
      KeychainHelper.save(value: newValue, key: #function)
    }
  }
  
  static var accountToken: String? {
    get {
      KeychainHelper.loadString(key: #function)
    }
    set {
      KeychainHelper.save(value: newValue, key: #function)
    }
  }
}
