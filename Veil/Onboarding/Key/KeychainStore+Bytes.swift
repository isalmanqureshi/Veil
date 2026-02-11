//
//  KeychainStore+Bytes.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//

import Foundation

extension KeychainStore {

    func saveString(_ value: String, service: String, account: String) throws {
        try save(Data(value.utf8), service: service, account: account)
    }

    func loadString(service: String, account: String) throws -> String? {
        guard let data = try load(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
