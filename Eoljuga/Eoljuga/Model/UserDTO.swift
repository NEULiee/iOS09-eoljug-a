//
//  UserDTO.swift
//  Eoljuga
//
//  Created by neuli on 2022/11/17.
//

import Foundation

struct FireStoreResult: Decodable {
    let document: DocumentResult
}

struct DocumentResult: Decodable {
    let fields: UserDTO
}

struct UserDTO: Codable {
    private let userUUID: FireStoreValues.StringValue
    private let name: FireStoreValues.StringValue
    private let profileImageURL: FireStoreValues.StringValue
    private let domain: FireStoreValues.StringValue
    private let camperID: FireStoreValues.StringValue
    private let blogUUID: FireStoreValues.StringValue
    private let signupDate: FireStoreValues.StringValue
    private let scrapFeedUUIDs: FireStoreValues.ArrayValue<FireStoreValues.StringValue>
    private let isPushNotification: FireStoreValues.BooleanValue

    private enum RootKey: String, CodingKey {
        case fields
    }

    private enum FieldKeys: String, CodingKey {
        case userUUID
        case name
        case profileImageURL
        case domain
        case caperID
        case blogUUID
        case signupDate
        case scrapFeedUUIDs
        case isPushNotification
    }

    init(user: User) {
        self.userUUID = FireStoreValues.StringValue(value: user.userUUID)
        self.name = FireStoreValues.StringValue(value: user.name)
        self.profileImageURL = FireStoreValues.StringValue(value: user.profileImageURL)
        self.domain = FireStoreValues.StringValue(value: user.domain.rawValue)
        self.camperID = FireStoreValues.StringValue(value: user.camperID)
        self.blogUUID = FireStoreValues.StringValue(value: user.blogUUID)
        self.signupDate = FireStoreValues.StringValue(value: user.signupDate)
        self.scrapFeedUUIDs = FireStoreValues.ArrayValue<FireStoreValues.StringValue>(
            values: user.scrapFeedUUIDs.map {
            FireStoreValues.StringValue(value: $0)
            }
        )
        self.isPushNotification = FireStoreValues.BooleanValue(value: user.isPushNotification)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userUUID = try container.decode(
            FireStoreValues.StringValue.self,
            forKey: .userUUID
        )
        self.name = try container.decode(
            FireStoreValues.StringValue.self,
            forKey: .name
        )
        self.profileImageURL = try container.decode(
            FireStoreValues.StringValue.self,
            forKey: .profileImageURL
        )
        self.domain = try container.decode(
            FireStoreValues.StringValue.self,
            forKey: .domain
        )
        self.camperID = try container.decode(
            FireStoreValues.StringValue.self,
            forKey: .camperID
        )
        self.blogUUID = try container.decode(
            FireStoreValues.StringValue.self,
            forKey: .blogUUID
        )
        self.signupDate = try container.decode(
            FireStoreValues.StringValue.self,
            forKey: .signupDate
        )
        self.scrapFeedUUIDs = try container.decode(
            FireStoreValues.ArrayValue<FireStoreValues.StringValue>.self,
            forKey: .scrapFeedUUIDs
        )
        self.isPushNotification = try container.decode(
            FireStoreValues.BooleanValue.self,
            forKey: .isPushNotification
        )
    }

    func toUser() -> User {
        return User(
            userUUID: userUUID.value,
            name: name.value,
            profileImageURL: profileImageURL.value,
            domain: Domain(rawValue: domain.value) ?? .iOS,
            camperID: camperID.value,
            blogUUID: blogUUID.value,
            signupDate: signupDate.value,
            scrapFeedUUIDs: scrapFeedUUIDs
                .arrayValue["values"]?
                .compactMap { $0.value } ?? [],
            isPushNotification: isPushNotification.value)
    }
}
