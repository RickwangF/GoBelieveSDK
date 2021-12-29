//
// Created by Nan Yang on 2021/12/23.
//

import GRDB

// -- auto-generated definition
// create table gb_conversation
// (
//     id                INTEGER      not null
//         primary key autoincrement,
//     conversationid    integer(256) not null,
//     avatar            TEXT(256),
//     nickname          TEXT(64),
//     timestamp         integer(256),
//     content           TEXT(256),
//     msguuid           text(256)    not null,
//     is_callback       integer(32)  not null,
//     is_group          integer(32)  not null,
//     is_delete         integer(32)  not null,
//     is_top            integer(32)  not null,
//     unreadcount       integer(256) not null,
//     member_type       integer(256),
//     member_level      integer(256),
//     member_img        TEXT(256),
//     draft             text(256),
//     unsend_tag        integer(32),
//     target_id         text(256),
//     is_self           integer(32),
//     area              TEXT(256),
//     remark_name       TEXT(256),
//     conversation_type integer(32)  not null
// );
public struct ConversationRecord: ConversationEntity, Hashable, Codable, FetchableRecord, PersistableRecord {
    public var id: Int64?
    public var targetUid: Int64 // uid
    public var avatarURL: String // avatarURL
    public var name: String // name
    public var timestamp: Int // timestamp
    public var content: String // content
    public var uuid: String // msguuid
    public var isRevoked: Bool // isCallback
    public var isGroup: Bool // isGroup
    public var isDeleted: Bool // isDelete
    public var isPinned: Bool // isTop
    public var newMessageCount: Int32 // newMsgCount
    public var memberType: Int // memberType
    public var memberLevel: String // memberLevel
    public var memberImage: String // memberImg
    public var draft: String // draft
    public var isUnsent: Bool // unsendTag
    public var targetId: String // targetId
    public var isFromSelf: Bool // is_self
    public var area: String // area
    public var remarkName: String // remarkName
    public var conversationType: Int // conversationType

    init(id: Int64?, targetUid: Int64, avatarURL: String, name: String, timestamp: Int, content: String,
        uuid: String, isRevoked: Bool, isGroup: Bool, isDeleted: Bool, isPinned: Bool, newMessageCount: Int32,
        memberType: Int, memberLevel: String, memberImage: String, draft: String, isUnsent: Bool, targetId: String,
        isFromSelf: Bool, area: String, remarkName: String, conversationType: Int) {
        self.id = id
        self.targetUid = targetUid
        self.avatarURL = avatarURL
        self.name = name
        self.timestamp = timestamp
        self.content = content
        self.uuid = uuid
        self.isRevoked = isRevoked
        self.isGroup = isGroup
        self.isDeleted = isDeleted
        self.isPinned = isPinned
        self.newMessageCount = newMessageCount
        self.memberType = memberType
        self.memberLevel = memberLevel
        self.memberImage = memberImage
        self.draft = draft
        self.isUnsent = isUnsent
        self.targetId = targetId
        self.isFromSelf = isFromSelf
        self.area = area
        self.remarkName = remarkName
        self.conversationType = conversationType
    }

    init() {
        id = nil
        targetUid = 0
        avatarURL = ""
        name = ""
        timestamp = 0
        content = ""
        uuid = ""
        isRevoked = false
        isGroup = false
        isDeleted = false
        isPinned = false
        newMessageCount = 0
        memberType = 0
        memberLevel = ""
        memberImage = ""
        draft = ""
        isUnsent = false
        targetId = ""
        isFromSelf = false
        area = ""
        remarkName = ""
        conversationType = 0
    }

    mutating public func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }

    public static var databaseTableName: String {
        "gb_conversation"
    }

    static var selectCount: String {
        "select count(*) from gb_conversation where conversationid = ?;"
    }

    static var selectSortedAll: String {
        """
        select *
        from gb_conversation
        where is_delete = 0
        group by is_top, timestamp, conversationid
        order by is_top desc, timestamp desc;
        """
    }

    static var updateNewMessageCount: String {
        "UPDATE gb_conversation SET unreadcount = ? WHERE conversationid = ?"
    }

    static var sumAllNewMessageCount: String {
        "SELECT SUM(unreadcount) FROM gb_conversation"
    }

    static var mergeSchemeV1: String {
        "alter table gb_conversation add conversation_type integer not null default 0;"
    }
    
    static var mergeSchemeV2: String {
        "create unique index conversation_index on gb_conversation (conversationid);"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case targetUid = "conversationid"
        case avatarURL = "avatar"
        case name = "nickname"
        case timestamp = "timestamp"
        case content = "content"
        case uuid = "msguuid"
        case isRevoked = "is_callback"
        case isGroup = "is_group"
        case isDeleted = "is_delete"
        case isPinned = "is_top"
        case newMessageCount = "unreadcount"
        case memberType = "member_type"
        case memberLevel = "member_level"
        case memberImage = "member_img"
        case draft = "draft"
        case isUnsent = "unsend_tag"
        case targetId = "target_id"
        case isFromSelf = "is_self"
        case area = "area"
        case remarkName = "remark_name"
        case conversationType = "conversation_type"
    }
}

extension ConversationRecord {
    init(from conversation: Conversation) {
        if let data = conversation as? ConversationRecordData {
            self = data.record
        } else {
            self.init(id: nil,
                targetUid: conversation.uid,
                avatarURL: conversation.avatarURL ?? "",
                name: conversation.name ?? "",
                timestamp: conversation.timestamp,
                content: conversation.content ?? "",
                uuid: conversation.msguuid ?? "", 
                isRevoked: conversation.isCallback,
                isGroup: conversation.isGroup,
                isDeleted: conversation.isDelete,
                isPinned: conversation.isTop,
                newMessageCount: conversation.newMsgCount,
                memberType: conversation.memberType,
                memberLevel: conversation.memberLevel ?? "",
                memberImage: conversation.memberImg ?? "",
                draft: conversation.draft ?? "",
                isUnsent: conversation.unsendTag,
                targetId: conversation.targetId ?? "",
                isFromSelf: conversation.is_self,
                area: conversation.area ?? "",
                remarkName: conversation.remarkName ?? "",
                conversationType: conversation.conversationType)
        }
    }
}
