import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { fetchContent, fetchParsedRSSList } from './feedAPI.js';
import { logger } from 'firebase-functions';
import { convertURL } from '../util.js';

if (!getApps().length) initializeApp()
const db = getFirestore()
const userRef = db.collection('user')
const feedRef = db.collection('feed')
const recommendFeedRef = db.collection('recommendFeed')
const fcmTokenRef = db.collection('fcmToken')

export async function updateFeedDB() {
	const userSnapshot = await userRef.get()
	const rssURLList = userSnapshot.docs.map(doc => {
		const blogURL = doc.data()['blogURL']
		const rssURL = convertURL(blogURL)
		return rssURL
	})
	const parsedRSSList = await fetchParsedRSSList(rssURLList)
	parsedRSSList.forEach(parsedRSS => updateFeedDBFromSingleBlog(parsedRSS))
}

export async function deleteRecommendFeeds() {
	await recommendFeedRef
		.get()
		.then((querySnapshot) => {
			querySnapshot.docs.forEach(async (doc) => {
				logger.log('test', doc.data()['feedUUID'])
				await deleteRecommendFeed(doc.id)
			})
		})
}

export async function updateRecommendFeedDB() {
	await deleteRecommendFeeds()

	await feedRef
		.orderBy('pubDate', 'desc')
		.limit(3)
		.get()
		.then((querySnapshot) => {
			querySnapshot.docs.forEach(async (doc) => {
				const feedUUID = doc.data()['feedUUID']
				await recommendFeedRef.doc(feedUUID).set(doc.data())
			})
		})
}

/**
 * 한 블로그의 RSS에 담겨있는 feed들을 DB에 저장한다.
 * @param {JSON} parsedRSS 
 */
async function updateFeedDBFromSingleBlog(parsedRSS) {
	const blogURL = parsedRSS.feed.link
	const writerUUID = await getFeedWriterUUID(blogURL)
	await parsedRSS.items.forEach(async (item) => {
		const feedUUID = item.link.hashCode()
		const docRef = feedRef.doc(feedUUID);
		await docRef.get()
			.then(doc => {
				if (doc.exists) {
					logger.log(item.link, 'is already exist')
					return
				}
				createFeedDataIfNeeded(docRef, writerUUID, feedUUID, item)
				logger.log(item.link, 'is created')
			})
	})
}

/**
 * DB에 한 포스트에 대한 정보를 저장한다.
 * @param {FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>} docRef feedData가 담길 Firestore의 doc 레퍼런스
 * @param {String} writerUUID 작성자의 UUID 값
 * @param {string} feedUUID feedURL을 hashing한 값
 * @param {JSON} feed RSS를 JSON으로 파싱한 정보
 */
async function createFeedDataIfNeeded(docRef, writerUUID, feedUUID, feed) {
	const content = await fetchContent(feed.link)
	docRef.set({
		// TODO: User db에서 UUID를 찾아 대입해주기
		feedUUID: feedUUID,
		writerUUID: writerUUID,
		title: feed.title,
		url: feed.link,
		thumbnail: feed.thumbnail,
		content: content,
		pubDate: Timestamp.fromDate(new Date(feed.pubDate)),
		regDate: Timestamp.now(),
	})
}

/**
 * 유저의 blogURL을 통해 db에서 유저를 찾고, 해당 유저의 UUID를 리턴한다.
 * @param {String} blogURL 유저의 블로그 URL이다. 끝에 '/'이 붙어서 넘어온다.
 * @returns 일치하는 유저의 UUID
 */
export async function getFeedWriterUUID(blogURL) {
	// https://stackoverflow.com/questions/46568142/google-firestore-query-on-substring-of-a-property-value-text-search/52715590#52715590
	logger.log('해당 유저의 blogURL', blogURL)
	return userRef
		.where('blogURL', '>=', blogURL.slice(0, -1))
		.where('blogURL', '<=', blogURL)
		.limit(1)
		.get()
		.then((querySnapshot) => {
			return querySnapshot.docs.at(0).id
		})
}

/**
 * @returns 푸시알림이 on 되어있는 유저의 UUID들
 */
export async function getUsersIsPushOnTrue() {
	const users = await userRef
		.where('isPushOn', '==', true)
		.get()

	const userUUIDs = []
	users.forEach((doc) => {
		userUUIDs.push(doc.data()['userUUID'])
	})

	return userUUIDs
}

/**
 * userUUID로 FCM Token을 찾는다.
 * @param {String} userUUID 
 * @returns userUUID에 해당하는 FCM Token
 */
export async function getFCMToken(userUUID) {
	logger.log('유저 아이디' + userUUID);
	return fcmTokenRef
		.doc(userUUID)
		.get()
		.then((doc) => {
			if (doc.exists) {
				return doc.data()['fcmToken'] 
			} else {
				return ''
			}
		})
}

/**
 * userUUID로 User를 찾는다.
 * @param {String} userUUID 
 * @returns user
 */
export async function getUser(userUUID) {
	return userRef
		.doc(userUUID)
		.get()
		.then((doc) => {
			return doc.data()
		})
}

/**
 * @returns 가장 최근의 Feed
 */
export async function getRecentFeed() {
	return await feedRef
		.orderBy('pubDate', 'desc')
		.limit(1)
		.get()
		.then((querySnapshot) => {
			return querySnapshot.docs.at(0).data()
		})
}

export async function deleteRecommendFeed(feedUUID) {
	logger.log('지울것들', feedUUID)
	const scrapUsersRef = recommendFeedRef
		.doc(feedUUID)
		.collection('scrapUsers')

	const batch  = db.batch();
	scrapUsersRef
		.get()
		.then((querySnapshot) => {
			querySnapshot.docs.forEach(async (doc) => {
				logger.log('삭제되는것', doc.id);
				batch.delete(doc.ref)
			})
		})
	await batch.commit();

	logger.log('스크랩 유저 삭제 후 feed 삭제')
	await recommendFeedRef
		.doc(feedUUID)
		.delete()
}

export async function deleteFeed(feedUUID) {
	logger.log('지울것들', feedUUID)
	const scrapUsersRef = feedRef
		.doc(feedUUID)
		.collection('scrapUsers')

	const batch  = db.batch();
	scrapUsersRef
		.get()
		.then((querySnapshot) => {
			querySnapshot.docs.forEach(async (doc) => {
				logger.log('삭제되는것', doc.id);
				batch.delete(doc.ref)
			})
		})
	await batch.commit();

	logger.log('스크랩 유저 삭제 후 feed 삭제')
	await feedRef
		.doc(feedUUID)
		.delete()
}

// MARK: 탈퇴

/**
 * FireStore FCM 삭제
 * @param {String} userUUID 
 */
export async function deleteFCMToken(userUUID) {
	logger.log('fcmToken을 삭제중')
	await fcmTokenRef.doc(userUUID).delete().then(() => {
		logger.log('fcmToken 삭제완료')
	})
}

/**
 * 내가 쓴 글 가져오기 - feed 중에서 writerUUID 가 userUUID와 일치하는 피드 UUID 가져오기
 * @param {String} userUUID 
 * @returns 해당 유저가 쓴 글
 */
export async function getUserFeedsUUIDs(userUUID) {
	logger.log('feed에서 유저가 쓴 글의 정보를 가져온다.')
	const querySnapshot = await feedRef
		.where('writerUUID', '==', userUUID)
		.get()
	
	const feedUUIDs = querySnapshot.docs.map(doc => {
		return doc.data()['feedUUID']
	})
	logger.log('유저가 쓴 글 들: ', feedUUIDs)

	return feedUUIDs
}

/**
 * 내가 쓴 글을 스크랩한 유저의 scrapFeedUUIDs 업데이트
 * @param {[String]} feedUUIDs 
 */
export async function updateUserScrapFeedUUIDs(feedUUIDs) {
	const batch = db.batch();

	logger.log('유저가 쓴 글의 feedUUIDs: ', feedUUIDs)
	logger.log('이 글을 스크랩한 유저를 찾는다.')

	feedUUIDs.forEach(async(feedUUID)=> {
		await userRef
			.where('scrapFeedUUIDs', 'array-contains', feedUUID)
			.get()
			.then((querySnapshot) => {
				logger.log('이 유저들의 스크랩 정보에서')
				querySnapshot.docs.forEach((doc) => {
					const userUUID = doc.data()['userUUID'];
					logger.log('이 유저의 정보에서', doc.data()['nickname'])
					const curFeedUUIDs = doc.data()['scrapFeedUUIDs']
					logger.log('삭제 전 피드들:', curFeedUUIDs)
					const deletedFeedUUIDs = curFeedUUIDs.filter(uuid => uuid != feedUUID)
					logger.log('삭제 후 피드들:', deletedFeedUUIDs)

					const curRef = userRef.doc(userUUID);
					batch.set(curRef, {'scrapFeddUUIDs': deletedFeedUUIDs})
				})
			})
	})

	batch.commit
}

/**
 * 내가 쓴 글들 삭제 후 recommend 재업데이트
 * @param {*} feedUUIDs 
 */
export async function deleteFeedsAndUpdateRecommendFeed(feedUUIDs) {
	logger.log('내가 쓴 글들 삭제 후 recommend 재업데이트')
	await feedUUIDs
		.forEach(async (feedUUID) => {
			await deleteFeed(feedUUID)
		})
	updateRecommendFeedDB()
}

/**
 * 유저가 스크랩한 피드 아이디들을 가져온다.
 * @param {String} userUUID 
 * @returns 유저가 스크랩한 피드들
 */
export async function getUserScrapFeedsUUIDs(userUUID) {
	return userRef
		.doc(userUUID)
		.get()
		.then((doc) => {
			logger.log('스크랩한 피드 아이디들:', doc.data()['scrapFeedUUIDs'])
			return doc.data()['scrapFeedUUIDs']
		})
}

/**
 * 내가 스크랩한 피드의 scrapUsers 에서 나의 userUUID를 지운다.
 * @param {String} userUUID 
 * @param {[String]} feedUUIDs 
 */
export async function deleteUserUUIDAtScrapFeed(userUUID, feedUUIDs) {
	logger.log('나는야 유저', userUUID)
	logger.log('유저가 스크랩 한 글의 feedUUIDs: ', feedUUIDs)

	feedUUIDs.forEach(async(feedUUID) => {
		await feedRef
			.doc(feedUUID)
			.collection('scrapUsers')
			.doc(userUUID)
			.delete()
			})
}

// 3. FireStore User 삭제
/**
 * 유저 삭제
 * @param {*} userUUID 
 */
export async function deleteUser(userUUID) {
	logger.log('유저를 삭제합니다.')
	userRef
		.doc(userUUID)
		.delete()
}