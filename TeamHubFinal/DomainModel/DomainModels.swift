//
//  DomainModels.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
struct Phone: Identifiable, Equatable, Hashable {
    let id: String
    let type: String
    let number: String
}

struct Employee: Identifiable, Equatable, Hashable{
    let id: String
    let name: String
    let designation: String
    let department: String
    let isActive: Bool
    let imgUrl: String?
    let email: String
    let city: String
    let joiningDate: String?
    let country: String
    let phones: [Phone]
}

