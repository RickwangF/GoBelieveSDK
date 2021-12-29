//
// Created by Nan Yang on 2021/12/23.
//

import Foundation

public final class ConversationRecordData: Conversation {
    private(set) var record: ConversationRecord

    init(record: ConversationRecord) {
        self.record = record
        super.init()
    }

    public override init() {
        record = ConversationRecord()
        super.init()
    }

    public override var name: String? {
        get {
            record.name
        }
        set {
            record.name = newValue ?? ""
        }
    }
    public override var avatarURL: String? {
        get {
            record.avatarURL
        }
        set {
            record.avatarURL = newValue ?? ""
        }
    }
    public override var content: String? {
        get {
            record.content
        }
        set {
            record.content = newValue ?? ""
        }
    }
    public override var msguuid: String? {
        get {
            record.uuid
        }
        set {
            record.uuid = newValue ?? ""
        }
    }
    public override var uid: Int64 {
        get {
            record.targetUid
        }
        set {
            record.targetUid = newValue
        }
    }
    public override var targetId: String? {
        get {
            record.targetId
        }
        set {
            record.targetId = newValue ?? ""
        }
    }
    public override var isTop: Bool {
        get {
            record.isPinned
        }
        set {
            record.isPinned = newValue
        }
    }
    public override var isCallback: Bool {
        get {
            record.isRevoked
        }
        set {
            record.isRevoked = newValue
        }
    }
    public override var isDelete: Bool {
        get {
            record.isDeleted
        }
        set {
            record.isDeleted = newValue
        }
    }
    public override var isGroup: Bool {
        get {
            record.isGroup
        }
        set {
            record.isGroup = newValue
        }
    }
    public override var memberLevel: String? {
        get {
            record.memberLevel
        }
        set {
            record.memberLevel = newValue ?? ""
        }
    }
    public override var memberType: Int {
        get {
            record.memberType
        }
        set {
            record.memberType = newValue
        }
    }
    public override var memberImg: String? {
        get {
            record.memberImage
        }
        set {
            record.memberImage = newValue ?? ""
        }
    }
    public override var draft: String? {
        get {
            record.draft
        }
        set {
            record.draft = newValue ?? ""
        }
    }
    public override var unsendTag: Bool {
        get {
            record.isUnsent
        }
        set {
            record.isUnsent = newValue
        }
    }
    public override var newMsgCount: Int32 {
        get {
            record.newMessageCount
        }
        set {
            record.newMessageCount = newValue
        }
    }
    public override var timestamp: Int {
        get {
            record.timestamp
        }
        set {
            record.timestamp = newValue
        }
    }
    public override var is_self: Bool {
        get {
            record.isFromSelf
        }
        set {
            record.isFromSelf = newValue
        }
    }
    public override var area: String? {
        get {
            record.area
        }
        set {
            record.area = newValue ?? ""
        }
    }
    public override var remarkName: String? {
        get {
            record.remarkName
        }
        set {
            record.remarkName = newValue ?? ""
        }
    }
    public override var conversationType: Int {
        get {
            record.conversationType
        }
        set {
            record.conversationType = newValue
        }
    }
}
