//
//  NetworkError.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
enum NetworkError: Error {
    case invalidURL
    case server
    case decoding
    case duplicateError(message: String)
}
