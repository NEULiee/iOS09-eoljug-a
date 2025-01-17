//
//  FeedWriter.swift
//  burstcamp
//
//  Created by youtak on 2022/11/30.
//

import Foundation

struct FeedWriter {
    let nickname: String
    let camperID: String
    let ordinalNumber: Int
    let domain: Domain
    let profileImageURL: String
    let blogTitle: String

    init(
        nickname: String,
        camperID: String,
        ordinalNumber: Int,
        domain: Domain,
        profileImageURL: String,
        blogTitle: String
    ) {
        self.nickname = nickname
        self.camperID = camperID
        self.ordinalNumber = ordinalNumber
        self.domain = domain
        self.profileImageURL = profileImageURL
        self.blogTitle = blogTitle
    }

    init(data: [String: Any]) {
        let nickname = data["nickname"] as? String ?? ""
        let camperID = data["camperID"] as? String ?? ""
        let ordinalNumber = data["ordinalNumber"] as? Int ?? 0
        let domainString = data["domain"] as? String ?? ""
        let domain = Domain(rawValue: domainString) ?? Domain.iOS
        let profileImageURL = data["profileImageURL"] as? String ?? ""
        let blogTitle = data["blogTitle"] as? String ?? ""

        self.nickname = nickname
        self.camperID = camperID
        self.ordinalNumber = ordinalNumber
        self.domain = domain
        self.profileImageURL = profileImageURL
        self.blogTitle = blogTitle
    }
}
