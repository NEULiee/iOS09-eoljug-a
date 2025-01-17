//
//  FeedCellType.swift
//  Eoljuga
//
//  Created by youtak on 2022/11/19.
//

import Foundation

enum FeedCellType: Int, CaseIterable {
    case recommend
    case normal
}

extension FeedCellType {
    init?(index: Int) {
        self.init(rawValue: index)
    }

    var columnCount: Int {
        switch self {
        case .recommend: return 1
        case .normal: return 1
        }
    }

    var index: Int {
        switch self {
        case .recommend: return 0
        case .normal: return 1
        }
    }
    static var count: Int {
        return FeedCellType.allCases.count
    }
}
