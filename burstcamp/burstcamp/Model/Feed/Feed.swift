//
//  Feed.swift
//  burstcamp
//
//  Created by youtak on 2022/11/24.
//

import Foundation

struct Feed {
    let feedUUID: String
    let writer: FeedWriter
    let title: String
    let pubDate: Date
    let url: String
    let thumbnailURL: String
    let content: String
    var scrapCount: Int

    init(feedDTO: FeedDTO, feedWriter: FeedWriter, scrapCount: Int = 0) {
        self.feedUUID = feedDTO.feedUUID
        self.writer = feedWriter
        self.title = feedDTO.title
        self.pubDate = feedDTO.pubDate
        self.url = feedDTO.url
        self.thumbnailURL = feedDTO.thumbnailURL
        self.content = feedDTO.content
        self.scrapCount = scrapCount
    }

    mutating func scrapCountUp() {
        scrapCount += 1
    }

    mutating func scrapCountDown() {
        if scrapCount > 0 {
            scrapCount -= 1
        }
    }
}
