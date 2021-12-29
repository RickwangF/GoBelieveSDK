//
// Created by Nan Yang on 2021/12/23.
//

import Foundation
import JiuFoundation

public final class ConversationDatabase: NSObject, GoConversationDatabase {
    public var conversationTableId: Int = 0

    @inlinable
    @available(*, deprecated, renamed:"shared")
    public static var instance: GoConversationDatabase {
        shared
    }

    @inlinable
    @objc(sharedInstance)
    public static var shared: GoConversationDatabase {
        _shared
    }

    @usableFromInline
    static let _shared = ConversationDatabase()

    private var dataSource: ConversationDataSource?

    public override init() {
        super.init()
    }

    public static func setDataBaseQueuePath(_ path: String) {
        let database: ConversationDataSource
        do {
            database = try ConversationDataSource(path: path)
        } catch {
#if DEBUG
            print(#fileID, #function, error)
#endif
            return
        }
        _shared.dataSource = database
    }

    public func add(_ conversation: Conversation) -> Bool {
        dataSource?.insert(record: ConversationRecord(from: conversation)) ?? false
    }

    public func add(_ conversation: Conversation, completion: ((Bool) -> Void)?) {
        dataSource?.insertAsync(record: ConversationRecord(from: conversation)) { result in
            completion?(result.isSuccess)
        }
    }

    public func getSortTopChatConversation(completion: @escaping ([Conversation]) -> Void) {
        dataSource?.sortedConversation { result in
            completion(result.unwrap(or: []).map(ConversationRecordData.init(record:)))
        }
    }

    public func clearAllConversationCompletion(_ completion: ((Bool) -> Void)?) {
        dataSource?.removeAll { result in
            completion?(result.isSuccess)
        }
    }

    public func deleteConversation(withUid uid: Int64) {
        dataSource?.remove(uid: uid, completion: Function.nothing)
    }

    public func clearConversationMsgCount(withUid uid: Int64) {
        _ = dataSource?.updateOne(uid: uid) { record in
            record.newMessageCount = 0
            return [ConversationRecord.CodingKeys.newMessageCount.rawValue]
        }
    }

    public func saveDraftToConversation(withUid uid: Int64, draft: String) {
        _ = dataSource?.updateOne(uid: uid) { record in
            record.draft = draft
            return [ConversationRecord.CodingKeys.draft.rawValue]
        }
    }

    public func saveDraftMessage(withUid uid: Int64, draft: String, conversation newConversation: Conversation) {
        _  = dataSource?.insertOne(uid: uid) {
            ConversationRecord(from: newConversation)
        } update: { record in
            record.draft = draft
            return [ConversationRecord.CodingKeys.draft.rawValue]
        }
    }

    public func disposeConversationIsTop(_ isTop: Bool, uid: Int64) {
        _ = dataSource?.updateOne(uid: uid) { record in
            record.isPinned = isTop
            return [ConversationRecord.CodingKeys.isPinned.rawValue]
        }
    }

    public func updateConversationRemarkName(_ remarkName: String, uid: Int64) {
        _ = dataSource?.updateOne(uid: uid) { record in
            record.remarkName = remarkName
            return [ConversationRecord.CodingKeys.remarkName.rawValue]
        }
    }

    public func updateConversationTargetId(_ targetId: String, nickname: String, avatar: String, uid: Int64) {
        _ = dataSource?.updateOne(uid: uid) { record in
            record.targetId = targetId
            record.name = nickname
            record.avatarURL = avatar
            return [
                ConversationRecord.CodingKeys.targetId.rawValue,
                ConversationRecord.CodingKeys.name.rawValue,
                ConversationRecord.CodingKeys.avatarURL.rawValue,
            ]
        }
    }

    public func updateConversationMemberInfo(withMemberType memberType: Int, memberLevel: String,
        memberImg: String, area: String, remarkName: String, uid: Int64) {
        _ = dataSource?.updateOne(uid: uid) { record in
            record.memberType = memberType
            record.memberLevel = memberLevel
            record.memberImage = memberImg
            record.area = area
            record.remarkName = remarkName
            return [
                ConversationRecord.CodingKeys.memberType.rawValue,
                ConversationRecord.CodingKeys.memberLevel.rawValue,
                ConversationRecord.CodingKeys.memberImage.rawValue,
                ConversationRecord.CodingKeys.area.rawValue,
                ConversationRecord.CodingKeys.remarkName.rawValue,
            ]
        }
    }

    public func updateConversationMessage(withContent content: String, msgUUID: String, timestamp: Int64,
        isSelf: Bool, isCallBack: Bool, count: Int, clearCount: Bool, receiver: Int64) {
        _ = dataSource?.updateOne(uid: receiver) { record in
            record.content = content
            record.uuid = msgUUID
            // TODO: timestamp Int64
            record.timestamp = Int(timestamp)
            record.isFromSelf = isSelf
            record.isRevoked = isCallBack
            if clearCount {
                record.newMessageCount = 0
            } else {
                // TODO: count Int32
                record.newMessageCount += Int32(count)
            }
            return [
                ConversationRecord.CodingKeys.content.rawValue,
                ConversationRecord.CodingKeys.uuid.rawValue,
                ConversationRecord.CodingKeys.timestamp.rawValue,
                ConversationRecord.CodingKeys.isFromSelf.rawValue,
                ConversationRecord.CodingKeys.isRevoked.rawValue,
                ConversationRecord.CodingKeys.newMessageCount.rawValue,
            ]
        }
    }

    public func getConversationNewMsgCount(withReceiver receiver: Int64) -> Int {
        guard let result = dataSource?.selectOnSync(uid: receiver) else {
            return 0
        }
        switch result {
        case let .success(value):
            return Int(value?.newMessageCount ?? 0)
        case .failure:
            return 0
        }
    }

    public func getAllConversationNewMsgCount() -> Int {
        let result = dataSource?.sumAllNewMessageCount()
        return (result?.unwrap(or: 0)) ?? 0
    }

    public func getConversationWithTargetUid(_ targetUid: Int64) -> Conversation {
        guard let result = dataSource?.selectOnSync(uid: targetUid) else {
            return Conversation()
        }
        // TODO: Result.unwrap(or:)
        return ConversationRecordData(record: result.unwrap(or: ConversationRecord()) ?? ConversationRecord())
    }

    public func updateConversationSendFailedStatus(_ haveFailed: Bool, targetUid: Int64) {
        _ = dataSource?.updateOne(uid: targetUid) { record in
            record.isUnsent = haveFailed
            return [ConversationRecord.CodingKeys.isUnsent.rawValue]
        }
    }

    public func updateConversationCallBackStatus(withMsgUUIDs uuids: [String]) {
        _ = dataSource?.setAllIsRevoked(uuids: uuids)
    }

    public func manualCheckConversationDBColumn() {
        // Do nothing.
    }
}
