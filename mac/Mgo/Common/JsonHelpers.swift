//
//  JsonHelpers.swift
//  Mgo
//
//  Created by Jose Dias on 05/12/2023.
//

import Foundation

struct FailableDecodable<Base : Decodable> : Decodable {

    let base: Base?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.base = try? container.decode(Base.self)
    }
}

func readJsonArrayFromFile<T>(atPath path: String) -> [T]? where T: Decodable {
    let url = URL(fileURLWithPath: path)
    
    do {
        let json = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decodedData = try decoder.decode([FailableDecodable<T>].self, from: json)
        return decodedData.compactMap { $0.base }
    }
    catch {
        Info.add("Error during JSON deserialization: \(error.localizedDescription)")
        return nil
    }
}
