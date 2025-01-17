//
//  HomeViewModel.swift
//  Eoljuga
//
//  Created by youtak on 2022/11/21.
//

import Combine
import Foundation

final class HomeViewModel {

    var recommendFeedData: [Feed] = []
    var normalFeedData: [Feed] = []

    private let firestoreFeedService: BeforeFirestoreFeedService
    private var cellUpdate = PassthroughSubject<IndexPath, Never>()
    private var cancelBag = Set<AnyCancellable>()

    private var isFetching: Bool = false
    private var canFetchMoreFeed: Bool = true

    init(firestoreFeedService: BeforeFirestoreFeedService) {
        self.firestoreFeedService = firestoreFeedService
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let viewRefresh: AnyPublisher<Bool, Never>
        let pagination: AnyPublisher<Void, Never>
    }

    enum FetchResult {
        case fetchFail(error: Error)
        case fetchSuccess
    }

    struct Output {
        var fetchResult = PassthroughSubject<FetchResult, Never>()
        var cellUpdate: AnyPublisher<IndexPath, Never>
    }

    func transform(input: Input) -> Output {
        let output = Output(
            cellUpdate: cellUpdate.eraseToAnyPublisher()
        )

        input.viewDidLoad
            .sink { [weak self] _ in
                self?.fetchAllFeed(output: output)
            }
            .store(in: &cancelBag)

        input.viewRefresh
            .sink { [weak self] _ in
                self?.fetchAllFeed(output: output)
            }
            .store(in: &cancelBag)

        input.pagination
            .sink { [weak self] _ in
                self?.paginateFeed(output: output)
            }
            .store(in: &cancelBag)

        return output
    }

    func dequeueCellViewModel(at index: Int) -> FeedScrapViewModel {
        let firestoreFeedService = BeforeDefaultFirestoreFeedService()
        let feedScrapViewModel = FeedScrapViewModel(
            feedUUID: normalFeedData[index].feedUUID,
            firestoreFeedService: firestoreFeedService
        )
        feedScrapViewModel.getScrapCountUp
            .sink { [weak self] state in
                guard let self = self else { return }
                if state {
                    self.normalFeedData[index].scrapCountUp()
                } else {
                    self.normalFeedData[index].scrapCountDown()
                }
                let indexPath = IndexPath(row: index, section: FeedCellType.normal.index)
                self.cellUpdate.send(indexPath)
            }
            .store(in: &cancelBag)

        return feedScrapViewModel
    }

    private func fetchAllFeed(output: Output) {
        Task {
            do {
                guard !isFetching else { return }
                isFetching = true
                canFetchMoreFeed = true

                async let recommendFeeds = fetchRecommendFeeds()
                async let normalFeeds = fetchLastestFeeds()
                self.recommendFeedData = try await recommendFeeds
                self.normalFeedData = try await normalFeeds
                output.fetchResult.send(.fetchSuccess)
            } catch {
                canFetchMoreFeed = false
                output.fetchResult.send(.fetchFail(error: error))
            }
            isFetching = false
        }
    }

    private func paginateFeed(output: Output) {
        Task {
            do {
                guard !isFetching, canFetchMoreFeed else {
                    return
                }
                isFetching = true

                let normalFeeds = try await fetchMoreFeeds()
                self.normalFeedData.append(contentsOf: normalFeeds)
                output.fetchResult.send(.fetchSuccess)
            } catch {
                canFetchMoreFeed = false
                output.fetchResult.send(.fetchFail(error: error))
            }
            isFetching = false
        }
    }

    private func fetchRecommendFeeds() async throws -> [Feed] {
        try await withThrowingTaskGroup(of: Feed.self, body: { taskGroup in
            var recommendFeeds: [Feed] = []
            let feedDTODictionary = try await self.firestoreFeedService.fetchRecommendFeedDTOs()

            for feedDTO in feedDTODictionary {
                taskGroup.addTask {
                    let feedDTO = FeedDTO(data: feedDTO)
                    let feedWriterDictionary = try await self.firestoreFeedService.fetchUser(
                        userUUID: feedDTO.writerUUID
                    )
                    let feedWriter = FeedWriter(data: feedWriterDictionary)
                    let feed = Feed(feedDTO: feedDTO, feedWriter: feedWriter)
                    return feed
                }
            }

            for try await feed in taskGroup {
                recommendFeeds.append(feed)
            }

            return recommendFeeds
        })
    }

    private func fetchLastestFeeds() async throws -> [Feed] {
        try await withThrowingTaskGroup(of: Feed.self, body: { taskGroup in
            var normalFeeds: [Feed] = []
            let feedDTODictionary = try await self.firestoreFeedService.fetchLatestFeedDTOs()

            for feedDTO in feedDTODictionary {
                taskGroup.addTask {
                    let feedDTO = FeedDTO(data: feedDTO)
                    let feedWriterDictionary = try await self.firestoreFeedService.fetchUser(
                        userUUID: feedDTO.writerUUID
                    )
                    let feedWriter = FeedWriter(data: feedWriterDictionary)
                    let scrapCount = try await self.firestoreFeedService.countFeedScarp(
                        feedUUID: feedDTO.feedUUID
                    )
                    let feed = Feed(
                        feedDTO: feedDTO,
                        feedWriter: feedWriter,
                        scrapCount: scrapCount
                    )
                    return feed
                }
            }

            for try await feed in taskGroup {
                normalFeeds.append(feed)
            }

            let result = normalFeeds.sorted { $0.pubDate > $1.pubDate }

            return result
        })
    }

    private func fetchMoreFeeds() async throws -> [Feed] {
        try await withThrowingTaskGroup(of: Feed.self, body: { taskGroup in
            var normalFeeds: [Feed] = []
            let feedDTODictionary = try await self.firestoreFeedService.fetchMoreFeeds()

            for feedDTO in feedDTODictionary {
                taskGroup.addTask {
                    let feedDTO = FeedDTO(data: feedDTO)
                    print(feedDTO.writerUUID)
                    let feedWriterDictionary = try await self.firestoreFeedService.fetchUser(
                        userUUID: feedDTO.writerUUID
                    )
                    let feedWriter = FeedWriter(data: feedWriterDictionary)
                    let scrapCount = try await self.firestoreFeedService.countFeedScarp(
                        feedUUID: feedDTO.feedUUID
                    )
                    let feed = Feed(
                        feedDTO: feedDTO,
                        feedWriter: feedWriter,
                        scrapCount: scrapCount
                    )
                    return feed
                }
            }

            for try await feed in taskGroup {
                normalFeeds.append(feed)
            }

            let result = normalFeeds.sorted { $0.pubDate > $1.pubDate }

            return result
        })
    }
}
